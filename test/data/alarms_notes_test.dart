import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notsince/core/prefs/app_prefs.dart';
import 'package:notsince/features/notifications/data/notification_service.dart';
import '../support/fakes.dart';
import 'package:hive_ce/hive.dart';
import 'package:notsince/core/hive/hive_registrar.g.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/features/alarms/application/alarms_controller.dart';
import 'package:notsince/features/alarms/data/alarm_repository.dart';
import 'package:notsince/features/alarms/data/alarm_scheduler.dart';
import 'package:notsince/features/alarms/domain/alarm_entry.dart';
import 'package:notsince/features/notes/application/notes_controller.dart';
import 'package:notsince/features/notes/data/note_repository.dart';
import 'package:notsince/features/notes/domain/note.dart';

class _FixedClock implements Clock {
  _FixedClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void set(DateTime value) => _now = value;
}

/// Records what the platform was asked to do, without touching the platform.
/// The real scheduler talks to the `alarm` plugin, which has no implementation
/// in a unit test.
class _FakeScheduler implements AlarmScheduler {
  final scheduled = <String, DateTime>{};
  final cancelled = <String>[];
  final snoozed = <String>[];

  @override
  Future<void> sync(AlarmEntry entry, {DateTime? from}) async {
    final at = entry.isEnabled ? entry.nextOccurrence(from ?? DateTime.now()) : null;
    if (at == null) {
      scheduled.remove(entry.id);
      cancelled.add(entry.id);
    } else {
      scheduled[entry.id] = at;
    }
  }

  @override
  Future<void> cancel(AlarmEntry entry) async {
    scheduled.remove(entry.id);
    cancelled.add(entry.id);
  }

  @override
  Future<void> cancelId(int scheduleId) async {}

  @override
  Future<void> reconcile(List<AlarmEntry> entries, {DateTime? from}) async {
    scheduled.clear();
    for (final e in entries.where((e) => e.isEnabled)) {
      await sync(e, from: from);
    }
  }

  @override
  Future<void> snooze(AlarmEntry entry, {DateTime? from}) async {
    snoozed.add(entry.id);
  }
}

