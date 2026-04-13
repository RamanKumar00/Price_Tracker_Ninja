import 'package:flutter/material.dart';

/// Premium Midnight Glassmorphism color palette.
/// Inspired by Linear, Vercel, and Raycast design aesthetic.
class NinjaColors {
  NinjaColors._();

  // ─── Base ───
  static const Color background = Color(0xFF0F0F1A);
  static const Color backgroundAlt = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFF16162A);
  static const Color surfaceLight = Color(0xFF1E1E36);
  static const Color surfaceHover = Color(0xFF252542);

  // ─── Accent ───
  static const Color violet = Color(0xFF8B5CF6);
  static const Color blue = Color(0xFF3B82F6);
  static const Color emerald = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color rose = Color(0xFFF43F5E);

  // ─── Gradients ───
  static const List<Color> primaryGradient = [violet, blue];
  static const List<Color> successGradient = [emerald, Color(0xFF06B6D4)];
  static const List<Color> warmGradient = [amber, rose];

  // ─── Text ───
  static const Color textPrimary = Color(0xFFF1F1F3);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // ─── Border ───
  static const Color border = Color(0x14FFFFFF); // 0.08 alpha
  static const Color borderHover = Color(0x26FFFFFF); // 0.15 alpha
  static const Color borderAccent = Color(0x668B5CF6); // 0.4 opacity violet

  // ─── Status ───
  static const Color success = emerald;
  static const Color error = rose;
  static const Color warning = amber;
  static const Color info = blue;

  // ─── Glass ───
  static const Color glassBg = Color(0x0AFFFFFF); // 0.04 alpha
  static const Color glassBgHover = Color(0x12FFFFFF); // 0.07 alpha

  /// Accent color by index for cycling.
  static const List<Color> accents = [violet, blue, emerald, amber, rose];
  static Color accentAt(int i) => accents[i % accents.length];
}
