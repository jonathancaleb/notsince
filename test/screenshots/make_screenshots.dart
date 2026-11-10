import 'dart:io';

import 'package:flutter/material.dart';

import 'dart:ui' show ImageByteFormat;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notsince/core/prefs/app_prefs.dart';
import 'package:notsince/core/theme/app_theme.dart';
import 'package:notsince/features/planner/data/planner_store.dart';
import 'package:notsince/features/planner/domain/models.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/features/alarms/application/alarms_controller.dart';
import 'package:notsince/features/alarms/data/alarm_repository.dart';
import 'package:notsince/features/alarms/data/alarm_scheduler.dart';
import 'package:notsince/features/counter/application/progress_provider.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/features/counter/data/tracker_repository.dart';
import 'package:notsince/features/notes/application/notes_controller.dart';
import 'package:notsince/features/notes/data/note_repository.dart';
import 'package:notsince/features/notifications/data/notification_service.dart';
import 'package:notsince/features/onboarding/presentation/warm_onboarding_screen.dart';
import 'package:notsince/features/shell/home_shell.dart';

import '../support/fakes.dart';

/// Renders store screenshots from the real widgets.
///
/// Run with:
///   flutter test test/screenshots/make_screenshots.dart --update-goldens
///
/// Deliberately *not* named `*_test.dart`, so `flutter test` skips it. It is a
/// generator, not a test: note cards take their tilt from a random id, so two
/// runs never produce identical pixels and a golden comparison would fail on
/// every CI run.
///
/// These are the actual screens, not mock-ups — the same widget tree the app
/// builds, driven with realistic data instead of the "Test task" leftovers a
/// hand-captured screenshot ends up with. Rendering them means a copy change
/// can never leave the store listing showing text the app no longer says.
///
/// Sized to a Galaxy S23: 1080x2340 physical, 3.0 density, so 360x780 logical.
const String emojiFamily = 'NotoColorEmoji';

/// The app is rendered into the area *between* the status bar and the gesture
/// pill; the framing script adds those strips back. Reserving them here through
/// `view.padding` does not work — the render still starts at y=0 and the status
/// bar ends up drawn on top of the wordmark.
const double s23Density = 3.0;
const int statusBarPx = 108;
const int gestureBarPx = 54;

/// Logical size: 360x726dp, which is an S23's 360x780 less the two strips.
const Size s23AppArea = Size(360, 726);

/// A fixed instant, so the clock in the shots never drifts and the day count
/// is always the same.
final shotTime = DateTime(2026, 3, 4, 9, 41);

