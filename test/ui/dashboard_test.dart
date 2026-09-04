import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notsince/core/prefs/app_prefs.dart';
import 'package:notsince/features/notifications/data/notification_service.dart';
import '../support/fakes.dart';
import 'package:hive_ce/hive.dart';
import 'package:notsince/core/hive/hive_registrar.g.dart';
import 'package:notsince/core/theme/app_theme.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/features/alarms/application/alarms_controller.dart';
import 'package:notsince/features/alarms/data/alarm_repository.dart';
import 'package:notsince/features/alarms/data/alarm_scheduler.dart';
import 'package:notsince/features/alarms/domain/alarm_entry.dart';
import 'package:notsince/features/counter/application/progress_provider.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/features/counter/data/tracker_repository.dart';
import 'package:notsince/features/counter/domain/tracker.dart';
import 'package:notsince/features/notes/application/notes_controller.dart';
import 'package:notsince/features/notes/data/note_repository.dart';
import 'package:notsince/features/notes/domain/note.dart';
import 'package:notsince/features/shell/home_shell.dart';

class _FixedClock implements Clock {
  const _FixedClock(this._now);

  final DateTime _now;

  @override
  DateTime now() => _now;
}

/// Does nothing: the platform scheduler has no implementation in a widget test,
/// and none of this is about whether an alarm actually rings.
class _NoScheduler implements AlarmScheduler {
  const _NoScheduler();

  @override
  Future<void> sync(AlarmEntry entry, {DateTime? from}) async {}
  @override
  Future<void> cancel(AlarmEntry entry) async {}
  @override
  Future<void> cancelId(int scheduleId) async {}
  @override
  Future<void> reconcile(List<AlarmEntry> entries, {DateTime? from}) async {}
  @override
  Future<void> snooze(AlarmEntry entry, {DateTime? from}) async {}
}

/// Renders the shell and dashboard for real.
///
/// The dashboard stacks a hero card, a two-up row and a horizontal strip above
/// a bottom nav — the kind of layout that only reveals an overflow at runtime.
/// Widget tests fail on overflow, so pumping it is the check.
///
/// Reading only: data is seeded through `tester.runAsync`, because
/// `testWidgets` runs its body in a fake-async zone where Hive's real disk
/// writes never complete, which then hangs teardown.
void main() {
  late Directory dir;
  late Box<Tracker> trackerBox;
  late Box<AlarmEntry> alarmBox;
  late Box<Note> noteBox;
  late Box<dynamic> prefsBox;
  late ProviderContainer container;
  late FakePrefs prefs;
  late FakeNotifications notifications;

  final now = DateTime(2026, 3, 4, 6); // Wednesday

  setUp(() async {
    prefs = FakePrefs();
    notifications = FakeNotifications();
    dir = await Directory.systemTemp.createTemp('notsince_dash');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapters();
    trackerBox = await Hive.openBox<Tracker>(TrackerRepository.boxName);
    alarmBox = await Hive.openBox<AlarmEntry>(AlarmRepository.boxName);
    noteBox = await Hive.openBox<Note>(NoteRepository.boxName);
    prefsBox = await Hive.openBox<dynamic>(AppPrefs.boxName);

    container = ProviderContainer(
      overrides: [
        appPrefsProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notifications),
        trackerBoxProvider.overrideWithValue(trackerBox),
        alarmBoxProvider.overrideWithValue(alarmBox),
        noteBoxProvider.overrideWithValue(noteBox),
        appPrefsBoxProvider.overrideWithValue(prefsBox),
        clockProvider.overrideWithValue(_FixedClock(now)),
        alarmSchedulerProvider.overrideWithValue(const _NoScheduler()),
        nowProvider.overrideWith((ref) => now),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await Hive.deleteFromDisk();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<void> seed(WidgetTester tester) async {
    await tester.runAsync(() async {
      container.read(trackersProvider.notifier).create(
            name: 'Drinking',
            startedAt: now.subtract(const Duration(days: 12)),
            emoji: '🍺',
            colorIndex: 0,
          );
      await container.read(alarmsProvider.notifier).create(
            label: 'Wake up',
            hour: 6,
            minute: 30,
            repeatDays: const [1, 2, 3, 4, 5],
            soundId: 'chime',
          );
      final note = container.read(notesProvider.notifier).create();
      container
          .read(notesProvider.notifier)
          .save(note.id, title: 'Shopping', body: 'Milk, bread');

      await trackerBox.flush();
      await alarmBox.flush();
      await noteBox.flush();
    });
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildLightTheme(), home: const HomeShell()),
      ),
    );
    await tester.pump();
  }

  testWidgets('the dashboard shows all three domains at once', (tester) async {
    await seed(tester);
    await pump(tester);

    // Counter hero.
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Drinking'), findsOneWidget);
    // 12 days clears 24 hours and 1 week, so two of six stops.
    expect(find.textContaining('2 of 6'), findsWidgets);
    // Next alarm, which today is 06:30 on a weekday.
    expect(find.text('06:30'), findsOneWidget);
    expect(find.text('Weekdays'), findsOneWidget);
    // The recent strip sits below the fold on a small viewport, and a ListView
    // only builds what is on screen.
    // The page, the milestone track and the notes strip are all scrollables,
    // so the outer one has to be named explicitly.
    await tester.scrollUntilVisible(
      find.text('Lately'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Lately'), findsOneWidget);
    expect(find.text('Shopping'), findsWidgets);
  });

  testWidgets('an empty dashboard invites the first counter', (tester) async {
    await pump(tester);

    expect(find.text('Nothing is being counted yet.'), findsOneWidget);
    expect(find.text('None set'), findsOneWidget);
  });

  testWidgets('the nav moves between tabs', (tester) async {
    await seed(tester);
    await pump(tester);

    await tester.tap(find.text('Alarms'));
    await tester.pumpAndSettle();
    expect(find.text('Wake up  ·  Weekdays'), findsOneWidget);

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(find.text('Create note or task'), findsOneWidget);

    await tester.tap(find.text('Habit'));
    await tester.pumpAndSettle();
    expect(find.text('Start a new count'), findsOneWidget);
  });

  testWidgets('a dashboard summary card hands off to its tab', (tester) async {
    await seed(tester);
    await pump(tester);

    // Scroll the card clear of the floating nav island before tapping it —
    // the island overlays the bottom of the page, so anything under it is not
    // hit-testable until the content scrolls out from beneath.
    await tester.scrollUntilVisible(
      find.text('Weekdays'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Tapping the alarm summary should switch tabs, not stack a second screen.
    await tester.tap(find.text('Weekdays'));
    await tester.pumpAndSettle();

    expect(find.text('Add an alarm'), findsOneWidget);
    expect(container.read(homeTabProvider), HomeTab.alarms);
  });
}
