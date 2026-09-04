import 'package:alarm/alarm.dart' as plugin;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:notsince/app.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive is opened before runApp so every read downstream is synchronous:
  // no AsyncValue in the widget tree and no loading state on the counter.
  await Hive.initFlutter();
  Hive.registerAdapters();

  final trackerBox = await Hive.openBox<Tracker>(TrackerRepository.boxName);
  final alarmBox = await Hive.openBox<AlarmEntry>(AlarmRepository.boxName);
  final noteBox = await Hive.openBox<Note>(NoteRepository.boxName);
  final prefsBox = await Hive.openBox<dynamic>(AppPrefs.boxName);

  // Must run before anything reads the tracker box.
  await TrackerRepository.migrate(trackerBox);

  await plugin.Alarm.init();

  final container = ProviderContainer(
    overrides: [
      trackerBoxProvider.overrideWithValue(trackerBox),
      alarmBoxProvider.overrideWithValue(alarmBox),
      noteBoxProvider.overrideWithValue(noteBox),
      appPrefsBoxProvider.overrideWithValue(prefsBox),
    ],
  );

  // The OS drops exact alarms on reboot, on force-stop, and when exact-alarm
  // permission is revoked, so the platform schedule is rebuilt from Hive at
  // every launch. Without this, alarms silently stop firing.
  await container
      .read(alarmSchedulerProvider)
      .reconcile(container.read(alarmsProvider));

  // Scheduled notifications do not survive a reboot either, so they are
  // rebuilt from storage for the same reason alarms are.
  final settings = container.read(appSettingsProvider);
  await container.read(notificationServiceProvider).reconcile(
        trackers: container.read(trackersProvider),
        notes: container.read(notesProvider),
        milestonesEnabled: settings.notifyMilestones,
        tasksEnabled: settings.notifyTasks,
        now: DateTime.now(),
      );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NotSinceApp(),
    ),
  );
}
