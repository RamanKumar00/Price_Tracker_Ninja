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
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
            // Center Cyan Tag
          Positioned(
            left: widget.size * 0.12,
            top: widget.size * 0.15,
            child: Transform.rotate(
              angle: (-math.pi / 5) + swing,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer neon glow behind the tag (using BackdropFilter or compositing instead of broken Web Icon shadow)
                  Icon(
                    Icons.local_offer_rounded,
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                    size: widget.size * 0.64,
                  ),
                  Icon(
                    Icons.local_offer_rounded,
                    color: Colors.cyanAccent.withValues(alpha: 0.25),
                    size: widget.size * 0.60,
                  ),
                  // Inner metallic tag body
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Colors.cyanAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Icon(
                      Icons.local_offer_rounded,
                      color: Colors.white,
                      size: widget.size * 0.58,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Right Tracking Cutout
          Positioned(
            right: -widget.size * 0.08,
            bottom: -widget.size * 0.08,
            child: Container(
              padding: EdgeInsets.all(widget.size * 0.08),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Very dark
                shape: BoxShape.circle,
                // Outer dark silver ring simulating metallic casing
                border: Border.all(
                  color: Colors.grey.shade400,
                  width: widget.size * 0.04,
                ),
                boxShadow: [
                  // Drop shadow over the main body
                  const BoxShadow(
                    color: Colors.black87,
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: Offset(-4, -4),
                  ),
                  // Green pulsing inner aura
                  BoxShadow(
                    color: Colors.greenAccent.withValues(alpha: 0.4 + swing.abs()),
                    blurRadius: 20 + (swing.abs() * 20),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.trending_down_rounded,
                    color: Colors.greenAccent.withValues(alpha: 0.5),
                    size: widget.size * 0.38,
                  ),
                  Icon(
                    Icons.trending_down_rounded,
                    color: Colors.greenAccent,
                    size: widget.size * 0.35,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
}
