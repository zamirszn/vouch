/// The ShareOS language, adapted for Vouch: full-bleed colour fields,
/// oversized tight headlines with one accented phrase, tiny editorial
/// metadata, flat cards and black pills. Everything is drawn from a
/// [PosterStyle] resolved by the [PosterField] a screen sits on.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pressable_spring.dart';

/// Fixed poster pigments. Field tones are chosen per screen; the ink, cream
/// and acid never change so the voice stays consistent.
class PosterColors {
  const PosterColors._();

  static const Color ink = Color(0xFF0D0D0B);
  static const Color cream = Color(0xFFF4F1E8);
  static const Color acid = Color(0xFFE3F14B);
  static const Color cobalt = Color(0xFF2B33E0);
  static const Color coral = Color(0xFFFF5A36);
  static const Color kelly = Color(0xFF2F8F4E);

  static const Color blush = Color(0xFFF0BFDE);
  static const Color butter = Color(0xFFF4C51F);
  static const Color sage = Color(0xFFBFDA9C);
  static const Color clay = Color(0xFF8D6C58);
  static const Color flame = Color(0xFFFF6B57);
}

/// Which poster field a screen is printed on.
enum PosterTone { blush, butter, sage, clay, flame, cream, ink }

/// The resolved foreground/card/pill colours for one field in one
/// brightness. Widgets read this instead of guessing the scheme.
class PosterStyle {
  const PosterStyle({
    required this.tone,
    required this.dark,
    required this.field,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.card,
    required this.cardInk,
    required this.cardMuted,
    required this.pill,
    required this.pillInk,
    required this.line,
    required this.soft,
  });

  final PosterTone tone;
  final bool dark;
  final Color field;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color card;
  final Color cardInk;
  final Color cardMuted;
  final Color pill;
  final Color pillInk;
  final Color line;
  final Color soft;

  /// Foreground that reads on top of [accent] fills.
  Color get onAccent =>
      accent.computeLuminance() > 0.55 ? PosterColors.ink : PosterColors.cream;

  /// The style of the field the calling widget is printed on.
  static PosterStyle of(BuildContext context) => PosterScope.of(context);

  static PosterStyle resolve(PosterTone tone, bool dark) {
    final ink = dark ? PosterColors.cream : PosterColors.ink;
    final Color field;
    final Color accent;

    if (dark) {
      (field, accent) = switch (tone) {
        PosterTone.blush => (const Color(0xFF3A2535), PosterColors.blush),
        PosterTone.butter => (const Color(0xFF3A2D0C), PosterColors.butter),
        PosterTone.sage => (const Color(0xFF26301C), PosterColors.sage),
        PosterTone.clay => (const Color(0xFF34261F), PosterColors.acid),
        PosterTone.flame => (const Color(0xFF471C14), const Color(0xFFFF8E7C)),
        PosterTone.cream => (const Color(0xFF171610), PosterColors.acid),
        PosterTone.ink => (PosterColors.ink, PosterColors.acid),
      };
    } else {
      (field, accent) = switch (tone) {
        PosterTone.blush => (PosterColors.blush, PosterColors.cream),
        PosterTone.butter => (PosterColors.butter, const Color(0xFF8E2A22)),
        PosterTone.sage => (PosterColors.sage, PosterColors.cream),
        PosterTone.clay => (PosterColors.clay, PosterColors.acid),
        PosterTone.flame => (PosterColors.flame, const Color(0xFF7E1B14)),
        PosterTone.cream => (PosterColors.cream, PosterColors.cobalt),
        PosterTone.ink => (PosterColors.ink, PosterColors.acid),
      };
    }

    final card = dark ? const Color(0xFF23211B) : PosterColors.cream;
    return PosterStyle(
      tone: tone,
      dark: dark,
      field: field,
      ink: ink,
      muted: ink.withValues(alpha: 0.62),
      accent: accent,
      card: card,
      cardInk: ink,
      cardMuted: ink.withValues(alpha: 0.58),
      pill: dark ? PosterColors.cream : PosterColors.ink,
      pillInk: dark ? PosterColors.ink : PosterColors.cream,
      line: ink.withValues(alpha: dark ? 0.18 : 0.16),
      soft: ink.withValues(alpha: dark ? 0.07 : 0.06),
    );
  }
}

