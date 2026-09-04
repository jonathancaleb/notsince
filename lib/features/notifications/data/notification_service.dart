import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/features/counter/domain/tracker.dart';
import 'package:notsince/features/notes/domain/note.dart';
import 'package:notsince/features/notifications/domain/notification_copy.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the app's notifications.
///
/// These are *not* alarms: they are quiet, dismissible reminders on their own
/// channels, so someone can silence milestones without silencing an alarm that
/// is supposed to wake them. They are scheduled ahead of time rather than
/// posted when the app happens to be open, because a milestone is reached at a
/// known future instant whether or not anyone is looking.
class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _milestoneChannel = 'milestones';
  static const _taskChannel = 'tasks';

  /// Notification ids are namespaced by bit so a habit, a task and an alarm can
  /// never overwrite one another's scheduled entry.
  static const _milestoneBase = 0x10000000;

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;

    // Scheduling at a wall-clock instant needs a timezone database and the
    // device's own zone; without it every scheduled time would be UTC.
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (error) {
      debugPrint('notsince: could not resolve local timezone: $error');
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
    _ready = true;
  }

  AndroidNotificationDetails _details(String channel, String name, Color colour) {
    return AndroidNotificationDetails(
      channel,
      name,
      channelDescription: name,
      // Quiet by design: these should be findable, not startling. An alarm is
      // the loud thing, and it has its own path.
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: 'ic_notification',
      color: colour,
      colorized: false,
      styleInformation: const BigTextStyleInformation(''),
    );
  }

  /// Schedules every future milestone for one habit, and clears the rest.
  ///
  /// Past milestones are skipped rather than fired late: being told at noon
  /// that you passed a week at 3am is noise, and the app already shows it.
  Future<void> syncHabit(
    Tracker tracker, {
    required bool enabled,
    required DateTime now,
    String? customMessage,
  }) async {
    await init();
    await cancelHabit(tracker);
    if (!enabled) return;

    final stops = tracker.sortedMilestones;
    for (var i = 0; i < stops.length; i++) {
      final at = tracker.startedAt.add(stops[i]);
      if (!at.isAfter(now)) continue;

      final body = (customMessage != null && customMessage.trim().isNotEmpty)
          ? customMessage.trim()
          : NotificationCopy.milestone(stops[i]);

      await _schedule(
        id: _milestoneId(tracker, i),
        title: '${tracker.emoji}  ${NotificationCopy.milestoneTitle(tracker.name)}',
        body: body,
        at: at,
        channel: _milestoneChannel,
        channelName: 'Milestones',
        colour: NsColors.light.crayon(tracker.colorIndex),
      );
    }
  }

  Future<void> cancelHabit(Tracker tracker) async {
    await init();
    // Cancels generously: the milestone list may have shrunk since the last
    // sync, and an orphaned entry would still fire.
    for (var i = 0; i < 24; i++) {
      await _plugin.cancel(id: _milestoneId(tracker, i));
    }
  }

  /// Schedules or clears one task's overdue reminder.
  Future<void> syncTask(
    Note note, {
    required bool enabled,
    required DateTime now,
  }) async {
    await init();
    await _plugin.cancel(id: note.notificationId);

    final due = note.dueAt;
    if (!enabled || !note.isOpenTask || due == null || !due.isAfter(now)) {
      return;
    }

    await _schedule(
      id: note.notificationId,
      title: NotificationCopy.overdueTitle,
      body: NotificationCopy.overdueTask(note.displayTitle),
      at: due,
      channel: _taskChannel,
      channelName: 'Tasks',
      colour: NsColors.light.noteTag(note.colorTag),
    );
  }

  Future<void> cancelTask(Note note) async {
    await init();
    await _plugin.cancel(id: note.notificationId);
  }

  /// Rebuilds everything from storage.
  ///
  /// Scheduled notifications do not survive a reboot on Android, so this runs
  /// at startup for the same reason the alarm scheduler reconciles.
  Future<void> reconcile({
    required List<Tracker> trackers,
    required List<Note> notes,
    required bool milestonesEnabled,
    required bool tasksEnabled,
    required DateTime now,
    Map<String, String> customMessages = const {},
  }) async {
    await init();
    await _plugin.cancelAll();

    for (final tracker in trackers) {
      await syncHabit(
        tracker,
        enabled: milestonesEnabled,
        now: now,
        customMessage: customMessages[tracker.id],
      );
    }
    for (final note in notes) {
      await syncTask(note, enabled: tasksEnabled, now: now);
    }
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  int _milestoneId(Tracker tracker, int index) =>
      _milestoneBase | ((tracker.id.hashCode & 0x00FFFFFF) << 4) | (index & 0xF);

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required String channel,
    required String channelName,
    required Color colour,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails:
            NotificationDetails(android: _details(channel, channelName, colour)),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (error) {
      // A refused permission throws here. The habit or task is unaffected —
      // it simply will not announce itself.
      debugPrint('notsince: could not schedule notification $id: $error');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(FlutterLocalNotificationsPlugin()),
);
