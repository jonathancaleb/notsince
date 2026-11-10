import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/sticker.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/core/time/duration_text.dart';
import 'package:notsince/features/counter/domain/milestones.dart';
import 'package:notsince/features/counter/presentation/counter_form_screen.dart';
import 'package:notsince/features/counter/presentation/milestone_editor_screen.dart';
import 'package:notsince/core/widgets/sticker_button.dart';
import 'package:notsince/core/widgets/sticker_card.dart';
import 'package:notsince/core/widgets/doodle_icon.dart';

/// Everything that belongs to one counter. App-wide preferences live in
/// [AppSettingsScreen] instead, so neither screen becomes a junk drawer.
class CounterSettingsScreen extends ConsumerWidget {
  const CounterSettingsScreen({super.key, required this.id});

  final String id;

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final tracker = ref.read(trackerProvider(id));
    if (tracker == null) return;

    final result = await _RenameDialog.show(context, tracker.name);
    if (result != null) {
      ref.read(trackersProvider.notifier).rename(id, result);
    }
  }

  Future<void> _editStart(BuildContext context, WidgetRef ref) async {
    final tracker = ref.read(trackerProvider(id));
    if (tracker == null) return;
    final now = ref.read(clockProvider).now();

    final date = await showDatePicker(
      context: context,
      initialDate: tracker.startedAt,
      firstDate: DateTime(now.year - 50),
      lastDate: now,
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(tracker.startedAt),
    );

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? tracker.startedAt.hour,
      time?.minute ?? tracker.startedAt.minute,
    );
    ref
        .read(trackersProvider.notifier)
        .editStartedAt(id, picked.isAfter(now) ? now : picked);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this habit?'),
        content: Text(
          '$name and its history are removed from this device. '
          'This cannot be undone.',
          style: AppType.footnote,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    ref.read(trackersProvider.notifier).delete(id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    final tracker = ref.watch(trackerProvider(id));
    if (tracker == null) return const SizedBox.shrink();

    final crayon = ns.crayon(tracker.colorIndex);
    final milestoneSummary = tracker.sortedMilestones.isEmpty
        ? 'None set'
        : tracker.sortedMilestones.map(milestoneLabel).join(', ');

    return Scaffold(
      appBar: AppBar(title: const Text('Habit settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          SettingRow(
            label: 'Counting',
            value: tracker.name,
            onTap: () => _editName(context, ref),
          ),
          const SizedBox(height: 14),
          SettingRow(
            label: 'Counting since',
            value: dateTimeLabel(tracker.startedAt),
            onTap: () => _editStart(context, ref),
          ),
          const SizedBox(height: 14),
          SettingRow(
            label: 'Milestones',
            value: milestoneSummary,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MilestoneEditorScreen(id: id)),
            ),
          ),
          const SizedBox(height: 28),
          const _Label('Icon'),
          const SizedBox(height: 12),
          IconPicker(
            selected: tracker.emoji,
            color: crayon,
            onSelected: (emoji) =>
                ref.read(trackersProvider.notifier).setAppearance(id, emoji: emoji),
          ),
          const SizedBox(height: 28),
          const _Label('Colour'),
          const SizedBox(height: 12),
          ColorPicker(
            selected: tracker.colorIndex,
            onSelected: (i) => ref
                .read(trackersProvider.notifier)
                .setAppearance(id, colorIndex: i),
          ),
          const SizedBox(height: 36),
          StickerButton(
            color: ns.paper,
            foreground: ns.ink,
            thin: true,
            onPressed: () => _delete(context, ref, tracker.name),
            child: const Text('Remove this habit'),
          ),
        ],
      ),
    );
  }
}

/// Owns its own controller.
///
/// Creating the controller in the caller and disposing it as soon as
/// `showDialog` returns looks right but is not: the dialog is still animating
/// out at that point, and its TextField touches the controller during the
/// transition — "A TextEditingController was used after being disposed". A
/// StatefulWidget ties the controller's life to the widget that actually uses
/// it, which is the only thing that knows when it is finished with.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  static Future<String?> show(BuildContext context, String initial) {
    return showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: initial),
    );
  }

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('What are you counting?'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        style: AppType.label,
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return Text(
      text,
      style: AppType.subhead.copyWith(color: ns.ink),
    );
  }
}

/// A tappable settings line, drawn as a sticker like everything else.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return GestureDetector(
      onTap: onTap,
      child: StickerCard(
        color: ns.paper,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        radius: Sticker.smallRadius,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppType.hint.copyWith(color: ns.muted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppType.bodyText.copyWith(color: ns.ink),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            DoodleIcon(Icons.chevron_right_rounded,
                size: 22, color: ns.ink),
          ],
        ),
      ),
    );
  }
}