/// Exposes the current field to descendants. Sheets and dialogs are separate
/// routes, so they fall back to the cream paper style.
class PosterScope extends InheritedWidget {
  const PosterScope({super.key, required this.style, required super.child});

  final PosterStyle style;

  static PosterStyle of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PosterScope>();
    return scope?.style ??
        PosterStyle.resolve(
          PosterTone.cream,
          Theme.of(context).brightness == Brightness.dark,
        );
  }

  @override
  bool updateShouldNotify(PosterScope oldWidget) => oldWidget.style != style;
}

/// A full-bleed poster surface. Sets the system bar icons to match the field.
class PosterField extends StatelessWidget {
  const PosterField({
    super.key,
    required this.tone,
    required this.child,
    this.safeArea = true,
    this.bottom = true,
  });

  final PosterTone tone;
  final Widget child;
  final bool safeArea;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final style = PosterStyle.resolve(tone, dark);
    final lightField = style.field.computeLuminance() > 0.45;
    final overlay =
        (lightField ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light)
            .copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: lightField
                  ? Brightness.dark
                  : Brightness.light,
              statusBarBrightness: lightField
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarContrastEnforced: false,
              systemNavigationBarIconBrightness: lightField
                  ? Brightness.dark
                  : Brightness.light,
            );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: PosterScope(
        style: style,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          color: style.field,
          child: SafeArea(top: safeArea, bottom: bottom, child: child),
        ),
      ),
    );
  }
}

/// The masthead: a wordmark on the left, an index/date on the right. Sits
/// above the headline on every poster.
class PosterTopBar extends StatelessWidget {
  const PosterTopBar({
    super.key,
    required this.right,
    this.left = 'VOUCH',
    this.trailing,
  });

  final String left;
  final String right;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);
    return Row(
      children: <Widget>[
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: style.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        PosterLabel(left, color: style.ink),
        const Spacer(),
        if (trailing != null) ...<Widget>[trailing!, const SizedBox(width: 10)],
        PosterLabel(right, color: style.muted),
      ],
    );
  }
}

/// The masthead for a pushed screen: a circled back arrow, the wordmark and
/// an index on the right.
class PosterBackBar extends StatelessWidget {
  const PosterBackBar({
    super.key,
    required this.right,
    this.onBack,
    this.trailing,
    this.icon = Icons.arrow_back_rounded,
  });

  final String right;
  final VoidCallback? onBack;
  final Widget? trailing;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);
    return Row(
      children: <Widget>[
        Semantics(
          button: true,
          label: 'Back',
          child: PressableSpring(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            pressedScale: 0.92,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: style.soft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: style.ink),
            ),
          ),
        ),
        const SizedBox(width: 11),
        PosterLabel('Vouch', color: style.ink),
        const Spacer(),
        if (trailing != null) ...<Widget>[trailing!, const SizedBox(width: 10)],
        PosterLabel(right, color: style.muted),
      ],
    );
  }
}

/// A tiny mono index or status label.
class PosterLabel extends StatelessWidget {
  const PosterLabel(
    this.text, {
    super.key,
    this.color,
    this.size = 9.5,
    this.tracking = 1.6,
    this.weight = FontWeight.w400,
  });

  final String text;
  final Color? color;
  final double size;
  final double tracking;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: size,
        fontWeight: weight,
        letterSpacing: tracking,
        height: 1.2,
        color: color ?? style.muted,
      ),
    );
  }
}

/// The poster headline: one statement, set as tight as the field allows.
/// The last [accentTail] words take the field's accent colour, the way the
/// ShareOS posters drop one phrase into acid or crimson.
class PosterHeadline extends StatelessWidget {
  const PosterHeadline(
    this.text, {
    super.key,
    this.size = 46,
    this.height = 0.86,
    this.accentTail = 0,
    this.color,
    this.accentColor,
    this.textAlign = TextAlign.left,
    this.maxLines,
  });

