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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   PremiumLogo(size: 84, orbitRadius: 120),
                  const SizedBox(height: 24),
                  Text(
                    'Price Ninja',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: NinjaColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Smart price tracking',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: NinjaColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: NinjaColors.violet.withValues(alpha: 0.6),
                    ),
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
