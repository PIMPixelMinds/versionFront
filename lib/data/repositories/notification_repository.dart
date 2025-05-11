import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pim/core/constants/api_constants.dart';

class NotificationRepository {
  Future<Map<String, dynamic>> displayNotifications(String token) async {
    final url = Uri.parse(ApiConstants.displayNotifications);

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"] ??
          "Failed to fetch notifications");
    }
  }

  Future<void> deleteAllNotifications(String token) async {
    final url = Uri.parse(ApiConstants.deleteNotification);

    final response = await http.delete(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete notifications");
    }
  }
}
