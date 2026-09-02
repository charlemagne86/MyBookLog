/// Unit tests for [ThemeProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/core/theme/theme_provider.dart';

void main() {
  group('ThemeProvider', () {
    test('starts in light mode with the Sage accent', () {
      final provider = ThemeProvider();

      expect(provider.themeMode, ThemeMode.light);
      expect(provider.isDarkMode, isFalse);
      expect(provider.themeColor, AppThemeColor.sage);
    });

    test('setThemeMode notifies listeners when the mode actually changes', () {
      final provider = ThemeProvider();
      var notified = 0;
      provider.addListener(() => notified++);

      provider.setThemeMode(ThemeMode.dark);

      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDarkMode, isTrue);
      expect(notified, 1);
    });

    test('setThemeMode is a no-op when already in that mode', () {
      final provider = ThemeProvider();
      var notified = 0;
      provider.addListener(() => notified++);

      provider.setThemeMode(ThemeMode.light);

      expect(notified, 0);
    });

    test('toggleTheme flips between light and dark', () {
      final provider = ThemeProvider();

      provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.dark);

      provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.light);
    });

    test('setThemeColor notifies listeners when the color actually changes', () {
      final provider = ThemeProvider();
      var notified = 0;
      provider.addListener(() => notified++);

      provider.setThemeColor(AppThemeColor.blue);

      expect(provider.themeColor, AppThemeColor.blue);
      expect(notified, 1);
    });

    test('setThemeColor is a no-op when already that color', () {
      final provider = ThemeProvider();
      var notified = 0;
      provider.addListener(() => notified++);

      provider.setThemeColor(AppThemeColor.sage);

      expect(notified, 0);
    });
  });

  group('AppThemeColor', () {
    test('every option has a distinct seed color', () {
      final seedColors = AppThemeColor.values.map((c) => c.seedColor).toSet();
      expect(seedColors.length, AppThemeColor.values.length);
    });
  });
}