void main() {
  late Directory dir;
  late Box<AlarmEntry> alarmBox;
  late Box<Note> noteBox;
  late _FixedClock clock;
  late _FakeScheduler scheduler;
  late ProviderContainer container;
  late FakePrefs prefs;
  late FakeNotifications notifications;

  final now = DateTime(2026, 3, 4, 6); // Wednesday

  Future<void> openContainer() async {
    alarmBox = await Hive.openBox<AlarmEntry>(AlarmRepository.boxName);
    noteBox = await Hive.openBox<Note>(NoteRepository.boxName);
    container = ProviderContainer(
      overrides: [
        appPrefsProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notifications),
        alarmBoxProvider.overrideWithValue(alarmBox),
        noteBoxProvider.overrideWithValue(noteBox),
        clockProvider.overrideWithValue(clock),
        alarmSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
  }

  setUp(() async {
    prefs = FakePrefs();
    notifications = FakeNotifications();
    dir = await Directory.systemTemp.createTemp('notsince_an');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapters();
    clock = _FixedClock(now);
    scheduler = _FakeScheduler();
    await openContainer();
  });

  tearDown(() async {
    container.dispose();
    await Hive.deleteFromDisk();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  group('alarms', () {
    AlarmsController controller() => container.read(alarmsProvider.notifier);

    test('creating an alarm persists it and schedules it', () async {
      final entry = await controller().create(
        label: 'Wake up',
        hour: 7,
        minute: 30,
        repeatDays: const [],
        soundId: 'chime',
      );

      expect(alarmBox.get(entry.id)!.label, 'Wake up');
      expect(scheduler.scheduled[entry.id], DateTime(2026, 3, 4, 7, 30));
    });

    test('a blank label falls back rather than showing an empty row', () async {
      final entry = await controller().create(
        label: '   ',
        hour: 7,
        minute: 0,
        repeatDays: const [],
        soundId: 'chime',
      );
      expect(entry.label, 'Alarm');
    });

    test('repeat days are deduped, sorted and range-checked', () async {
      final entry = await controller().create(
        label: 'Gym',
        hour: 6,
        minute: 0,
        repeatDays: const [5, 1, 1, 9, 0, 3],
        soundId: 'chime',
      );
      expect(entry.repeatDays, const [1, 3, 5]);
    });

    test('disabling cancels the platform alarm but keeps the row', () async {
      final entry = await controller().create(
        label: 'Wake up',
        hour: 7,
        minute: 0,
        repeatDays: const [],
        soundId: 'chime',
      );

      await controller().setEnabled(entry.id, false);

      expect(container.read(alarmsProvider), hasLength(1));
      expect(scheduler.scheduled.containsKey(entry.id), isFalse);
      expect(scheduler.cancelled, contains(entry.id));
      expect(alarmBox.get(entry.id)!.isEnabled, isFalse);
    });

    test('deleting removes it from the box and the schedule', () async {
      final entry = await controller().create(
        label: 'Wake up',
        hour: 7,
        minute: 0,
        repeatDays: const [],
        soundId: 'chime',
      );

      await controller().delete(entry.id);

      expect(container.read(alarmsProvider), isEmpty);
      expect(alarmBox.get(entry.id), isNull);
      expect(scheduler.cancelled, contains(entry.id));
    });

    test('a one-off alarm disables itself after ringing', () async {
      final entry = await controller().create(
        label: 'Once',
        hour: 7,
        minute: 0,
        repeatDays: const [],
        soundId: 'chime',
      );

      clock.set(DateTime(2026, 3, 4, 7, 1));
      await controller().settleAfterRing(entry.id);

      expect(container.read(alarmProvider(entry.id))!.isEnabled, isFalse);
    });

    test('a repeating alarm stays enabled and re-schedules', () async {
      final entry = await controller().create(
        label: 'Daily',
        hour: 7,
        minute: 0,
        repeatDays: const [1, 2, 3, 4, 5, 6, 7],
        soundId: 'chime',
      );

      clock.set(DateTime(2026, 3, 4, 7, 1));
      await controller().settleAfterRing(entry.id);

      expect(container.read(alarmProvider(entry.id))!.isEnabled, isTrue);
      expect(scheduler.scheduled[entry.id], DateTime(2026, 3, 5, 7));
    });

    test('the list is ordered by time of day', () async {
      await controller().create(
          label: 'Late', hour: 22, minute: 0, repeatDays: const [], soundId: 'chime');
      await controller().create(
          label: 'Early', hour: 6, minute: 15, repeatDays: const [], soundId: 'chime');

      expect(container.read(alarmsProvider).map((a) => a.label),
          ['Early', 'Late']);
    });

    test('nextAlarm picks the soonest enabled one', () async {
      final later = await controller().create(
          label: 'Later', hour: 9, minute: 0, repeatDays: const [], soundId: 'chime');
      final sooner = await controller().create(
          label: 'Sooner', hour: 7, minute: 0, repeatDays: const [], soundId: 'chime');

      expect(container.read(nextAlarmProvider)!.entry.id, sooner.id);

      await controller().setEnabled(sooner.id, false);
      expect(container.read(nextAlarmProvider)!.entry.id, later.id);
    });

    test('reconcile rebuilds the schedule from storage', () async {
      await controller().create(
          label: 'On', hour: 7, minute: 0, repeatDays: const [], soundId: 'chime');
      final off = await controller().create(
          label: 'Off', hour: 8, minute: 0, repeatDays: const [], soundId: 'chime');
      await controller().setEnabled(off.id, false);

      // Stands in for a reboot: the OS forgot everything.
      scheduler.scheduled.clear();
      await scheduler.reconcile(container.read(alarmsProvider), from: now);

      expect(scheduler.scheduled.keys, hasLength(1));
      expect(scheduler.scheduled.containsKey(off.id), isFalse);
    });
  });

  group('prefs', () {
    test('the onboarding flag survives a real box', () async {
      final box = await Hive.openBox<dynamic>(AppPrefs.boxName);
      final prefs = AppPrefs(box);

      expect(prefs.hasOnboarded, isFalse);
      await prefs.setOnboarded();
      expect(prefs.hasOnboarded, isTrue);

      // A wipe has to put the app back to how it shipped, onboarding included.
      await prefs.clear();
      expect(prefs.hasOnboarded, isFalse);
    });
  });

  group('notes', () {
    NotesController controller() => container.read(notesProvider.notifier);

    test('saving keeps the note and bumps updatedAt', () {
      final note = controller().create();
      clock.set(now.add(const Duration(minutes: 5)));

      controller().save(note.id, title: 'Shopping', body: 'Milk');

      final saved = container.read(noteProvider(note.id))!;
      expect(saved.title, 'Shopping');
      expect(saved.updatedAt, now.add(const Duration(minutes: 5)));
      expect(noteBox.get(note.id)!.body, 'Milk');
    });

    test('a note left completely blank is removed rather than saved', () {
      final note = controller().create();

      controller().save(note.id, title: '   ', body: '\n');

      expect(container.read(notesProvider), isEmpty);
    });

    test('a note with only a body keeps its first line as a title', () {
      final note = controller().create();
      controller().save(note.id, title: '', body: 'Call the dentist\nand book');

      expect(container.read(noteProvider(note.id))!.displayTitle,
          'Call the dentist');
    });

    test('the list is most recently edited first', () {
      final first = controller().create();
      controller().save(first.id, title: 'First', body: 'a');

      clock.set(now.add(const Duration(minutes: 1)));
      final second = controller().create();
      controller().save(second.id, title: 'Second', body: 'b');

      expect(container.read(notesProvider).map((n) => n.title),
          ['Second', 'First']);

      clock.set(now.add(const Duration(minutes: 2)));
      controller().save(first.id, title: 'First', body: 'edited');

      expect(container.read(notesProvider).map((n) => n.title),
          ['First', 'Second']);
    });

    test('a task can be ticked and un-ticked', () {
      final task = controller().create(isTask: true);
      controller().save(task.id, title: 'Call the dentist', body: '');

      controller().setDone(task.id, true);
      final done = container.read(noteProvider(task.id))!;
      expect(done.isDone, isTrue);
      expect(done.completedAt, isNotNull);

      controller().setDone(task.id, false);
      final open = container.read(noteProvider(task.id))!;
      expect(open.isDone, isFalse);
      expect(open.completedAt, isNull);
    });

    test('ticking a note does nothing, since it has nothing to finish', () {
      final note = controller().create();
      controller().save(note.id, title: 'Just a note', body: '');

      controller().setDone(note.id, true);

      expect(container.read(noteProvider(note.id))!.isDone, isFalse);
    });

    test('finished tasks sink below everything else', () {
      final task = controller().create(isTask: true);
      controller().save(task.id, title: 'Old task', body: '');

      clock.set(now.add(const Duration(minutes: 1)));
      final note = controller().create();
      controller().save(note.id, title: 'A note', body: '');

      // Ticking touches the task most recently, but it must not jump the queue.
      clock.set(now.add(const Duration(minutes: 2)));
      controller().setDone(task.id, true);

      expect(container.read(notesProvider).map((n) => n.title),
          ['A note', 'Old task']);
    });

    test('turning a task back into a note clears its tick', () {
      final task = controller().create(isTask: true);
      controller().save(task.id, title: 'Was a task', body: '');
      controller().setDone(task.id, true);

      controller().setIsTask(task.id, false);

      final converted = container.read(noteProvider(task.id))!;
      expect(converted.isTask, isFalse);
      expect(converted.isDone, isFalse);
      expect(converted.completedAt, isNull);
    });

    test('clearCompleted removes finished tasks and nothing else', () async {
      final done = controller().create(isTask: true);
      controller().save(done.id, title: 'Done', body: '');
      final open = controller().create(isTask: true);
      controller().save(open.id, title: 'Open', body: '');
      final note = controller().create();
      controller().save(note.id, title: 'Note', body: '');

      controller().setDone(done.id, true);
      await controller().clearCompleted();

      expect(container.read(notesProvider).map((n) => n.title),
          containsAll(<String>['Open', 'Note']));
      expect(container.read(noteProvider(done.id)), isNull);
    });

    test('open tasks are counted for the dashboard', () {
      final a = controller().create(isTask: true);
      controller().save(a.id, title: 'One', body: '');
      final b = controller().create(isTask: true);
      controller().save(b.id, title: 'Two', body: '');
      final note = controller().create();
      controller().save(note.id, title: 'Not a task', body: '');

      expect(container.read(openTaskCountProvider), 2);

      controller().setDone(a.id, true);
      expect(container.read(openTaskCountProvider), 1);
    });

    test('an untitled task says so rather than showing nothing', () {
      final task = controller().create(isTask: true);
      controller().save(task.id, title: '', body: 'buy milk\nand eggs');
      expect(container.read(noteProvider(task.id))!.displayTitle, 'buy milk');
    });

    test('a task with a future deadline schedules a reminder', () {
      final task = controller().create(isTask: true);
      final due = now.add(const Duration(hours: 3));
      controller().save(task.id, title: 'Call the dentist', body: '', dueAt: due);

      expect(notifications.tasks[task.id], due);
    });

    test('ticking a task clears its reminder', () {
      final task = controller().create(isTask: true);
      controller()
          .save(task.id, title: 'Done soon', body: '', dueAt: now.add(const Duration(hours: 3)));
      expect(notifications.tasks.containsKey(task.id), isTrue);

      controller().setDone(task.id, true);

      expect(notifications.tasks.containsKey(task.id), isFalse);
    });

    test('turning a task into a note drops its deadline', () {
      final task = controller().create(isTask: true);
      controller().save(task.id, title: 'Was due', body: '',
          dueAt: now.add(const Duration(hours: 3)));

      controller().save(task.id, title: 'Was due', body: '', isTask: false);

      expect(container.read(noteProvider(task.id))!.dueAt, isNull);
      expect(notifications.tasks.containsKey(task.id), isFalse);
    });

    test('a task is overdue only once its time has passed', () {
      final task = controller().create(isTask: true);
      final due = now.add(const Duration(hours: 1));
      controller().save(task.id, title: 'Later', body: '', dueAt: due);

      expect(container.read(noteProvider(task.id))!.isOverdueAt(now), isFalse);
      expect(
          container.read(noteProvider(task.id))!
              .isOverdueAt(due.add(const Duration(minutes: 1))),
          isTrue);
    });

    test('a note is never overdue, whatever is stored on it', () {
      final note = controller().create();
      controller().save(note.id, title: 'Just a note', body: '');
      expect(container.read(noteProvider(note.id))!
          .isOverdueAt(now.add(const Duration(days: 400))), isFalse);
    });

    test('deleting a task cancels its reminder', () async {
      final task = controller().create(isTask: true);
      controller().save(task.id, title: 'Gone', body: '',
          dueAt: now.add(const Duration(hours: 3)));

      await controller().delete(task.id);

      expect(notifications.cancelledTasks, contains(task.id));
    });

    test('changing the tag keeps the note', () {
      final note = controller().create();
      controller().save(note.id, title: 'Tagged', body: 'x');

      controller().setTag(note.id, 'coral');

      expect(container.read(noteProvider(note.id))!.colorTag, 'coral');
      expect(noteBox.get(note.id)!.colorTag, 'coral');
    });
  });
}
