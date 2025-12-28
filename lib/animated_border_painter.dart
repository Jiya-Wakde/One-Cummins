import 'package:flutter/material.dart';

class AnimatedBorderPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color> colors;

  AnimatedBorderPainter({
    required this.progress,
    required this.colors,
    this.strokeWidth = 7,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(24),
    );

    final path = Path()..addRRect(rrect);
    final metric = path.computeMetrics().first;

    final length = metric.length;

    final glowLength = length * 0.22; // visible portion
    final start = progress * length;
    final end = start + glowLength;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: colors,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // FIRST PART
    final path1 = metric.extractPath(
      start % length,
      end.clamp(0, length),
    );
    canvas.drawPath(path1, paint);

    //SECOND PART 
    if (end > length) {
      final path2 = metric.extractPath(
        0,
        end - length,
      );
      canvas.drawPath(path2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
