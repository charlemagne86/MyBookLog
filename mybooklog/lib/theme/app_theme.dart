import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Defines light and dark ThemeData configurations for the app.
class AppTheme {
  AppTheme._();

  static const String _headlineFont = 'Merriweather';
  static const String _bodyFont = 'Inter';

  static TextTheme _textTheme(ColorScheme scheme) {
    // `final` (not `const`) avoids a CFE crash in certain Dart versions
    // where const-propagation into List<String> parameters is mishandled.
    final serif = TextStyle(
      fontFamily: _headlineFont,
      fontFamilyFallback: const <String>['Georgia', 'Times New Roman', 'serif'],
    );
    final sans = TextStyle(
      fontFamily: _bodyFont,
      fontFamilyFallback: const <String>['Roboto', 'Arial', 'sans-serif'],
    );
    return TextTheme(
      displayLarge: serif.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      displayMedium: serif.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      displaySmall: serif.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineLarge: serif.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      headlineMedium: serif.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineSmall: serif.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: sans.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: sans.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleSmall: sans.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: sans.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: sans.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodySmall: sans.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      labelLarge: sans.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      labelMedium: sans.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      labelSmall: sans.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  static TextStyle _pageTitleStyle({
    required TextStyle baseStyle,
    required Color color,
  }) {
    return baseStyle.copyWith(
      color: color,
      shadows: [
        Shadow(
          color: color.withAlpha(72),
          blurRadius: 2.5,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  static TextStyle _bookNameStyle(ColorScheme scheme) {
    return TextStyle(
      fontFamily: _bodyFont,
      fontSize: 17,
      fontWeight: FontWeight.w500,
      color: scheme.brightness == Brightness.dark
          ? Colors.white
          : AppColors.textPrimary,
    );
  }

  static InputDecorationTheme _inputTheme(ColorScheme scheme) {
    final rounded = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(
        fontSize: 16,
        color: AppColors.textSecondary,
        fontFamily: _bodyFont,
      ),
      labelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        fontFamily: _bodyFont,
      ),
      helperStyle: const TextStyle(
        fontSize: 16,
        color: AppColors.textSecondary,
        fontFamily: _bodyFont,
      ),
      errorStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.errorRed,
        fontFamily: _bodyFont,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: rounded,
      enabledBorder: rounded,
      focusedBorder: rounded.copyWith(
        borderSide: BorderSide(color: scheme.primary, width: 2.0),
      ),
      errorBorder: rounded.copyWith(
        borderSide: const BorderSide(color: AppColors.errorRed),
      ),
      focusedErrorBorder: rounded.copyWith(
        borderSide: const BorderSide(color: AppColors.errorRed, width: 1.8),
      ),
    );
  }

  static ButtonStyle _pillButtonStyle({
    required Color background,
    required Color foreground,
    BorderSide? side,
  }) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(64, 54)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      backgroundColor: WidgetStatePropertyAll(background),
      foregroundColor: WidgetStatePropertyAll(foreground),
      side: side == null ? null : WidgetStatePropertyAll(side),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: _bodyFont,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accentSage,
      brightness: Brightness.light,
      surface: AppColors.surface,
      error: AppColors.errorRed,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _textTheme(colorScheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.headerBackground,
        foregroundColor: AppColors.headerForeground,
        iconTheme: const IconThemeData(color: AppColors.headerForeground),
        actionsIconTheme: const IconThemeData(color: AppColors.headerForeground),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _pageTitleStyle(
          baseStyle: _textTheme(colorScheme).headlineSmall!,
          color: AppColors.headerForeground,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        shadowColor: AppColors.textPrimary.withAlpha((0.08 * 255).round()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shadowColor: AppColors.textPrimary.withAlpha((0.08 * 255).round()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: _inputTheme(colorScheme),
      listTileTheme: ListTileThemeData(
        titleTextStyle: _bookNameStyle(colorScheme),
        subtitleTextStyle: _textTheme(colorScheme).bodyMedium?.copyWith(
          color: colorScheme.brightness == Brightness.dark
          ? Colors.white70
          : AppColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _pillButtonStyle(
          background: colorScheme.primary,
          foreground: AppColors.white,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _pillButtonStyle(
          background: colorScheme.secondary,
          foreground: colorScheme.onSecondary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _pillButtonStyle(
          background: Colors.transparent,
          foreground: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _pillButtonStyle(
          background: Colors.transparent,
          foreground: colorScheme.primary,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.all(10),
          foregroundColor: AppColors.textPrimary,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        shadowColor: AppColors.textPrimary.withAlpha((0.08 * 255).round()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        textStyle: _textTheme(colorScheme).bodyMedium,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: AppColors.border,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        labelStyle: _textTheme(colorScheme).labelMedium!,
        secondaryLabelStyle: _textTheme(colorScheme).labelMedium!,
        brightness: Brightness.light,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: _textTheme(
          colorScheme,
        ).bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Ready for future dark mode support; can be expanded incrementally.
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accentSage,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      textTheme: _textTheme(
        colorScheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.headerBackground,
        foregroundColor: AppColors.headerForeground,
        iconTheme: const IconThemeData(color: AppColors.headerForeground),
        actionsIconTheme: const IconThemeData(color: AppColors.headerForeground),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: _pageTitleStyle(
          baseStyle: _textTheme(colorScheme).headlineSmall!,
          color: AppColors.headerForeground,
        ),
      ),
      inputDecorationTheme: _inputTheme(
        colorScheme,
      ).copyWith(fillColor: const Color(0xFF2A2A2A)),
      listTileTheme: ListTileThemeData(
        titleTextStyle: _bookNameStyle(colorScheme),
        subtitleTextStyle: _textTheme(colorScheme).bodyMedium?.copyWith(
          color: Colors.white70,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _pillButtonStyle(
          background: colorScheme.primary,
          foreground: colorScheme.onPrimary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _pillButtonStyle(
          background: colorScheme.secondary,
          foreground: colorScheme.onSecondary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _pillButtonStyle(
          background: Colors.transparent,
          foreground: Colors.white,
          side: const BorderSide(color: Colors.white70, width: 1.2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _pillButtonStyle(
          background: Colors.transparent,
          foreground: Colors.white,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.all(10),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
