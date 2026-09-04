import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/sticker.dart';
import 'package:notsince/features/counter/domain/milestones.dart';
import 'package:notsince/core/widgets/sticker_button.dart';
import 'package:notsince/core/widgets/sticker_card.dart';

/// Thresholds are just durations, so editing them is adding to and removing
/// from a list. Removing a milestone is not destructive: nothing is scored
/// against it, and the count itself is untouched.
class MilestoneEditorScreen extends ConsumerWidget {
  const MilestoneEditorScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    final tracker = ref.watch(trackerProvider(id));
    if (tracker == null) return const SizedBox.shrink();

    final crayon = ns.crayon(tracker.colorIndex);
    final milestones = tracker.sortedMilestones;
    final isDefault = milestones.length == kDefaultMilestones.length &&
        milestones.every(kDefaultMilestones.contains);

    return Scaffold(
      appBar: AppBar(title: const Text('Milestones')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Points along the way worth marking. Change them to whatever '
            'suits what you are counting.',
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: ns.muted,
            ),
          ),
          const SizedBox(height: 20),
          for (final milestone in milestones) ...[
            StickerCard(
              color: crayon,
              padding: const EdgeInsets.fromLTRB(18, 6, 6, 6),
              radius: Sticker.smallRadius,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      milestoneLabel(milestone),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: ns.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: ns.ink,
                    tooltip: 'Remove ${milestoneLabel(milestone)}',
                    onPressed: () =>
                        ref.read(trackersProvider.notifier).setMilestones(
                              id,
                              milestones.where((m) => m != milestone).toList(),
                            ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          StickerButton(
            color: ns.paper,
            foreground: ns.ink,
            thin: true,
            onPressed: () async {
              final added = await _AddMilestoneDialog.show(context);
              if (added == null) return;
              ref
                  .read(trackersProvider.notifier)
                  .setMilestones(id, [...milestones, added]);
            },
            child: const Text('Add a milestone'),
          ),
          if (!isDefault) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref
                  .read(trackersProvider.notifier)
                  .setMilestones(id, kDefaultMilestones),
              child: const Text('Restore defaults'),
            ),
          ],
        ],
      ),
    );
  }
}

enum _Unit {
  hours('hours', Duration(hours: 1)),
  days('days', Duration(days: 1)),
  weeks('weeks', Duration(days: 7)),
  months('months', kMonth),
  years('years', kYear);

  const _Unit(this.label, this.unit);

  final String label;
  final Duration unit;
}

class _AddMilestoneDialog extends StatefulWidget {
  const _AddMilestoneDialog();

  static Future<Duration?> show(BuildContext context) {
    return showDialog<Duration>(
      context: context,
      builder: (_) => const _AddMilestoneDialog(),
    );
  }

  @override
  State<_AddMilestoneDialog> createState() => _AddMilestoneDialogState();
}

class _AddMilestoneDialogState extends State<_AddMilestoneDialog> {
  final _amount = TextEditingController(text: '2');
  _Unit _unit = _Unit.weeks;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Duration? get _value {
    final n = int.tryParse(_amount.text.trim());
    if (n == null || n <= 0) return null;
    return _unit.unit * n;
  }

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return AlertDialog(
      title: const Text('Add a milestone'),
      content: Row(
        children: [
          SizedBox(
            width: 92,
            child: TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: ns.ink,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<_Unit>(
              initialValue: _unit,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: ns.ink,
              ),
              items: [
                for (final unit in _Unit.values)
                  DropdownMenuItem(value: unit, child: Text(unit.label)),
              ],
              onChanged: (unit) => setState(() => _unit = unit ?? _unit),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed:
              _value == null ? null : () => Navigator.of(context).pop(_value),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
