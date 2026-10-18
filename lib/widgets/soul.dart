/// Small hand-made details — stickers, squiggles, dashed rules and paper
/// texture — that keep the interface from reading like a component library.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/vouch_theme.dart';
import 'pressable_spring.dart';

/// A six-spoke asterisk drawn with rounded caps. Optionally turns slowly.
class Asterisk extends StatefulWidget {
  const Asterisk({
    super.key,
    this.size = 14,
    this.color,
    this.strokeWidth = 2,
    this.spin = false,
  });

  final double size;
  final Color? color;
  final double strokeWidth;
  final bool spin;

  @override
  State<Asterisk> createState() => _AsteriskState();
}

class _AsteriskState extends State<Asterisk>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void initState() {
    super.initState();
    if (widget.spin) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.secondary;
    final painter = CustomPaint(
      size: Size.square(widget.size),
      painter: _AsteriskPainter(color: color, strokeWidth: widget.strokeWidth),
    );
    if (!widget.spin) return painter;
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduced) return painter;
    return RotationTransition(turns: _controller, child: painter);
  }
}

class _AsteriskPainter extends CustomPainter {
  const _AsteriskPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    for (var i = 0; i < 3; i++) {
      final angle = (math.pi / 3) * i + 0.02;
      final dx = math.cos(angle) * r;
      final dy = math.sin(angle) * r;
      canvas.drawLine(
        center - Offset(dx, dy),
        center + Offset(dx, dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_AsteriskPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// A hand-drawn underline. Sits under a headline word or label.
class Squiggle extends StatelessWidget {
  const Squiggle({
    super.key,
    this.width = 120,
    this.height = 8,
    this.color,
    this.strokeWidth = 2.4,
  });

  final double width;
  final double height;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ?? Theme.of(context).colorScheme.secondary;
    return CustomPaint(
      size: Size(width, height),
      painter: _SquigglePainter(color: resolved, strokeWidth: strokeWidth),
    );
  }
}

class _SquigglePainter extends CustomPainter {
  const _SquigglePainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final mid = size.height / 2;
    final amp = size.height / 2 - strokeWidth / 2;
    final path = Path()..moveTo(0, mid);
    const step = 13.0;
    var x = 0.0;
    var up = true;
    while (x < size.width) {
      final next = math.min(x + step, size.width);
      path.quadraticBezierTo(
        (x + next) / 2,
        up ? mid - amp : mid + amp,
        next,
        mid,
      );
      x = next;
      up = !up;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SquigglePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// A dashed hairline used as an editorial divider.
class DashRule extends StatelessWidget {
  const DashRule({super.key, this.color, this.height = 1.6});

  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final resolved = color ??
        Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.8);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _DashPainter(color: resolved, height: height),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = height
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    const dash = 5.0;
    const gap = 5.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dash, size.width), y),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.height != height;
}

/// A rotated label with a hard offset shadow, like a print sticker.
class Sticker extends StatelessWidget {
  const Sticker(
    this.label, {
    super.key,
    this.icon,
    this.color,
    this.foreground,
    this.rotation = -0.045,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? foreground;
  final double rotation;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = color ?? scheme.tertiary;
    final fg = foreground ?? scheme.onTertiary;

    return Transform.rotate(
      angle: rotation,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: fg.withValues(alpha: 0.85), width: 1.3),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.shadow.withValues(
                alpha: scheme.brightness == Brightness.dark ? 0.5 : 0.22,
              ),
              offset: const Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 5),
            ],
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Bricolage',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                height: 1.1,
                color: fg,
                fontVariations: const <FontVariation>[
                  FontVariation('wght', 700),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A crisp bordered surface with a printed offset shadow.
class InkCard extends StatelessWidget {
  const InkCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
    this.radius = 26,
    this.onTap,
    this.borderColor,
    this.border = true,
    this.shadow = true,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? borderColor;
  final bool border;
  final bool shadow;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    final content = Container(
      clipBehavior: clipBehavior,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
        border: border
            ? Border.all(
                color: borderColor ??
                    (dark
                        ? scheme.onSurface.withValues(alpha: 0.14)
                        : scheme.onSurface.withValues(alpha: 0.12)),
                width: 1.4,
              )
            : null,
        boxShadow: shadow
            ? <BoxShadow>[
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: dark ? 0.45 : 0.16),
                  offset: const Offset(4, 4),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return PressableSpring(
      onTap: onTap,
      pressedScale: 0.98,
      child: content,
    );
  }
}

/// The signature CTA: a pill with a label and a circled arrow, set on a hard
/// shadow. Cream on dark, indigo on light.
class SoulButton extends StatelessWidget {
  const SoulButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.foreground,
    this.expand = true,
    this.height = 58,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final Color? foreground;
  final bool expand;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final enabled = onPressed != null;
    final bg = color ??
        (dark ? VouchColors.cream : const Color(0xFF5B4BFF));
    final fg = foreground ?? (dark ? const Color(0xFF171520) : VouchColors.cream);
    final labelStyle = _labelStyle(fg);

    final content = Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        height: height,
        constraints: compact
            ? null
            : BoxConstraints(minWidth: expand ? double.infinity : 0),
        padding: EdgeInsets.fromLTRB(
          compact ? 18 : 22,
          0,
          8,
          0,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: fg.withValues(alpha: 0.22),
            width: 1.2,
          ),
          boxShadow: enabled
              ? <BoxShadow>[
                  BoxShadow(
                    color: scheme.shadow.withValues(
                      alpha: dark ? 0.5 : 0.22,
                    ),
                    offset: const Offset(3, 3),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 10),
            ],
            if (compact)
              Text(label, maxLines: 1, style: labelStyle)
            else
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
            if (!compact) ...<Widget>[
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_rounded, color: fg, size: 20),
              ),
            ],
          ],
        ),
      ),
    );

    final tappable = expand
        ? SizedBox(width: double.infinity, child: content)
        : content;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: PressableSpring(
        onTap: onPressed,
        pressedScale: 0.975,
        enabled: enabled,
        child: tappable,
      ),
    );
  }

  static TextStyle _labelStyle(Color fg) => TextStyle(
        fontFamily: 'Bricolage',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: fg,
        fontVariations: const <FontVariation>[
          FontVariation('wght', 600),
        ],
      );
}

