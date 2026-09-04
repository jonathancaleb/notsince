import 'package:flutter/material.dart';
import 'package:notsince/core/prefs/app_prefs.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/features/alarms/data/alarm_scheduler.dart';
import 'package:notsince/features/alarms/domain/alarm_entry.dart';
import 'package:notsince/features/alarms/data/alarm_repository.dart';
import 'package:notsince/features/counter/data/tracker_repository.dart';
import 'package:notsince/features/counter/domain/tracker.dart';
import 'package:notsince/features/notes/data/note_repository.dart';
import 'package:notsince/features/notes/domain/note.dart';
import 'package:notsince/features/notifications/data/notification_service.dart';

/// Shared test doubles.
///
/// Everything the controllers reach for that would touch a platform channel or
/// a disk lives here, so each test file overrides the same three providers and
/// none of them accidentally schedules a real notification.
class FixedClock implements Clock {
  FixedClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void set(DateTime value) => _now = value;
}

/// In-memory prefs. Hive works fine in a plain unit test, but a widget test
/// runs in a fake-async zone where a real disk write never completes.
class FakePrefs implements AppPrefs {
  bool onboarded = false;
  ThemeMode mode = ThemeMode.system;
  bool milestones = true;
  bool tasks = true;

  @override
  bool get hasOnboarded => onboarded;

  @override
  Future<void> setOnboarded() async => onboarded = true;

  @override
  ThemeMode get themeMode => mode;

  @override
  Future<void> setThemeMode(ThemeMode value) async => mode = value;

  @override
  bool get notifyMilestones => milestones;

  @override
  Future<void> setNotifyMilestones(bool value) async => milestones = value;

  @override
  bool get notifyTasks => tasks;

  @override
  Future<void> setNotifyTasks(bool value) async => tasks = value;

  @override
  Future<void> clear() async {
    onboarded = false;
    mode = ThemeMode.system;
    milestones = true;
    tasks = true;
  }
}

/// Records what would have been scheduled, without a platform plugin.
class FakeNotifications implements NotificationService {
  final habits = <String, bool>{};
  final tasks = <String, DateTime>{};
  final cancelledHabits = <String>[];
  final cancelledTasks = <String>[];
  final customMessages = <String, String?>{};
  bool cancelledEverything = false;

  @override
  Future<void> init() async {}

  @override
  Future<void> syncHabit(
    Tracker tracker, {
    required bool enabled,
    required DateTime now,
    String? customMessage,
  }) async {
    habits[tracker.id] = enabled;
    customMessages[tracker.id] = customMessage;
  }

  @override
  Future<void> cancelHabit(Tracker tracker) async {
    habits.remove(tracker.id);
    cancelledHabits.add(tracker.id);
  }

  @override
  Future<void> syncTask(
    Note note, {
    required bool enabled,
    required DateTime now,
  }) async {
    final due = note.dueAt;
    if (enabled && note.isOpenTask && due != null && due.isAfter(now)) {
      tasks[note.id] = due;
    } else {
      tasks.remove(note.id);
    }
  }

  @override
  Future<void> cancelTask(Note note) async {
    tasks.remove(note.id);
    cancelledTasks.add(note.id);
  }

  @override
  Future<void> reconcile({
    required List<Tracker> trackers,
    required List<Note> notes,
    required bool milestonesEnabled,
    required bool tasksEnabled,
    required DateTime now,
    Map<String, String> customMessages = const {},
  }) async {
    habits.clear();
    tasks.clear();
    for (final t in trackers) {
      await syncHabit(t, enabled: milestonesEnabled, now: now);
    }
    for (final n in notes) {
      await syncTask(n, enabled: tasksEnabled, now: now);
    }
  }

  @override
  Future<void> cancelAll() async {
    habits.clear();
    tasks.clear();
    cancelledEverything = true;
  }
}

/// Does nothing: the platform alarm scheduler has no implementation in a test,
/// and none of these tests are about whether an alarm actually rings.
class NoScheduler implements AlarmScheduler {
  const NoScheduler();

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


/// In-memory repositories.
///
/// A widget test that *mutates* cannot use Hive: `testWidgets` runs its body in
/// a fake-async zone where a real disk write never completes, so the write
/// hangs and then teardown hangs waiting on the box. Read-only widget tests can
/// seed through `tester.runAsync` and keep Hive; anything that writes during
/// the test needs these. Round-tripping through a real box is covered by the
/// repository tests.
class FakeTrackerRepository implements TrackerRepository {
  final Map<String, Tracker> items = {};

  @override
  List<Tracker> readAll() {
    final all = items.values.toList()
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    return all;
  }

  @override
  Future<void> write(Tracker tracker) async => items[tracker.id] = tracker;

  @override
  Future<void> writeAll(List<Tracker> trackers) async {
    for (final t in trackers) {
      items[t.id] = t;
    }
  }

  @override
  Future<void> delete(String id) async => items.remove(id);

  @override
  Future<void> clear() async => items.clear();
}

class FakeNoteRepository implements NoteRepository {
  final Map<String, Note> items = {};

  @override
  List<Note> readAll() {
    final all = items.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all;
  }

  @override
  Future<void> write(Note note) async => items[note.id] = note;

  @override
  Future<void> delete(String id) async => items.remove(id);

  @override
  Future<void> clear() async => items.clear();
}

class FakeAlarmRepository implements AlarmRepository {
  final Map<String, AlarmEntry> items = {};

  @override
  List<AlarmEntry> readAll() {
    final all = items.values.toList()
      ..sort((a, b) {
        final byTime =
            (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute);
        return byTime != 0 ? byTime : a.sortIndex.compareTo(b.sortIndex);
      });
    return all;
  }

  @override
  Future<void> write(AlarmEntry entry) async => items[entry.id] = entry;

  @override
  Future<void> delete(String id) async => items.remove(id);

  @override
  Future<void> clear() async => items.clear();
}
