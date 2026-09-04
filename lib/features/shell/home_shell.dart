import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/theme/sticker.dart';
import 'package:notsince/features/alarms/application/alarms_controller.dart';
import 'package:notsince/features/alarms/data/alarm_scheduler.dart';
import 'package:notsince/features/alarms/presentation/alarm_ring_screen.dart';
import 'package:notsince/features/alarms/presentation/alarms_screen.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/features/counter/presentation/counter_screen.dart';
import 'package:notsince/features/dashboard/presentation/dashboard_screen.dart';
import 'package:notsince/features/notes/presentation/notes_screen.dart';

enum HomeTab { home, habit, alarms, notes }

/// Which tab is showing.
///
/// Lifted out of the shell's own State so the dashboard's summary cards can
/// hand off to a tab — tapping "next alarm" should take you to alarms, not open
/// a second copy of that screen on top of home.
class HomeTabController extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.home;

  void select(HomeTab tab) => state = tab;
}

final homeTabProvider =
    NotifierProvider<HomeTabController, HomeTab>(HomeTabController.new);

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  bool _ringScreenOpen = false;

  /// Opens the ring screen when the platform starts ringing one of our alarms.
  ///
  /// The full-screen intent already brings the app forward; this is what puts
  /// the right screen in front of the person once it is.
  void _onRinging(Set<int> ringing) {
    if (ringing.isEmpty || _ringScreenOpen || !mounted) return;

    final entry = ref
        .read(alarmsProvider)
        .where((a) => ringing.contains(a.scheduleId))
        .firstOrNull;
    if (entry == null) return;

    _ringScreenOpen = true;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => AlarmRingScreen(id: entry.id)))
        .whenComplete(() => _ringScreenOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(ringingAlarmIdsProvider, (_, next) {
      final ids = next.value;
      if (ids != null) _onRinging(ids);
    });

    final tab = ref.watch(homeTabProvider);

    return Scaffold(
      // The nav floats over the content rather than sitting below it, so the
      // page runs to the bottom edge and the bar reads as an object on top.
      // Screens leave bottom padding for it.
      body: Stack(
        children: [
          // IndexedStack, not a switch: the habit pager and the notes grid
          // should still be where you left them when you come back.
          IndexedStack(
            index: tab.index,
            children: const [
              DashboardScreen(),
              CounterScreen(),
              AlarmsScreen(),
              NotesScreen(),
            ],
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _NavIsland(),
          ),
        ],
      ),
    );
  }
}

/// The nav as its own sticker: detached from the edge, with its own outline and
/// offset shadow, content passing underneath it.
class _NavIsland extends ConsumerWidget {
  const _NavIsland();

  static const _items = <(HomeTab, IconData, String)>[
    (HomeTab.home, Icons.cottage_rounded, 'Home'),
    (HomeTab.habit, Icons.eco_rounded, 'Habit'),
    (HomeTab.alarms, Icons.alarm_rounded, 'Alarms'),
    (HomeTab.notes, Icons.sticky_note_2_rounded, 'Notes'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    final current = ref.watch(homeTabProvider);
    final accent = _accentFor(context, ref, current);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: ns.paper,
            border: Sticker.outline(ns.ink),
            borderRadius: BorderRadius.circular(Sticker.radius),
            boxShadow: Sticker.shadow(ns.ink, Sticker.lift),
          ),
          child: Row(
            children: [
              for (final (tab, icon, label) in _items)
                Expanded(
                  child: _NavItem(
                    icon: icon,
                    label: label,
                    accent: accent,
                    isSelected: tab == current,
                    onTap: () =>
                        ref.read(homeTabProvider.notifier).select(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The colour the island takes for the tab you are on.
///
/// This is the point of the contextual nav: on the habit tab it is that
/// habit's own crayon, on alarms it is amber, on notes it is blue. The bar
/// belongs to what you are looking at instead of floating free of it.
Color _accentFor(BuildContext context, WidgetRef ref, HomeTab tab) {
  final ns = context.ns;
  switch (tab) {
    case HomeTab.alarms:
      return ns.alarm;
    case HomeTab.notes:
      return ns.noteTag('blue');
    case HomeTab.home:
    case HomeTab.habit:
      final trackers = ref.watch(trackersProvider);
      if (trackers.isEmpty) return ns.accent;
      return ns.crayon(trackers.first.colorIndex);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return Semantics(
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The selected tab is a filled circle that sits proud of the bar:
            // the same lift language as every other pressable sticker, so the
            // current tab looks like the one thing standing up.
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 44,
              height: 36,
              alignment: Alignment.center,
              transform: Matrix4.translationValues(0, isSelected ? -3 : 0, 0),
              decoration: BoxDecoration(
                color: isSelected ? accent : Colors.transparent,
                border: Border.all(
                  color: isSelected ? ns.ink : Colors.transparent,
                  width: Sticker.thinBorder,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow:
                    isSelected ? Sticker.shadow(ns.ink, const Offset(2, 3)) : null,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? ns.ink : ns.muted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppType.muted(ns).copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? ns.ink : ns.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
