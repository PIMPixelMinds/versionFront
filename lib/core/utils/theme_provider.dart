import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    loadThemeMode();
  }

  Future<void> loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? mode = prefs.getString('theme_mode');

    if (mode == 'light') {
      _themeMode = ThemeMode.light;
    } else if (mode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }
}