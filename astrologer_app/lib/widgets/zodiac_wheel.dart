import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ZodiacWheel extends StatefulWidget {
  final String? highlightedSign;
  final double size;

  const ZodiacWheel({super.key, this.highlightedSign, this.size = 280});

  @override
  State<ZodiacWheel> createState() => _ZodiacWheelState();
}

class _ZodiacWheelState extends State<ZodiacWheel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: ZodiacWheelPainter(
          rotationAngle: _controller.value * 2 * pi,
          highlightedSign: widget.highlightedSign,
          accentColor: context.clr.accent,
        ),
      ),
    );
  }
}

class ZodiacWheelPainter extends CustomPainter {
  final double rotationAngle;
  final String? highlightedSign;
  final Color accentColor;

  static const List<String> signs = ['♈', '♉', '♊', '♋', '♌', '♍', '♎', '♏', '♐', '♑', '♒', '♓'];
  static const List<String> signNames = [
    'ARIES', 'TAURUS', 'GEMINI', 'CANCER', 'LEO', 'VIRGO',
    'LIBRA', 'SCORPIO', 'SAGIT', 'CAPRI', 'AQUAR', 'PISCES'
  ];

  ZodiacWheelPainter({required this.rotationAngle, this.highlightedSign, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);
    canvas.translate(-center.dx, -center.dy);

    _drawCircle(canvas, center, radius * 0.95, accentColor.withValues(alpha: 0.3), 1.0);
    _drawCircle(canvas, center, radius * 0.75, accentColor.withValues(alpha: 0.2), 0.8);
    _drawCircle(canvas, center, radius * 0.55, accentColor.withValues(alpha: 0.15), 0.6);
    _drawCircle(canvas, center, radius * 0.30, accentColor.withValues(alpha: 0.1), 0.5);

    // Outer ring segments
    for (int i = 0; i < 12; i++) {
      final startAngle = (i * 30 - 90) * pi / 180;
      final endAngle = ((i + 1) * 30 - 90) * pi / 180;

      final paint = Paint()
        ..color = i.isEven ? accentColor.withValues(alpha: 0.08) : accentColor.withValues(alpha: 0.04)
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: radius * 0.95), startAngle, endAngle - startAngle, false)
        ..close();

      canvas.drawPath(path, paint);

      // Divider lines
      final linePaint = Paint()
        ..color = accentColor.withValues(alpha: 0.3)
        ..strokeWidth = 0.5;
      final lineEnd = Offset(
        center.dx + radius * 0.95 * cos(startAngle),
        center.dy + radius * 0.95 * sin(startAngle),
      );
      canvas.drawLine(
        Offset(center.dx + radius * 0.55 * cos(startAngle), center.dy + radius * 0.55 * sin(startAngle)),
        lineEnd,
        linePaint,
      );
    }

    canvas.restore();

    // Draw symbols (don't rotate with wheel for readability)
    canvas.save();
    canvas.translate(center.dx, center.dy);

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90 + 15) * pi / 180;
      final symbolRadius = radius * 0.65;
      final x = symbolRadius * cos(angle);
      final y = symbolRadius * sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: signs[i],
          style: TextStyle(
            fontSize: size.width * 0.055,
            color: accentColor.withValues(alpha: 0.9),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }

    // Center decorative element
    _drawStarburstCenter(canvas, size);

    canvas.restore();
  }

  void _drawCircle(Canvas canvas, Offset center, double radius, Color color, double strokeWidth) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  void _drawStarburstCenter(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final innerRadius = size.width * 0.12;
    final outerRadius = size.width * 0.17;

    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      canvas.drawLine(
        Offset(innerRadius * cos(angle), innerRadius * sin(angle)),
        Offset(outerRadius * cos(angle), outerRadius * sin(angle)),
        paint,
      );
    }

    canvas.drawCircle(Offset.zero, innerRadius, paint);
    canvas.drawCircle(
      Offset.zero,
      size.width * 0.06,
      Paint()..color = accentColor.withValues(alpha: 0.3),
    );
  }

  @override
  bool shouldRepaint(ZodiacWheelPainter old) => old.rotationAngle != rotationAngle || old.accentColor != accentColor;
}