/// Fades content out under the status bar so scrolling text never collides
/// with the system icons. Only fades once the view has actually scrolled.
class TopFade extends StatefulWidget {
  const TopFade({super.key, required this.child, this.extent = 26});

  final Widget child;
  final double extent;

  @override
  State<TopFade> createState() => _TopFadeState();
}

class _TopFadeState extends State<TopFade> {
  bool _scrolled = false;

  bool _onScroll(ScrollNotification notification) {
    final scrolled = notification.metrics.pixels > 0.5;
    if (scrolled != _scrolled) {
      setState(() => _scrolled = scrolled);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final stop = height.isFinite && height > 0
              ? (widget.extent / height).clamp(0.0, 0.2)
              : 0.03;
          // Always keep the ShaderMask in the tree. Swapping it in only after
          // the first scroll rebuilds the scroll view underneath and resets
          // its position, which makes scrolling jump back to the top.
          return ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const <Color>[Colors.transparent, Colors.white],
              stops: <double>[0, _scrolled ? stop : 0.0001],
            ).createShader(rect),
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Faint dot paper behind the app.
class PaperDots extends StatelessWidget {
  const PaperDots({super.key, this.spacing = 26, this.radius = 1.1});

  final double spacing;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.onSurface.withValues(
      alpha: scheme.brightness == Brightness.dark ? 0.055 : 0.045,
    );
    return IgnorePointer(
      child: CustomPaint(
        painter: _DotsPainter(
          color: color,
          spacing: spacing,
          radius: radius,
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter({
    required this.color,
    required this.spacing,
    required this.radius,
  });

  final Color color;
  final double spacing;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.spacing != spacing ||
      oldDelegate.radius != radius;
}
