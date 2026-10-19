/// Frosted glass surface with a hairline stroke and inner highlight.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import 'pressable.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VouchSpace.x5),
    this.radius = VouchRadius.card,
    this.tint,
    this.onTap,
    this.onLongPress,
    this.glow = false,
    this.blur = false,
    this.borderColor,
    this.background,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Adds a soft coloured halo behind the card.
  final bool glow;

  /// Adds a real backdrop blur. Used sparingly (nav bar, sheets).
  final bool blur;
  final Color? borderColor;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final accent = tint ?? theme.glow;
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              background ?? theme.glassStrong,
              background ?? theme.glass,
            ],
          ),
          border: Border.all(color: borderColor ?? theme.line, width: 1),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              left: radius * 0.5,
              right: radius * 0.5,
              top: 0,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      const Color(0x00FFFFFF),
                      const Color(0x66FFFFFF),
                      const Color(0x00FFFFFF),
                    ],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );

    Widget surface = card;
    if (blur) {
      surface = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: card,
        ),
      );
    }
    if (glow) {
      surface = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: accent.withValues(alpha: 0.16),
              blurRadius: 48,
              spreadRadius: -12,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: surface,
      );
    }
    if (onTap != null || onLongPress != null) {
      surface = Pressable(
        onTap: onTap,
        onLongPress: onLongPress,
        scale: 0.985,
        child: surface,
      );
    }
    return surface;
  }
}
