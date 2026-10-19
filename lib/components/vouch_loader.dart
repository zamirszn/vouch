/// Small custom spinner. No CircularProgressIndicator.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:motor/motor.dart';

import '../design/vouch_motion.dart';
import '../design/vouch_sequences.dart';

class VouchLoader extends StatelessWidget {
  const VouchLoader({
    super.key,
    this.size = 20,
    this.color = const Color(0xFF0B0B0C),
    this.strokeWidth = 2.2,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final painter = _SpinnerPainter(color: color, strokeWidth: strokeWidth);
    if (VouchMotion.reduced(context)) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: painter..turn = 0.12),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: SequenceMotionBuilder<int, double>(
        sequence: VouchSequences.rotation,
        converter: MotionConverter.single,
        playing: true,
        builder: (context, value, phase, _) => CustomPaint(
          painter: _SpinnerPainter(
            color: color,
            strokeWidth: strokeWidth,
            turn: value,
          ),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter({
    required this.color,
    required this.strokeWidth,
    this.turn = 0,
  });

  final Color color;
  final double strokeWidth;
  double turn;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final track = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, math.pi * 1.7, false, track);
    canvas.drawArc(rect, turn * math.pi * 2, math.pi * 0.55, false, arc);
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) =>
      oldDelegate.turn != turn || oldDelegate.color != color;
}
