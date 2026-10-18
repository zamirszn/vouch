/// The hero gauge on Home: a measured ring of printed ticks, a needle at the
/// current completion, and the streak set as a giant numeral in the middle.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/date_utils.dart';
import '../theme/vouch_theme.dart';
import 'soul.dart';

class PromiseOrb extends StatelessWidget {
  const PromiseOrb({
    super.key,
    required this.state,
    required this.streak,
    required this.completion,
    required this.caption,
    this.size = 250,
  });

  final VouchDayState state;
  final int streak;
  final double completion;
  final String caption;
  final double size;

  Color get _accent => switch (state) {
        VouchDayState.completed => VouchColors.kept,
        VouchDayState.missed => VouchColors.coral,
        VouchDayState.pending => VouchColors.indigo,
        VouchDayState.rest => VouchColors.mist,
        VouchDayState.upcoming => VouchColors.mist,
      };

  String get _code => switch (state) {
        VouchDayState.completed => 'KEPT',
        VouchDayState.missed => 'MISSED',
        VouchDayState.pending => 'OPEN',
        VouchDayState.rest => 'REST',
        VouchDayState.upcoming => 'NEXT',
      };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final value = completion.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 2,
            top: 2,
            child: _MicroLabel('STREAK / $_code'),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: _MicroLabel('${(value * 100).round()}% KEPT'),
          ),
          Positioned(
            left: 2,
            bottom: 4,
            child: _MicroLabel('(DAYS)'),
          ),
          Positioned(
            right: 2,
            bottom: 4,
            child: _MicroLabel('V.01'),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _DialPainter(
                value: value,
                accent: _accent,
                track: scheme.onSurface.withValues(alpha: 0.14),
                paper: scheme.surface,
                ring: scheme.onSurface.withValues(alpha: 0.12),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '$streak',
                  style: text.displayLarge?.copyWith(
                    fontSize: size * 0.29,
                    height: 0.86,
                    letterSpacing: -5,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'DAY STREAK',
                  style: text.labelSmall?.copyWith(
                    color: _accent,
                    letterSpacing: 2.2,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Sticker(
                caption,
                rotation: 0.03,
                color: _accent,
                foreground: state == VouchDayState.rest ||
                        state == VouchDayState.upcoming
                    ? VouchColors.cream
                    : VouchColors.cream,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MicroLabel extends StatelessWidget {
  const _MicroLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 8.5,
            letterSpacing: 1.2,
          ),
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.value,
    required this.accent,
    required this.track,
    required this.paper,
    required this.ring,
  });

  final double value;
  final Color accent;
  final Color track;
  final Color paper;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    const ticks = 84;
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2 - 18;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ring;

    canvas.drawCircle(center, outer, ringPaint);
    canvas.drawCircle(center, outer - 22, ringPaint);

    final start = -math.pi / 2;
    final filled = (value * ticks).round();
    for (var i = 0; i < ticks; i++) {
      final angle = start + (math.pi * 2 * i) / ticks;
      final major = i % 7 == 0;
      final active = i < filled;
      final length = major ? 11.0 : 6.0;
      final paint = Paint()
        ..strokeWidth = active ? (major ? 2.2 : 1.6) : (major ? 1.2 : 0.9)
        ..strokeCap = StrokeCap.square
        ..color = active ? accent : track;
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + dir * outer,
        center + dir * (outer - length),
        paint,
      );
    }

    final needleAngle = start + math.pi * 2 * value;
    final needleDir = Offset(math.cos(needleAngle), math.sin(needleAngle));
    final needle = center + needleDir * outer;
    canvas.drawCircle(needle, 5.5, Paint()..color = paper);
    canvas.drawCircle(needle, 3.4, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.accent != accent ||
      oldDelegate.track != track ||
      oldDelegate.paper != paper ||
      oldDelegate.ring != ring;
}
