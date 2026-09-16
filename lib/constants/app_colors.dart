import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors - soft pastel mint
  static const Color primaryGreen = Color(0xFF6FA98E);
  static const Color darkGreen = Color(0xFF4E8066);
  static const Color lightGreen = Color(0xFF93C2A8);
  static const Color accentGreen = Color(0xFFB3D8BF);
  static const Color paleGreen = Color(0xFFE3F0E4);

  // Neutral Colors - warm cream
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFAF6F0);
  static const Color lightGray = Color(0xFFECE5DB);
  static const Color mediumGray = Color(0xFFA29A8E);
  static const Color darkGray = Color(0xFF524C45);
  static const Color black = Color(0xFF2B2924);

  // Accent Colors
  static const Color gold = Color(0xFFE9A84E);
  static const Color softGold = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color info = Color(0xFF1E88E5);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkGreen, primaryGreen, lightGreen],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkGreen, primaryGreen],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF1F8E9), Color(0xFFE8F5E9)],
  );
}
