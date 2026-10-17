import 'package:flutter/material.dart';

/// The palette, as a theme extension so it can differ between light and dark.
///
/// `AppPalette` holds the raw hex values and stays the light palette; this is
/// what widgets read, via `context.ns`. It exists because the sticker language
/// needs colours Material's `ColorScheme` has no role for — an ink outline, six
/// habit crayons, four note tags — and because those have to flip with the
/// theme rather than being compile-time constants.
@immutable
class NsColors extends ThemeExtension<NsColors> {
  const NsColors({
    required this.ink,
    required this.paper,
    required this.primary,
    required this.accent,
    required this.tint,
    required this.onInk,
    required this.muted,
    required this.alarm,
    required this.alarmTint,
    required this.crayons,
    required this.crayonTints,
    required this.noteTags,
  });

  /// Outline and text. Dark on light, light on dark — the one decision that
  /// makes every shape read as cut out of the page.
  final Color ink;

  /// The page itself.
  final Color paper;

  final Color primary;
  final Color accent;
  final Color tint;

  /// Text on a filled primary surface.
  final Color onInk;

  /// Secondary text: ink softened rather than grey. Light muted sits at
  /// 5.2:1 on paper; dark muted at 8.2:1.
  final Color muted;

  final Color alarm;
  final Color alarmTint;

  final List<Color> crayons;
  final List<Color> crayonTints;
  final Map<String, Color> noteTags;

  Color crayon(int index) => crayons[index % crayons.length];

  Color crayonTint(int index) => crayonTints[index % crayonTints.length];

  Color noteTag(String tag) => noteTags[tag] ?? crayons.first;

  /// Warm off-white ground, deep green ink.
  static const light = NsColors(
    ink: Color(0xFF302C27),
    paper: Color(0xFFFAF7F0),
    primary: Color(0xFF3B6D11),
    accent: Color(0xFF639922),
    tint: Color(0xFFEAF3DE),
    onInk: Color(0xFFFFFFFF),
    muted: Color(0xFF6E675F),
    alarm: Color(0xFFF5A623),
    alarmTint: Color(0xFFFDF0D9),
    crayons: [
      Color(0xFF639922), // moss
      Color(0xFFE8B33D), // marigold
      Color(0xFF5B9DC9), // sky
      Color(0xFF9B7BC4), // grape
      Color(0xFF2E9187), // teal
      Color(0xFFD2739B), // rose
    ],
    crayonTints: [
      Color(0xFFE7F1D8),
      Color(0xFFFBF0D6),
      Color(0xFFDFEDF7),
      Color(0xFFEDE6F6),
      Color(0xFFDAEFED),
      Color(0xFFF9E4EE),
    ],
    noteTags: {
      'sage': Color(0xFF9FC97A),
      'yellow': Color(0xFFF7D774),
      'coral': Color(0xFFF2967D),
      'blue': Color(0xFF8FB4D9),
    },
  );

  /// Warm charcoal surfaces; habit ring accents are lifted by AppColors.
  /// Tinted fills remain quiet enough to support light text.
  static const dark = NsColors(
    ink: Color(0xFFF3EDE3),
    paper: Color(0xFF171513),
    primary: Color(0xFF8FC45A),
    accent: Color(0xFFA3D46C),
    tint: Color(0xFF1E1C1A),
    onInk: Color(0xFF171513),
    muted: Color(0xFFB6ACA0),
    alarm: Color(0xFFD9922A),
    alarmTint: Color(0xFF2E2411),
    crayons: [
      Color(0xFF4E7A1B),
      Color(0xFFB8862A),
      Color(0xFF3F7699),
      Color(0xFF6E5691),
      Color(0xFF226E66),
      Color(0xFFA15875),
    ],
    crayonTints: [
      Color(0xFF1C2612),
      Color(0xFF2A2313),
      Color(0xFF141F27),
      Color(0xFF1E1826),
      Color(0xFF10231F),
      Color(0xFF251722),
    ],
    noteTags: {
      'sage': Color(0xFF3E5C24),
      'yellow': Color(0xFF6B5518),
      'coral': Color(0xFF6E3427),
      'blue': Color(0xFF2C4763),
    },
  );

  @override
  NsColors copyWith({
    Color? ink,
    Color? paper,
    Color? primary,
    Color? accent,
    Color? tint,
    Color? onInk,
    Color? muted,
    Color? alarm,
    Color? alarmTint,
    List<Color>? crayons,
    List<Color>? crayonTints,
    Map<String, Color>? noteTags,
  }) {
    return NsColors(
      ink: ink ?? this.ink,
      paper: paper ?? this.paper,
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      tint: tint ?? this.tint,
      onInk: onInk ?? this.onInk,
      muted: muted ?? this.muted,
      alarm: alarm ?? this.alarm,
      alarmTint: alarmTint ?? this.alarmTint,
      crayons: crayons ?? this.crayons,
      crayonTints: crayonTints ?? this.crayonTints,
      noteTags: noteTags ?? this.noteTags,
    );
  }

  /// Themes cross-fade, so this has to interpolate rather than snap.
  @override
  NsColors lerp(NsColors? other, double t) {
    if (other == null) return this;
    List<Color> lerpAll(List<Color> a, List<Color> b) => [
      for (var i = 0; i < a.length; i++) Color.lerp(a[i], b[i % b.length], t)!,
    ];

    return NsColors(
      ink: Color.lerp(ink, other.ink, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      tint: Color.lerp(tint, other.tint, t)!,
      onInk: Color.lerp(onInk, other.onInk, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      alarm: Color.lerp(alarm, other.alarm, t)!,
      alarmTint: Color.lerp(alarmTint, other.alarmTint, t)!,
      crayons: lerpAll(crayons, other.crayons),
      crayonTints: lerpAll(crayonTints, other.crayonTints),
      noteTags: {
        for (final entry in noteTags.entries)
          entry.key:
              Color.lerp(entry.value, other.noteTags[entry.key], t) ??
              entry.value,
      },
    );
  }
}

extension NsColorsContext on BuildContext {
  /// The palette for the current theme.
  NsColors get ns => Theme.of(this).extension<NsColors>() ?? NsColors.light;
}
