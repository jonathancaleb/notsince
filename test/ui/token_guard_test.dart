import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A structural guard, not a UI test: the type scale and the palette are
/// meant to be closed sets, so no new `fontSize:` literals or raw `Color(0x…)`
/// values may appear outside `lib/core/theme/`.
///
/// Structural exceptions are, by name:
///  - `Wordmark(fontSize: …)` — the wordmark is a drawing, and its caller
///    states the drawn size at the call site;
///  - `Colors.white` / `Colors.transparent` — structural on-ink fills and
///    outlines, allowed to stay (never a new raw hex);
///  - `Color.lerp`/alpha tints of an existing token rather than a new hue —
///    the guard only fails on raw hex constructors.
void main() {
  test('no fontSize or raw hex colors outside core/theme', () {
    final offenders = <String>[];
    final libRoot = Directory('lib');

    for (final entity in libRoot.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll('\\', '/');
      if (normalized.contains('/core/theme/')) continue;

      final text = entity.readAsStringSync();
      final lines = text.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];

        // Inline comments describing the rule may name a size; strip them.
        final lowered = line.split('//').first.toLowerCase();

        // `Wordmark(fontSize: …)` states a drawn size at the call site by
        // design — it is a parameter of a drawing, not text styling.
        if (lowered.contains('wordmark(')) continue;

        final fontSizeLiteral = RegExp(r'fontSize:\s*\d', caseSensitive: false);
        final hexLiteral = RegExp(r'Color\(0x', caseSensitive: false);

        if (fontSizeLiteral.hasMatch(lowered)) {
          offenders.add(
            '${entity.uri.path}:${i + 1}: fontSize literal',
          );
        }
        if (hexLiteral.hasMatch(lowered)) {
          offenders.add(
            '${entity.uri.path}:${i + 1}: raw hex color literal',
          );
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Literals against the closed type scale / palette. Add a named entry '
          'in lib/core/theme/app_type.dart or app_colors.dart instead:',
    );
  });
}
