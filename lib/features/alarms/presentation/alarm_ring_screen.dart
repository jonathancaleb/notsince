import 'package:alarm/alarm.dart' as plugin;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/widgets/sticker_button.dart';
import 'package:notsince/core/widgets/sticker_card.dart';
import 'package:notsince/features/alarms/application/alarms_controller.dart';
import 'package:notsince/features/alarms/domain/alarm_entry.dart';

/// The screen that takes over when an alarm fires.
///
/// Deliberately has only two controls and no way back: anything else here is
/// something to fumble at while half awake. Snooze is the bigger target because
/// it is the one reached for first.
class AlarmRingScreen extends ConsumerWidget {
  const AlarmRingScreen({super.key, required this.id});

  final String id;

  Future<void> _stop(BuildContext context, WidgetRef ref) async {
    final entry = ref.read(alarmProvider(id));
    if (entry != null) {
      await plugin.Alarm.stop(entry.scheduleId);
      await ref.read(alarmsProvider.notifier).settleAfterRing(id);
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _snooze(BuildContext context, WidgetRef ref) async {
    final entry = ref.read(alarmProvider(id));
    if (entry != null) {
      await plugin.Alarm.stop(entry.scheduleId);
      await ref.read(alarmsProvider.notifier).snooze(id);
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    final entry = ref.watch(alarmProvider(id));
    if (entry == null) return const SizedBox.shrink();

    return PopScope(
      // The alarm has to be dealt with, not backed out of.
      canPop: false,
      child: Scaffold(
        backgroundColor: ns.alarmTint,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                StickerCard(
                  color: ns.alarm,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      const Text('🔔', style: TextStyle(fontSize: 44)),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          clockLabel(entry.hour, entry.minute),
                          style: AppType.counter(76),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.label,
                        textAlign: TextAlign.center,
                        style: AppType.cardTitle,
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 3),
                StickerButton(
                  color: ns.paper,
                  foreground: ns.ink,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  onPressed: () => _snooze(context, ref),
                  child: Text('Snooze ${entry.snoozeMinutes} min'),
                ),
                const SizedBox(height: 14),
                StickerButton(
                  color: ns.primary,
                  onPressed: () => _stop(context, ref),
                  child: const Text('Stop'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
