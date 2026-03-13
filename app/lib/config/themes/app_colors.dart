import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette - Orange gradient (from Stitch design)
  static const Color primary = Color(0xFFE8601C);
  static const Color primaryLight = Color(0xFFF4845F);
  static const Color primaryDark = Color(0xFFD14E0F);
  static const Color primarySurface = Color(0xFFFFF3ED);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF4845F), Color(0xFFE8601C), Color(0xFFD14E0F)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF4845F), Color(0xFFE8601C)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFFF8F5)],
  );

  // Secondary palette
  static const Color secondary = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFFA78BFA);

  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Neutral colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE5E7EB);

  // Background
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundDark = Color(0xFF111827);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1F2937);

  // Glass effect
  static const Color glassWhite = Color(0x40FFFFFF);
  static const Color glassBorder = Color(0x30FFFFFF);
  static const Color glassOverlay = Color(0x15FFFFFF);
}
