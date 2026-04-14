import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/color_constants.dart';
import '../widgets/premium_logo.dart';

/// Premium splash — clean fade, subtle glow.
class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;

  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NinjaColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_fadeController, _pulseController]),
          builder: (context, _) {
            return Opacity(
              opacity: _fadeController.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // The Ninja Orbiting specifically around the branding center
                  const PremiumLogo(size: 72, orbitRadius: 220),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Price Ninja',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: NinjaColors.textPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Smart price tracking',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: NinjaColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
