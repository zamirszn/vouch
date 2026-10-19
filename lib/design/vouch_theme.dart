/// Semantic theme for Vouch. Deliberately not `ThemeData`: the app uses
/// `WidgetsApp` and reads all visual values from this inherited scope.
library;

import 'package:flutter/widgets.dart';

import 'vouch_tokens.dart';

@immutable
class VouchThemeData {
  const VouchThemeData({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.raised,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.line,
    required this.lineStrong,
    required this.glass,
    required this.glassStrong,
    required this.accent,
    required this.kept,
    required this.missed,
    required this.pending,
    required this.aura,
    required this.glow,
    required this.lightBoard,
  });

  final Brightness brightness;
  final Color canvas;
  final Color surface;
  final Color raised;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color line;
  final Color lineStrong;
  final Color glass;
  final Color glassStrong;
  final Color accent;
  final Color kept;
  final Color missed;
  final Color pending;
  final List<Color> aura;
  final Color glow;

  /// True when the light theme is the warm "presentation board" variant.
  final bool lightBoard;

  bool get isDark => brightness == Brightness.dark;

  static const VouchThemeData dark = VouchThemeData(
    brightness: Brightness.dark,
    canvas: VouchColors.canvas,
    surface: Color(0xFF101116),
    raised: Color(0xFF17181F),
    ink: VouchColors.ink,
    muted: VouchColors.muted,
    faint: VouchColors.faint,
    line: VouchColors.line,
    lineStrong: VouchColors.lineStrong,
    glass: Color(0x12FFFFFF),
    glassStrong: Color(0x1FFFFFFF),
    accent: VouchColors.yellow,
    kept: VouchColors.mint,
    missed: VouchColors.coral,
    pending: VouchColors.violet,
    aura: <Color>[Color(0xFF3C2A88), Color(0xFF0B3F35), Color(0xFF08090B)],
    glow: VouchColors.violet,
    lightBoard: false,
  );

  static const VouchThemeData light = VouchThemeData(
    brightness: Brightness.light,
    canvas: VouchColors.paper,
    surface: VouchColors.paperRaised,
    raised: Color(0xFFFFFFFF),
    ink: VouchColors.paperInk,
    muted: VouchColors.paperMuted,
    faint: Color(0xFF9A9A9D),
    line: VouchColors.paperLine,
    lineStrong: Color(0x33000000),
    glass: Color(0x66FFFFFF),
    glassStrong: Color(0x99FFFFFF),
    accent: Color(0xFFD9F02E),
    kept: Color(0xFF16845F),
    missed: Color(0xFFD23A3A),
    pending: Color(0xFF5A49D6),
    aura: <Color>[Color(0xFFE4E0FF), Color(0xFFDDF3E7), Color(0xFFE9E9E7)],
    glow: Color(0xFFB7A8FF),
    lightBoard: true,
  );

  VouchThemeData copyWith({Brightness? brightness}) {
    if (brightness == null || brightness == this.brightness) return this;
    return brightness == Brightness.dark ? dark : light;
  }
}

class VouchScope extends InheritedWidget {
  const VouchScope({
    super.key,
    required this.theme,
    required this.tone,
    required super.child,
  });

  final VouchThemeData theme;
  final VouchTone tone;

  static VouchThemeData of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<VouchScope>();
    return scope?.theme ?? VouchThemeData.dark;
  }

  static VouchTone toneOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<VouchScope>();
    return scope?.tone ?? VouchTone.pending;
  }

  static VouchScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VouchScope>();

  @override
  bool updateShouldNotify(VouchScope oldWidget) =>
      oldWidget.theme != theme || oldWidget.tone != tone;
}

extension VouchBuildContext on BuildContext {
  VouchThemeData get vouch => VouchScope.of(this);
  VouchTone get vouchTone => VouchScope.toneOf(this);
}
