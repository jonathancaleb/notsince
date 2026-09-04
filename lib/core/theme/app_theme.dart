import 'package:flutter/material.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/sticker.dart';

ThemeData buildLightTheme() => _theme(NsColors.light, Brightness.light);

ThemeData buildDarkTheme() => _theme(NsColors.dark, Brightness.dark);

/// One builder for both themes.
///
/// Everything that differs between light and dark lives in [NsColors]; nothing
/// here branches on brightness. That is what keeps the two from drifting apart
/// as screens are added.
ThemeData _theme(NsColors ns, Brightness brightness) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: ns.primary,
    onPrimary: ns.onInk,
    primaryContainer: ns.tint,
    onPrimaryContainer: ns.ink,
    secondary: ns.accent,
    onSecondary: ns.onInk,
    secondaryContainer: ns.tint,
    onSecondaryContainer: ns.ink,
    tertiary: ns.accent,
    onTertiary: ns.onInk,
    tertiaryContainer: ns.tint,
    onTertiaryContainer: ns.ink,
    // Material 3 requires an error role and defaults it to red. Nothing in this
    // app is an error state — least of all a reset — so the role is mapped into
    // the same green family. Red cannot leak in even by accident.
    error: ns.primary,
    onError: ns.onInk,
    errorContainer: ns.tint,
    onErrorContainer: ns.ink,
    surface: ns.paper,
    onSurface: ns.ink,
    surfaceContainerLowest: ns.paper,
    surfaceContainerLow: ns.paper,
    surfaceContainer: ns.tint,
    surfaceContainerHigh: ns.tint,
    surfaceContainerHighest: ns.tint,
    onSurfaceVariant: ns.muted,
    outline: ns.ink,
    outlineVariant: ns.ink,
    inverseSurface: ns.ink,
    onInverseSurface: ns.paper,
    inversePrimary: ns.accent,
    shadow: ns.ink,
    scrim: ns.ink.withValues(alpha: 0.4),
    surfaceTint: Colors.transparent,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: AppType.body,
    brightness: brightness,
  );

  // Text inherits its colour from here, so styles in AppType stay colourless
  // and work in both themes without every call site restating it.
  final text = base.textTheme.apply(
    bodyColor: ns.ink,
    displayColor: ns.ink,
  );

  return base.copyWith(
    extensions: [ns],
    textTheme: text,
    scaffoldBackgroundColor: ns.paper,
    appBarTheme: AppBarTheme(
      backgroundColor: ns.paper,
      surfaceTintColor: Colors.transparent,
      foregroundColor: ns.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppType.screenTitle.copyWith(color: ns.ink),
    ),
    // Text fields are drawn as stickers too, so an unstyled field never appears.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ns.paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: TextStyle(color: ns.muted),
      border: _fieldBorder(ns.ink, Sticker.border),
      enabledBorder: _fieldBorder(ns.ink, Sticker.border),
      focusedBorder: _fieldBorder(ns.ink, Sticker.border + 1),
      disabledBorder: _fieldBorder(ns.ink, Sticker.border),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: ns.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: ns.ink, width: Sticker.border),
        borderRadius: BorderRadius.circular(Sticker.radius),
      ),
      titleTextStyle: AppType.cardTitle.copyWith(color: ns.ink),
      contentTextStyle: AppType.bodyText.copyWith(color: ns.ink),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: ns.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      showDragHandle: true,
      dragHandleColor: ns.ink,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: ns.ink, width: Sticker.border),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(Sticker.radius)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ns.primary,
        textStyle: AppType.button,
      ),
    ),
    iconTheme: IconThemeData(color: ns.ink),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: ns.primary,
      selectionColor: ns.primary.withValues(alpha: 0.25),
      selectionHandleColor: ns.primary,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ns.ink,
      contentTextStyle: AppType.bodyText.copyWith(color: ns.paper),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: DividerThemeData(color: ns.ink, thickness: 2, space: 2),
  );
}

OutlineInputBorder _fieldBorder(Color ink, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(Sticker.smallRadius),
      borderSide: BorderSide(color: ink, width: width),
    );
