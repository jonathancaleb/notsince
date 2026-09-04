import 'package:flutter/material.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/sticker.dart';

/// A switch drawn in the app's own language — Material's has a blurred thumb
/// shadow and its own palette, both of which would be the only ones on screen.
class StickerSwitch extends StatelessWidget {
  const StickerSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: 56,
            height: 32,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? ns.accent : ns.paper,
              border: Sticker.thinOutline(ns.ink),
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: ns.paper,
                  border: Sticker.thinOutline(ns.ink),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
