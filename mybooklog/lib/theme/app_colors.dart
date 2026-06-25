import 'package:flutter/material.dart';

/// App-wide color constants (raw palette values).
class AppColors {
  AppColors._();

  // Backgrounds & Containers
  //static const Color background = Color(0xFFFDFBF7); // Soft Cream
  static const Color background = Color(0xFFF7F4EB); // Oatmeal
  static const Color surface = Color(0xFFFFFFFF); // Surface Containers
  static const Color border = Color(0xFFE5E0D8); // Faint Border

  // Typography
  static const Color textPrimary = Color(0xFF2C2A29); // Deep Charcoal
  static const Color textSecondary = Color(0xFF706C68);

  // Accents
  static const Color accentSage = Color(0xFF6E8A78); // Primary Accent
  static const Color headerBackground = accentSage;
  static const Color headerForeground = white;

   // Utility colors
   static const Color white = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF4F8A65);
  static const Color selectionFill = Color(0xFFE7EEE9);

  // Semantic / states
  static const Color errorRed = Color(0xFFB3261E);

  // Compatibility aliases for existing app code while migrating.
  static const Color parchmentBackground = background;
  static const Color appBackground = background;
  static const Color primaryBrown = accentSage;
  static const Color darkText = textPrimary;
}