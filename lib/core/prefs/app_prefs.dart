import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

/// A tiny key–value box for the handful of app-level flags that are not worth
/// an entity of their own.
class AppPrefs {
  const AppPrefs(this._box);

  static const boxName = 'prefs';
  static const _onboarded = 'onboarded';
  static const _themeMode = 'themeMode';
  static const _notifyMilestones = 'notifyMilestones';
  static const _notifyTasks = 'notifyTasks';

  final Box<dynamic> _box;

  bool get hasOnboarded => _box.get(_onboarded, defaultValue: false) as bool;

  Future<void> setOnboarded() => _box.put(_onboarded, true);

  /// Stored by name rather than index so reordering the enum cannot silently
  /// change someone's setting.
  ThemeMode get themeMode {
    final name = _box.get(_themeMode) as String?;
    return ThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) => _box.put(_themeMode, mode.name);

  bool get notifyMilestones =>
      _box.get(_notifyMilestones, defaultValue: true) as bool;

  Future<void> setNotifyMilestones(bool value) =>
      _box.put(_notifyMilestones, value);

  bool get notifyTasks => _box.get(_notifyTasks, defaultValue: true) as bool;

  Future<void> setNotifyTasks(bool value) => _box.put(_notifyTasks, value);

  /// Used by "remove all data", so a wipe really does return the app to the
  /// state it shipped in rather than leaving flags behind.
  Future<void> clear() => _box.clear();
}

final appPrefsBoxProvider = Provider<Box<dynamic>>(
  (ref) => throw UnimplementedError('appPrefsBoxProvider must be overridden'),
);

final appPrefsProvider =
    Provider<AppPrefs>((ref) => AppPrefs(ref.watch(appPrefsBoxProvider)));

/// Settings that change what the app looks like or does have to be watchable,
/// not just readable, so a toggle repaints the app rather than needing a
/// restart.
class AppSettingsController extends Notifier<AppSettingsState> {
  @override
  AppSettingsState build() {
    final prefs = ref.read(appPrefsProvider);
    return AppSettingsState(
      themeMode: prefs.themeMode,
      notifyMilestones: prefs.notifyMilestones,
      notifyTasks: prefs.notifyTasks,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    ref.read(appPrefsProvider).setThemeMode(mode);
  }

  void setNotifyMilestones(bool value) {
    state = state.copyWith(notifyMilestones: value);
    ref.read(appPrefsProvider).setNotifyMilestones(value);
  }

  void setNotifyTasks(bool value) {
    state = state.copyWith(notifyTasks: value);
    ref.read(appPrefsProvider).setNotifyTasks(value);
  }
}

@immutable
class AppSettingsState {
  const AppSettingsState({
    required this.themeMode,
    required this.notifyMilestones,
    required this.notifyTasks,
  });

  final ThemeMode themeMode;
  final bool notifyMilestones;
  final bool notifyTasks;

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    bool? notifyMilestones,
    bool? notifyTasks,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      notifyMilestones: notifyMilestones ?? this.notifyMilestones,
      notifyTasks: notifyTasks ?? this.notifyTasks,
    );
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettingsState>(
        AppSettingsController.new);
