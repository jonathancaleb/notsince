import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notsince/core/prefs/app_prefs.dart';
import 'package:notsince/core/theme/app_theme.dart';
import 'package:notsince/features/onboarding/presentation/onboarding_screen.dart';

/// In-memory stand-in for [AppPrefs].
///
/// No Hive here on purpose: `testWidgets` runs its body in a fake-async zone
/// where a real disk write never completes, which then hangs teardown. That the
/// flag survives a real box is covered by the repository tests.
class _FakePrefs implements AppPrefs {
  bool _onboarded = false;
  ThemeMode _mode = ThemeMode.system;
  bool _milestones = true;
  bool _tasks = true;

  @override
  bool get hasOnboarded => _onboarded;

  @override
  Future<void> setOnboarded() async => _onboarded = true;

  @override
  ThemeMode get themeMode => _mode;

  @override
  Future<void> setThemeMode(ThemeMode mode) async => _mode = mode;

  @override
  bool get notifyMilestones => _milestones;

  @override
  Future<void> setNotifyMilestones(bool value) async => _milestones = value;

  @override
  bool get notifyTasks => _tasks;

  @override
  Future<void> setNotifyTasks(bool value) async => _tasks = value;

  @override
  Future<void> clear() async {
    _onboarded = false;
    _mode = ThemeMode.system;
  }
}

/// Onboarding is four full-bleed pages of cards above text, which is exactly
/// the shape that overflows on a phone nobody measured on. A widget test fails
/// on overflow, so pumping every page at several real screen sizes is the
/// check — including the 360x760 handset where this first went wrong and the
/// 320dp width where the header did.
void main() {
  late _FakePrefs prefs;
  late ProviderContainer container;

  setUp(() {
    prefs = _FakePrefs();
    container = ProviderContainer(
      overrides: [appPrefsProvider.overrideWithValue(prefs)],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pump(
    WidgetTester tester,
    Size size, {
    VoidCallback? onDone,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildLightTheme(),
          home: OnboardingScreen(onDone: onDone ?? () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> toLastPage(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
  }

  // A tall modern handset, the 360x760 phone that overflowed, and a short
  // narrow device.
  const sizes = <String, Size>{
    'tall handset': Size(412, 915),
    '360x760 handset': Size(360, 760),
    'short narrow screen': Size(320, 568),
  };

  sizes.forEach((name, size) {
    testWidgets('every page lays out on a $name', (tester) async {
      await pump(tester, size);

      expect(find.text('Count the days,\nnot the failures.'), findsOneWidget);

      // Walking all four pages is what exercises each illustration; an
      // overflow on any of them fails the test.
      await toLastPage(tester);

      expect(find.text('Nothing leaves\nyour phone.'), findsOneWidget);
      expect(find.text('Set up my first habit'), findsOneWidget);
    });
  });

  testWidgets('skipping finishes and records that it is done', (tester) async {
    var done = false;
    await pump(tester, const Size(360, 760), onDone: () => done = true);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(done, isTrue);
    expect(prefs.hasOnboarded, isTrue);
  });

  testWidgets('finishing the last page records it too', (tester) async {
    var done = false;
    await pump(tester, const Size(360, 760), onDone: () => done = true);

    await toLastPage(tester);
    await tester.tap(find.text('Set up my first habit'));
    await tester.pumpAndSettle();

    expect(done, isTrue);
    expect(prefs.hasOnboarded, isTrue);
  });

  testWidgets('skip is offered on every page but the last', (tester) async {
    await pump(tester, const Size(360, 760));

    expect(find.text('Skip'), findsOneWidget);
    await toLastPage(tester);

    // Nothing left to skip once you are on the final page.
    expect(find.text('Skip'), findsNothing);
  });
}