  final String text;
  final double size;
  final double height;
  final int accentTail;
  final Color? color;
  final Color? accentColor;
  final TextAlign textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);
    final base = TextStyle(
      fontFamily: 'InstrumentSans',
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: height,
      letterSpacing: size * -0.05,
      color: color ?? style.ink,
      fontVariations: const <FontVariation>[
        FontVariation('wght', 700),
        FontVariation('wdth', 92),
      ],
    );

    return Text.rich(
      TextSpan(style: base, children: _spans(accentColor ?? style.accent)),
      textAlign: textAlign,
      maxLines: maxLines,
    );
  }

  List<InlineSpan> _spans(Color accent) {
    if (accentTail <= 0) {
      return <InlineSpan>[TextSpan(text: text)];
    }
    final starts = <int>[
      for (final match in RegExp(r'\S+').allMatches(text)) match.start,
    ];
    if (starts.isEmpty) return <InlineSpan>[TextSpan(text: text)];
    final index = math.max(0, starts.length - accentTail);
    final cut = starts[index];
    return <InlineSpan>[
      TextSpan(text: text.substring(0, cut)),
      TextSpan(
        text: text.substring(cut),
        style: TextStyle(color: accent),
      ),
    ];
  }
}

/// A label/body pair from the poster's metadata grids.
class PosterMetaRow extends StatelessWidget {
  const PosterMetaRow(
    this.label,
    this.body, {
    super.key,
    this.labelWidth = 96,
    this.labelColor,
    this.bodyColor,
    this.size = 11.5,
  });

  final String label;
  final String body;
  final double labelWidth;
  final Color? labelColor;
  final Color? bodyColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'InstrumentSans',
              fontSize: size,
              fontWeight: FontWeight.w600,
              height: 1.3,
              letterSpacing: -0.1,
              color: labelColor ?? style.ink,
              fontVariations: const <FontVariation>[FontVariation('wght', 600)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            body,
            style: TextStyle(
              fontFamily: 'InstrumentSans',
              fontSize: size,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: bodyColor ?? style.muted,
              fontVariations: const <FontVariation>[FontVariation('wght', 400)],
            ),
          ),
        ),
      ],
    );
  }
}

/// A section marker in the poster's margin: index, label and a hairline.
class PosterSectionLabel extends StatelessWidget {
  const PosterSectionLabel(
    this.index,
    this.label, {
    super.key,
    this.trailing,
    this.uppercase = true,
  });

  final String index;
  final String label;
  final Widget? trailing;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);
    return Row(
      children: <Widget>[
        PosterLabel('($index)', color: style.muted, size: 9),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            uppercase ? label.toUpperCase() : label,
            style: TextStyle(
              fontFamily: 'InstrumentSans',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: style.ink,
              fontVariations: const <FontVariation>[FontVariation('wght', 700)],
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// A flat solid-colour card. No shadow, no gradient — the ShareOS card.
class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.child,
    this.color,
    this.foreground,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.onTap,
    this.border = false,
  });

  final Widget child;
  final Color? color;
  final Color? foreground;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);
    final bg = color ?? style.card;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: border
            ? Border.all(
                color: (foreground ?? style.cardInk).withValues(alpha: 0.14),
                width: 1,
              )
            : null,
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: 'InstrumentSans',
          fontSize: 14,
          height: 1.4,
          color: foreground ?? style.cardInk,
        ),
        child: IconTheme(
          data: IconThemeData(color: foreground ?? style.cardInk, size: 20),
          child: child,
        ),
      ),
    );

    if (onTap == null) return content;
    return PressableSpring(onTap: onTap, pressedScale: 0.985, child: content);
  }
}

