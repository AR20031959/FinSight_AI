import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HealthScoreGauge extends StatelessWidget {
  final double score; // 0 to 100
  final double size;

  const HealthScoreGauge({
    super.key,
    required this.score,
    this.size = 140.0,
  });

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? const Color(0xFF22C55E)
        : score >= 60
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return CustomPaint(
      size: Size(size, size),
      painter: _GaugePainter(score: score, color: color),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: GoogleFonts.outfit(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                "Health Score",
                style: GoogleFonts.inter(
                  fontSize: size * 0.09,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;

  _GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 10.0;

    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.75,
      pi * 1.5,
      false,
      bgPaint,
    );

    final sweepAngle = (pi * 1.5) * (score / 100.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.75,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}
