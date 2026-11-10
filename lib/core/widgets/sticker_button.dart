import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/sketch.dart';
import 'package:notsince/core/theme/sticker.dart';

/// A pressable sketch.
///
/// Motion answers a touch rather than decorating: on press the shape slides
/// into its hatched shadow (so the bottom-right edge stays put) and gives a
/// small wobble, the way a paper cut-out tips under a fingertip. It settles
/// back with a little overshoot on release.
class StickerButton extends StatefulWidget {
  const StickerButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color,
    this.foreground,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.radius = Sticker.smallRadius,
    this.expand = true,
    this.thin = false,
  });

  final Widget child;
  final VoidCallback? onPressed;

  /// Default to the theme's primary and its contrasting ink.
  final Color? color;
  final Color? foreground;

  final EdgeInsetsGeometry padding;
  final double radius;
  final bool expand;
  final bool thin;

  @override
  State<StickerButton> createState() => _StickerButtonState();
}

class _StickerButtonState extends State<StickerButton>
    with SingleTickerProviderStateMixin {
  late final _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 380),
  );

  bool get _enabled => widget.onPressed != null;

  void _down() {
    if (!MediaQuery.disableAnimationsOf(context)) _press.forward();
  }

  void _up() => _press.reverse();

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    final fill = widget.color ?? ns.primary;
    final ink = widget.foreground ?? ns.onInk;
    final lift = Sticker.hatchOffset(Sticker.lift);
    final pressed = Sticker.hatchOffset(Sticker.pressed);

    return Semantics(
      button: true,
      enabled: _enabled,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => _down() : null,
        onTapUp: _enabled ? (_) => _up() : null,
        onTapCancel: _enabled ? _up : null,
        onTap: widget.onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: AnimatedBuilder(
            animation: _press,
            builder: (context, child) {
              // Forward is a straight press; the release runs back through
              // elasticOut so the shape settles with one small bounce.
              final t = _press.status == AnimationStatus.reverse
                  ? Curves.easeOutBack.transform(_press.value)
                  : _press.value;
              final shadow = Offset.lerp(lift, pressed, t)!;
              final travel = lift - shadow;
              return Transform.translate(
                offset: travel,
                child: Transform.rotate(
                  angle: math.sin(t * math.pi) * -.018,
                  child: CustomPaint(
                    painter: SketchBoxPainter(
                      fill: _enabled ? fill : ns.tint,
                      ink: ns.ink,
                      radius: widget.radius,
                      shadow: shadow,
                      strokeWidth: widget.thin
                          ? Sketch.thinStroke
                          : Sketch.stroke,
                    ),
                    child: child,
                  ),
                ),
              );
            },
            child: Padding(
              padding: widget.padding,
              child: DefaultTextStyle.merge(
                textAlign: TextAlign.center,
                style: AppType.buttonLarge.copyWith(
                  color: _enabled ? ink : ns.muted,
                ),
                child: IconTheme(
                  data: IconThemeData(
                    color: _enabled ? ink : ns.muted,
                    size: 20,
                  ),
                  child: widget.expand
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Flexible(child: widget.child)],
                        )
                      : widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
