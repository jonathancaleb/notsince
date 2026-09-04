import 'package:flutter/material.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/app_type.dart';

/// The entire identity: no mark, no mascot, just the name set in green.
///
/// Tightened tracking and a heavy weight make the word read as one drawn shape
/// rather than as running text, which is the only job it has to do.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.fontSize = 26, this.color});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return Text(
      'notsince',
      style: TextStyle(
        fontFamily: AppType.display,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1,
        color: color ?? ns.primary,
      ),
    );
  }
}
