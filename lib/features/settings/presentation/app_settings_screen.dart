import 'package:notsince/features/planner/data/planner_store.dart';
import 'package:notsince/features/alarms/application/alarms_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/app_info/app_info.dart';
import 'package:notsince/core/prefs/app_prefs.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/theme/sticker.dart';
import 'package:notsince/features/counter/presentation/counter_settings_screen.dart';
import 'package:notsince/core/widgets/sticker_button.dart';
import 'package:notsince/core/widgets/sticker_card.dart';
import 'package:notsince/core/widgets/sticker_switch.dart';
import 'package:notsince/features/legal/presentation/legal_screen.dart';
import 'package:notsince/features/notifications/data/notification_service.dart';
import 'package:notsince/features/notes/application/notes_controller.dart';

/// App-wide settings: the order counters appear in, and the data as a whole.
///
/// Anything belonging to a single counter stays on that counter, behind its own
/// tune button, so this screen never grows into a list of every setting in the
/// app.
class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  Future<void> _wipe(BuildContext context, WidgetRef ref, int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove everything?'),
        content: Text(
          'Every habit, alarm, note and task is erased from this device, '
          'including $count ${count == 1 ? 'habit' : 'habits'} and their '
          'history. This cannot be undone.',
          style: const TextStyle(fontSize: 15, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep them'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove all'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await ref.read(trackersProvider.notifier).wipeAll();
    for (final alarm in [...ref.read(alarmsProvider)]) {
      await ref.read(alarmsProvider.notifier).delete(alarm.id);
    }
    await ref.read(notesProvider.notifier).clearAll();
    await ref.read(plannerProvider.notifier).clear();
    await ref.read(appPrefsProvider).clear();
    if (context.mounted) Navigator.of(context).pop();
  }

  /// Turning a switch changes what should already be queued with the system,
  /// so the schedule is rebuilt rather than waiting for the next launch.
  void _reschedule(WidgetRef ref) {
    final settings = ref.read(appSettingsProvider);
    ref
        .read(notificationServiceProvider)
        .reconcile(
          trackers: ref.read(trackersProvider),
          notes: ref.read(notesProvider),
          milestonesEnabled: settings.notifyMilestones,
          tasksEnabled: settings.notifyTasks,
          now: DateTime.now(),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    final trackers = ref.watch(trackersProvider);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _SectionTitle('Your habits'),
          const SizedBox(height: 6),
          Text(
            'Drag to change the order you swipe through them.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: ns.muted,
            ),
          ),
          const SizedBox(height: 14),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: trackers.length,
            onReorderItem: (oldIndex, newIndex) =>
                ref.read(trackersProvider.notifier).reorder(oldIndex, newIndex),
            // The default proxy drops a Material shadow under the dragged row,
            // which would be the only blurred shadow in the app.
            proxyDecorator: (child, index, animation) => child,
            itemBuilder: (context, i) {
              final tracker = trackers[i];
              return Padding(
                key: ValueKey(tracker.id),
                padding: const EdgeInsets.only(bottom: 12),
                child: StickerCard(
                  color: ns.crayonTint(tracker.colorIndex),
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  radius: Sticker.smallRadius,
                  child: Row(
                    children: [
                      Text(tracker.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tracker.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ns.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune_rounded, size: 20),
                        color: ns.ink,
                        tooltip: 'Settings for ${tracker.name}',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CounterSettingsScreen(id: tracker.id),
                          ),
                        ),
                      ),
                      ReorderableDragStartListener(
                        index: i,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            size: 22,
                            color: ns.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          const _SectionTitle('Appearance'),
          const SizedBox(height: 12),
          _ThemePicker(
            selected: settings.themeMode,
            onSelected: (mode) =>
                ref.read(appSettingsProvider.notifier).setThemeMode(mode),
          ),
          const SizedBox(height: 28),
          const _SectionTitle('Notifications'),
          const SizedBox(height: 6),
          Text(
            'Quiet reminders on their own channel. Alarms are separate and are '
            'not affected by these.',
            style: AppType.muted(ns),
          ),
          const SizedBox(height: 14),
          _ToggleRow(
            label: 'Milestones',
            detail: 'A note when a habit reaches one of its stops.',
            value: settings.notifyMilestones,
            onChanged: (v) {
              ref.read(appSettingsProvider.notifier).setNotifyMilestones(v);
              _reschedule(ref);
            },
          ),
          const SizedBox(height: 12),
          _ToggleRow(
            label: 'Overdue tasks',
            detail: 'A note when a task passes the time you set for it.',
            value: settings.notifyTasks,
            onChanged: (v) {
              ref.read(appSettingsProvider.notifier).setNotifyTasks(v);
              _reschedule(ref);
            },
          ),
          const SizedBox(height: 28),
          const _SectionTitle('Your data'),
          const SizedBox(height: 12),
          StickerCard(
            color: ns.tint,
            padding: const EdgeInsets.all(18),
            radius: Sticker.smallRadius,
            child: Text(
              'Everything stays on this device. There is no account, no sync, '
              'no analytics, and the app never connects to the internet.',
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: ns.ink,
              ),
            ),
          ),
          const SizedBox(height: 16),
          StickerButton(
            color: ns.paper,
            foreground: ns.ink,
            thin: true,
            onPressed: () => _wipe(context, ref, trackers.length),
            child: const Text('Remove all data'),
          ),
          const SizedBox(height: 32),
          const _SectionTitle('About'),
          const SizedBox(height: 12),
          _AboutRow(
            label: 'Privacy policy',
            onTap: () => LegalScreen.openPrivacy(context),
          ),
          const SizedBox(height: 12),
          _AboutRow(
            label: 'Terms of use',
            onTap: () => LegalScreen.openTerms(context),
          ),
          const SizedBox(height: 12),
          _AboutRow(
            label: 'Open source licences',
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppInfo.name,
              applicationVersion: AppInfo.version,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              '${AppInfo.name} ${AppInfo.version}\nby ${AppInfo.developer}',
              textAlign: TextAlign.center,
              style: AppType.muted(ns).copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Light, dark or whatever the phone is set to.
class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.selected, required this.onSelected});

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    const options = <(ThemeMode, String, IconData)>[
      (ThemeMode.light, 'Light', Icons.wb_sunny_rounded),
      (ThemeMode.dark, 'Dark', Icons.nightlight_round),
      (ThemeMode.system, 'System', Icons.smartphone_rounded),
    ];

    return Row(
      children: [
        for (final (mode, label, icon) in options)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => onSelected(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: mode == selected ? ns.accent : ns.paper,
                    border: Sticker.thinOutline(ns.ink),
                    borderRadius: BorderRadius.circular(Sticker.tinyRadius),
                    boxShadow: mode == selected
                        ? Sticker.shadow(ns.ink, const Offset(3, 3))
                        : null,
                  ),
                  child: Column(
                    children: [
                      Icon(icon, size: 20, color: ns.ink),
                      const SizedBox(height: 4),
                      Text(label, style: AppType.label.copyWith(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;

    return StickerCard(
      color: value ? ns.tint : ns.paper,
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
      radius: Sticker.smallRadius,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppType.label),
                const SizedBox(height: 2),
                Text(detail, style: AppType.muted(ns).copyWith(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          StickerSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.onTap});

  final String label;
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
            Expanded(child: Text(label, style: AppType.label)),
            Icon(Icons.chevron_right_rounded, size: 22, color: ns.ink),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return Text(
      text,
      style: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: ns.ink,
      ),
    );
  }
}
