import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/theme/sticker.dart';
import 'package:notsince/core/widgets/sticker_button.dart';
import 'package:notsince/core/widgets/sticker_card.dart';
import 'package:notsince/features/alarms/application/alarms_controller.dart';
import 'package:notsince/features/alarms/data/alarm_permissions.dart';
import 'package:notsince/features/alarms/domain/alarm_entry.dart';
import 'package:notsince/features/alarms/domain/ringtone.dart';

/// Create and edit share one screen, so an alarm is described the same way
/// however you got here.
class AlarmFormScreen extends ConsumerStatefulWidget {
  const AlarmFormScreen({super.key, this.id});

  /// Null creates a new alarm.
  final String? id;

  static Future<void> open(BuildContext context, {String? id}) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => AlarmFormScreen(id: id)),
    );
  }

  @override
  ConsumerState<AlarmFormScreen> createState() => _AlarmFormScreenState();
}

class _AlarmFormScreenState extends ConsumerState<AlarmFormScreen> {
  late final TextEditingController _label;
  late int _hour;
  late int _minute;
  late Set<int> _days;
  late String _soundId;
  late int _snooze;

  bool get _isNew => widget.id == null;

  @override
  void initState() {
    super.initState();
    final existing = widget.id == null
        ? null
        : ref.read(alarmsProvider.notifier).byId(widget.id!);

    _label = TextEditingController(text: existing?.label ?? '');
    _hour = existing?.hour ?? 7;
    _minute = existing?.minute ?? 0;
    _days = {...?existing?.repeatDays};
    _soundId = existing?.soundId ?? kDefaultRingtoneId;
    _snooze = existing?.snoozeMinutes ?? 5;
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked == null) return;
    setState(() {
      _hour = picked.hour;
      _minute = picked.minute;
    });
  }

  Future<void> _save() async {
    // Asked for here rather than at launch: the request makes sense at the
    // moment someone is actually setting an alarm, and an app that opens with a
    // permission dialog explains nothing.
    final permissions = await ref.read(alarmPermissionsProvider).request();
    if (!mounted) return;
    if (permissions.explanation case final message?) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 6)),
      );
    }

    final controller = ref.read(alarmsProvider.notifier);
    if (_isNew) {
      await controller.create(
        label: _label.text,
        hour: _hour,
        minute: _minute,
        repeatDays: _days.toList(),
        soundId: _soundId,
        snoozeMinutes: _snooze,
      );
    } else {
      await controller.update(
        widget.id!,
        label: _label.text,
        hour: _hour,
        minute: _minute,
        repeatDays: _days.toList(),
        soundId: _soundId,
        snoozeMinutes: _snooze,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref.read(alarmsProvider.notifier).delete(widget.id!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'New alarm' : 'Edit alarm')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // The time is the whole point of the screen, so it is the
                  // biggest thing on it and tapping it anywhere opens the picker.
                  GestureDetector(
                    onTap: _pickTime,
                    child: StickerCard(
                      color: ns.alarmTint,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text(
                          clockLabel(_hour, _minute),
                          style: AppType.counter(66),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _Label('Repeat'),
                  const SizedBox(height: 12),
                  _DayPicker(
                    selected: _days,
                    onToggle: (day) => setState(() {
                      _days.contains(day) ? _days.remove(day) : _days.add(day);
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(repeatLabel(_days.toList()), style: AppType.muted(ns)),
                  const SizedBox(height: 28),
                  const _Label('Label'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _label,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppType.label,
                    decoration: const InputDecoration(hintText: 'Alarm'),
                  ),
                  const SizedBox(height: 28),
                  const _Label('Sound'),
                  const SizedBox(height: 12),
                  _SoundPicker(
                    selected: _soundId,
                    onSelected: (id) => setState(() => _soundId = id),
                  ),
                  const SizedBox(height: 28),
                  const _Label('Snooze'),
                  const SizedBox(height: 12),
                  _SnoozePicker(
                    selected: _snooze,
                    onSelected: (m) => setState(() => _snooze = m),
                  ),
                  if (!_isNew) ...[
                    const SizedBox(height: 36),
                    StickerButton(
                      color: ns.paper,
                      foreground: ns.ink,
                      onPressed: _delete,
                      child: const Text('Remove this alarm'),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: StickerButton(
                color: ns.alarm,
                foreground: ns.ink,
                onPressed: _save,
                child: Text(_isNew ? 'Set alarm' : 'Save changes'),
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
  Widget build(BuildContext context) =>
      Text(text, style: AppType.label);
}

class _DayPicker extends StatelessWidget {
  const _DayPicker({required this.selected, required this.onToggle});

  final Set<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          GestureDetector(
            onTap: () => onToggle(day),
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected.contains(day)
                    ? ns.alarm
                    : ns.paper,
                border: Sticker.thinOutline(ns.ink),
                shape: BoxShape.circle,
              ),
              child: Text(
                names[day - 1],
                style: AppType.label.copyWith(fontSize: 15),
              ),
            ),
          ),
      ],
    );
  }
}

class _SoundPicker extends StatelessWidget {
  const _SoundPicker({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final tone in kRingtones)
          _Chip(
            label: tone.name,
            isSelected: tone.id == selected,
            color: ns.alarm,
            onTap: () => onSelected(tone.id),
          ),
      ],
    );
  }
}

class _SnoozePicker extends StatelessWidget {
  const _SnoozePicker({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final minutes in const [5, 10, 15, 30])
          _Chip(
            label: '$minutes min',
            isSelected: minutes == selected,
            color: ns.alarm,
            onTap: () => onSelected(minutes),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : ns.paper,
          border: Sticker.thinOutline(ns.ink),
          borderRadius: BorderRadius.circular(Sticker.tinyRadius),
          boxShadow: isSelected ? Sticker.shadow(ns.ink, const Offset(3, 3)) : null,
        ),
        child: Text(label, style: AppType.label.copyWith(fontSize: 15)),
      ),
    );
  }
}
