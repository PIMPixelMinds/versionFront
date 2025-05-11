import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pim/core/constants/api_constants.dart';

class NotificationFirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<RemoteMessage> notifications = [];

  Future<String?> getFcmToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print("❌ Error getting FCM token: $e");
      return null;
    }
  }

  Future<void> initNotifications(String fullName, String historiqueId) async {
    // Request notification permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Check authorization status
    final settings = await _firebaseMessaging.getNotificationSettings();
    print("📜 Notification settings: $settings");

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? fcmToken;
      try {
        if (Platform.isIOS) {
          // Wait for APNs token with a timeout
          String? apnsToken;
          const maxRetries = 10;
          const retryDelay = Duration(seconds: 1);
          for (int i = 0; i < maxRetries; i++) {
            apnsToken = await _firebaseMessaging.getAPNSToken();
            if (apnsToken != null) {
              print("✅ APNs token received: $apnsToken");
              break;
            }
            print("⏳ Waiting for APNs token... ($i/$maxRetries)");
            await Future.delayed(retryDelay);
          }
          if (apnsToken == null) {
            print("❌ APNs token not available after $maxRetries retries.");
            return;
          }
        }
        fcmToken = await getFcmToken();
        print("✅ FCM Token: $fcmToken");

        if (fcmToken != null) {
          await sendFcmTokenToBackend(fullName, fcmToken);
          await sendAuthFcmTokenToBackend(fullName, fcmToken);
          await sendBodyFcmTokenToBackend(historiqueId, fcmToken);
        }
      } catch (e) {
        print("❌ Error initializing notifications: $e");
      }

      // Handle token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        print("🔄 Refreshed FCM Token: $newToken");
        await sendFcmTokenToBackend(fullName, newToken);
        await sendAuthFcmTokenToBackend(fullName, newToken);
        await sendBodyFcmTokenToBackend(historiqueId, newToken);
      });
    } else {
      print("❌ Notifications not authorized.");
    }

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ms_logo');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) async {
      print("🔔 New notification received: ${message.notification?.body}");
      print("🕒 Received at: ${DateTime.now()}");

      await _showNotification(
        message.notification?.title,
        message.notification?.body,
      );

      notifications.add(message);
    });
  }

  Future<void> _showNotification(String? title, String? body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pim-msaware',
      'PIM-MSAware',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ms_logo',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    int uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _flutterLocalNotificationsPlugin.show(
      uniqueId,
      title,
      body,
      platformDetails,
      payload: 'notification_payload_$uniqueId',
    );
  }

  // Appointment Notifications
  Future<void> sendFcmTokenToBackend(String fullName, String fcmToken) async {
    final url = Uri.parse(ApiConstants.updateFcmTokenEndpoint);
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"fullName": fullName, "fcmToken": fcmToken}),
      );
      print("📤 Sent appointement FCM token to backend: ${response.statusCode}");
    } catch (e) {
      print("❌ Error sending FCM token to backend: $e");
    }
  }


  // Quiz Event Notifications
  Future<void> sendAuthFcmTokenToBackend(String fullName, String fcmToken) async {
    final url = Uri.parse(ApiConstants.updateAuthFcmTokenEndpoint);
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"fullName": fullName, "fcmToken": fcmToken}),
      );
      print("📤 Sent auth FCM token to backend: ${response.statusCode}");
    } catch (e) {
      print("❌ Error sending auth FCM token to backend: $e");
    }
  }

  // Body Alert Notifications
  Future<void> sendBodyFcmTokenToBackend(String historiqueId, String fcmToken) async {
    final url = Uri.parse(ApiConstants.updateHistoriqueFcmTokenEndpoint);
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"historiqueId": historiqueId, "fcmToken": fcmToken}),
      );
      print("📤 Sent body FCM token to backend: ${response.statusCode}");
    } catch (e) {
      print("❌ Error sending body FCM token to backend: $e");
    }
  }
}