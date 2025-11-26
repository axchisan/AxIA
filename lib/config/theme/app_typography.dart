import 'package:flutter/material.dart';

class AppTypography {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // Body Text
  static const TextStyle body1 = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Small Text
  static const TextStyle caption = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Buttons
  static const TextStyle button = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  // Monospace (para datos técnicos)
  static const TextStyle mono = TextStyle(
    fontFamily: 'Courier',
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}
