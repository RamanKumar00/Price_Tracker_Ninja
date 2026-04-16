import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/color_constants.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/premium_logo.dart';
import '../widgets/neon_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Track Prices\nEffortlessly',
      description: 'Monitor price drops across Amazon, Flipkart, Myntra, and more in real-time.',
      icon: Icons.auto_graph_rounded,
      color: NinjaColors.violet,
    ),
    OnboardingData(
      title: 'Smart Alerts\nOn the Go',
      description: 'Get instant WhatsApp and email notifications as soon as the price hits your target.',
      icon: Icons.notifications_active_rounded,
      color: NinjaColors.blue,
    ),
    OnboardingData(
      title: 'Save Big\nEvery Time',
      description: 'Never overpay again. Join thousands of Ninjas saving money every single day.',
      icon: Icons.savings_rounded,
      color: NinjaColors.emerald,
    ),
  ];

  void _onNext() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    ref.read(onboardingProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NinjaColors.background,
      body: Stack(
        children: [
          // Background Gradient Glow
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [
                  _pages[_currentIndex].color.withOpacity(0.15),
                  NinjaColors.background,
                ],
              ),
            ),
          ),

          // Content
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final data = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Illustration/Icon Container with ORBITAL LOGO
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // The Center Circle
                              Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: data.color.withOpacity(0.1),
                                  border: Border.all(
                                    color: data.color.withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  data.icon,
                                  size: 80,
                                  color: data.color,
                                ),
                              ).animate(key: ValueKey('icon_$index')).scale(
                                    duration: 600.ms,
                                    curve: Curves.easeOutBack,
                                  ).shimmer(
                                    delay: 800.ms,
                                    duration: 1500.ms,
                                  ),
                            ],
                          ),
                          
                          const SizedBox(height: 60),
                          
                          Text(
                            data.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: NinjaColors.textPrimary,
                              height: 1.1,
                              letterSpacing: -1,
                            ),
                          ).animate(key: ValueKey('t$index')).fadeIn(delay: 200.ms).slideY(begin: 0.2),
                          
                          const SizedBox(height: 20),
                          
                          Text(
                            data.description,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: NinjaColors.textSecondary,
                              height: 1.5,
                            ),
                          ).animate(key: ValueKey('d$index')).fadeIn(delay: 400.ms).slideY(begin: 0.2),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Navigation bar
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 50),
                child: Column(
                  children: [
                    // Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 8),
                          width: _currentIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentIndex == index
                                ? _pages[_currentIndex].color
                                : NinjaColors.border,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Action Buttons
                    Row(
                      children: [
                        if (_currentIndex < _pages.length - 1)
                          TextButton(
                            onPressed: _finish,
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                color: NinjaColors.textMuted,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const Spacer(),
                        SizedBox(
                          width: 160,
                          child: NeonButton(
                            text: _currentIndex == _pages.length - 1 ? 'Get Started' : 'Next',
                            icon: _currentIndex == _pages.length - 1 
                                ? Icons.rocket_launch_rounded 
                                : Icons.arrow_forward_rounded,
                            onPressed: _onNext,
                            colorIndex: _currentIndex,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
