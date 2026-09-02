import 'package:flutter/material.dart';

import 'app_colors.dart';

//One step needed in Xcode (can't be done here since the .pbxproj is not in the repo):
//Open ios/Runner.xcworkspace in Xcode
//Select the Runner target → General → App Icons Source
//Change it to AppIcon (pointing at the new asset catalog)

/// The accent color schemes a user can pick from. Adding a new one is just
/// a new case here plus a color in [AppColors] — [AppTheme.lightTheme] and
/// [AppTheme.darkTheme] derive everything else from whichever seed color
/// this resolves to.
enum AppThemeColor {
  sage('Sage', AppColors.accentSage),
  blue('Blue', AppColors.accentBlue);

  const AppThemeColor(this.label, this.seedColor);

  final String label;
  final Color seedColor;
}

/// Remembers the user's chosen look: light/dark mode, and which accent color
/// scheme is active.
///
/// It "notifies" the rest of the app whenever either choice changes, which
/// makes every screen instantly re-draw in the new colors. Note: the choice
/// currently lives only in memory — it resets to light mode/the default
/// accent every time the app is restarted (see the recommendations doc
/// about persisting it).
class ThemeProvider extends ChangeNotifier {
  // The current choices. The app starts in light mode with the default
  // (Sage) accent.
  ThemeMode _themeMode = ThemeMode.light;
  AppThemeColor _themeColor = AppThemeColor.sage;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  AppThemeColor get themeColor => _themeColor;

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

  /// Switches the accent color scheme. Does nothing if it's already active.
  void setThemeColor(AppThemeColor color) {
    if (_themeColor == color) return;
    _themeColor = color;
    notifyListeners();
  }
}
