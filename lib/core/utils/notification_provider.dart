import 'package:flutter/material.dart';
import '../../../data/repositories/shared_prefs_service.dart';

class NotificationProvider extends ChangeNotifier {
  final SharedPrefsService _prefsService = SharedPrefsService();

  bool _notificationsEnabled = true;

  bool get notificationsEnabled => _notificationsEnabled;

  // Load the saved value from SharedPrefsService
  Future<void> loadNotificationsPreference() async {
    _notificationsEnabled = await _prefsService.getNotificationsEnabled();
    notifyListeners();
  }

  // Update value and save it through SharedPrefsService
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    await _prefsService.setNotificationsEnabled(enabled);
  }
}
