import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notsince/core/theme/app_theme.dart';
import 'package:notsince/core/widgets/doodle_icon.dart';

/// Resolves an `Icons.name` reference found in source to its IconData by
/// rendering nothing: the map below is the set the app draws by hand, and the
/// test fails if a screen starts using a glyph that is not in it.
void main() {
  test('every Material icon used in lib/ has a hand-drawn version', () {
    final used = <String>{};
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.endsWith('doodle_icon.dart')) continue;
      final src = f.readAsStringSync();
      for (final m in RegExp(r'Icons\.([a-z_0-9]+)').allMatches(src)) {
        if (m.group(1) == 'first') continue; // kCounterIcons.first, not a glyph
        used.add(m.group(1)!);
      }
    }
    final source = File('lib/core/widgets/doodle_icon.dart').readAsStringSync();
    final drawn = RegExp(r'Icons\.([a-z_0-9]+):')
        .allMatches(source)
        .map((m) => m.group(1)!)
        .toSet();
    expect(used.difference(drawn), isEmpty,
        reason: 'Add a drawing to _drawings in doodle_icon.dart');
  });

  testWidgets('every drawing paints without throwing, light and dark',
      (tester) async {
    const icons = [
      Icons.wb_sunny_rounded, Icons.nightlight_round, Icons.smartphone_rounded,
      Icons.calendar_month_rounded, Icons.calendar_today_rounded,
      Icons.edit_calendar_rounded, Icons.local_florist_rounded,
      Icons.sticky_note_2_rounded, Icons.insights_rounded,
      Icons.auto_awesome_outlined, Icons.add_rounded, Icons.close_rounded,
      Icons.check_rounded, Icons.chevron_right_rounded,
      Icons.arrow_forward_rounded, Icons.arrow_back_rounded,
      Icons.settings_rounded, Icons.tune_rounded, Icons.more_horiz_rounded,
      Icons.drag_handle_rounded, Icons.lock_rounded, Icons.link_rounded,
      Icons.inventory_2_outlined, Icons.folder_rounded,
      Icons.create_new_folder_outlined, Icons.edit_outlined,
      Icons.visibility_outlined, Icons.delete_outline_rounded,
      Icons.play_arrow_rounded, Icons.pause_rounded, Icons.schedule_rounded,
      Icons.alarm_rounded, Icons.radio_button_unchecked_rounded,
      Icons.check_box_outline_blank_rounded, Icons.check_box_rounded,
    ];
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Wrap(
              children: [
                for (final i in icons) ...[
                  DoodleIcon(i),
                  DoodleIcon(i, size: 16, semanticLabel: 'x'),
                ],
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      for (final i in icons) {
        expect(DoodleIcon.hasDrawing(i), isTrue, reason: '$i');
      }
    }
  });

  testWidgets('an icon with no drawing falls back to the Material glyph',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DoodleIcon(Icons.ac_unit)),
    );
    expect(find.byType(Icon), findsOneWidget);
  });
}
