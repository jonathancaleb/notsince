import 'dart:async';

import 'package:alarm/alarm.dart' as plugin;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:notsince/app.dart';
import 'package:notsince/features/planner/data/planner_store.dart';
import 'package:notsince/core/hive/hive_registrar.g.dart';
import 'package:notsince/core/prefs/app_prefs.dart';
import 'package:notsince/features/alarms/application/alarms_controller.dart';
import 'package:notsince/features/alarms/data/alarm_repository.dart';
import 'package:notsince/features/alarms/data/alarm_scheduler.dart';
import 'package:notsince/features/alarms/domain/alarm_entry.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/features/counter/data/tracker_repository.dart';
import 'package:notsince/features/counter/domain/tracker.dart';
import 'package:notsince/features/notes/data/note_repository.dart';
import 'package:notsince/features/notes/application/notes_controller.dart';
import 'package:notsince/features/notes/domain/note.dart';
import 'package:notsince/features/notifications/data/notification_service.dart';

/// Startup is split in two, and the split is the point.
///
/// Only opening Hive has to finish before the first frame, because the whole
/// widget tree reads the boxes synchronously. Everything else here talks to
/// Android — alarms, scheduled notifications — and none of it changes what is
/// drawn. Awaiting that platform work ahead of [runApp] once meant a single
/// method channel throwing left the app sitting on its launch background
/// forever, which reads to a user, and to Play review, as an app that does not
/// open. So the platform side now runs after the first frame and every step of
/// it is allowed to fail on its own.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = await _openStore();
  if (container == null) {
    runApp(const _StorageFailureApp());
    return;
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NotSinceApp(),
    ),
  );

  unawaited(_restorePlatformSchedule(container));
}

/// Opens every box and returns a container holding them, or null if storage is
/// unusable.
///
/// Hive is opened before `runApp` so every read downstream is synchronous: no
/// AsyncValue in the widget tree and no loading state on the counter. That is
/// also why a failure here cannot be shrugged off the way a failed alarm can —
/// there is nothing to show without it, so the app says so instead of hanging.
Future<ProviderContainer?> _openStore() async {
  try {
    await Hive.initFlutter();
    Hive.registerAdapters();

    final trackerBox = await Hive.openBox<Tracker>(TrackerRepository.boxName);
    final alarmBox = await Hive.openBox<AlarmEntry>(AlarmRepository.boxName);
    final noteBox = await Hive.openBox<Note>(NoteRepository.boxName);
    final prefsBox = await Hive.openBox<dynamic>(AppPrefs.boxName);
    final plannerBox = await Hive.openBox<dynamic>('planner_v1');
    await migratePlanner(plannerBox);

    // Must run before anything reads the tracker box.
    await TrackerRepository.migrate(trackerBox);

    return ProviderContainer(
      overrides: [
        trackerBoxProvider.overrideWithValue(trackerBox),
        alarmBoxProvider.overrideWithValue(alarmBox),
        noteBoxProvider.overrideWithValue(noteBox),
        appPrefsBoxProvider.overrideWithValue(prefsBox),
        plannerBoxProvider.overrideWithValue(plannerBox),
      ],
    );
  } catch (error, stack) {
    debugPrint('notsince: could not open storage: $error\n$stack');
    return null;
  }
}

/// Rebuilds what the OS has forgotten, after the app is already on screen.
///
/// Android drops exact alarms on reboot, on force-stop, and when exact-alarm
/// permission is revoked, and scheduled notifications do not survive a reboot
/// either, so both are re-derived from Hive at every launch. Each step is
/// guarded separately: a device that refuses to schedule notifications should
/// still get its alarms back, and neither should cost anyone the app.
Future<void> _restorePlatformSchedule(ProviderContainer container) async {
  try {
    await plugin.Alarm.init();
    await container
        .read(alarmSchedulerProvider)
        .reconcile(container.read(alarmsProvider));
  } catch (error, stack) {
    debugPrint('notsince: could not restore alarms: $error\n$stack');
  }

  try {
    final settings = container.read(appSettingsProvider);
    await container.read(notificationServiceProvider).reconcile(
          trackers: container.read(trackersProvider),
          notes: container.read(notesProvider),
          milestonesEnabled: settings.notifyMilestones,
          tasksEnabled: settings.notifyTasks,
          now: DateTime.now(),
        );
  } catch (error, stack) {
    debugPrint('notsince: could not restore notifications: $error\n$stack');
  }
}

/// Shown when the boxes cannot be opened.
///
/// Deliberately built from nothing but Material defaults — no app theme, no
/// bundled fonts, no providers. Whatever went wrong, this has to be able to
/// draw.
class _StorageFailureApp extends StatelessWidget {
  const _StorageFailureApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'notsince',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'notsince could not open your data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  'Restarting the app usually fixes this. If it keeps '
                  'happening, reinstalling will clear the stored data and '
                  'start the count again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.black.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

