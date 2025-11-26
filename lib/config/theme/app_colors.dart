import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Deep Purples & Violets
  static const Color primaryViolet = Color(0xFF7C3AED); // Violet-600
  static const Color primaryPurple = Color(0xFF6D28D9); // Purple-600
  static const Color primaryDeep = Color(0xFF5B21B6); // Purple-700
  
  // Neon & Accent Colors
  static const Color neonPurple = Color(0xFFBB86FC); // Neon Purple
  static const Color neonCyan = Color(0xFF00D9FF); // Neon Cyan
  static const Color neonMagenta = Color(0xFFFF006E); // Neon Magenta
  
  // Background Colors - Dark Theme
  static const Color bgDarkPrimary = Color(0xFF0F0F1E); // Almost Black
  static const Color bgDarkSecondary = Color(0xFF1A1A2E); // Dark Purple-Gray
  static const Color bgDarkTertiary = Color(0xFF2D2D44); // Medium Dark
  static const Color bgDarkCard = Color(0xFF16213E); // Card Background
  
  // Background Colors - Light Theme
  static const Color bgLightPrimary = Color(0xFFFAFAFA); // Off White
  static const Color bgLightSecondary = Color(0xFFF3F0FF); // Light Purple
  static const Color bgLightCard = Color(0xFFFFFFFF); // White
  
  // Text Colors
  static const Color textDarkPrimary = Color(0xFFE0E0E0); // Light Gray
  static const Color textDarkSecondary = Color(0xFFA0A0A0); // Medium Gray
  static const Color textDarkTertiary = Color(0xFF707070); // Dark Gray
  
  static const Color textLightPrimary = Color(0xFF1A1A1A); // Dark Gray
  static const Color textLightSecondary = Color(0xFF666666); // Medium Gray
  static const Color textLightTertiary = Color(0xFF999999); // Light Gray
  
  // Status Colors
  static const Color statusAvailable = Color(0xFF10B981); // Green
  static const Color statusFocus = Color(0xFFF59E0B); // Amber
  static const Color statusAway = Color(0xFF6B7280); // Gray
  static const Color statusBusy = Color(0xFFEF4444); // Red
  
  // Glassmorphism
  static const Color glassDark = Color(0x1A1A1A2E);
  static const Color glassLight = Color(0x1AFFFFFF);
  
  // Gradients
  static const List<Color> purpleGradient = [
    Color(0xFF7C3AED),
    Color(0xFF6D28D9),
  ];
  
  static const List<Color> neonGradient = [
    Color(0xFFBB86FC),
    Color(0xFF00D9FF),
  ];

  static Color get background => bgDarkPrimary;
  static Color get accentPurple => neonPurple;
  static Color get textSecondary => textDarkSecondary;
  static Color get surface => bgDarkCard;
}
