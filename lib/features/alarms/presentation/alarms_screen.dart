import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/theme/sticker.dart';
import 'package:notsince/core/widgets/sticker_button.dart';
import 'package:notsince/core/widgets/sticker_card.dart';
import 'package:notsince/core/widgets/sticker_switch.dart';
import 'package:notsince/features/alarms/application/alarms_controller.dart';
import 'package:notsince/features/alarms/domain/alarm_entry.dart';
import 'package:notsince/features/alarms/presentation/alarm_form_screen.dart';

class AlarmsScreen extends ConsumerWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    final alarms = ref.watch(alarmsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alarms')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: alarms.isEmpty
                  ? const _NoAlarms()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: alarms.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => _AlarmTile(entry: alarms[i]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: StickerButton(
                color: ns.alarm,
                foreground: ns.ink,
                onPressed: () => AlarmFormScreen.open(context),
                child: const Text('Add an alarm'),
              ),
            ),
            // The nav island floats over the bottom of every screen, so a
            // bottom action has to reserve room for it or it sits underneath,
            // invisible and untappable.
            const SizedBox(height: Sticker.navClearance),
          ],
        ),
      ),
    );
  }
}

class _NoAlarms extends StatelessWidget {
  const _NoAlarms();

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Text(
          'No alarms yet. The one you add will ring even when your phone is '
          'on silent.',
          textAlign: TextAlign.center,
          style: AppType.muted(ns),
        ),
      ),
    );
  }
}

class _AlarmTile extends ConsumerWidget {
  const _AlarmTile({required this.entry});

  final AlarmEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    // A disabled alarm keeps its shape but loses its fill, so the list still
    // reads as a list rather than the row disappearing into the page.
    final enabled = entry.isEnabled;

    return Semantics(
      button: true,
      label:
          '${clockLabel(entry.hour, entry.minute)}, ${entry.label}, '
          '${repeatLabel(entry.repeatDays)}',
      child: GestureDetector(
        onTap: () => AlarmFormScreen.open(context, id: entry.id),
        child: StickerCard(
          color: enabled ? ns.alarmTint : ns.paper,
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clockLabel(entry.hour, entry.minute),
                      style: AppType.clock.copyWith(
                        color: enabled ? ns.ink : ns.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.label}  ·  ${repeatLabel(entry.repeatDays)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.muted(ns),
                    ),
                  ],
                ),
              ),
              StickerSwitch(
                value: enabled,
                onChanged: (v) =>
                    ref.read(alarmsProvider.notifier).setEnabled(entry.id, v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
