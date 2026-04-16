import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/color_constants.dart';

/// Premium Midnight metric card — frosted glass, colored accent line, tap-to-flip.
class MetricCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? backContent;
  final int colorIndex;
  final int delayMs;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.backContent,
    this.colorIndex = 0,
    this.delayMs = 0,
  });

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _entryController;
  bool _isFlipped = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _entryController.forward();
    });
  }

  void _toggleFlip() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  @override
  Widget build(BuildContext context) {
    final accent = NinjaColors.accentAt(widget.colorIndex);

    return FadeTransition(
      opacity: _entryController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _entryController,
          curve: Curves.easeOutCubic,
        )),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: _toggleFlip,
            child: AnimatedBuilder(
              animation: _flipController,
              builder: (context, child) {
                final angle = _flipController.value * math.pi;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 130,
                    decoration: BoxDecoration(
                      color: _isHovered
                          ? NinjaColors.glassBgHover
                          : NinjaColors.glassBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isHovered
                            ? NinjaColors.borderHover
                            : NinjaColors.border,
                      ),
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: accent.withOpacity(0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : [],
                    ),
                    child: angle > math.pi / 2
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _buildBack(accent),
                          )
                        : _buildFront(accent),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFront(Color accent) {
    return Stack(
      children: [
        // Accent line on left
        Positioned(
          left: 0,
          top: 12,
          bottom: 12,
          child: Container(
            width: 3,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(widget.icon, size: 16, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    widget.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: NinjaColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: NinjaColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBack(Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          widget.backContent ?? 'Tap to flip back',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: accent,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _entryController.dispose();
    super.dispose();
  }
}
