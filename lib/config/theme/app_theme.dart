import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryViolet,
      scaffoldBackgroundColor: AppColors.bgDarkPrimary,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDarkSecondary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.h2.copyWith(
          color: AppColors.textDarkPrimary,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.bgDarkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.neonPurple.withOpacity(0.2),
          ),
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.h1.copyWith(
          color: AppColors.textDarkPrimary,
        ),
        displayMedium: AppTypography.h2.copyWith(
          color: AppColors.textDarkPrimary,
        ),
        displaySmall: AppTypography.h3.copyWith(
          color: AppColors.textDarkPrimary,
        ),
        bodyLarge: AppTypography.body1.copyWith(
          color: AppColors.textDarkPrimary,
        ),
        bodyMedium: AppTypography.body2.copyWith(
          color: AppColors.textDarkSecondary,
        ),
        bodySmall: AppTypography.caption.copyWith(
          color: AppColors.textDarkTertiary,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgDarkSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.neonPurple.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.neonPurple,
            width: 2,
          ),
        ),
        hintStyle: AppTypography.body2.copyWith(
          color: AppColors.textDarkTertiary,
        ),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryViolet,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.neonPurple,
        size: 24,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryViolet,
      scaffoldBackgroundColor: AppColors.bgLightPrimary,
      
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgLightCard,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.h2.copyWith(
          color: AppColors.textLightPrimary,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.bgLightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.primaryViolet.withOpacity(0.1),
          ),
        ),
      ),

      textTheme: TextTheme(
        displayLarge: AppTypography.h1.copyWith(
          color: AppColors.textLightPrimary,
        ),
        displayMedium: AppTypography.h2.copyWith(
          color: AppColors.textLightPrimary,
        ),
        displaySmall: AppTypography.h3.copyWith(
          color: AppColors.textLightPrimary,
        ),
        bodyLarge: AppTypography.body1.copyWith(
          color: AppColors.textLightPrimary,
        ),
        bodyMedium: AppTypography.body2.copyWith(
          color: AppColors.textLightSecondary,
        ),
        bodySmall: AppTypography.caption.copyWith(
          color: AppColors.textLightTertiary,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgLightSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryViolet.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryViolet,
            width: 2,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryViolet,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
