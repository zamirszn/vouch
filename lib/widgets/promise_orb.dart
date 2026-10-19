/// The hero gauge on Today: a solid black disc of printed ticks, the streak
/// set as a giant numeral and the day's state stamped beneath. Reads as one
/// of the ShareOS posters' circular panels.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/date_utils.dart';
import '../theme/vouch_theme.dart';
import 'poster.dart';

class PromiseOrb extends StatelessWidget {
  const PromiseOrb({
    super.key,
    required this.state,
    required this.streak,
    required this.completion,
    required this.caption,
    this.size = 224,
  });

  final VouchDayState state;
  final int streak;
  final double completion;
  final String caption;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);
    final value = completion.clamp(0.0, 1.0);

    final accent = switch (state) {
      VouchDayState.completed =>
        style.dark ? const Color(0xFF74E39A) : PosterColors.kelly,
      VouchDayState.missed => PosterColors.coral,
      VouchDayState.pending =>
        style.dark ? PosterColors.cobalt : PosterColors.acid,
      VouchDayState.rest => style.muted,
      VouchDayState.upcoming => style.muted,
    };

    final disc = style.pill;
    final discInk = style.pillInk;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _DialPainter(
                    value: value,
                    accent: accent,
                    disc: disc,
                    discInk: discInk,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '$streak',
                      style: TextStyle(
                        fontFamily: 'InstrumentSans',
                        fontSize: size * 0.30,
                        fontWeight: FontWeight.w700,
                        height: 0.82,
                        letterSpacing: size * -0.055,
                        color: discInk,
                        fontVariations: const <FontVariation>[
                          FontVariation('wght', 700),
                          FontVariation('wdth', 92),
                        ],
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'DAY STREAK',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 8.5,
                        letterSpacing: 2.0,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(value * 100).round()}% KEPT',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 8,
                        letterSpacing: 1.4,
                        color: discInk.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 18,
                right: 20,
                child: Text(
                  'V.01',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 7.5,
                    letterSpacing: 1.2,
                    color: discInk.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PosterTag(
          caption,
          color: accent,
          foreground: accent.computeLuminance() > 0.55
              ? PosterColors.ink
              : PosterColors.cream,
        ),
      ],
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.value,
    required this.accent,
    required this.disc,
    required this.discInk,
  });

  final double value;
  final Color accent;
  final Color disc;
  final Color discInk;

  @override
  void paint(Canvas canvas, Size size) {
    const ticks = 72;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    canvas.drawCircle(center, radius - 2, Paint()..color = disc);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = discInk.withValues(alpha: 0.14);
    canvas.drawCircle(center, radius - 9, ringPaint);

    final start = -math.pi / 2;
    final filled = (value * ticks).round();
    for (var i = 0; i < ticks; i++) {
      final angle = start + (math.pi * 2 * i) / ticks;
      final major = i % 6 == 0;
      final active = i < filled;
      final length = major ? 9.0 : 5.0;
      final paint = Paint()
        ..strokeWidth = active ? (major ? 2.0 : 1.5) : (major ? 1.2 : 0.9)
        ..strokeCap = StrokeCap.square
        ..color = active ? accent : discInk.withValues(alpha: 0.16);
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + dir * (radius - 14),
        center + dir * (radius - 14 - length),
        paint,
      );
    }

    final needleAngle = start + math.pi * 2 * value;
    final needleDir = Offset(math.cos(needleAngle), math.sin(needleAngle));
    final needle = center + needleDir * (radius - 24);
    canvas.drawCircle(needle, 4.5, Paint()..color = accent);
    canvas.drawCircle(
      needle,
      2,
      Paint()..color = accent.computeLuminance() > 0.55
          ? VouchColors.ink
          : VouchColors.cream,
    );
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.accent != accent ||
      oldDelegate.disc != disc ||
      oldDelegate.discInk != discInk;
}
