import 'package:flutter/material.dart';

//One step needed in Xcode (can't be done here since the .pbxproj is not in the repo):
//Open ios/Runner.xcworkspace in Xcode
//Select the Runner target → General → App Icons Source
//Change it to AppIcon (pointing at the new asset catalog)

/// Centralized theme mode state for app-wide switching.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
