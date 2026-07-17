import 'package:flutter/material.dart';

/// App-wide color constants (raw palette values).
///
/// Every color the app uses is named and defined in this one place, so the
/// whole app can be re-colored by editing this file only. The palette is a
/// warm, calm "library" feel: an oatmeal background, deep charcoal text, and
/// a muted sage green as the single accent color.
class AppColors {
  AppColors._();

  // Backgrounds & Containers
  static const Color background = Color(0xFFF7F4EB); // Oatmeal
  static const Color surface = Color(0xFFFFFFFF); // Surface Containers
  static const Color border = Color(0xFFE5E0D8); // Faint Border

  // Typography
  static const Color textPrimary = Color(0xFF2C2A29); // Deep Charcoal
  static const Color textSecondary = Color(0xFF706C68);

  // Accents
  static const Color accentSage = Color(0xFF6E8A78); // Primary Accent

  // Utility colors
  static const Color white = Color(0xFFFFFFFF);

  // Semantic / states
  static const Color errorRed = Color(0xFFB3261E);
}
