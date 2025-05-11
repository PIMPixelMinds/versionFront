import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const _tokenKey = 'accessToken';
  static const _refreshTokenKey = 'refreshToken';
  static const _isLoggedInKey = 'isLoggedIn';
  static const _tokenCreationTimeKey = 'tokenCreationTime';
  static const _languageCodeKey = 'languageCode';
  static const _notificationsEnabledKey = 'notificationsEnabled'; // NEW

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setInt(_tokenCreationTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<int?> getTokenCreationTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_tokenCreationTimeKey);
  }

  // Language handling
  Future<void> saveLanguageCode(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, languageCode);
  }

  Future<String?> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageCodeKey);
  }

  // NEW: Notifications preference
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true; // default true
  }
}

