import 'package:flutter/material.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/sticker.dart';

/// A cut-out shape: ink outline, hard offset shadow, no blur.
class StickerCard extends StatelessWidget {
  const StickerCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(24),
    this.radius = Sticker.radius,
    this.lift = Sticker.lift,
    this.thin = false,
  });

  final Widget child;

  /// Defaults to the theme's tint, which differs between light and dark.
  final Color? color;

  final EdgeInsetsGeometry padding;
  final double radius;
  final Offset lift;

  /// Thinner outline for small shapes, so a chip does not look as heavy as a
  /// full card.
  final bool thin;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? ns.tint,
        border: thin ? Sticker.thinOutline(ns.ink) : Sticker.outline(ns.ink),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: Sticker.shadow(ns.ink, lift),
      ),
      child: child,
    );
  }
}
