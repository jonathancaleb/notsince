import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/features/counter/application/progress_provider.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/sticker.dart';
import 'package:notsince/core/time/duration_text.dart';
import 'package:notsince/core/widgets/sticker_card.dart';

/// A plain list. No chart, no trend line, no "longest run" — ranking past runs
/// against each other would reintroduce exactly the pressure this app avoids.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    final tracker = ref.watch(trackerProvider(id));
    final progress = ref.watch(progressProvider(id));
    if (tracker == null) return const SizedBox.shrink();

    final crayon = ns.crayon(tracker.colorIndex);
    // Newest first.
    final past = tracker.history.reversed.toList();

    return Scaffold(
      appBar: AppBar(title: Text('${tracker.emoji}  ${tracker.name}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _RunTile(
            title: runLength(progress?.elapsed ?? Duration.zero),
            subtitle: 'since ${dateTimeLabel(tracker.startedAt)}',
            color: crayon,
            isCurrent: true,
          ),
          if (past.isEmpty) ...[
            const SizedBox(height: 28),
            Text(
              'This is your first count. Past counts collect here.',
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: ns.muted,
              ),
            ),
          ],
          for (final run in past) ...[
            const SizedBox(height: 14),
            _RunTile(
              title: runLength(run.length),
              subtitle:
                  '${dateTimeLabel(run.startedAt)} to ${dateTimeLabel(run.endedAt)}',
              color: crayon,
              isCurrent: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _RunTile extends StatelessWidget {
  const _RunTile({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isCurrent,
  });

  final String title;
  final String subtitle;
  final Color color;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return StickerCard(
      color: isCurrent ? color : ns.paper,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      radius: Sticker.smallRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: ns.ink,
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ns.paper,
                    border: Sticker.thinOutline(ns.ink),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'now',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ns.ink,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isCurrent ? ns.ink : ns.muted,
            ),
          ),
        ],
      ),
    );
  }
}
