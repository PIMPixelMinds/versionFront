import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  Future<void> loadLocaleFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('preferred_language');

    if (languageCode != null && languageCode.isNotEmpty) {
      _locale = Locale(languageCode);
    } else {
      _locale = null;  // fallback: system language
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_language', locale.languageCode);
  }
}
