/// Numerals drawn as a 5×7 dot matrix, animated with a spring when they change.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:motor/motor.dart';

import '../design/vouch_motion.dart';

class DotMatrixNumber extends StatefulWidget {
  const DotMatrixNumber(
    this.value, {
    super.key,
    this.height = 54,
    this.color = const Color(0xFFF6F6F2),
    this.dim = const Color(0xFFFFFFFF),
    this.showOffDots = true,
    this.semanticLabel,
  });

  final int value;
  final double height;
  final Color color;

  /// Base colour for unlit dots (opacity is applied by the painter).
  final Color dim;
  final bool showOffDots;
  final String? semanticLabel;

  @override
  State<DotMatrixNumber> createState() => _DotMatrixNumberState();
}

class _DotMatrixNumberState extends State<DotMatrixNumber>
    with TickerProviderStateMixin {
  late SingleMotionController _controller;

  @override
  void initState() {
    super.initState();
    final reduce = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _controller = SingleMotionController(
      motion: VouchMotion.value,
      vsync: this,
      initialValue: reduce ? widget.value.toDouble() : 0,
    );
    if (!reduce) {
      _controller.animateTo(widget.value.toDouble());
    }
  }

  @override
  void didUpdateWidget(DotMatrixNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    if (WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations) {
      _controller.value = widget.value.toDouble();
    } else {
      _controller.animateTo(widget.value.toDouble());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final digits = widget.value.abs().toString();
    final cell = widget.height / 7;
    final width = digits.length * 5 * cell +
        math.max(0, digits.length - 1) * cell * 1.25;
    return Semantics(
      label: widget.semanticLabel ?? '${widget.value}',
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: widget.height,
          child: CustomPaint(
            painter: _DotMatrixPainter(
              controller: _controller,
              color: widget.color,
              dim: widget.dim,
              showOffDots: widget.showOffDots,
            ),
          ),
        ),
      ),
    );
  }
}

class _DotMatrixPainter extends CustomPainter {
  _DotMatrixPainter({
    required this.controller,
    required this.color,
    required this.dim,
    required this.showOffDots,
  }) : super(repaint: controller);

  final Animation<double> controller;
  final Color color;
  final Color dim;
  final bool showOffDots;

  static const Map<String, List<int>> _glyphs = <String, List<int>>{
    '0': <int>[0x0E, 0x11, 0x13, 0x15, 0x19, 0x11, 0x0E],
    '1': <int>[0x04, 0x0C, 0x04, 0x04, 0x04, 0x04, 0x0E],
    '2': <int>[0x0E, 0x11, 0x01, 0x02, 0x04, 0x08, 0x1F],
    '3': <int>[0x1F, 0x02, 0x04, 0x02, 0x01, 0x11, 0x0E],
    '4': <int>[0x02, 0x06, 0x0A, 0x12, 0x1F, 0x02, 0x02],
    '5': <int>[0x1F, 0x10, 0x1E, 0x01, 0x01, 0x11, 0x0E],
    '6': <int>[0x06, 0x08, 0x10, 0x1E, 0x11, 0x11, 0x0E],
    '7': <int>[0x1F, 0x01, 0x02, 0x04, 0x08, 0x08, 0x08],
    '8': <int>[0x0E, 0x11, 0x11, 0x0E, 0x11, 0x11, 0x0E],
    '9': <int>[0x0E, 0x11, 0x11, 0x0F, 0x01, 0x02, 0x0C],
    '-': <int>[0x00, 0x00, 0x00, 0x1F, 0x00, 0x00, 0x00],
    '%': <int>[0x19, 0x1A, 0x02, 0x04, 0x08, 0x0B, 0x13],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final raw = controller.value;
    final value = raw.round();
    final digits = value.abs().toString();
    final cell = size.height / 7;
    final radius = cell * 0.32;
    final pulse = 0.88 + 0.12 * (value - raw).abs().clamp(0.0, 1.0);

    final lit = Paint()..color = color;
    final off = Paint()..color = dim.withValues(alpha: 0.075);

    var x = 0.0;
    for (final char in digits.split('')) {
      final glyph = _glyphs[char] ?? _glyphs['0']!;
      for (var row = 0; row < 7; row++) {
        final bits = glyph[row];
        for (var col = 0; col < 5; col++) {
          final on = (bits & (1 << (4 - col))) != 0;
          final center = Offset(
            x + col * cell + cell / 2,
            row * cell + cell / 2,
          );
          if (on) {
            canvas.drawCircle(center, radius * pulse, lit);
          } else if (showOffDots) {
            canvas.drawCircle(center, radius * 0.62, off);
          }
        }
      }
      x += cell * (5 + 1.25);
    }
  }

  @override
  bool shouldRepaint(_DotMatrixPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dim != dim ||
      oldDelegate.showOffDots != showOffDots ||
      oldDelegate.controller != controller;
}
