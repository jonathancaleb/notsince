import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/prefs/app_prefs.dart';
import 'package:notsince/core/theme/app_theme.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/features/counter/presentation/counter_form_screen.dart';
import 'package:notsince/features/onboarding/presentation/warm_onboarding_screen.dart';
import 'package:notsince/features/shell/home_shell.dart';
import 'package:notsince/features/garden/presentation/garden_screen.dart';
import 'package:notsince/features/planner/data/planner_store.dart';

class NotSinceApp extends ConsumerWidget {
  const NotSinceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'notsince',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightWithAccent(
        ref.watch(plannerProvider.select((s) => s.accent)),
      ),
      darkTheme: AppTheme.darkWithAccent(
        ref.watch(plannerProvider.select((s) => s.accent)),
      ),
      themeMode: ref.watch(appSettingsProvider).themeMode,
      home: const _RootGate(),
      onGenerateRoute: (settings) {
        final path = Uri.tryParse(settings.name ?? '')?.path ?? '';
        const tabs = {
          '/today': HomeTab.home,
          '/planner': HomeTab.planner,
          '/garden': HomeTab.garden,
          '/notes': HomeTab.notes,
          '/insights': HomeTab.insights,
        };
        final tab = tabs[path];
        if (tab != null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => _DeepLinkGate(tab: tab),
          );
        }
        if (path.startsWith('/habit/')) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) =>
                _DeepLinkGate(habitId: Uri.decodeComponent(path.substring(7))),
          );
        }
        return null;
      },
    );
  }
}

class _DeepLinkGate extends ConsumerStatefulWidget {
  const _DeepLinkGate({this.tab, this.habitId});
  final HomeTab? tab;
  final String? habitId;
  @override
  ConsumerState<_DeepLinkGate> createState() => _DeepLinkGateState();
}

class _DeepLinkGateState extends ConsumerState<_DeepLinkGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.tab != null) {
        ref.read(homeTabProvider.notifier).select(widget.tab!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.read(appPrefsProvider).hasOnboarded) return const _RootGate();
    return widget.habitId == null
        ? const HomeShell()
        : PlantDetailScreen(id: widget.habitId!);
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
    if (!_onboarded) return WarmOnboardingScreen(onDone: _finishOnboarding);
    return const HomeShell();
  }
}
