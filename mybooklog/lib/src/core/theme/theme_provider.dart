import 'package:flutter/material.dart';

//One step needed in Xcode (can't be done here since the .pbxproj is not in the repo):
//Open ios/Runner.xcworkspace in Xcode
//Select the Runner target → General → App Icons Source
//Change it to AppIcon (pointing at the new asset catalog)

/// Remembers whether the app is currently in light mode or dark mode.
///
/// It "notifies" the rest of the app whenever the choice changes, which makes
/// every screen instantly re-draw in the new colors. Note: the choice
/// currently lives only in memory — it resets to light mode every time the
/// app is restarted (see the recommendations doc about persisting it).
class ThemeProvider extends ChangeNotifier {
  // The current choice. The app starts in light mode.
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

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
}
