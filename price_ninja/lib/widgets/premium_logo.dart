import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated Premium Logo matching Cyberpunk/Metallic Tracker aesthetic.
class PremiumLogo extends StatefulWidget {
  final double size;
  final bool shouldAnimate;
  final double? orbitRadius;

  const PremiumLogo({
    super.key,
    this.size = 64,
    this.shouldAnimate = true,
    this.orbitRadius,
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
        vsync: this, duration: const Duration(milliseconds: 4000));
    if (widget.shouldAnimate) {
      _animController.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.shouldAnimate) return _buildLogo(0, 0);

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final val = _animController.value;
        final angle = val * 2 * math.pi;
        
        // Circular Orbital Motion (Circumference)
        final double radius = widget.orbitRadius ?? (widget.size * 1.5); // Default to a larger orbit
        final double orbitX = math.cos(angle) * radius;
        final double orbitY = math.sin(angle) * radius;
        
        // Subtle tilt/swing based on rotation
        final swing = math.cos(angle) * 0.1;

        return Transform.translate(
          offset: Offset(orbitX, orbitY),
          child: Transform.rotate(
            angle: swing,
            child: _buildLogo(orbitY, swing),
          ),
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
