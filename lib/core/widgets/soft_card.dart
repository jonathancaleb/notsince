import 'package:flutter/material.dart';
import 'package:notsince/core/theme/sketch.dart';

/// A quieter card: sketched outline, no shadow. When a [gradient] is given
/// its first colour stands in as a flat wash — a gradient on a pencil drawing
/// reads as a screen effect, not as paper.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(24),
    this.gradient,
  });
  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    final wash = gradient?.colors.first;
    return SketchBox(
      fill: wash ?? color ?? Theme.of(context).colorScheme.surface,
      padding: padding,
      radius: 22,
      shadow: Offset.zero,
      child: child,
    );
  }
}
