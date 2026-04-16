import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/color_constants.dart';

/// Premium button — gradient or outlined, clean hover states.
class NeonButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final int colorIndex;
  final bool outlined;

  const NeonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.colorIndex = 0,
    this.outlined = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = NinjaColors.accentAt(widget.colorIndex);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: widget.outlined || widget.onPressed == null
                ? null
                : LinearGradient(
                    colors: [accent, accent.withOpacity(0.8)],
                  ),
            color: widget.onPressed == null
                ? Colors.grey.withOpacity(0.2) // Disabled state color
                : (widget.outlined ? Colors.transparent : null),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.onPressed == null
                  ? Colors.transparent
                  : (widget.outlined
                      ? (_isHovered ? accent : accent.withOpacity(0.4))
                      : Colors.transparent),
            ),
            boxShadow: _isHovered && !widget.outlined && widget.onPressed != null
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.onPressed == null
                      ? Colors.grey.withOpacity(0.5)
                      : (widget.outlined ? accent : Colors.white),
                  ),
                )
              else if (widget.icon != null)
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.onPressed == null
                      ? Colors.grey.withOpacity(0.5)
                      : (widget.outlined ? accent : Colors.white),
                ),
              if (widget.icon != null || widget.isLoading)
                const SizedBox(width: 8),
              Text(
                widget.text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.onPressed == null
                      ? Colors.grey.withOpacity(0.5)
                      : (widget.outlined ? accent : Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
