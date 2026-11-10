import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/sketch.dart';
import 'package:notsince/core/theme/sticker.dart';
import 'package:notsince/core/widgets/doodle_icon.dart';

import 'app_colors.dart';

/// The source-of-truth theme builder.
///
/// [buildLightTheme] / [buildDarkTheme] render the sticker look. [AppTheme]
/// finishes that base with the user's chosen accent (the accent picker asks for
/// an integer from [AppColors.palette] before a theme exists, so custom accents
/// arrive as raw argb) and re-balances type + button shapes on top.

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
    outline: ns.ink.withValues(alpha: .10),
    outlineVariant: ns.ink.withValues(
      alpha: brightness == Brightness.dark ? .02 : .10,
    ),
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
  // Material's own type scale is sized for a text face. The roles stock
  // components fall through to (list tiles, text fields, menus, snack bars)
  // are mapped onto the pen styles so nothing reads a size too small.
  final text = base.textTheme
      .copyWith(
        displaySmall: AppType.displayLarge,
        headlineSmall: AppType.sheetTitle,
        titleLarge: AppType.cardTitle,
        titleMedium: AppType.lead,
        titleSmall: AppType.plain,
        bodyLarge: AppType.paragraph,
        bodyMedium: AppType.paragraph,
        bodySmall: AppType.caption,
        labelLarge: AppType.button,
        labelMedium: AppType.caption,
        labelSmall: AppType.caption,
      )
      .apply(bodyColor: ns.ink, displayColor: ns.ink);

  return base.copyWith(
    extensions: [ns],
    textTheme: text,
    // Scaffolds are see-through: every route is put on the dotted sketchbook
    // page by [PaperPageTransitionsBuilder], so the page texture is painted
    // once per route instead of being restated by every screen.
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: ns.paper,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: PaperPageTransitionsBuilder(
            platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
                ? const CupertinoPageTransitionsBuilder()
                : const FadeForwardsPageTransitionsBuilder(),
          ),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
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
      shape: SketchBorder(
        side: BorderSide(color: Sketch.inkLine(ns.ink), width: Sketch.stroke),
      ),
      titleTextStyle: AppType.cardTitle.copyWith(color: ns.ink),
      contentTextStyle: AppType.bodyText.copyWith(color: ns.ink),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: ns.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      showDragHandle: true,
      dragHandleColor: Sketch.inkLine(ns.ink),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Sketch.inkLine(ns.ink), width: Sticker.border),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Sticker.radius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ns.primary,
        textStyle: AppType.button,
      ),
    ),
    iconTheme: IconThemeData(color: ns.ink),
    // App bars build their own back and close glyphs; route them through the
    // doodle set so the one icon on every pushed screen is hand-drawn too.
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (_) => const DoodleIcon(Icons.arrow_back_rounded),
      closeButtonIconBuilder: (_) => const DoodleIcon(Icons.close_rounded),
    ),
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
    dividerTheme: DividerThemeData(
      color: Sketch.inkShade(ns.ink),
      thickness: 1.2,
      space: 2,
    ),
  );
}

OutlineInputBorder _fieldBorder(Color ink, double width) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(Sticker.smallRadius),
  borderSide: BorderSide(color: Sketch.inkLine(ink), width: width),
);

/// The finished themes the app actually runs with: the sticker base plus the
/// user's accent, with the accent lifted in dark mode so habit rings keep their
/// presence on charcoal.
abstract final class AppTheme {
  static ThemeData get light => _finish(buildLightTheme());
  static ThemeData get dark => _finish(buildDarkTheme());
  static ThemeData lightWithAccent(int accent) =>
      _finish(buildLightTheme(), accent: accent);
  static ThemeData darkWithAccent(int accent) =>
      _finish(buildDarkTheme(), accent: accent);

  static ThemeData _finish(ThemeData base, {int? accent}) {
    final color = AppColors.lifted(
      accent ?? AppColors.accent.toARGB32(),
      base.brightness,
    );
    final scheme = base.colorScheme.copyWith(
      primary: color,
      secondary: color,
      onPrimary: color.computeLuminance() > .18
          ? AppColors.darkBg
          : Colors.white,
      surface: base.brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.surface,
    );
    final penLine = Sketch.inkLine(scheme.onSurface);
    return base.copyWith(
      colorScheme: scheme,
      extensions: [
        base.extension<NsColors>()!.copyWith(
          primary: color,
          accent: color,
          onInk: scheme.onPrimary,
        ),
      ],
      textTheme: base.textTheme
          .copyWith(
            displaySmall: AppType.displayLarge,
            titleLarge: AppType.cardTitle,
            bodyLarge: AppType.paragraph,
            bodyMedium: AppType.paragraph,
            labelSmall: AppType.caption,
          )
          .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          elevation: 0,
          textStyle: AppType.buttonLarge,
          foregroundColor: scheme.onPrimary,
          shape: SketchBorder(side: BorderSide(color: penLine)),
          side: BorderSide(color: penLine, width: Sketch.stroke),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: AppType.button,
          foregroundColor: scheme.onSurface,
          shape: SketchBorder(side: BorderSide(color: penLine)),
          side: BorderSide(color: penLine, width: Sketch.stroke),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: SketchBorder(
          radius: 18,
          side: BorderSide(color: penLine, width: Sketch.thinStroke),
        ),
        side: BorderSide(color: penLine, width: Sketch.thinStroke),
        labelStyle: AppType.label.copyWith(color: scheme.onSurface),
        checkmarkColor: scheme.onSurface,
        selectedColor: scheme.primaryContainer,
        backgroundColor: base.extension<NsColors>()!.paper,
      ),
    );
  }
}
