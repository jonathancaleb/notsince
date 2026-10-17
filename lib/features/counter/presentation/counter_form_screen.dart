import 'package:notsince/features/planner/data/planner_store.dart';
import 'package:notsince/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/sticker.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/core/time/duration_text.dart';
import 'package:notsince/features/counter/domain/counter_icons.dart';
import 'package:notsince/core/widgets/sticker_button.dart';
import 'package:notsince/core/widgets/sticker_card.dart';

/// Making a counter: what it is, how it looks, when it started.
///
/// The same screen is the first thing a new user sees and the "add" flow later
/// on, so there is one place where a counter comes into being and one set of
/// decisions to make about it.
class CounterFormScreen extends ConsumerStatefulWidget {
  const CounterFormScreen({super.key, this.isFirst = false});

  /// Softens the framing for someone who has never seen the app.
  final bool isFirst;

  /// Returns the new counter's id, or null if the person backed out.
  static Future<String?> create(BuildContext context, {bool isFirst = false}) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => CounterFormScreen(isFirst: isFirst)),
    );
  }

  @override
  ConsumerState<CounterFormScreen> createState() => _CounterFormScreenState();
}

class _CounterFormScreenState extends ConsumerState<CounterFormScreen> {
  final _name = TextEditingController();
  late DateTime _startedAt = ref.read(clockProvider).now();
  String _emoji = kCounterIcons.first;
  late int _colorIndex = AppColors.palette
      .indexOf(ref.read(plannerProvider).accent)
      .clamp(0, AppColors.palette.length - 1);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final now = ref.read(clockProvider).now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startedAt,
      // Backdating only: a count cannot begin in the future.
      firstDate: DateTime(now.year - 50),
      lastDate: now,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startedAt),
    );
    if (!mounted) return;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? _startedAt.hour,
      time?.minute ?? _startedAt.minute,
    );
    setState(() => _startedAt = picked.isAfter(now) ? now : picked);
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final created = ref
        .read(trackersProvider.notifier)
        .create(
          name: name,
          startedAt: _startedAt,
          emoji: _emoji,
          colorIndex: _colorIndex,
        );
    ref
        .read(plannerProvider.notifier)
        .setHabit(created.id, color: AppColors.palette[_colorIndex]);
    Navigator.of(context).pop(created.id);
  }

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    final canSave = _name.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirst ? 'Your first habit' : 'New habit'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  const _Label('What are you counting?'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppType.lead.copyWith(color: ns.ink),
                    decoration: const InputDecoration(hintText: 'Drinking'),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      if (canSave) _save();
                    },
                  ),
                  const SizedBox(height: 28),
                  const _Label('Pick an icon'),
                  const SizedBox(height: 12),
                  IconPicker(
                    selected: _emoji,
                    color: ns.crayon(_colorIndex),
                    onSelected: (e) => setState(() => _emoji = e),
                  ),
                  const SizedBox(height: 28),
                  const _Label('Pick a colour'),
                  const SizedBox(height: 12),
                  ColorPicker(
                    selected: _colorIndex,
                    onSelected: (i) => setState(() => _colorIndex = i),
                  ),
                  const SizedBox(height: 28),
                  const _Label('Counting since'),
                  const SizedBox(height: 12),
                  StartTimeCard(startedAt: _startedAt, onTap: _pickStart),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: StickerButton(
                color: ns.crayon(_colorIndex),
                onPressed: canSave ? _save : null,
                child: const Text('Start counting'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return Text(text, style: AppType.subhead.copyWith(color: ns.ink));
  }
}

/// Shared by the create flow and per-counter settings so an icon is chosen the
/// same way wherever it is chosen.
class IconPicker extends StatelessWidget {
  const IconPicker({
    super.key,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final String selected;
  final Color color;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final emoji in kCounterIcons)
          Semantics(
            button: true,
            selected: emoji == selected,
            label: 'Icon $emoji',
            child: GestureDetector(
              onTap: () => onSelected(emoji),
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: emoji == selected ? color : ns.paper,
                  border: Sticker.thinOutline(ns.ink),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: emoji == selected
                      ? Sticker.shadow(ns.ink, const Offset(3, 3))
                      : null,
                ),
                child: Text(emoji, style: AppType.glyph(24)),
              ),
            ),
          ),
      ],
    );
  }
}

class ColorPicker extends StatelessWidget {
  const ColorPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    // Wrap, not Row: six fixed-width swatches plus gaps overflow a 360dp
    // screen, and a Row has no way to give. Wrap also drops the trailing gap.
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < ns.crayons.length; i++)
          Semantics(
            button: true,
            selected: i == selected,
            label: 'Colour ${i + 1}',
            child: GestureDetector(
              onTap: () => onSelected(i),
              child: Container(
                padding: EdgeInsets.only(
                  left: i == selected ? 2 : 5,
                  right: i == selected ? 2 : 5,
                ),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ns.crayons[i],
                  border: Border.all(
                    color: ns.ink,
                    width: i == selected ? 4 : Sticker.thinBorder,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: i == selected
                      ? Sticker.shadow(ns.ink, const Offset(3, 3))
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class StartTimeCard extends StatelessWidget {
  const StartTimeCard({
    super.key,
    required this.startedAt,
    required this.onTap,
  });

  final DateTime startedAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return GestureDetector(
      onTap: onTap,
      child: StickerCard(
        color: ns.paper,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        radius: Sticker.smallRadius,
        child: Row(
          children: [
            Expanded(
              child: Text(
                dateTimeLabel(startedAt),
                style: AppType.bodyText.copyWith(color: ns.ink),
              ),
            ),
            Icon(Icons.edit_calendar_rounded, size: 20, color: ns.ink),
          ],
        ),
      ),
    );
  }
}
