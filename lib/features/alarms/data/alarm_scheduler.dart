import 'package:alarm/alarm.dart' as plugin;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/features/alarms/domain/alarm_entry.dart';
import 'package:notsince/features/alarms/domain/ringtone.dart';

/// Bridges our alarms to the platform scheduler.
///
/// There are two stores here and only one of them is authoritative. Hive holds
/// the alarms the person created; the plugin holds what the OS has actually
/// been asked to fire, in its own shared_preferences. Those drift — exact
/// alarms are dropped on reboot, on force-stop, and when exact-alarm permission
/// is revoked — so [reconcile] re-derives the platform's schedule from Hive at
/// every launch. Without it, alarms quietly stop firing and nothing in the UI
/// would say so.
class AlarmScheduler {
  const AlarmScheduler();

  plugin.AlarmSettings _settings(AlarmEntry entry, DateTime fireAt) {
    return plugin.AlarmSettings(
      id: entry.scheduleId,
      dateTime: fireAt,
      assetAudioPath: ringtoneById(entry.soundId).asset,
      loopAudio: true,
      vibrate: true,
      // Fades in over 15s so an alarm wakes rather than startles, but
      // volumeEnforced keeps the device from being turned down mid-ring —
      // that is the whole point of a ring-through-silent alarm.
      volumeSettings: plugin.VolumeSettings.fade(
        fadeDuration: Duration(seconds: 15),
        volumeEnforced: true,
      ),
      notificationSettings: plugin.NotificationSettings(
        title: entry.label,
        body: clockLabel(entry.hour, entry.minute),
        stopButton: 'Stop',
        icon: 'ic_notification',
        // Android tints the small icon with this; it does not follow the
        // app theme, so it stays the light-theme amber.
        iconColor: NsColors.light.alarm,
      ),
      // Shows the ring screen over the lock screen instead of a notification
      // the person has to find.
      androidFullScreenIntent: true,
      warningNotificationOnKill: true,
    );
  }

  /// Schedules [entry] at its next occurrence, or cancels it if it is disabled
  /// or has no next occurrence.
  Future<void> sync(AlarmEntry entry, {DateTime? from}) async {
    final now = from ?? DateTime.now();
    final fireAt = entry.isEnabled ? entry.nextOccurrence(now) : null;

    if (fireAt == null) {
      await cancel(entry);
      return;
    }

    try {
      await plugin.Alarm.set(alarmSettings: _settings(entry, fireAt));
    } catch (error, stack) {
      // A refused exact-alarm permission throws here. The alarm stays in Hive
      // so the list still shows it and the next reconcile can pick it up.
      debugPrint('notsince: could not schedule ${entry.id}: $error\n$stack');
    }
  }

  Future<void> cancel(AlarmEntry entry) => cancelId(entry.scheduleId);

  Future<void> cancelId(int scheduleId) async {
    try {
      await plugin.Alarm.stop(scheduleId);
    } catch (error) {
      debugPrint('notsince: could not cancel $scheduleId: $error');
    }
  }

  /// Makes the platform's schedule match [entries] exactly.
  ///
  /// Cancels anything the platform still holds that we no longer own — an
  /// alarm deleted while the app was not running, for instance — then
  /// re-schedules every enabled alarm.
  Future<void> reconcile(List<AlarmEntry> entries, {DateTime? from}) async {
    final wanted = {
      for (final e in entries.where((e) => e.isEnabled)) e.scheduleId: e,
    };

    try {
      for (final scheduled in await plugin.Alarm.getAlarms()) {
        if (!wanted.containsKey(scheduled.id)) await cancelId(scheduled.id);
      }
    } catch (error) {
      debugPrint('notsince: could not read platform alarms: $error');
    }

    for (final entry in wanted.values) {
      await sync(entry, from: from);
    }
  }

  /// Re-arms an alarm [minutes] from now without disturbing its normal time.
  Future<void> snooze(AlarmEntry entry, {DateTime? from}) async {
    final now = from ?? DateTime.now();
    final fireAt = now.add(Duration(minutes: entry.snoozeMinutes));
    try {
      await plugin.Alarm.set(alarmSettings: _settings(entry, fireAt));
    } catch (error) {
      debugPrint('notsince: could not snooze ${entry.id}: $error');
    }
  }
}

final alarmSchedulerProvider =
    Provider<AlarmScheduler>((ref) => const AlarmScheduler());

/// Ids of alarms the platform is currently ringing.
final ringingAlarmIdsProvider = StreamProvider<Set<int>>((ref) {
  return plugin.Alarm.ringing
      .map((set) => set.alarms.map((a) => a.id).toSet());
});
