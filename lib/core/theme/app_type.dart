import 'package:flutter/material.dart';
import 'package:notsince/core/theme/ns_colors.dart';

/// Two families with distinct jobs, both bundled as assets rather than fetched
/// by `google_fonts` — the app makes no network calls, and a font that
/// downloads itself would break that. Both licensed OFL; see assets/fonts/.
///
/// Baloo 2 is the voice: heavy, round, slightly goofy. It is used *only* where
/// something should feel spoken out loud — the day count, an alarm time, a
/// screen title. Quicksand carries everything a person actually reads, where
/// Baloo's personality would get tiring.
///
/// None of these styles name a colour. They inherit from the theme's text
/// styles so the same style works in light and dark; anything that needs a
/// specific colour applies it with `copyWith` at the call site.
abstract final class AppType {
  static const display = 'Baloo2';
  static const body = 'Quicksand';

  /// Largest spoken style: dashboards and the onboarding welcome. The theme's
  /// `displaySmall` maps to it.
  static const displayLarge = TextStyle(
    fontFamily: display,
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );

  /// The day count. Sized by the caller; this only fixes its character.
  static TextStyle counter(double size) => TextStyle(
    fontFamily: display,
    fontSize: size,
    fontWeight: FontWeight.w800,
    height: 1.0,
    // Baloo is wide by nature; pulling it in keeps a big number a single
    // shape rather than a row of separate glyphs.
    letterSpacing: size * -0.03,
  );

  static const screenTitle = TextStyle(
    fontFamily: display,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static const cardTitle = TextStyle(
    fontFamily: display,
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  /// Alarm times, which need the same at-a-glance weight as the day count.
  static const clock = TextStyle(
    fontFamily: display,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );

  static const bodyText = TextStyle(
    fontFamily: body,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  static const label = TextStyle(
    fontFamily: body,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const button = TextStyle(
    fontFamily: body,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Body copy for reading paragraphs — like [bodyText] but quieter (no
  /// explicit weight) and slightly looser. The theme's `bodyLarge` and
  /// `bodyMedium` map to it, so unstyled `Text` picks it up.
  static const paragraph = TextStyle(
    fontFamily: body,
    fontSize: 16,
    height: 1.5,
  );

  /// Small caption — like [small] but at weight 400. The theme's `labelSmall`
  /// maps to it.
  static const caption = TextStyle(
    fontFamily: body,
    fontSize: 13,
    height: 1.4,
  );

  /// Secondary text is a weight and a colour, not a different face.
  static const small = TextStyle(
    fontFamily: body,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  /// Secondary text in the current theme's muted ink.
  static TextStyle muted(NsColors ns) => small.copyWith(color: ns.muted);

  /// Small but strong: chips, badges and kickers that label a group.
  static const smallStrong = TextStyle(
    fontFamily: body,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  /// The floating nav's caption. Kept at 12 px minimum so nav labels stay
  /// readable and grow sanely with text scaling.
  static const navCaption = TextStyle(
    fontFamily: body,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  /// Single-line detail text; height left inherited from the ambient style.
  static const detail = TextStyle(
    fontFamily: body,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  /// Multi-line detail text with the standard body leading.
  static const hint = TextStyle(
    fontFamily: body,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  /// Group labels within a card, between [detail] and [smallStrong] in tone.
  static const kicker = TextStyle(
    fontFamily: body,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// Paragraphs in dialogs, reassurance copy — quieter tone, standard leading.
  static const footnote = TextStyle(
    fontFamily: body,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  /// Body copy at weight 400, where strength would shout.
  static const plain = TextStyle(fontFamily: body, fontSize: 15);

  /// Headings on the themeless storage-failure screen.
  static const heading = TextStyle(
    fontFamily: body,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  /// A row's reading emphasis between body and subhead.
  static const lead = TextStyle(
    fontFamily: body,
    fontSize: 17,
    fontWeight: FontWeight.w500,
  );

  /// A card's strong first-line title.
  static const subhead = TextStyle(
    fontFamily: body,
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  /// Strong body-size row titles.
  static const bodyStrong = TextStyle(
    fontFamily: body,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  /// Mid-weight row labels (alarm form options).
  static const midLabel = TextStyle(
    fontFamily: body,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  /// Group titles inside a settings-style list.
  static const section = TextStyle(
    fontFamily: body,
    fontSize: 19,
    fontWeight: FontWeight.w600,
  );

  /// Titles on sheets a step below screen titles.
  static const sheetTitle = TextStyle(
    fontFamily: body,
    fontSize: 23,
    fontWeight: FontWeight.w600,
  );

  /// The counter's empty-state headline.
  static const softTitle = TextStyle(
    fontFamily: body,
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  /// Emoji and glyph marks. Never a text style — size only.
  static TextStyle glyph(double size) => TextStyle(fontSize: size);

  // Baloo 2 companions to [cardTitle], for titles a step or two off 22.

  /// Card titles a step smaller.
  static const subtitle = TextStyle(
    fontFamily: display,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  static const cardLead = TextStyle(
    fontFamily: display,
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );
  static const cardSmall = TextStyle(
    fontFamily: display,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static const editorTitle = TextStyle(
    fontFamily: display,
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  /// The counter stat a step below [clock].
  static const stat = TextStyle(
    fontFamily: display,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );

  /// The same counter stat at [cardTitle] size, for quiet columns.
  static const statSmall = TextStyle(
    fontFamily: display,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );

  /// Sticker button labels are one step larger than [button].
  static const buttonLarge = TextStyle(
    fontFamily: display,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// A label inside a sticker button that runs smaller than [buttonLarge],
  /// keeping the button typeface.
  static const miniButton = TextStyle(
    fontFamily: display,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
}
