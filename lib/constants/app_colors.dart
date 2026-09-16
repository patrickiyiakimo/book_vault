import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors - soft warm orange
  static const Color primaryOrange = Color(0xFFE08A4B);
  static const Color darkOrange = Color(0xFFB96A35);
  static const Color lightOrange = Color(0xFFEFAB7C);
  static const Color accentOrange = Color(0xFFF6C79E);
  static const Color paleOrange = Color(0xFFFCEADB);

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
    colors: [darkOrange, primaryOrange, lightOrange],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkOrange, primaryOrange],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF4E8), Color(0xFFFDEBDC)],
  );
}