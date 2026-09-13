import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

//One step needed in Xcode (can't be done here since the .pbxproj is not in the repo):
//Open ios/Runner.xcworkspace in Xcode
//Select the Runner target → General → App Icons Source
//Change it to AppIcon (pointing at the new asset catalog)

/// The accent color schemes a user can pick from. Adding a new one is just
/// a new case here plus a color in [AppColors] — [AppTheme.lightTheme] and
/// [AppTheme.darkTheme] derive everything else from whichever seed color
/// this resolves to.
///
/// Each case's identifier (via `.name`) doubles as its persisted value in
/// [ThemeProvider] — keep it in sync with the case name if you rename one.
enum AppThemeColor {
  sage('Sage', AppColors.accentSage),
  indigo('Indigo', AppColors.accentIndigo),
  terracotta('Terracotta', AppColors.accentTerracotta);

  const AppThemeColor(this.label, this.seedColor);

  final String label;
  final Color seedColor;
}

/// Remembers the user's chosen look: light/dark mode, and which accent color
/// scheme is active.
///
/// It "notifies" the rest of the app whenever either choice changes, which
/// makes every screen instantly re-draw in the new colors. The color choice
/// is persisted (via [SharedPreferences]) so it survives an app restart;
/// light/dark mode is not yet exposed anywhere in the UI, so it still lives
/// only in memory — no user-visible behavior would change by persisting it.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider({SharedPreferences? prefs}) : _prefs = prefs {
    _themeColor = _loadThemeColor();
  }

  static const _themeColorPrefsKey = 'theme_color';

  // Null in contexts that don't care about persistence (e.g. most widget
  // tests) — the provider still works, it just doesn't remember anything.
  final SharedPreferences? _prefs;

  // The current choices. The app starts in light mode; the accent color
  // starts at whatever was last saved, or Sage if nothing was saved yet.
  ThemeMode _themeMode = ThemeMode.light;
  late AppThemeColor _themeColor;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  AppThemeColor get themeColor => _themeColor;

  AppThemeColor _loadThemeColor() {
    final savedName = _prefs?.getString(_themeColorPrefsKey);
    return AppThemeColor.values.firstWhere(
      (color) => color.name == savedName,
      orElse: () => AppThemeColor.sage,
    );
  }

  /// Switches to a specific mode (light or dark). Does nothing if the app is
  /// already in that mode, to avoid pointless screen redraws.
  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners(); // tell every listening screen to repaint
  }

  /// Flips between light and dark, whichever is the opposite of now.
  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  /// Switches the accent color scheme and remembers the choice for next
  /// time. Does nothing if it's already active.
  void setThemeColor(AppThemeColor color) {
    if (_themeColor == color) return;
    _themeColor = color;
    _prefs?.setString(_themeColorPrefsKey, color.name);
    notifyListeners();
  }
}
