import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/color_constants.dart';
import 'premium_logo.dart';

/// Premium animated title — shimmer gradient text, flying logo mark.
class PremiumAnimatedTitle extends StatefulWidget {
  final String text;
  final double fontSize;

  const PremiumAnimatedTitle({
    super.key,
    required this.text,
    this.fontSize = 28,
  });

  @override
  State<PremiumAnimatedTitle> createState() => _PremiumAnimatedTitleState();
}

class _PremiumAnimatedTitleState extends State<PremiumAnimatedTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    // Shimmer effect
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();

    _shimmerAnim = Tween<double>(begin: -0.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Gradient Shimmer Text
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _shimmerAnim,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: [
                      NinjaColors.textPrimary,
                      NinjaColors.textPrimary,
                      NinjaColors.violet,
                      NinjaColors.blue,
                      NinjaColors.textPrimary,
                      NinjaColors.textPrimary,
                    ],
                    stops: [
                      0.0,
                      (_shimmerAnim.value - 0.3).clamp(0.0, 1.0),
                      (_shimmerAnim.value - 0.1).clamp(0.0, 1.0),
                      (_shimmerAnim.value + 0.1).clamp(0.0, 1.0),
                      (_shimmerAnim.value + 0.3).clamp(0.0, 1.0),
                      1.0,
                    ],
                    begin: const FractionalOffset(0.0, 0.0),
                    end: const FractionalOffset(1.0, 0.0),
                  ).createShader(bounds);
                },
                child: Text(
                  widget.text,
                  style: GoogleFonts.inter(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.8,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }
}

