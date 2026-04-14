import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated Premium Logo matching Cyberpunk/Metallic Tracker aesthetic.
class PremiumLogo extends StatefulWidget {
  final double size;
  final bool animate;

  const PremiumLogo({
    super.key,
    this.size = 64,
    this.animate = true,
  });

  @override
  State<PremiumLogo> createState() => _PremiumLogoState();
}

class _PremiumLogoState extends State<PremiumLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    if (widget.animate) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return _buildLogo(0, 0);

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final val = _animController.value;
        // Float linearly up/down (sine wave limits)
        final floatY = math.sin(val * math.pi) * (widget.size * -0.06);
        // Swing slightly like a pendulum
        final swing = math.cos(val * math.pi) * 0.08;

        return Transform.translate(
          offset: Offset(0, floatY),
          child: _buildLogo(floatY, swing),
        );
      },
    );
  }

  Widget _buildLogo(double floatY, double swing) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        // Cyber background
        gradient: const RadialGradient(
          colors: [Color(0xFF1E293B), Color(0xFF070B14)],
          center: Alignment.topLeft,
          radius: 1.8,
        ),
        borderRadius: BorderRadius.circular(widget.size * 0.28),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          // Cyberpunk subtle cyan outer glow
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.15),
            blurRadius: widget.size * 0.3,
            offset: Offset(0, (widget.size * 0.1) - floatY),
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          'assets/images/app_logo.png',
          width: widget.size * 0.85,
          height: widget.size * 0.85,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
}
