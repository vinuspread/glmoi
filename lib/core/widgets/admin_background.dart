import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:app_admin/core/theme/app_theme.dart';

class AdminBackground extends StatelessWidget {
  final Widget child;

  const AdminBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _GridPattern()),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.8, -0.9),
                radius: 1.2,
                colors: [
                  AppTheme.accentLight.withValues(alpha: 191),
                  AppTheme.background,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _GridPattern extends StatelessWidget {
  const _GridPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPatternPainter(
        color: AppTheme.border.withValues(alpha: 56),
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  final Color color;

  const _GridPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    canvas.save();
    canvas.translate(size.width * 0.55, size.height * 0.18);
    canvas.rotate(-math.pi / 10);
    canvas.translate(-size.width * 0.55, -size.height * 0.18);

    const double step = 28;
    for (double x = -size.width; x <= size.width * 2; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = -size.height; y <= size.height * 2; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GridPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
