/// A thin vertical ruler used beside headline numbers.
library;

import 'package:flutter/widgets.dart';
import 'package:motor/motor.dart';

import '../design/vouch_motion.dart';

class VerticalRuler extends StatelessWidget {
  const VerticalRuler({
    super.key,
    required this.value,
    this.height = 92,
    this.width = 26,
    this.color = const Color(0xFF67F5B5),
    this.animate = true,
  });

  /// 0 → 1.
  final double value;
  final double height;
  final double width;
  final Color color;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    Widget paint(double v) => SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _RulerPainter(value: v, color: color),
          ),
        );

    if (!animate || VouchMotion.reduced(context)) return paint(clamped);

    return SingleMotionBuilder(
      value: clamped,
      from: 0,
      motion: VouchMotion.value,
      builder: (context, v, child) => paint(v.clamp(0.0, 1.0)),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const ticks = 28;
    final x = size.width - 1;
    for (var i = 0; i <= ticks; i++) {
      final f = i / ticks;
      final y = size.height * (1 - f);
      final on = f <= value + 0.001;
      final major = i % 4 == 0;
      final len = major ? size.width * 0.72 : size.width * 0.4;
      final paint = Paint()
        ..color = on ? color : color.withValues(alpha: 0.16)
        ..strokeWidth = major ? 1.4 : 1
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x - len, y), Offset(x, y), paint);
    }
    final knobY = size.height * (1 - value);
    canvas.drawLine(
      Offset(0, knobY),
      Offset(size.width, knobY),
      Paint()
        ..color = color
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(
      Offset(size.width / 2, knobY),
      2.4,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_RulerPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