/// The black pill: label, optional icon, circled arrow on the right.
class PosterPill extends StatelessWidget {
  const PosterPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.foreground,
    this.expand = true,
    this.height = 56,
    this.compact = false,
    this.arrow = true,
    this.arrowColor,
    this.arrowForeground,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final Color? foreground;
  final bool expand;
  final double height;
  final bool compact;
  final bool arrow;
  final Color? arrowColor;
  final Color? arrowForeground;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);
    final enabled = onPressed != null;
    final bg = color ?? style.pill;
    final fg = foreground ?? style.pillInk;

    final content = Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        height: height,
        constraints: expand
            ? const BoxConstraints(minWidth: double.infinity)
            : null,
        padding: EdgeInsets.only(left: compact ? 16 : 20, right: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, color: fg, size: 19),
              const SizedBox(width: 9),
            ],
            if (compact)
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'InstrumentSans',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  fontVariations: const <FontVariation>[
                    FontVariation('wght', 600),
                  ],
                ),
              )
            else
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'InstrumentSans',
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: fg,
                    fontVariations: const <FontVariation>[
                      FontVariation('wght', 600),
                    ],
                  ),
                ),
              ),
            if (arrow) ...<Widget>[
              const SizedBox(width: 10),
              Container(
                width: height - 14,
                height: height - 14,
                decoration: BoxDecoration(
                  color: arrowColor ?? style.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: height * 0.34,
                  color: arrowForeground ?? style.onAccent,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: PressableSpring(
        onTap: onPressed,
        pressedScale: 0.975,
        enabled: enabled,
        child: expand
            ? SizedBox(width: double.infinity, child: content)
            : content,
      ),
    );
  }
}

/// A small flat capsule for statuses and counts.
class PosterTag extends StatelessWidget {
  const PosterTag(
    this.label, {
    super.key,
    this.color,
    this.foreground,
    this.icon,
    this.dark = false,
  });

  final String label;
  final Color? color;
  final Color? foreground;
  final IconData? icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);
    final bg = color ?? (dark ? style.ink : style.soft);
    final fg = foreground ?? (dark ? style.field : style.ink);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 8.5,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.0,
              height: 1.1,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// A broad stat tile in a poster colour.
class PosterStatCard extends StatelessWidget {
  const PosterStatCard({
    super.key,
    required this.value,
    required this.label,
    this.color,
    this.foreground,
    this.padding = const EdgeInsets.fromLTRB(13, 13, 13, 12),
  });

  final String value;
  final String label;
  final Color? color;
  final Color? foreground;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);
    final fg = foreground ?? style.cardInk;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? style.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontFamily: 'InstrumentSans',
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.0,
              letterSpacing: -1.4,
              color: fg,
              fontVariations: const <FontVariation>[
                FontVariation('wght', 700),
                FontVariation('wdth', 94),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            maxLines: 2,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 8,
              letterSpacing: 0.8,
              height: 1.25,
              color: fg.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

/// The bottom-left wordmark pair from the posters: "Listen / To The Story".
class PosterFooter extends StatelessWidget {
  const PosterFooter({
    super.key,
    required this.lead,
    required this.muted,
    this.trailing,
  });

  final String lead;
  final String muted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);
    final base = TextStyle(
      fontFamily: 'InstrumentSans',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.12,
      letterSpacing: -0.4,
      fontVariations: const <FontVariation>[FontVariation('wght', 600)],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(lead, style: base.copyWith(color: style.ink)),
              Text(muted, style: base.copyWith(color: style.muted)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// A flat colour field with an oversized numeral — used for the streak and
/// other counts on the posters.
class PosterBigNumber extends StatelessWidget {
  const PosterBigNumber({
    super.key,
    required this.value,
    this.label,
    this.color,
    this.size = 64,
  });

  final String value;
  final String? label;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
            fontFamily: 'InstrumentSans',
            fontSize: size,
            fontWeight: FontWeight.w700,
            height: 0.82,
            letterSpacing: size * -0.05,
            color: color ?? style.ink,
            fontVariations: const <FontVariation>[
              FontVariation('wght', 700),
              FontVariation('wdth', 92),
            ],
          ),
        ),
        if (label != null) ...<Widget>[
          const SizedBox(height: 6),
          PosterLabel(label!, color: style.muted),
        ],
      ],
    );
  }
}
