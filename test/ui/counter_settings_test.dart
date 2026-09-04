import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notsince/core/prefs/app_prefs.dart';
import 'package:notsince/core/theme/app_theme.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/features/counter/application/progress_provider.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/features/counter/data/tracker_repository.dart';
import 'package:notsince/features/counter/presentation/counter_settings_screen.dart';
import 'package:notsince/features/notifications/data/notification_service.dart';

import '../support/fakes.dart';

/// Editing a habit.
///
/// The rename dialog used to create a TextEditingController in the caller and
/// dispose it the moment `showDialog` returned — while the dialog was still
/// animating out and its TextField was still listening. That threw
/// "A TextEditingController was used after being disposed". A widget test fails
/// on a thrown assertion, so pumping the dialog all the way through its exit
/// transition is what catches it: `pumpAndSettle` after Save is load-bearing
/// here, not housekeeping.
///
/// No Hive: this test writes, and a real disk write never completes inside
/// `testWidgets`' fake-async zone.
void main() {
  late ProviderContainer container;
  late FakeTrackerRepository repository;
  late FakeNotifications notifications;

  final now = DateTime(2026, 3, 4, 12);

  setUp(() {
    repository = FakeTrackerRepository();
    notifications = FakeNotifications();
    container = ProviderContainer(
      overrides: [
        trackerRepositoryProvider.overrideWithValue(repository),
        appPrefsProvider.overrideWithValue(FakePrefs()),
        notificationServiceProvider.overrideWithValue(notifications),
        clockProvider.overrideWithValue(FixedClock(now)),
        nowProvider.overrideWith((ref) => now),
      ],
    );
  });

  tearDown(() => container.dispose());

  String seed() => container
      .read(trackersProvider.notifier)
      .create(
        name: 'Drinking',
        startedAt: now.subtract(const Duration(days: 12)),
        emoji: '🍺',
        colorIndex: 0,
      )
      .id;

  Future<void> pump(WidgetTester tester, String id) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildLightTheme(),
          home: CounterSettingsScreen(id: id),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> rename(WidgetTester tester, String from, String to) async {
    await tester.tap(find.text(from));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), to);
    await tester.tap(find.text('Save'));
    // Settles the dialog's exit transition, which is where the disposed
    // controller used to be touched.
    await tester.pumpAndSettle();
  }

  testWidgets('renaming a habit saves and closes cleanly', (tester) async {
    final id = seed();
    await pump(tester, id);

    await tester.tap(find.text('Drinking'));
    await tester.pumpAndSettle();
    expect(find.text('What are you counting?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Beer');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(container.read(trackerProvider(id))!.name, 'Beer');
    expect(find.text('Beer'), findsOneWidget);
    expect(find.text('What are you counting?'), findsNothing);
  });

  testWidgets('cancelling leaves the name alone', (tester) async {
    final id = seed();
    await pump(tester, id);

    await tester.tap(find.text('Drinking'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Discarded');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(container.read(trackerProvider(id))!.name, 'Drinking');
  });

  testWidgets('opening the dialog repeatedly is safe', (tester) async {
    // Each open builds its own controller. A leak across dialogs — the original
    // bug — shows up on the second pass.
    final id = seed();
    await pump(tester, id);

    await rename(tester, 'Drinking', 'One');
    await rename(tester, 'One', 'Two');
    await rename(tester, 'Two', 'Three');

    expect(container.read(trackerProvider(id))!.name, 'Three');
  });

  testWidgets('a blank name is ignored rather than saved', (tester) async {
    final id = seed();
    await pump(tester, id);

    await tester.tap(find.text('Drinking'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(container.read(trackerProvider(id))!.name, 'Drinking');
  });

  testWidgets('removing the habit deletes it and pops', (tester) async {
    final id = seed();
    await pump(tester, id);

    // The remove button sits below the icon and colour pickers.
    await tester.scrollUntilVisible(
      find.text('Remove this habit'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove this habit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(container.read(trackersProvider), isEmpty);
    expect(notifications.cancelledHabits, contains(id));
  });
}