void main() {
  late ProviderContainer container;
  late FakePrefs prefs;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadBundledFonts();
  });

  setUp(() async {
    prefs = FakePrefs();
    container = ProviderContainer(
      overrides: [
        trackerRepositoryProvider.overrideWithValue(FakeTrackerRepository()),
        noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
        alarmRepositoryProvider.overrideWithValue(FakeAlarmRepository()),
        appPrefsProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(FakeNotifications()),
        alarmSchedulerProvider.overrideWithValue(const NoScheduler()),
        clockProvider.overrideWithValue(FixedClock(shotTime)),
        nowProvider.overrideWith((ref) => shotTime),
      ],
    );
    _seed(container);
    await _seedPlanner(container);
  });

  tearDown(() => container.dispose());

  /// Renders one screen and writes it as a PNG.
  ///
  /// Captured by hand rather than through `matchesGoldenFile`, which rasterises
  /// at 1x however the view's density is set — the result was a 360px-wide
  /// image upscaled into the store listing. Going through the repaint boundary
  /// lets the pixel ratio be stated explicitly, so a 360dp layout comes out at
  /// a real 1080px.
  Future<void> shoot(
    WidgetTester tester,
    String name, {
    HomeTab tab = HomeTab.home,
    ThemeMode mode = ThemeMode.light,
    Widget home = const HomeShell(),
    int nextTaps = 0,
  }) async {
    tester.view.physicalSize = s23AppArea;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    container.read(homeTabProvider.notifier).select(tab);

    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _withEmoji(AppTheme.light),
            darkTheme: _withEmoji(AppTheme.dark),
            themeMode: mode,
            home: home,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < nextTaps; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;

    late Uint8List png;
    await tester.runAsync(() async {
      final image = await render.toImage(pixelRatio: s23Density);
      final data = await image.toByteData(format: ImageByteFormat.png);
      png = data!.buffer.asUint8List();
      image.dispose();
    });

    final output =
        Platform.environment['SCREENSHOT_OUTPUT'] ?? 'test/screenshots/raw';
    final out = File('$output/$name.png');
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(png);
    // ignore: avoid_print
    print('wrote ${out.path}');
  }

  testWidgets('01 home', (t) => shoot(t, '01-home'));
  testWidgets('02 habit', (t) => shoot(t, '02-habit', tab: HomeTab.habit));
  testWidgets('03 alarms', (t) => shoot(t, '03-alarms', tab: HomeTab.alarms));
  testWidgets('04 notes', (t) => shoot(t, '04-notes', tab: HomeTab.notes));
  testWidgets('05 dark home', (t) => shoot(t, '05-dark', mode: ThemeMode.dark));
  testWidgets(
    '06 planner',
    (t) => shoot(t, '06-planner', tab: HomeTab.planner),
  );
  testWidgets('07 garden', (t) => shoot(t, '07-garden', tab: HomeTab.garden));
  testWidgets(
    '08 insights',
    (t) => shoot(t, '08-insights', tab: HomeTab.insights),
  );
  testWidgets(
    '09 dark garden',
    (t) =>
        shoot(t, '09-dark-garden', tab: HomeTab.garden, mode: ThemeMode.dark),
  );
  for (var page = 0; page < 4; page++) {
    testWidgets(
      '1$page onboarding ${page + 1}',
      (t) => shoot(
        t,
        '1$page-onboarding-${page + 1}',
        home: WarmOnboardingScreen(onDone: () {}),
        nextTaps: page,
      ),
    );
  }
  testWidgets(
    '14 dark onboarding',
    (t) => shoot(
      t,
      '14-dark-onboarding',
      home: WarmOnboardingScreen(onDone: () {}),
      mode: ThemeMode.dark,
    ),
  );
}

Future<void> _seedPlanner(ProviderContainer container) async {
  final planner = container.read(plannerProvider.notifier);
  await planner.addProject('Personal', 0xFF639922);
  await planner.addProject('Work', 0xFF5B9DC9);
  await planner.addTask('A walk before lunch @Personal');
  await planner.addTask(
    'Finish a first draft @Work',
    recurrence: const RecurrenceRule(weekdays: [1, 2, 3, 4, 5]),
  );
  await planner.addTask('Make time for a chapter @Personal');
  await planner.saveNote(
    const PlannerNote(
      id: 'reflection',
      body: '# A gentler rhythm\n\nA little care goes a long way.\n\n- Walk after dinner\n- Read a chapter\n- Put the phone down',
    ),
  );
  final clock = container.read(clockProvider) as FixedClock;
  final habits = container.read(trackersProvider);
  for (var i = 6; i >= 0; i--) {
    clock.set(shotTime.subtract(Duration(days: i)));
    await planner.checkIn(habits.first.id);
  }
  clock.set(DateTime(shotTime.year, shotTime.month, shotTime.day, 9));
  await planner.toggleTimer(SubjectType.day, dayKey(shotTime));
  clock.set(DateTime(shotTime.year, shotTime.month, shotTime.day, 9, 25));
  await planner.toggleTimer(
    SubjectType.project,
    container.read(plannerProvider).projects.last.id,
  );
  clock.set(shotTime);
  await planner.toggleTimer(
    SubjectType.project,
    container.read(plannerProvider).projects.last.id,
  );
}

/// Adds the emoji fallback the device would supply from its system fonts.
ThemeData _withEmoji(ThemeData theme) {
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamilyFallback: const [emojiFamily]),
  );
}

