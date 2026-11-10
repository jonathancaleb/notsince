import 'package:flutter/material.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/theme/sketch.dart';

/// The entire identity: no mark, no mascot, just the name, handwritten.
///
/// The word is in ink and the accent goes into a scribbled underline that
/// draws itself on, the same mark as the app icon and the launch screen, so
/// the logo is one thing wherever it appears.
class Wordmark extends StatelessWidget {
  const Wordmark({
    super.key,
    this.fontSize = 26,
    this.color,
    this.underline = true,
  });

  final double fontSize;
  final Color? color;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    final size = fontSize * 1.3;
    final word = Text(
      'notsince',
      maxLines: 1,
      softWrap: false,
      style: TextStyle(
        fontFamily: AppType.display,
        fontSize: size,
        height: 1,
        color: color ?? ns.ink,
      ),
    );
    if (!underline) return word;
    return ScribbleUnderline(
      color: ns.primary,
      width: (size * .085).clamp(2.0, 5.0),
      gap: 0,
      child: word,
    );
  }
}
