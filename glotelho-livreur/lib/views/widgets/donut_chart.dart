import 'package:flutter/material.dart';

/// Petit graphique en anneau (donut) sans dépendance externe.
class DonutChart extends StatelessWidget {
  final double value1;
  final double value2;
  final Color color1;
  final Color color2;
  final String centerLabel;
  final String centerValue;

  const DonutChart({
    super.key,
    required this.value1,
    required this.value2,
    required this.centerLabel,
    required this.centerValue,
    this.color1 = const Color(0xFF7C6FF0),
    this.color2 = const Color(0xFFC8960C),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(160, 160),
            painter: _DonutPainter(value1: value1, value2: value2, color1: color1, color2: color2),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(centerLabel, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              const SizedBox(height: 4),
              Text(centerValue, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double value1;
  final double value2;
  final Color color1;
  final Color color2;

  _DonutPainter({required this.value1, required this.value2, required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final total = value1 + value2;
    if (total <= 0) return;

    final strokeWidth = 24.0;
    final rect = Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth);

    final angle1 = (value1 / total) * 2 * 3.141592653589793;
    final angle2 = (value2 / total) * 2 * 3.141592653589793;

    final paint1 = Paint()
      ..color = color1
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final paint2 = Paint()
      ..color = color2
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -3.141592653589793 / 2;
    canvas.drawArc(rect, startAngle, angle1, false, paint1);
    canvas.drawArc(rect, startAngle + angle1, angle2, false, paint2);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}