/// Believable content for someone a month in.
///
/// Chosen to show the app doing its job: a habit far enough along that the
/// plant has leaves, an alarm that is actually switched on, and a mix of notes
/// and tasks including one already ticked.
void _seed(ProviderContainer container) {
  final trackers = container.read(trackersProvider.notifier);
  trackers.create(
    name: 'Drinking',
    startedAt: shotTime.subtract(const Duration(days: 34, hours: 5)),
    emoji: '🍺',
    colorIndex: 0,
  );
  trackers.create(
    name: 'Late-night scrolling',
    startedAt: shotTime.subtract(const Duration(days: 9, hours: 2)),
    emoji: '📱',
    colorIndex: 2,
  );

  final alarms = container.read(alarmsProvider.notifier);
  alarms.create(
    label: 'Wake up',
    hour: 6,
    minute: 30,
    repeatDays: const [1, 2, 3, 4, 5],
    soundId: 'chime',
  );
  alarms.create(
    label: 'Wind down',
    hour: 22,
    minute: 0,
    repeatDays: const [1, 2, 3, 4, 5, 6, 7],
    soundId: 'marimba',
  );

  final notes = container.read(notesProvider.notifier);

  final task = notes.create(isTask: true, colorTag: 'blue');
  notes.save(
    task.id,
    title: 'Call the dentist',
    body: 'Ask about the evening slot',
    dueAt: shotTime.add(const Duration(days: 2)),
  );

  final done = notes.create(isTask: true, colorTag: 'sage');
  notes.save(done.id, title: 'Book gym induction', body: 'Tuesday, 7pm');
  notes.setDone(done.id, true);

  final list = notes.create(colorTag: 'yellow');
  notes.save(
    list.id,
    title: 'Things that help',
    body: 'Walk after dinner\nCall Sam\nBed before 11',
  );

  final plan = notes.create(colorTag: 'coral');
  notes.save(plan.id, title: 'Saturday', body: 'Cinema instead of the pub');
}

/// Loads the app's own fonts into the test renderer.
///
/// Without this the golden renders in the test framework's placeholder face and
/// every screenshot comes out as grey blocks.
Future<void> _loadBundledFonts() async {
  const families = <String, List<String>>{
    'NanumPen': ['assets/fonts/NanumPenScript-400.ttf'],
    'Baloo2': [
      'assets/fonts/Baloo2-400.ttf',
      'assets/fonts/Baloo2-600.ttf',
      'assets/fonts/Baloo2-700.ttf',
      'assets/fonts/Baloo2-800.ttf',
    ],
    'Quicksand': [
      'assets/fonts/Quicksand-400.ttf',
      'assets/fonts/Quicksand-500.ttf',
      'assets/fonts/Quicksand-600.ttf',
      'assets/fonts/Quicksand-700.ttf',
    ],
  };

  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      loader.addFont(
        File(path).readAsBytes().then((b) => ByteData.view(b.buffer)),
      );
    }
    await loader.load();
  }

  // Material's icon font ships with the SDK rather than the app, so the test
  // renderer has to be pointed at it or every icon draws as an empty box.
  final icons = File(
    '${_flutterRoot()}/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(icons.readAsBytes().then((b) => ByteData.view(b.buffer)));
    await loader.load();
  } else {
    // ignore: avoid_print
    print('WARNING: Material icon font not found — icons will render blank.');
  }

  // Emoji come from the system font on a device, and the test renderer has
  // none. The font is registered under its own family here and reached through
  // `fontFamilyFallback` on the theme in [shoot] — a missing glyph resolves
  // through the fallback list, not by walking the fonts inside a family.
  final emoji = File('test/screenshots/fonts/NotoEmoji.ttf');
  if (emoji.existsSync()) {
    final loader = FontLoader(emojiFamily)
      ..addFont(emoji.readAsBytes().then((b) => ByteData.view(b.buffer)));
    await loader.load();
  } else {
    // ignore: avoid_print
    print('WARNING: emoji font not found — emoji will render blank.');
  }
}

/// Where the Flutter SDK lives, derived from the running Dart executable.
String _flutterRoot() {
  var dir = File(Platform.resolvedExecutable).parent;
  while (dir.path != dir.parent.path) {
    if (Directory('${dir.path}/bin/cache/artifacts/material_fonts')
        .existsSync()) {
      return dir.path;
    }
    dir = dir.parent;
  }
  return Platform.environment['FLUTTER_ROOT'] ?? '';
}
