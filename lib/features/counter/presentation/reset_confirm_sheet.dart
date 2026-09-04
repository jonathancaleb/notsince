import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/features/counter/application/progress_provider.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/time/duration_text.dart';
import 'package:notsince/core/widgets/sticker_button.dart';

/// One clear action with one confirmation step.
///
/// Copy discipline: no "relapse", no "failed", no "start over", no "are you
/// sure". A reset is a new count beginning, described as exactly that. The
/// confirm button is the counter's own colour, not a destructive style.
class ResetConfirmSheet extends ConsumerWidget {
  const ResetConfirmSheet({super.key, required this.id});

  final String id;

  static Future<void> show(BuildContext context, String id) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ResetConfirmSheet(id: id),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    final tracker = ref.watch(trackerProvider(id));
    final progress = ref.watch(progressProvider(id));
    if (tracker == null) return const SizedBox.shrink();

    final elapsed = progress?.elapsed ?? Duration.zero;
    final crayon = ns.crayon(tracker.colorIndex);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(tracker.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Start a new count?',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      color: ns.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your current count of ${runLength(elapsed)} moves into your '
              'history, and a new one begins from now.',
              style: TextStyle(
                fontSize: 16,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: ns.muted,
              ),
            ),
            const SizedBox(height: 28),
            StickerButton(
              color: crayon,
              onPressed: () {
                ref.read(trackersProvider.notifier).reset(id);
                Navigator.of(context).pop();
              },
              child: const Text('Start new count'),
            ),
            const SizedBox(height: 12),
            StickerButton(
              color: ns.paper,
              foreground: ns.ink,
              thin: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    );
  }
}
