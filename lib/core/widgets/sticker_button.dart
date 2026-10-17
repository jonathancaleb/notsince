import 'package:flutter/material.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/sticker.dart';

/// A pressable sticker.
///
/// The only motion in the app that isn't a page transition, and it exists to
/// answer a touch rather than to decorate: the shape slides into its own shadow
/// so the button physically goes down under the finger. Because it travels
/// exactly as far as the shadow shrinks, the bottom-right edge never moves and
/// nothing around it shifts.
class StickerButton extends StatefulWidget {
  const StickerButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color,
    this.foreground,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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

class _StickerButtonState extends State<StickerButton> {
  bool _down = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    final pressed = _down && _enabled;
    final offset = pressed ? Sticker.pressed : Sticker.lift;
    final travel = Sticker.lift - Sticker.pressed;

    final fill = widget.color ?? ns.primary;
    final ink = widget.foreground ?? ns.onInk;

    return Semantics(
      button: true,
      enabled: _enabled,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: _enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(
              pressed && !MediaQuery.disableAnimationsOf(context)
                  ? travel.dx
                  : 0,
              pressed && !MediaQuery.disableAnimationsOf(context)
                  ? travel.dy
                  : 0,
              0,
            ),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: _enabled ? fill : ns.tint,
              border: widget.thin
                  ? Sticker.thinOutline(ns.ink)
                  : Sticker.outline(ns.ink),
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: Sticker.shadow(ns.ink, offset),
            ),
            child: DefaultTextStyle.merge(
              textAlign: TextAlign.center,
              style: AppType.buttonLarge.copyWith(
                color: _enabled ? ink : ns.muted,
              ),
              child: IconTheme(
                data: IconThemeData(color: _enabled ? ink : ns.muted, size: 20),
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
    );
  }
}
