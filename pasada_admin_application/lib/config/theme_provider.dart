import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'palette.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Palette.lightPrimary,
      scaffoldBackgroundColor: Palette.lightBackground,
      cardColor: Palette.lightCard,
      dividerColor: Palette.lightDivider,
      colorScheme: ColorScheme.light(
        primary: Palette.lightPrimary,
        secondary: Palette.lightSecondary,
        surface: Palette.lightSurface,
        error: Palette.lightError,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Palette.lightText,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Palette.lightText),
        bodyMedium: TextStyle(color: Palette.lightText),
        titleLarge: TextStyle(color: Palette.lightText),
        titleMedium: TextStyle(color: Palette.lightText),
        titleSmall: TextStyle(color: Palette.lightText),
      ),
      iconTheme: IconThemeData(color: Palette.lightText),
      appBarTheme: AppBarTheme(
        backgroundColor: Palette.lightSurface,
        foregroundColor: Palette.lightText,
        elevation: 0,
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Palette.darkPrimary,
      scaffoldBackgroundColor: Palette.darkBackground,
      cardColor: Palette.darkCard,
      dividerColor: Palette.darkDivider,
      colorScheme: ColorScheme.dark(
        primary: Palette.darkPrimary,
        secondary: Palette.darkSecondary,
        surface: Palette.darkSurface,
        error: Palette.darkError,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Palette.darkText,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Palette.darkText),
        bodyMedium: TextStyle(color: Palette.darkText),
        titleLarge: TextStyle(color: Palette.darkText),
        titleMedium: TextStyle(color: Palette.darkText),
        titleSmall: TextStyle(color: Palette.darkText),
      ),
      iconTheme: IconThemeData(color: Palette.darkText),
      appBarTheme: AppBarTheme(
        backgroundColor: Palette.darkSurface,
        foregroundColor: Palette.darkText,
        elevation: 0,
      ),
    );
  }

  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;
}
