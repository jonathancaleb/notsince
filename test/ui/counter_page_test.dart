import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notsince/core/prefs/app_prefs.dart';
import 'package:notsince/features/notifications/data/notification_service.dart';
import '../support/fakes.dart';
import 'package:hive_ce/hive.dart';
import 'package:notsince/features/counter/application/progress_provider.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/core/theme/app_theme.dart';
import 'package:notsince/core/widgets/habit_plant.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/features/counter/data/tracker_repository.dart';
import 'package:notsince/features/counter/domain/tracker.dart';
import 'package:notsince/features/counter/presentation/counter_screen.dart';
import 'package:notsince/core/hive/hive_registrar.g.dart';

class _FixedClock implements Clock {
  const _FixedClock(this._now);

  final DateTime _now;

  @override
  DateTime now() => _now;
}

/// Renders the real screens.
///
/// Sticker cards draw hard offset shadows that take no layout space, and the
/// pager stacks a card, buttons and a dot row into a fixed-height page — both
/// are easy to get subtly wrong in a way that only shows up as an overflow at
/// runtime, so this pumps the actual widgets rather than testing the model
/// again.
///
/// Reading only: counters are seeded through `tester.runAsync` because
/// `testWidgets` runs its body in a fake-async zone where Hive's real disk
/// writes can never complete, which then hangs teardown. Mutation is covered by
/// the repository tests instead.
void main() {
  late Directory dir;
  late Box<Tracker> box;
  late ProviderContainer container;
  late FakePrefs prefs;
  late FakeNotifications notifications;

  // The "fits on a handset" checks below measure real geometry, so they need
  // the real pen face: the test renderer's placeholder font is a full em wide
  // per letter, about twice the pen's width, and wraps lines the app never
  // wraps.
  setUpAll(() async {
    final loader = FontLoader('NanumPen')
      ..addFont(
        File('assets/fonts/NanumPenScript-400.ttf')
            .readAsBytes()
            .then((b) => ByteData.view(b.buffer)),
      );
    await loader.load();
  });

  final now = DateTime(2026, 3, 1, 12);

  setUp(() async {
    prefs = FakePrefs();
    notifications = FakeNotifications();
    dir = await Directory.systemTemp.createTemp('notsince_ui');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapters();
    box = await Hive.openBox<Tracker>(TrackerRepository.boxName);
    container = ProviderContainer(
      overrides: [
        appPrefsProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notifications),
        trackerBoxProvider.overrideWithValue(box),
        clockProvider.overrideWithValue(_FixedClock(now)),
        // Freeze time at the provider the UI actually watches. This also keeps
        // the real 1 Hz ticker out of the tree — a periodic timer never lets
        // pumpAndSettle reach a quiet frame.
        nowProvider.overrideWith((ref) => now),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await Hive.deleteFromDisk();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<void> seed(
    WidgetTester tester,
    List<({String name, String emoji, Duration ago, int color})> counters,
  ) async {
    await tester.runAsync(() async {
      for (final counter in counters) {
        container.read(trackersProvider.notifier).create(
              name: counter.name,
              startedAt: now.subtract(counter.ago),
              emoji: counter.emoji,
              colorIndex: counter.color,
            );
      }
      await box.flush();
    });
  }

  /// The device the screenshots came from. The habit card has to fit this
  /// without scrolling, or the plant — the thing the screen is for — falls
  /// below the fold.
  const handset = Size(360, 760);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildLightTheme(),
          home: const CounterScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('empty state offers the one action that matters',
      (tester) async {
    await pump(tester);

    expect(find.text('Nothing is being counted yet.'), findsOneWidget);
    expect(find.text('Start a habit'), findsOneWidget);
  });

  testWidgets('a counter renders its count, name and next milestone',
      (tester) async {
    await seed(tester, [
      (
        name: 'Drinking',
        emoji: '🍺',
        ago: const Duration(days: 12, hours: 5),
        color: 0,
      ),
    ]);

    await pump(tester);

    expect(find.text('12'), findsOneWidget);
    expect(find.text('days'), findsOneWidget);
    expect(find.text('Drinking'), findsOneWidget);
    expect(find.text('5 hr 0 min'), findsOneWidget);
    // 12 days is past 1 week, so the next default threshold is 1 month.
    // 12 days clears 24 hours and 1 week, so two of six stops.
    expect(find.textContaining('2 of 6'), findsWidgets);
    expect(find.text('Start a new count'), findsOneWidget);
  });

  testWidgets('a reached milestone surfaces its banner', (tester) async {
    await seed(tester, [
      (name: 'Smoking', emoji: '🚬', ago: const Duration(days: 9), color: 2),
    ]);

    await pump(tester);

    // 24 hours is the oldest threshold reached and unacknowledged.
    expect(find.text('24 hours reached'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });

  testWidgets('the plant is visible without scrolling on a 360x760 handset',
      (tester) async {
    tester.view.physicalSize = handset;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await seed(tester, [
      (name: 'Exercises', emoji: '🌱', ago: const Duration(days: 12), color: 0),
    ]);
    await pump(tester);
    // The page scrolls, so "visible" means the painted plant sits inside the
    // viewport — not merely that it exists in the tree.
    final plant = find.byType(HabitPlant);
    expect(plant, findsOneWidget);

    final box = tester.getRect(plant);
    final view = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(box.bottom, lessThanOrEqualTo(view.height),
        reason: 'the plant is cut off the bottom of the screen');
    expect(box.top, greaterThanOrEqualTo(0));

    // The actions below it have to clear the "Add a habit" button too — a
    // half-hidden button reads as a broken layout even though the page scrolls.
    for (final label in ['Start a new count', 'History']) {
      final rect = tester.getRect(find.text(label));
      expect(rect.bottom, lessThanOrEqualTo(view.height),
          reason: '"\$label" is cut off the bottom of the screen');
    }
  });

  testWidgets('counters show one at a time and swipe between', (tester) async {
    await seed(tester, [
      (name: 'Drinking', emoji: '🍺', ago: const Duration(days: 12), color: 0),
      (name: 'Smoking', emoji: '🚬', ago: const Duration(days: 94), color: 2),
    ]);

    await pump(tester);

    // One focus at a time: the second counter is not on screen.
    expect(find.text('Drinking'), findsOneWidget);
    expect(find.text('Smoking'), findsNothing);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Smoking'), findsOneWidget);
    expect(find.text('94'), findsOneWidget);
  });
}
