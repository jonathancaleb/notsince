import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/prefs/app_prefs.dart';
import 'package:notsince/core/theme/app_theme.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/features/counter/presentation/counter_form_screen.dart';
import 'package:notsince/features/onboarding/presentation/onboarding_screen.dart';
import 'package:notsince/features/shell/home_shell.dart';

class NotSinceApp extends ConsumerWidget {
  const NotSinceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'notsince',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ref.watch(appSettingsProvider).themeMode,
      home: const _RootGate(),
    );
  }
}

/// Everything above the tabs: onboarding on first run, then the shell.
/// No router — a handful of screens, no deep links, nothing to address by URL.
class _RootGate extends ConsumerStatefulWidget {
  const _RootGate();

  @override
  ConsumerState<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends ConsumerState<_RootGate> {
  late bool _onboarded = ref.read(appPrefsProvider).hasOnboarded;

  /// Onboarding hands straight over to making the first habit, so the last
  /// slide's promise ("set up my first habit") is what actually happens.
  void _finishOnboarding() {
    setState(() => _onboarded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ref.read(trackersProvider).isNotEmpty) return;
      CounterFormScreen.create(context, isFirst: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_onboarded) return OnboardingScreen(onDone: _finishOnboarding);
    return const HomeShell();
  }
}
