/// Custom glyphs. The app ships no Material icon font; every icon is drawn.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

enum VouchGlyph {
  check,
  checkCircle,
  close,
  closeCircle,
  plus,
  minus,
  arrowRight,
  arrowUpRight,
  chevronDown,
  chevronLeft,
  chevronRight,
  person,
  people,
  calendar,
  phone,
  message,
  note,
  settings,
  share,
  bell,
  refresh,
  moon,
  sun,
  logout,
  copy,
  clock,
  edit,
  dots,
  eye,
  star,
  lock,
  mail,
}

class VouchIcon extends StatelessWidget {
  const VouchIcon(
    this.glyph, {
    super.key,
    this.size = 22,
    this.color,
    this.strokeWidth = 1.7,
  });

  final VouchGlyph glyph;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? DefaultTextStyle.of(context).style.color ?? const Color(0xFFFFFFFF);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _VouchIconPainter(
          glyph: glyph,
          color: resolved,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _VouchIconPainter extends CustomPainter {
  _VouchIconPainter({
    required this.glyph,
    required this.color,
    required this.strokeWidth,
  });

  final VouchGlyph glyph;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 24.0;
    canvas.save();
    canvas.scale(s.clamp(0.2, 8));
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final line = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Offset o(double x, double y) => Offset(x, y);

    void poly(List<Offset> pts, {bool close = false}) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final pt in pts.skip(1)) {
        path.lineTo(pt.dx, pt.dy);
      }
      if (close) path.close();
      canvas.drawPath(path, p);
    }

    void circle(double x, double y, double r) =>
        canvas.drawCircle(o(x, y), r, p);

