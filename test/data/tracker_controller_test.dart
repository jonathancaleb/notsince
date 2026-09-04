import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notsince/core/prefs/app_prefs.dart';
import 'package:notsince/features/notifications/data/notification_service.dart';
import '../support/fakes.dart';
import 'package:hive_ce/hive.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/features/counter/data/tracker_repository.dart';
import 'package:notsince/features/counter/domain/milestones.dart';
import 'package:notsince/features/counter/domain/tracker.dart';
import 'package:notsince/core/hive/hive_registrar.g.dart';

class _FixedClock implements Clock {
  _FixedClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void set(DateTime value) => _now = value;
}

void main() {
  late Directory dir;
  late Box<Tracker> box;
  late _FixedClock clock;
  late ProviderContainer container;
  late FakePrefs prefs;
  late FakeNotifications notifications;

  final start = DateTime(2026, 1, 1, 12);

  Future<void> openContainer() async {
    box = await Hive.openBox<Tracker>(TrackerRepository.boxName);
    await TrackerRepository.migrate(box);
    container = ProviderContainer(
      overrides: [
        appPrefsProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notifications),
        trackerBoxProvider.overrideWithValue(box),
        clockProvider.overrideWithValue(clock),
      ],
    );
  }

  setUp(() async {
    prefs = FakePrefs();
    notifications = FakeNotifications();
    dir = await Directory.systemTemp.createTemp('notsince_test');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapters();
    clock = _FixedClock(start);
    await openContainer();
  });

  tearDown(() async {
    container.dispose();
    // deleteFromDisk already closes every open box; calling Hive.close() as
    // well leaves a closed box cached under the same name, which then breaks
    // the next test's writes.
    await Hive.deleteFromDisk();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  TrackersController controller() =>
      container.read(trackersProvider.notifier);
  List<Tracker> trackers() => container.read(trackersProvider);

  Tracker make({String name = 'Drinking', DateTime? at, String emoji = '🍺'}) {
    return controller().create(
      name: name,
      startedAt: at ?? start,
      emoji: emoji,
      colorIndex: 0,
    );
  }

  test('starts with no counters', () {
    expect(trackers(), isEmpty);
  });

  test('create persists through a round trip', () {
    final created = make(name: '  Drinking  ');

    expect(created.id, isNotEmpty);
    expect(trackers().single.name, 'Drinking');

    final stored = box.get(created.id)!;
    expect(stored.name, 'Drinking');
    expect(stored.startedAt, start);
    expect(stored.emoji, '🍺');
    expect(stored.milestones, kDefaultMilestones);
    expect(stored.history, isEmpty);
  });

  test('counters get distinct ids and consecutive positions', () {
    final a = make(name: 'Drinking');
    final b = make(name: 'Smoking', emoji: '🚬');

    expect(a.id, isNot(b.id));
    expect(trackers().map((t) => t.sortIndex), [0, 1]);
  });

  test('editing one counter leaves the others alone', () {
    final a = make(name: 'Drinking');
    final b = make(name: 'Smoking', emoji: '🚬');

    controller().rename(a.id, 'Beer');

    expect(container.read(trackerProvider(a.id))!.name, 'Beer');
    expect(container.read(trackerProvider(b.id))!.name, 'Smoking');
  });

  test('reorder rewrites positions and survives a reload', () async {
    final a = make(name: 'Drinking');
    final b = make(name: 'Smoking', emoji: '🚬');
    final c = make(name: 'Coffee', emoji: '☕');

    // Drag the last counter to the front.
    controller().reorder(2, 0);
    expect(trackers().map((t) => t.name), ['Coffee', 'Drinking', 'Smoking']);
    expect(trackers().map((t) => t.sortIndex), [0, 1, 2]);

    // A fresh container reads the order back off disk, not out of memory.
    container.dispose();
    await openContainer();
    expect(trackers().map((t) => t.id), [c.id, a.id, b.id]);
  });

  test('delete removes one counter and closes the gap in positions', () async {
    make(name: 'Drinking');
    final b = make(name: 'Smoking', emoji: '🚬');
    make(name: 'Coffee', emoji: '☕');

    await controller().delete(b.id);

    expect(trackers().map((t) => t.name), ['Drinking', 'Coffee']);
    expect(trackers().map((t) => t.sortIndex), [0, 1]);
    expect(box.get(b.id), isNull);
  });

  test('wipeAll empties the box', () async {
    make(name: 'Drinking');
    make(name: 'Smoking', emoji: '🚬');

    final wiped = controller().wipeAll();
    // State updates synchronously; persistence catches up.
    expect(trackers(), isEmpty);

    await wiped;
    expect(box.isEmpty, isTrue);
  });

  test('reset closes the run into history and restarts the count', () {
    final t = make();
    final resetAt = start.add(const Duration(days: 12));
    clock.set(resetAt);

    controller().reset(t.id);

    final updated = container.read(trackerProvider(t.id))!;
    expect(updated.startedAt, resetAt);
    expect(updated.history, hasLength(1));
    expect(updated.history.single.startedAt, start);
    expect(updated.history.single.length, const Duration(days: 12));
  });

  test('reset clears acknowledgements so milestones can be met again', () {
    final t = make();
    clock.set(start.add(const Duration(days: 8)));
    controller().acknowledgeMilestone(t.id, const Duration(days: 7));
    expect(container.read(trackerProvider(t.id))!.acknowledged,
        {const Duration(days: 7)});

    controller().reset(t.id);
    expect(container.read(trackerProvider(t.id))!.acknowledged, isEmpty);
  });

  test('a past run length survives editing the current start time', () {
    final t = make();
    final resetAt = start.add(const Duration(days: 12));
    clock.set(resetAt);
    controller().reset(t.id);

    // Backdate the *current* run. The finished run must be unaffected — this
    // is why runs store their own end, rather than being derived pairwise.
    controller()
        .editStartedAt(t.id, resetAt.subtract(const Duration(days: 5)));

    expect(container.read(trackerProvider(t.id))!.history.single.length,
        const Duration(days: 12));
  });

  test('reset never runs backwards past the start of the run it closes', () {
    final t = make();
    clock.set(start.subtract(const Duration(days: 3)));

    controller().reset(t.id);

    final updated = container.read(trackerProvider(t.id))!;
    expect(updated.history.single.length, Duration.zero);
    expect(updated.startedAt, start);
  });

  test('editing the start time drops now-unreached acknowledgements', () {
    final t = make();
    clock.set(start.add(const Duration(days: 8)));
    controller().acknowledgeMilestone(t.id, const Duration(hours: 24));
    controller().acknowledgeMilestone(t.id, const Duration(days: 7));

    // Move the start forward so only 2 days have elapsed.
    controller()
        .editStartedAt(t.id, clock.now().subtract(const Duration(days: 2)));

    expect(container.read(trackerProvider(t.id))!.acknowledged,
        {const Duration(hours: 24)});
  });

  test('setMilestones dedupes, sorts and drops orphaned acknowledgements', () {
    final t = make();
    clock.set(start.add(const Duration(days: 40)));
    controller().acknowledgeMilestone(t.id, const Duration(days: 30));

    controller().setMilestones(t.id, const [
      Duration(days: 7),
      Duration(hours: 24),
      Duration(days: 7),
      Duration.zero,
    ]);

    final updated = container.read(trackerProvider(t.id))!;
    expect(updated.milestones, const [Duration(hours: 24), Duration(days: 7)]);
    // The 1-month acknowledgement no longer refers to a configured threshold.
    expect(updated.acknowledged, isEmpty);
  });

  test('creating a habit schedules its milestones', () {
    final t = make();
    expect(notifications.habits[t.id], isTrue);
  });

  test('a reset reschedules milestones from the new start', () {
    final t = make();
    notifications.habits.clear();

    clock.set(start.add(const Duration(days: 12)));
    controller().reset(t.id);

    expect(notifications.habits[t.id], isTrue);
  });

  test('deleting a habit cancels its milestones', () async {
    final t = make();
    await controller().delete(t.id);
    expect(notifications.cancelledHabits, contains(t.id));
  });

  test('wiping everything cancels every scheduled notification', () async {
    make();
    await controller().wipeAll();
    expect(notifications.cancelledEverything, isTrue);
  });

  test('milestones are not scheduled when the setting is off', () {
    prefs.milestones = false;
    final t = make();
    expect(notifications.habits[t.id], isFalse);
  });

  test('rename ignores blank input', () {
    final t = make();
    controller().rename(t.id, '   ');
    expect(container.read(trackerProvider(t.id))!.name, 'Drinking');
  });

  group('migration from the single-counter schema', () {
    test('adopts the legacy record, keeping its count and history', () async {
      container.dispose();

      // Exactly what the previous version wrote: one record, no id, at 'current'.
      await box.put(
        TrackerRepository.legacyKey,
        Tracker(
          name: 'Drinking',
          startedAt: start,
          acknowledged: {const Duration(hours: 24)},
        ),
      );
      await box.close();

      await openContainer();

      final migrated = trackers().single;
      expect(migrated.id, isNotEmpty);
      expect(migrated.name, 'Drinking');
      expect(migrated.startedAt, start);
      expect(migrated.acknowledged, {const Duration(hours: 24)});
      expect(migrated.sortIndex, 0);
      expect(box.get(TrackerRepository.legacyKey), isNull);
    });

    test('is a no-op when there is nothing to migrate', () async {
      final t = make();
      container.dispose();
      await box.close();

      await openContainer();

      expect(trackers().single.id, t.id);
    });
  });
}
