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
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/features/counter/data/tracker_repository.dart';
import 'package:notsince/features/counter/domain/tracker.dart';
import 'package:notsince/features/notes/data/note_repository.dart';
import 'package:notsince/features/notes/domain/note.dart';
import 'package:notsince/features/notifications/data/notification_service.dart';
import 'package:notsince/features/onboarding/presentation/warm_onboarding_screen.dart';
import 'package:notsince/features/planner/data/planner_store.dart';
import 'package:notsince/features/planner/presentation/notes_hub_screen.dart';
import 'package:notsince/features/shell/home_shell.dart';
import 'package:notsince/theme/app_theme.dart';
import 'package:notsince/widgets/habit_circle.dart';

import '../support/fakes.dart';

void main() {
  late Directory dir;
  late ProviderContainer container;
  late FakePrefs prefs;
  final now = DateTime(2026, 10, 12, 9);
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('planner-ui-');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapters();
    final trackers = await Hive.openBox<Tracker>(TrackerRepository.boxName);
    final alarms = await Hive.openBox<AlarmEntry>(AlarmRepository.boxName);
    final notes = await Hive.openBox<Note>(NoteRepository.boxName);
    prefs = FakePrefs()..onboarded = true;
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
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool dark = false,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    testWidgets(
      'five tabs fit a narrow screen in ${dark ? 'dark' : 'light'} mode',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pump(tester, const HomeShell(), dark: dark);
        for (final tab in ['Planner', 'Garden', 'Notes', 'Insights', 'Today']) {
          await tester.tap(find.text(tab).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
  testWidgets('quick add appears in Today and the day timer stays visible', (
    tester,
  ) async {
    await pump(tester, const HomeShell());
    await tester.scrollUntilVisible(
      find.byType(TextField),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), 'Read a chapter');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      container.read(plannerProvider).tasks.single.title,
      'Read a chapter',
    );
    expect(find.text('Make room for today'), findsOneWidget);
  });
  testWidgets('long press checks in without resetting the existing counter', (
    tester,
  ) async {
    await tester.runAsync(() async {
      container
          .read(trackersProvider.notifier)
          .create(
            name: 'Reading',
            startedAt: DateTime(2026, 10, 1),
            emoji: '??',
            colorIndex: 0,
          );
      await Hive.box<Tracker>(TrackerRepository.boxName).flush();
    });
    final habit = container.read(trackersProvider).single;
    await pump(tester, const HomeShell());
    await tester.longPress(find.byType(HabitCircle));
    await tester.pumpAndSettle();
    expect(container.read(plannerProvider).checkIns[habit.id], ['2026-10-12']);
    expect(
      container.read(trackersProvider).single.startedAt,
      DateTime(2026, 10, 1),
    );
  });
  testWidgets(
    'three intro slides lead to accent selection and saved onboarding',
    (tester) async {
      var done = false;
      prefs.onboarded = false;
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester, WarmOnboardingScreen(onDone: () => done = true));
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(
        find.text('Pick a color.\nPlant your first seed.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.bySemanticsLabel('Accent 3'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Accent 3'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plant my first habit'));
      await tester.pumpAndSettle();
      expect(done, isTrue);
      expect(prefs.onboarded, isTrue);
      expect(container.read(plannerProvider).accent, 0xFF5B9DC9);
    },
  );
  testWidgets('note autosaves markdown and uses its first line for the title', (
    tester,
  ) async {
    await pump(tester, const PlannerNoteEditor());
    await tester.enterText(
      find.byType(TextField),
      '# Morning ideas\n**Read** a little',
    );
    await tester.pumpAndSettle();
    expect(container.read(plannerProvider).notes.single.title, 'Morning ideas');
    await tester.tap(find.byTooltip('Preview markdown'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('named deep link opens the requested tab', (tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NotSinceApp(),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(HomeShell));
    Navigator.of(context).pushNamed('/planner');
    await tester.pumpAndSettle();
    expect(container.read(homeTabProvider), HomeTab.planner);
    expect(find.text('All projects'), findsOneWidget);
  });
}
