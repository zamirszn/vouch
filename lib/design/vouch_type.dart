/// Typography scale for the Vouch rebuild.
///
/// Instrument Sans carries display and body type; Space Mono is reserved for
/// annotations, labels and timestamps. Everything is explicit so no Material
/// text theme leaks back in.
library;

import 'package:flutter/widgets.dart';

import 'vouch_tokens.dart';

abstract final class VouchFonts {
  static const String display = 'InstrumentSans';
  static const String mono = 'SpaceMono';
}

abstract final class VouchType {
  static const List<FontVariation> _regular = <FontVariation>[
    FontVariation('wght', 440),
  ];
  static const List<FontVariation> _medium = <FontVariation>[
    FontVariation('wght', 560),
  ];
  static const List<FontVariation> _bold = <FontVariation>[
    FontVariation('wght', 680),
  ];

  /// The giant line that names the promise. Tight leading, negative tracking.
  static TextStyle hero(Color color) => TextStyle(
        fontFamily: VouchFonts.display,
        fontSize: 54,
        height: 0.94,
        letterSpacing: -2.2,
        color: color,
        fontVariations: _bold,
      );

  static TextStyle display(Color color) => TextStyle(
        fontFamily: VouchFonts.display,
        fontSize: 42,
        height: 0.98,
        letterSpacing: -1.6,
        color: color,
        fontVariations: _bold,
      );

  static TextStyle title(Color color) => TextStyle(
        fontFamily: VouchFonts.display,
        fontSize: 27,
        height: 1.05,
        letterSpacing: -0.8,
        color: color,
        fontVariations: _bold,
      );

  static TextStyle cardTitle(Color color) => TextStyle(
        fontFamily: VouchFonts.display,
        fontSize: 19,
        height: 1.15,
        letterSpacing: -0.3,
        color: color,
        fontVariations: _medium,
      );

  static TextStyle body(Color color) => TextStyle(
        fontFamily: VouchFonts.display,
        fontSize: 15,
        height: 1.4,
        letterSpacing: -0.1,
        color: color,
        fontVariations: _regular,
      );

  static TextStyle bodyStrong(Color color) => TextStyle(
        fontFamily: VouchFonts.display,
        fontSize: 15,
        height: 1.35,
        letterSpacing: -0.1,
        color: color,
        fontVariations: _medium,
      );

  static TextStyle caption(Color color) => TextStyle(
        fontFamily: VouchFonts.display,
        fontSize: 13,
        height: 1.35,
        color: color,
        fontVariations: _regular,
      );

  /// Uppercase mono annotation. Callers pass already-uppercased text.
  static TextStyle label(Color color, {double size = 11}) => TextStyle(
        fontFamily: VouchFonts.mono,
        fontSize: size,
        height: 1.2,
        letterSpacing: 1.5,
        color: color,
      );

  static TextStyle mono(Color color, {double size = 13}) => TextStyle(
        fontFamily: VouchFonts.mono,
        fontSize: size,
        height: 1.3,
        color: color,
      );

  /// Fallback numeral style when a value is not drawn as dot matrix.
  static TextStyle numeral(Color color, {double size = 64}) => TextStyle(
        fontFamily: VouchFonts.display,
        fontSize: size,
        height: 0.9,
        letterSpacing: -3,
        color: color,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        fontVariations: _bold,
      );

  static const TextStyle button = TextStyle(
    fontFamily: VouchFonts.display,
    fontSize: 15,
    height: 1.1,
    letterSpacing: -0.1,
    fontVariations: _medium,
  );

  static const TextStyle nav = TextStyle(
    fontFamily: VouchFonts.display,
    fontSize: 12,
    height: 1.1,
    letterSpacing: 0.1,
    fontVariations: _medium,
  );

  /// Standard screen-side padding used by every page.
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: VouchSpace.gutter,
  );
}
