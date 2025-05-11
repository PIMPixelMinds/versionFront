import 'package:flutter/material.dart';
import 'package:pim/data/model/notification_model.dart';
import 'package:pim/data/repositories/notification_repository.dart';
import '../data/repositories/shared_prefs_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();

  bool isLoading = false;
  String? errorMessage;
  List<Notifications> notifications = [];

  Future<void> fetchNotifications() async {
    isLoading = true;
    notifyListeners();
    final SharedPrefsService _prefsService = SharedPrefsService();
    final token = await _prefsService.getAccessToken();
    try {
      final data = await _repository.displayNotifications(token!);
      notifications = (data['notification'] as List)
          .map((item) => Notifications.fromJson(item))
          .toList();
      errorMessage = '';
    } catch (error) {
      errorMessage = error.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> deleteAllNotifications() async {
    final SharedPrefsService _prefsService = SharedPrefsService();
    final token = await _prefsService.getAccessToken();
    try {
      await _repository.deleteAllNotifications(token!);
      notifications.clear();
      notifyListeners();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }
}
