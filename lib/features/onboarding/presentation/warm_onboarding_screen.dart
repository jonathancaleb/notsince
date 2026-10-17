import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/prefs/app_prefs.dart';
import 'package:notsince/features/garden/growth_engine.dart';
import 'package:notsince/features/garden/presentation/garden_screen.dart';
import 'package:notsince/features/planner/data/planner_store.dart';
import 'package:notsince/core/theme/app_colors.dart';
import 'package:notsince/core/widgets/primary_button.dart';

class WarmOnboardingScreen extends ConsumerStatefulWidget {
  const WarmOnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  ConsumerState<WarmOnboardingScreen> createState() =>
      _WarmOnboardingScreenState();
}

class _WarmOnboardingScreenState extends ConsumerState<WarmOnboardingScreen> {
  int _page = 0;
  late int _color = ref.read(plannerProvider).accent;
  bool _saving = false;
  static const _slides = [
    (
      'Small beginnings.\nBeautiful growth.',
      'Keep your commitments, care for a habit, and let small daily steps take root.',
    ),
    (
      'A day with\nroom to breathe.',
      'Plan tasks, give projects a little focus, and see where your time went.',
    ),
    (
      'Your thoughts.\nYour own little world.',
      'Write a journal and gather your notes. Everything stays on this device. Rest days never erase your growth.',
    ),
  ];
  Future<void> _next() async {
    if (_page < 3) {
      setState(() => _page++);
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(plannerProvider.notifier).setAccent(_color);
      await ref.read(appPrefsProvider).setOnboarded();
      if (mounted) widget.onDone();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'notsince',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                if (_page < 3)
                  TextButton(
                    onPressed: () => setState(() => _page = 3),
                    child: const Text('Skip intro'),
                  ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: _page == 3 ? 8 : 40),
                    if (_page < 3)
                      Center(
                        child: Transform.scale(
                          scale: 1.5,
                          child: PlantIllustration(
                            stage: GrowthStage.values[_page],
                            wilted: false,
                            color: AppColors.lifted(
                              _color,
                              Theme.of(context).brightness,
                            ),
                          ),
                        ),
                      ),
                    if (_page < 3) const SizedBox(height: 56),
                    Text(
                      _page < 3
                          ? _slides[_page].$1
                          : 'Pick a color.\nPlant your first seed.',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _page < 3
                          ? _slides[_page].$2
                          : 'A color for your first seed. Change it any time.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (_page == 3) ...[
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final color in AppColors.palette)
                            Semantics(
                              label:
                                  'Accent ${AppColors.palette.indexOf(color) + 1}',
                              selected: _color == color,
                              button: true,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(28),
                                onTap: () => setState(() => _color = color),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Color(color),
                                  child: _color == color
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: CircleAvatar(
                      radius: 4,
                      backgroundColor: i == _page
                          ? Color(_color)
                          : Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: _page == 3 ? 'Plant my first habit' : 'Next',
                onPressed: _saving ? null : _next,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
