import 'package:flutter/material.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/sticker.dart';
import 'package:notsince/features/counter/presentation/counter_form_screen.dart';
import 'package:notsince/features/counter/presentation/widgets/counter_page.dart';
import 'package:notsince/features/settings/presentation/app_settings_screen.dart';
import 'package:notsince/core/widgets/sticker_button.dart';
import 'package:notsince/core/widgets/wordmark.dart';

/// Home: one counter at a time, swipe sideways for the next.
///
/// A pager rather than a list because a counter is meant to be looked at, not
/// scanned past. Adding more counters should not turn any single one into a row
/// in a table.
class CounterScreen extends ConsumerStatefulWidget {
  const CounterScreen({super.key});

  @override
  ConsumerState<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends ConsumerState<CounterScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addCounter() async {
    final created = await CounterFormScreen.create(context);
    if (created == null || !mounted) return;

    // Land on the counter that was just made, rather than leaving the person
    // on an unrelated page wondering whether it worked.
    final index = ref.read(trackersProvider).indexWhere((t) => t.id == created);
    if (index >= 0 && _controller.hasClients) {
      _controller.jumpToPage(index);
      setState(() => _index = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    final trackers = ref.watch(trackersProvider);

    if (trackers.isEmpty) return const _NoCounters();

    // A deleted counter can leave the index past the end.
    final safeIndex = _index.clamp(0, trackers.length - 1);
    final active = trackers[safeIndex];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Wordmark(),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 4),
            _PagerDots(
              count: trackers.length,
              index: safeIndex,
              color: ns.crayon(active.colorIndex),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: trackers.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => CounterPage(
                  key: ValueKey(trackers[i].id),
                  id: trackers[i].id,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, Sticker.navClearance),
              child: StickerButton(
                color: ns.paper,
                foreground: ns.ink,
                thin: true,
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: _addCounter,
                child: const Text('Add a habit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reachable only by deleting every counter. An empty screen is an invitation
/// to act, so it offers the one action that matters rather than explaining why
/// it is empty.
class _NoCounters extends StatelessWidget {
  const _NoCounters();

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Wordmark(fontSize: 34),
              const SizedBox(height: 16),
              Text(
                'Nothing is being counted yet.',
                style: AppType.softTitle.copyWith(color: ns.muted),
              ),
              const SizedBox(height: 28),
              StickerButton(
                onPressed: () => CounterFormScreen.create(context),
                child: const Text('Start a habit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One sticker dot per habit, so the pager says how many there are.
class _PagerDots extends StatelessWidget {
  const _PagerDots({
    required this.count,
    required this.index,
    required this.color,
  });

  final int count;
  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    if (count < 2) return const SizedBox(height: 12);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: i == index ? 26 : 12,
              height: 12,
              decoration: BoxDecoration(
                color: i == index ? color : ns.paper,
                border: Border.all(color: ns.ink, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
      ],
    );
  }
}
