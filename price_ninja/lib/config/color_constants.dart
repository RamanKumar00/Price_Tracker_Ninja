import 'package:flutter/material.dart';

/// Premium Midnight Glassmorphism color palette.
/// Inspired by Linear, Vercel, and Raycast design aesthetic.
class NinjaColors {
  NinjaColors._();

  // ─── Base ───
  static const Color background = Color(0xFF080712); // Deep cosmic dark
  static const Color backgroundAlt = Color(0xFF0E0C1C); // Subtle depth
  static const Color surface = Color(0xFF131026); // Surface tint
  static const Color surfaceLight = Color(0xFF1A1736); // Elevated elements
  static const Color surfaceHover = Color(0xFF25204D); // Hover states

  // ─── Accent ───
  static const Color violet = Color(0xFFD946EF); // Neon Fuchsia
  static const Color blue = Color(0xFF00E5FF); // Cyber Cyan
  static const Color emerald = Color(0xFF00FA9A); // Spring Green Flash
  static const Color amber = Color(0xFFFFC300); // Radiant Gold
  static const Color rose = Color(0xFFFF1744); // Electric Red

  // ─── Gradients ───
  static const List<Color> primaryGradient = [Color(0xFF8A2BE2), Color(0xFFD946EF)]; // Purple to Fuchsia
  static const List<Color> successGradient = [Color(0xFF00E5FF), Color(0xFF00FA9A)]; // Cyan to Green
  static const List<Color> warmGradient = [Color(0xFFFFC300), Color(0xFFFF1744)]; // Gold to Red

  // ─── Text ───
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF64748B);

  // ─── Border ───
  static const Color border = Color(0x1AFFFFFF); // 0.10 alpha
  static const Color borderHover = Color(0x33FFFFFF); // 0.20 alpha
  static const Color borderAccent = Color(0x66D946EF); // 0.4 opacity fuchsia

  // ─── Status ───
  static const Color success = emerald;
  static const Color error = rose;
  static const Color warning = amber;
  static const Color info = blue;

  // ─── Glass ───
  static const Color glassBg = Color(0x0CFFFFFF); // 0.05 alpha for better glass feel
  static const Color glassBgHover = Color(0x14FFFFFF); // 0.08 alpha

  /// Accent color by index for cycling.
  static const List<Color> accents = [violet, blue, emerald, amber, rose];
  static Color accentAt(int i) => accents[i % accents.length];
}
