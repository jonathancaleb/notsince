import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:notsince/app.dart';
import 'package:notsince/core/hive/hive_registrar.g.dart';
import 'package:notsince/core/prefs/app_prefs.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/features/alarms/data/alarm_repository.dart';
import 'package:notsince/features/alarms/data/alarm_scheduler.dart';
import 'package:notsince/features/alarms/domain/alarm_entry.dart';
import 'package:notsince/features/counter/data/tracker_repository.dart';
import 'package:notsince/features/counter/domain/tracker.dart';
import 'package:notsince/features/notes/data/note_repository.dart';
import 'package:notsince/features/notes/domain/note.dart';
import 'package:notsince/features/notifications/data/notification_service.dart';

import '../support/fakes.dart';

/// The main screens must not overflow when users raise their text size.
///
/// Walks the nav to every tab at 1.3× and 2.0× text scale — the Android
/// settings the platform offers beyond 1.0 — in both themes, and fails if any
/// layout throws. Rendering is seed-data driven: no added habits means the
/// empty states get checked too, which are the layouts most likely to clip a
/// single long line.
void main() {
  late Directory dir;
  late ProviderContainer container;

  final now = DateTime(2026, 10, 12, 9);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('text-scale-');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapters();
    final trackers = await Hive.openBox<Tracker>(TrackerRepository.boxName);
    final alarms = await Hive.openBox<AlarmEntry>(AlarmRepository.boxName);
    final notes = await Hive.openBox<Note>(NoteRepository.boxName);
    final prefs = FakePrefs()..onboarded = true;
    container = ProviderContainer(
      overrides: [
        trackerBoxProvider.overrideWithValue(trackers),
        alarmBoxProvider.overrideWithValue(alarms),
        noteBoxProvider.overrideWithValue(notes),
        appPrefsProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(FixedClock(now)),
        notificationServiceProvider.overrideWithValue(FakeNotifications()),
        alarmSchedulerProvider.overrideWithValue(const NoScheduler()),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  const tabs = ['Today', 'Planner', 'Garden', 'Notes', 'Insights'];

  for (final scale in const [1.3, 2.0]) {
    for (final dark in const [false, true]) {
      testWidgets(
        'every tab lays out at text scale $scale in '
        '${dark ? 'dark' : 'light'} mode',
        (tester) async {
          tester.view.physicalSize = const Size(360, 720);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(
            tester.platformDispatcher.clearTextScaleFactorTestValue,
          );

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: NotSinceApp(),
            ),
          );
          if (dark) {
            container
                .read(appSettingsProvider.notifier)
                .setThemeMode(ThemeMode.dark);
          }
          await tester.pumpAndSettle();

          for (final tab in tabs) {
            await tester.tap(find.text(tab).last);
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '$tab at text scale $scale '
                  '${dark ? '(dark)' : '(light)'}',
            );
          }
        },
      );
    }
  }
}
