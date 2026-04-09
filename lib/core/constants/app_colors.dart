import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette — Warm Wheat & Earth
  static const Color primaryBrown = Color(0xFF6B4226);
  static const Color primaryGold = Color(0xFFC8860A);
  static const Color primaryGoldLight = Color(0xFFE8A820);

  // Background & Surface
  static const Color backgroundCream = Color(0xFFFAF7F0);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFFFFBF5);

  // Dark Tones
  static const Color darkBrown = Color(0xFF2C1810);
  static const Color darkEspresso = Color(0xFF1A0F08);

  // Text
  static const Color textPrimary = Color(0xFF2C1810);
  static const Color textSecondary = Color(0xFF6B5E52);
  static const Color textHint = Color(0xFFB0A090);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Accent
  static const Color accentGreen = Color(0xFF4A7C3F);
  static const Color accentGreenLight = Color(0xFFE8F5E3);

  // Combo / Special
  static const Color comboPrimary = Color(0xFFE85D26);
  static const Color comboSecondary = Color(0xFFFFF0E8);
  static const Color comboBadge = Color(0xFFFF6B35);

  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFF8F00);
  static const Color info = Color(0xFF1976D2);

  // Border & Divider
  static const Color border = Color(0xFFEDE8E0);
  static const Color divider = Color(0xFFF0EBE3);

  // Shimmer
  static const Color shimmerBase = Color(0xFFEDE8E0);
  static const Color shimmerHighlight = Color(0xFFFAF7F0);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5E34), Color(0xFFC8860A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient comboGradient = LinearGradient(
    colors: [Color(0xFFE85D26), Color(0xFFFF9A3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF2C1810), Color(0xFF6B4226)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFBF5), Color(0xFFFFF5E6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