    void rrect(Rect rect, double r) => canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(r)),
          p,
        );

    switch (glyph) {
      case VouchGlyph.check:
        poly([o(5, 12.5), o(9.8, 17.2), o(19, 7)], close: false);
      case VouchGlyph.checkCircle:
        circle(12, 12, 8.4);
        poly([o(8, 12.2), o(11, 15.2), o(16.4, 9.4)]);
      case VouchGlyph.close:
        poly([o(6.5, 6.5), o(17.5, 17.5)]);
        poly([o(17.5, 6.5), o(6.5, 17.5)]);
      case VouchGlyph.closeCircle:
        circle(12, 12, 8.4);
        poly([o(8.7, 8.7), o(15.3, 15.3)]);
        poly([o(15.3, 8.7), o(8.7, 15.3)]);
      case VouchGlyph.plus:
        poly([o(12, 5), o(12, 19)]);
        poly([o(5, 12), o(19, 12)]);
      case VouchGlyph.minus:
        poly([o(5, 12), o(19, 12)]);
      case VouchGlyph.arrowRight:
        poly([o(4, 12), o(19, 12)]);
        poly([o(13.5, 6.5), o(20, 12), o(13.5, 17.5)]);
      case VouchGlyph.arrowUpRight:
        poly([o(6.5, 17.5), o(17, 7)]);
        poly([o(9, 7), o(17, 7), o(17, 15)]);
      case VouchGlyph.chevronDown:
        poly([o(6.5, 9.5), o(12, 15), o(17.5, 9.5)]);
      case VouchGlyph.chevronLeft:
        poly([o(14.5, 5.5), o(8, 12), o(14.5, 18.5)]);
      case VouchGlyph.chevronRight:
        poly([o(9.5, 5.5), o(16, 12), o(9.5, 18.5)]);
      case VouchGlyph.person:
        circle(12, 8, 3.4);
        final path = Path()
          ..moveTo(5.5, 20)
          ..cubicTo(5.8, 15.7, 8.4, 14, 12, 14)
          ..cubicTo(15.6, 14, 18.2, 15.7, 18.5, 20);
        canvas.drawPath(path, p);
      case VouchGlyph.people:
        circle(9.2, 8.6, 2.8);
        circle(16.4, 9.4, 2.2);
        final a = Path()
          ..moveTo(3.8, 19.4)
          ..cubicTo(4.1, 15.9, 6.2, 14.4, 9.2, 14.4)
          ..cubicTo(12.2, 14.4, 14.3, 15.9, 14.6, 19.4);
        final b = Path()
          ..moveTo(15, 15.2)
          ..cubicTo(18.1, 14.9, 20.2, 16.2, 20.5, 19.4);
        canvas.drawPath(a, p);
        canvas.drawPath(b, p);
      case VouchGlyph.calendar:
        rrect(const Rect.fromLTWH(4, 5.5, 16, 15), 4);
        poly([o(4, 10.2), o(20, 10.2)]);
        poly([o(8.5, 3.4), o(8.5, 7.4)]);
        poly([o(15.5, 3.4), o(15.5, 7.4)]);
        canvas.drawCircle(o(8.5, 14.2), 0.9, Paint()..color = color);
        canvas.drawCircle(o(12, 14.2), 0.9, Paint()..color = color);
        canvas.drawCircle(o(15.5, 14.2), 0.9, Paint()..color = color);
      case VouchGlyph.phone:
        final path = Path()
          ..moveTo(7.2, 3.6)
          ..cubicTo(5.6, 3.6, 4.2, 5, 4.5, 6.7)
          ..cubicTo(5.4, 13.1, 10.9, 18.6, 17.3, 19.5)
          ..cubicTo(19, 19.8, 20.4, 18.4, 20.4, 16.8)
          ..lineTo(20.4, 15.4)
          ..cubicTo(20.4, 14.2, 19.5, 13.3, 18.3, 13.1)
          ..lineTo(16.1, 12.8)
          ..cubicTo(15.2, 12.7, 14.4, 13, 13.8, 13.7)
          ..lineTo(13.2, 14.4)
          ..cubicTo(11.3, 13.3, 10, 12, 9.1, 10.3)
          ..lineTo(9.9, 9.6)
          ..cubicTo(10.6, 8.9, 10.9, 8.1, 10.7, 7.2)
          ..lineTo(10.1, 5.2)
          ..cubicTo(9.8, 4.2, 8.8, 3.6, 7.8, 3.6)
          ..close();
        canvas.drawPath(path, p);
      case VouchGlyph.message:
        rrect(const Rect.fromLTWH(3.8, 4.8, 16.4, 12.6), 5);
        poly([o(9.2, 17.2), o(9.2, 21), o(13.2, 17.2)]);
      case VouchGlyph.note:
        final path = Path()
          ..moveTo(5.8, 3.4)
          ..lineTo(14.2, 3.4)
          ..lineTo(18.6, 7.8)
          ..lineTo(18.6, 20.6)
          ..lineTo(5.8, 20.6)
          ..close();
        canvas.drawPath(path, p);
        poly([o(14.2, 3.6), o(14.2, 8), o(18.4, 8)]);
        poly([o(9, 12), o(15.4, 12)]);
        poly([o(9, 15.4), o(15.4, 15.4)]);
      case VouchGlyph.settings:
        circle(12, 12, 3);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final inner = o(12 + math.cos(a) * 5.4, 12 + math.sin(a) * 5.4);
          final outer = o(12 + math.cos(a) * 7.6, 12 + math.sin(a) * 7.6);
          canvas.drawLine(inner, outer, line);
        }
      case VouchGlyph.share:
        poly([o(8, 11), o(5, 11), o(5, 20), o(19, 20), o(19, 11), o(16, 11)]);
        poly([o(12, 15), o(12, 4)]);
        poly([o(8, 8), o(12, 4), o(16, 8)]);
      case VouchGlyph.bell:
        final path = Path()
          ..moveTo(5.6, 17.4)
          ..lineTo(18.4, 17.4)
          ..lineTo(16.9, 14.9)
          ..lineTo(16.9, 10.3)
          ..cubicTo(16.9, 7.1, 14.6, 4.6, 12, 4.6)
          ..cubicTo(9.4, 4.6, 7.1, 7.1, 7.1, 10.3)
          ..lineTo(7.1, 14.9)
          ..close();
        canvas.drawPath(path, p);
        final clapper = Path()
          ..moveTo(9.8, 17.6)
          ..cubicTo(9.8, 19.4, 10.8, 20.4, 12, 20.4)
          ..cubicTo(13.2, 20.4, 14.2, 19.4, 14.2, 17.6);
        canvas.drawPath(clapper, p);
      case VouchGlyph.refresh:
        canvas.drawArc(
          const Rect.fromLTWH(4, 4, 16, 16),
          -math.pi * 0.35,
          math.pi * 1.55,
          false,
          p,
        );
        poly([o(18.2, 4.2), o(19.4, 9.3), o(14.4, 8.2)]);
      case VouchGlyph.moon:
        final path = Path()
          ..moveTo(15.7, 3.8)
          ..arcToPoint(o(19.9, 14.9), radius: const Radius.circular(8), largeArc: true)
          ..arcToPoint(o(15.7, 3.8), radius: const Radius.circular(6.4), clockwise: false);
        canvas.drawPath(path, p);
      case VouchGlyph.sun:
        circle(12, 12, 3.6);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          canvas.drawLine(
            o(12 + math.cos(a) * 6.2, 12 + math.sin(a) * 6.2),
            o(12 + math.cos(a) * 8, 12 + math.sin(a) * 8),
            line,
          );
        }
      case VouchGlyph.logout:
        poly([o(10, 4), o(5, 4), o(5, 20), o(10, 20)]);
        poly([o(10, 12), o(20, 12)]);
        poly([o(16, 8), o(20, 12), o(16, 16)]);
      case VouchGlyph.copy:
        rrect(const Rect.fromLTWH(4, 4, 11, 12), 3);
        rrect(const Rect.fromLTWH(9, 8, 11, 12), 3);
      case VouchGlyph.clock:
        circle(12, 12, 8.4);
        poly([o(12, 7), o(12, 12), o(15.6, 14)]);
      case VouchGlyph.edit:
        poly([o(5, 19), o(5.8, 15.2), o(15.6, 5.4), o(18.6, 8.4), o(8.8, 18.2)]);
        poly([o(5, 19), o(8.8, 18.2)]);
      case VouchGlyph.dots:
        final dot = Paint()..color = color;
        for (final x in <double>[6.4, 12, 17.6]) {
          canvas.drawCircle(o(x, 12), 1.5, dot);
        }
      case VouchGlyph.eye:
        final path = Path()
          ..moveTo(3, 12)
          ..cubicTo(6, 7.2, 9, 5.4, 12, 5.4)
          ..cubicTo(15, 5.4, 18, 7.2, 21, 12)
          ..cubicTo(18, 16.8, 15, 18.6, 12, 18.6)
          ..cubicTo(9, 18.6, 6, 16.8, 3, 12)
          ..close();
        canvas.drawPath(path, p);
        circle(12, 12, 2.2);
      case VouchGlyph.star:
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final a = -math.pi / 2 + i * math.pi / 5;
          final r = i.isEven ? 8 : 3.6;
          final pt = o(12 + math.cos(a) * r, 12 + math.sin(a) * r);
          if (i == 0) {
            path.moveTo(pt.dx, pt.dy);
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        }
        path.close();
        canvas.drawPath(path, p);
      case VouchGlyph.lock:
        rrect(const Rect.fromLTWH(5, 10, 14, 10), 3);
        final shackle = Path()
          ..moveTo(8.2, 10)
          ..lineTo(8.2, 8)
          ..cubicTo(8.2, 5.4, 10, 3.8, 12, 3.8)
          ..cubicTo(14, 3.8, 15.8, 5.4, 15.8, 8)
          ..lineTo(15.8, 10);
        canvas.drawPath(shackle, p);
      case VouchGlyph.mail:
        rrect(const Rect.fromLTWH(3.6, 5.4, 16.8, 13.2), 3);
        poly([o(4.2, 7), o(12, 13), o(19.8, 7)]);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_VouchIconPainter oldDelegate) =>
      oldDelegate.glyph != glyph ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
