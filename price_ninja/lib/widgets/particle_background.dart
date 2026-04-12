import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/color_constants.dart';

/// Premium ambient background — subtle gradient mesh with floating soft orbs.
class PatternBackground extends StatefulWidget {
  final Widget child;

  const PatternBackground({super.key, required this.child});

  @override
  State<PatternBackground> createState() => _PatternBackgroundState();
}

class _PatternBackgroundState extends State<PatternBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NinjaColors.background,
                  NinjaColors.backgroundAlt,
                  NinjaColors.background,
                ],
              ),
            ),
          ),
        ),
        // Ambient orbs
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _AmbientOrbsPainter(progress: _controller.value),
                );
              },
            ),
          ),
        ),
        // Subtle grid
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _SubtleGridPainter()),
          ),
        ),
        // Content
        widget.child,
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _AmbientOrbsPainter extends CustomPainter {
  final double progress;

  _AmbientOrbsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final orbs = [
      _Orb(0.15, 0.2, 180, NinjaColors.violet, 0),
      _Orb(0.8, 0.3, 150, NinjaColors.blue, 1.5),
      _Orb(0.5, 0.7, 200, NinjaColors.emerald, 3.0),
      _Orb(0.9, 0.8, 120, NinjaColors.violet, 4.5),
    ];

    for (final orb in orbs) {
      final dx = math.sin(progress * math.pi * 2 + orb.phase) * 30;
      final dy = math.cos(progress * math.pi * 2 + orb.phase * 0.7) * 20;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color.withValues(alpha: 0.06),
            orb.color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(
            orb.xFrac * size.width + dx,
            orb.yFrac * size.height + dy,
          ),
          radius: orb.radius,
        ));

      canvas.drawCircle(
        Offset(orb.xFrac * size.width + dx, orb.yFrac * size.height + dy),
        orb.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SubtleGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const gap = 60.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Orb {
  final double xFrac, yFrac, radius;
  final Color color;
  final double phase;
  _Orb(this.xFrac, this.yFrac, this.radius, this.color, this.phase);
}
