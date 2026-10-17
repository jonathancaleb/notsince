import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/theme/sticker.dart';
import 'package:notsince/features/alarms/application/alarms_controller.dart';
import 'package:notsince/features/alarms/data/alarm_scheduler.dart';
import 'package:notsince/features/alarms/presentation/alarm_ring_screen.dart';
import 'package:notsince/features/alarms/presentation/alarms_screen.dart';

import 'package:notsince/features/counter/presentation/counter_screen.dart';
import 'package:notsince/features/planner/presentation/today_screen.dart';
import 'package:notsince/features/planner/presentation/planner_screen.dart';
import 'package:notsince/features/planner/presentation/notes_hub_screen.dart';
import 'package:notsince/features/planner/presentation/reports_screen.dart';
import 'package:notsince/features/garden/presentation/garden_screen.dart';
import 'package:notsince/features/planner/data/planner_store.dart';
import 'package:notsince/core/theme/app_colors.dart';

enum HomeTab { home, habit, alarms, notes, planner, garden, insights }

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

final homeTabProvider = NotifierProvider<HomeTabController, HomeTab>(
  HomeTabController.new,
);

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
    if (ringing.isEmpty ||
        _ringScreenOpen ||
        !mounted ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }

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
              TodayScreen(),
              CounterScreen(),
              AlarmsScreen(),
              NotesHubScreen(),
              PlannerScreen(),
              GardenScreen(),
              InsightsScreen(),
            ],
          ),
          const Positioned(left: 0, right: 0, bottom: 0, child: _NavIsland()),
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
    (HomeTab.home, Icons.wb_sunny_rounded, 'Today'),
    (HomeTab.planner, Icons.calendar_month_rounded, 'Planner'),
    (HomeTab.garden, Icons.local_florist_rounded, 'Garden'),
    (HomeTab.notes, Icons.sticky_note_2_rounded, 'Notes'),
    (HomeTab.insights, Icons.insights_rounded, 'Insights'),
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
        child: CustomPaint(
          painter: _NavPainter(Theme.of(context).colorScheme.surface, ns.ink),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                for (final (tab, icon, label) in _items)
                  Expanded(
                    child: _NavItem(
                      icon: icon,
                      label: label,
                      raised: tab == HomeTab.garden,
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
    case HomeTab.planner:
    case HomeTab.garden:
    case HomeTab.insights:
    case HomeTab.home:
    case HomeTab.habit:
      return AppColors.lifted(
        ref.watch(plannerProvider).accent,
        Theme.of(context).brightness,
      );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.accent,
    required this.isSelected,
    required this.onTap,
    this.raised = false,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final bool isSelected;
  final bool raised;
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
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 44,
              height: 36,
              alignment: Alignment.center,
              transform: Matrix4.translationValues(
                0,
                raised
                    ? -8
                    : isSelected
                    ? -3
                    : 0,
                0,
              ),
              decoration: BoxDecoration(
                color: isSelected ? accent : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? ns.ink.withValues(alpha: .08)
                      : Colors.transparent,
                  width: Sticker.thinBorder,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: isSelected
                    ? Sticker.shadow(ns.ink, const Offset(2, 3))
                    : null,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? (accent.computeLuminance() > .18
                          ? AppColors.darkBg
                          : Colors.white)
                    : ns.muted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppType.navCaption.copyWith(
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

class _NavPainter extends CustomPainter {
  const _NavPainter(this.surface, this.ink);
  final Color surface, ink;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(28)),
      );
    canvas.drawShadow(path, Colors.black.withValues(alpha: .16), 12, false);
    canvas.drawPath(path, Paint()..color = surface);
    canvas.drawPath(
      path,
      Paint()
        ..color = ink.withValues(alpha: ink.computeLuminance() > .5 ? .02 : .1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7,
    );
  }

  @override
  bool shouldRepaint(_NavPainter oldDelegate) =>
      oldDelegate.surface != surface || oldDelegate.ink != ink;
}
