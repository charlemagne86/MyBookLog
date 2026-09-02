/// Unit tests for [ThemeProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeProvider', () {
    test('starts in light mode with the Sage accent when nothing is saved', () {
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

    test(
      'setThemeColor notifies listeners when the color actually changes',
      () {
        final provider = ThemeProvider();
        var notified = 0;
        provider.addListener(() => notified++);

        provider.setThemeColor(AppThemeColor.slate);

        expect(provider.themeColor, AppThemeColor.slate);
        expect(notified, 1);
      },
    );

    test('setThemeColor is a no-op when already that color', () {
      final provider = ThemeProvider();
      var notified = 0;
      provider.addListener(() => notified++);

      provider.setThemeColor(AppThemeColor.sage);

      expect(notified, 0);
    });

    group('persistence', () {
      test('with no prefs given, the choice just isn\'t remembered', () {
        final provider = ThemeProvider();
        provider.setThemeColor(AppThemeColor.slate);
        // A fresh provider with no store still starts at the default —
        // nothing to load from, and nothing should throw either.
        expect(ThemeProvider().themeColor, AppThemeColor.sage);
      });

      test('loads a previously-saved color on construction', () async {
        SharedPreferences.setMockInitialValues({'theme_color': 'slate'});
        final prefs = await SharedPreferences.getInstance();

        final provider = ThemeProvider(prefs: prefs);

        expect(provider.themeColor, AppThemeColor.slate);
      });

      test('falls back to Sage when the saved value is unrecognized', () async {
        SharedPreferences.setMockInitialValues({
          'theme_color': 'not_a_real_theme',
        });
        final prefs = await SharedPreferences.getInstance();

        final provider = ThemeProvider(prefs: prefs);

        expect(provider.themeColor, AppThemeColor.sage);
      });

      test('setThemeColor saves the choice for the next instance', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        ThemeProvider(prefs: prefs).setThemeColor(AppThemeColor.slate);

        expect(prefs.getString('theme_color'), 'slate');
        // A brand-new provider reading the same store picks it up.
        expect(ThemeProvider(prefs: prefs).themeColor, AppThemeColor.slate);
      });
    });
  });

  group('AppThemeColor', () {
    test('every option has a distinct seed color', () {
      final seedColors = AppThemeColor.values.map((c) => c.seedColor).toSet();
      expect(seedColors.length, AppThemeColor.values.length);
    });
  });
}
