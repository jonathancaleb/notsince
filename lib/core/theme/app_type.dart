import 'package:flutter/material.dart';
import 'package:notsince/core/theme/ns_colors.dart';

/// One face for everything: Nanum Pen Script, the sketchbook's handwriting,
/// bundled as an asset rather than fetched by `google_fonts` — the app makes
/// no network calls, and a font that downloads itself would break that.
/// Licensed OFL; see assets/fonts/.
///
/// The pen face has one weight and a small x-height, so sizes run about 35%
/// larger than they would in a text face, leading is tighter, and nothing
/// asks for bold: the engine would synthesise one, which smears the strokes.
/// Hierarchy comes from size and colour instead.
///
/// [display] and [body] name the same family. They are kept apart so the
/// spoken styles (titles, counts, buttons) and the reading styles
/// (paragraphs, captions) can still be told from each other, and split again
/// if a second face ever returns.
///
/// None of these styles name a colour. They inherit from the theme's text
/// styles so the same style works in light and dark; anything that needs a
/// specific colour applies it with `copyWith` at the call site.
abstract final class AppType {
  static const display = 'NanumPen';
  static const body = display;

  /// Largest spoken style: dashboards and the onboarding welcome. The theme's
  /// `displaySmall` maps to it.
  static const displayLarge = TextStyle(
    fontFamily: display,
    fontSize: 38,
    height: 1.05,
  );

  /// The day count. Sized by the caller; this only fixes its character.
  static TextStyle counter(double size) => TextStyle(
    fontFamily: display,
    // Callers size the count for a heavy face; the pen needs more room to
    // carry the same presence.
    fontSize: size * 1.3,
    height: .9,
  );

  static const screenTitle = TextStyle(
    fontFamily: display,
    fontSize: 32,
    height: 1.05,
  );

  static const cardTitle = TextStyle(
    fontFamily: display,
    fontSize: 29,
    height: 1.1,
  );

  /// Alarm times, which need the same at-a-glance weight as the day count.
  static const clock = TextStyle(
    fontFamily: display,
    fontSize: 46,
    height: 1.0,
  );

  static const bodyText = TextStyle(
    fontFamily: body,
    fontSize: 22,
    height: 1.2,
  );

  /// A sentence or two written by hand: onboarding and empty states, where
  /// the copy is part of the drawing. Not for long reading — that stays in
  /// [paragraph].
  static const penBody = TextStyle(
    fontFamily: display,
    fontSize: 24,
    height: 1.2,
  );

  static const label = TextStyle(
    fontFamily: display,
    fontSize: 22,
    height: 1.1,
  );

  static const button = TextStyle(
    fontFamily: display,
    fontSize: 22,
    height: 1.0,
  );

  /// Body copy for reading paragraphs — like [bodyText] but quieter (no
  /// explicit weight) and slightly looser. The theme's `bodyLarge` and
  /// `bodyMedium` map to it, so unstyled `Text` picks it up.
  static const paragraph = TextStyle(
    fontFamily: body,
    fontSize: 22,
    height: 1.2,
  );

  /// Small caption — like [small] but at weight 400. The theme's `labelSmall`
  /// maps to it.
  static const caption = TextStyle(
    fontFamily: body,
    fontSize: 18,
    height: 1.2,
  );

  /// Secondary text is a weight and a colour, not a different face.
  static const small = TextStyle(
    fontFamily: body,
    fontSize: 18,
    height: 1.2,
  );

  /// Secondary text in the current theme's muted ink.
  static TextStyle muted(NsColors ns) => small.copyWith(color: ns.muted);

  /// Small but strong: chips, badges and kickers that label a group.
  static const smallStrong = TextStyle(
    fontFamily: display,
    fontSize: 18,
    height: 1.1,
  );

  /// The floating nav's caption. Kept at 12 px minimum so nav labels stay
  /// readable and grow sanely with text scaling.
  static const navCaption = TextStyle(
    fontFamily: display,
    fontSize: 17,
    height: 1.0,
  );

  /// Single-line detail text; height left inherited from the ambient style.
  static const detail = TextStyle(
    fontFamily: body,
    fontSize: 19,
  );

  /// Multi-line detail text with the standard body leading.
  static const hint = TextStyle(
    fontFamily: body,
    fontSize: 19,
    height: 1.2,
  );

  /// Group labels within a card, between [detail] and [smallStrong] in tone.
  static const kicker = TextStyle(
    fontFamily: display,
    fontSize: 20,
    height: 1.1,
  );

  /// Paragraphs in dialogs, reassurance copy — quieter tone, standard leading.
  static const footnote = TextStyle(
    fontFamily: body,
    fontSize: 20,
    height: 1.2,
  );

  /// Body copy at weight 400, where strength would shout.
  static const plain = TextStyle(fontFamily: body, fontSize: 20);

  /// Headings on the themeless storage-failure screen.
  static const heading = TextStyle(
    fontFamily: display,
    fontSize: 27,
    height: 1.1,
  );

  /// A row's reading emphasis between body and subhead.
  static const lead = TextStyle(
    fontFamily: body,
    fontSize: 23,
  );

  /// A card's strong first-line title.
  static const subhead = TextStyle(
    fontFamily: body,
    fontSize: 23,
  );

  /// Strong body-size row titles.
  static const bodyStrong = TextStyle(
    fontFamily: body,
    fontSize: 22,
  );

  /// Mid-weight row labels (alarm form options).
  static const midLabel = TextStyle(
    fontFamily: body,
    fontSize: 20,
  );

  /// Group titles inside a settings-style list.
  static const section = TextStyle(
    fontFamily: display,
    fontSize: 26,
    height: 1.1,
  );

  /// Titles on sheets a step below screen titles.
  static const sheetTitle = TextStyle(
    fontFamily: display,
    fontSize: 31,
    height: 1.1,
  );

  /// The counter's empty-state headline.
  static const softTitle = TextStyle(
    fontFamily: display,
    fontSize: 25,
    height: 1.15,
  );

  /// Emoji and glyph marks. Never a text style — size only.
  static TextStyle glyph(double size) => TextStyle(fontSize: size);

  // Pen companions to [cardTitle], for titles a step or two off it.

  /// Card titles a step smaller.
  static const subtitle = TextStyle(
    fontFamily: display,
    fontSize: 25,
    height: 1.1,
  );
  static const cardLead = TextStyle(
    fontFamily: display,
    fontSize: 23,
    height: 1.1,
  );
  static const cardSmall = TextStyle(
    fontFamily: display,
    fontSize: 22,
    height: 1.1,
  );
  static const editorTitle = TextStyle(
    fontFamily: display,
    fontSize: 32,
    height: 1.1,
  );

  /// The counter stat a step below [clock].
  static const stat = TextStyle(
    fontFamily: display,
    fontSize: 42,
    height: 1.0,
  );

  /// The same counter stat at [cardTitle] size, for quiet columns.
  static const statSmall = TextStyle(
    fontFamily: display,
    fontSize: 29,
    height: 1.0,
  );

  /// Sticker button labels are one step larger than [button].
  static const buttonLarge = TextStyle(
    fontFamily: display,
    fontSize: 24,
    height: 1.0,
  );

  /// A label inside a sticker button that runs smaller than [buttonLarge],
  /// keeping the button typeface.
  static const miniButton = TextStyle(
    fontFamily: display,
    fontSize: 21,
    height: 1.0,
  );
}
