import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// What an alarm needs from Android before it can actually wake someone.
///
/// The `alarm` plugin declares the permissions in its manifest but never asks
/// for them, and two of them are not granted by declaring:
///
/// * **Notifications** (Android 13+). The alarm rings from a foreground
///   service, and a service that cannot post its notification cannot run. This
///   is a normal runtime dialog.
/// * **Exact alarms** (Android 12 only). `USE_EXACT_ALARM` covers Android 13+
///   automatically for alarm-clock apps, but on Android 12 the user has to
///   grant `SCHEDULE_EXACT_ALARM` on a system settings page — there is no
///   dialog for it, so this sends them there.
///
/// Everything returns a result rather than throwing: a refused permission
/// should leave the person with an app that still works and an alarm that is
/// simply not armed, not with a crash.
class AlarmPermissions {
  const AlarmPermissions();

  /// Requests everything needed, and reports whether an alarm can now ring.
  Future<AlarmPermissionResult> request() async {
    if (!_isAndroid) return const AlarmPermissionResult(canRing: true);

    var notifications = await Permission.notification.status;
    if (!notifications.isGranted) {
      notifications = await Permission.notification.request();
    }

    var exact = await Permission.scheduleExactAlarm.status;
    if (!exact.isGranted) {
      exact = await Permission.scheduleExactAlarm.request();
    }

    return AlarmPermissionResult(
      canRing: notifications.isGranted && exact.isGranted,
      notificationsGranted: notifications.isGranted,
      exactAlarmsGranted: exact.isGranted,
    );
  }

  /// Whether an alarm would ring right now, without prompting for anything.
  Future<bool> canRing() async {
    if (!_isAndroid) return true;
    return await Permission.notification.isGranted &&
        await Permission.scheduleExactAlarm.isGranted;
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

class AlarmPermissionResult {
  const AlarmPermissionResult({
    required this.canRing,
    this.notificationsGranted = true,
    this.exactAlarmsGranted = true,
  });

  final bool canRing;
  final bool notificationsGranted;
  final bool exactAlarmsGranted;

  /// What to tell the person, in terms of what will happen rather than which
  /// permission is missing.
  String? get explanation {
    if (canRing) return null;
    if (!notificationsGranted && !exactAlarmsGranted) {
      return 'Alarms need notification and exact-alarm access to ring. '
          'Without them this is a reminder, not an alarm.';
    }
    if (!notificationsGranted) {
      return 'Without notification access an alarm cannot ring. '
          'You can turn it on in system settings.';
    }
    return 'Without exact-alarm access an alarm may ring late. '
        'You can turn it on in system settings.';
  }
}

final alarmPermissionsProvider =
    Provider<AlarmPermissions>((ref) => const AlarmPermissions());
