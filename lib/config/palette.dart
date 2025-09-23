import 'package:flutter/painting.dart';

class Palette {
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF00CC58);
  static const Color lightSecondary = Color(0xFFFFCE21);
  static const Color lightText = Color(0xFF121212);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightBorder = Color(0xFFDFDDDD);
  static const Color lightDivider = Color(0xFFE0E0E0);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightError = Color(0xFFD7481D);
  static const Color lightSuccess = Color(0xFF00CC58);
  static const Color lightWarning = Color(0xFFFFCE21);
  static const Color lightInfo = Color(0xFF2196F3);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkPrimary = Color(0xFF00CC58);
  static const Color darkSecondary = Color(0xFFFFCE21);
  static const Color darkText = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkBorder = Color(0xFF404040);
  static const Color darkDivider = Color(0xFF404040);
  static const Color darkCard = Color(0xFF2A2A2A);
  static const Color darkError = Color(0xFFD7481D);
  static const Color darkSuccess = Color(0xFF00CC58);
  static const Color darkWarning = Color(0xFFFFCE21);
  static const Color darkInfo = Color(0xFF2196F3);

  // Legacy colors for backward compatibility
  static const Color whiteColor = lightBackground;
  static const Color greenColor = lightPrimary;
  static const Color yellowColor = lightSecondary;
  static const Color orangeColor = lightWarning;
  static const Color redColor = lightError;
  static const Color blackColor = lightText;
  static const Color greyColor = lightBorder;
}