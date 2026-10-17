import 'package:flutter/material.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/features/counter/application/milestone_provider.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/sticker.dart';
import 'package:notsince/features/counter/domain/milestones.dart';
import 'package:notsince/core/widgets/sticker_button.dart';
import 'package:notsince/core/widgets/sticker_card.dart';

/// A quiet acknowledgement, in place, on the screen the person is already on.
/// Not a modal, not a takeover, not a celebration — it waits to be noticed and
/// is dismissed by hand.
class MilestoneBanner extends ConsumerWidget {
  const MilestoneBanner({super.key, required this.id, required this.color});

  final String id;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    final pending = ref.watch(pendingMilestoneProvider(id));

    // The one non-interactive motion in the app: a single fade and settle on
    // arrival. Nothing loops, nothing repeats.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
      child: pending == null
          ? const SizedBox(key: ValueKey('none'), width: double.infinity)
          : Padding(
              key: ValueKey(pending),
              padding: const EdgeInsets.only(bottom: 20),
              child: StickerCard(
                color: color,
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                radius: Sticker.smallRadius,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${milestoneLabel(pending)} reached',
                            style: AppType.subhead.copyWith(color: ns.ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Worth noticing.',
                            style: AppType.detail.copyWith(color: ns.ink),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    StickerButton(
                      color: ns.paper,
                      foreground: ns.ink,
                      thin: true,
                      expand: false,
                      radius: 12,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      onPressed: () => ref
                          .read(trackersProvider.notifier)
                          .acknowledgeMilestone(id, pending),
                      child: const Text('Got it',
                          style: AppType.miniButton),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
