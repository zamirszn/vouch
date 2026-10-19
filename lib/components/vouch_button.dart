/// Buttons in four weights: signal, glass, ghost and danger.
library;

import 'package:flutter/widgets.dart';

import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import 'pressable.dart';
import 'vouch_icon.dart';
import 'vouch_loader.dart';

enum VouchButtonStyle { signal, glass, ghost, danger, light }

class VouchButton extends StatelessWidget {
  const VouchButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = VouchButtonStyle.signal,
    this.glyph,
    this.trailingGlyph,
    this.loading = false,
    this.expand = false,
    this.height = 52,
    this.compact = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final VouchButtonStyle style;
  final VouchGlyph? glyph;
  final VouchGlyph? trailingGlyph;
  final bool loading;
  final bool expand;
  final double height;
  final bool compact;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final (background, foreground, border) = switch (style) {
      VouchButtonStyle.signal => (
          theme.accent,
          const Color(0xFF0B0B0C),
          null,
        ),
      VouchButtonStyle.glass => (
          theme.glassStrong,
          theme.ink,
          theme.line,
        ),
      VouchButtonStyle.ghost => (
          const Color(0x00000000),
          theme.ink,
          theme.line,
        ),
      VouchButtonStyle.danger => (
          theme.missed.withValues(alpha: 0.16),
          theme.missed,
          theme.missed.withValues(alpha: 0.35),
        ),
      VouchButtonStyle.light => (
          theme.isDark ? const Color(0xFFF6F6F2) : theme.ink,
          theme.isDark ? const Color(0xFF0B0B0C) : theme.raised,
          null,
        ),
    };

    final enabled = onPressed != null && !loading;
    final effectiveForeground =
        enabled ? foreground : foreground.withValues(alpha: 0.45);

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (loading)
          VouchLoader(size: 18, color: effectiveForeground, strokeWidth: 2)
        else if (glyph != null)
          VouchIcon(glyph!, size: 19, color: effectiveForeground),
        if (loading || glyph != null) const SizedBox(width: VouchSpace.x2),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: VouchType.button.copyWith(
              color: effectiveForeground,
              fontSize: compact ? 13.5 : 15,
              letterSpacing: compact ? 0 : -0.1,
            ),
          ),
        ),
        if (trailingGlyph != null) ...<Widget>[
          const SizedBox(width: VouchSpace.x2),
          VouchIcon(trailingGlyph!, size: 18, color: effectiveForeground),
        ],
      ],
    );

    final button = AnimatedOpacity(
      opacity: enabled || loading ? 1 : 0.65,
      duration: VouchDurations.fast,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? VouchSpace.x4 : VouchSpace.x5,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(VouchRadius.pill),
          border: border == null ? null : Border.all(color: border, width: 1),
          boxShadow: style == VouchButtonStyle.signal
              ? <BoxShadow>[
                  BoxShadow(
                    color: theme.accent.withValues(alpha: enabled ? 0.28 : 0),
                    blurRadius: 24,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Center(widthFactor: expand ? 1 : null, child: content),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      child: Pressable(
        onTap: enabled ? onPressed : null,
        scale: 0.975,
        child: SizedBox(width: expand ? double.infinity : null, child: button),
      ),
    );
  }
}

/// A square icon-only action, used for close / check / plus controls.
class CircleAction extends StatelessWidget {
  const CircleAction({
    super.key,
    required this.glyph,
    this.onTap,
    this.size = 52,
    this.background,
    this.foreground,
    this.border,
    this.semanticLabel,
  });

  final VouchGlyph glyph;
  final VoidCallback? onTap;
  final double size;
  final Color? background;
  final Color? foreground;
  final Color? border;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final fg = foreground ?? theme.ink;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Pressable(
        onTap: onTap,
        scale: 0.92,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: background ?? theme.glassStrong,
            border: Border.all(
              color: border ?? theme.line,
              width: 1,
            ),
          ),
          child: Center(child: VouchIcon(glyph, size: size * 0.42, color: fg)),
        ),
      ),
    );
  }
}
