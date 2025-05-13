import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pim/core/constants/api_constants.dart';
import 'package:pim/main.dart'; // Ensure you have a navigatorKey setup in your main.dart

class NotificationFirebaseApi {
  static final NotificationFirebaseApi _instance =
      NotificationFirebaseApi._internal();
  factory NotificationFirebaseApi() => _instance;
  NotificationFirebaseApi._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final List<RemoteMessage> _notifications = [];
  bool _isInitialized = false;

  Future<String?> getFcmToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print("❌ Error getting FCM token: $e");
      return null;
    }
  }

  Future<void> initNotifications(String authId, String historiqueId) async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _firebaseMessaging.requestPermission(
        alert: true, badge: true, sound: true);
    final settings = await _firebaseMessaging.getNotificationSettings();
    print("📜 Notification settings: $settings");

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? fcmToken;
      try {
        if (Platform.isIOS) {
          const maxRetries = 10;
          const retryDelay = Duration(seconds: 1);
          String? apnsToken;
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
          await sendFcmTokenToBackend(authId, fcmToken);
          await sendAuthFcmTokenToBackend(authId, fcmToken);
          await sendBodyFcmTokenToBackend(historiqueId, fcmToken);
        }

        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          print("🔄 Refreshed FCM Token: $newToken");
          await sendFcmTokenToBackend(authId, newToken);
          await sendAuthFcmTokenToBackend(authId, newToken);
          await sendBodyFcmTokenToBackend(historiqueId, newToken);
        });
      } catch (e) {
        print("❌ Error initializing notifications: $e");
      }
    } else {
      print("❌ Notifications not authorized.");
    }

    await _setupInteractionHandlers();
    await _initializeLocalNotifications();
    _listenToForegroundMessages();
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@drawable/ms_logo');

    final DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  void _listenToForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) async {
      final title = message.notification?.title ?? "";
      final body = message.notification?.body ?? "";
      final data = message.data;
      final screen =
          data['screen']; // Extract the screen name from the notification data

      print("🔔 Foreground Notification: $title - $body");

      bool isDuplicate = _notifications.any((existing) =>
          (existing.data['messageId'] == data['messageId'] &&
              data['messageId'].isNotEmpty) ||
          (existing.notification?.title == title &&
              existing.notification?.body == body &&
              DateTime.now()
                      .difference(existing.sentTime ?? DateTime.now())
                      .inMinutes <
                  5));

      if (!isDuplicate) {
        _notifications.add(message);
        await _showNotification(title, body, screen);
      } else {
        print("⛔️ Duplicate notification ignored.");
      }
    });
  }

  Future<void> _showNotification(
      String? title, String? body, String? screen) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pim-msaware',
      'PIM-MSAware',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ms_logo',
    );

const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    int uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _flutterLocalNotificationsPlugin.show(
      uniqueId,
      title,
      body,
      platformDetails,
      payload:
          jsonEncode({'screen': screen}), // Pass the screen name in the payload
    );
  }

  Future<void> _setupInteractionHandlers() async {
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNavigation);

    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigation(initialMessage);
    }
  }

  void _handleNavigation(RemoteMessage message) {
    final screen = message.data['screen'];
    print("🔗 Navigating to screen: $screen");

    if (screen != null) {
      navigatorKey.currentState
          ?.pushNamed('/$screen'); // Navigate to the specified screen
    }
  }

  Future<void> sendFcmTokenToBackend(String userId, String fcmToken) async {
    final url = Uri.parse(ApiConstants.updateFcmTokenEndpoint);
    await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId, "fcmToken": fcmToken}),
    );
  }

  Future<void> sendAuthFcmTokenToBackend(
      String fullName, String fcmToken) async {
    final url = Uri.parse(ApiConstants.updateAuthFcmTokenEndpoint);
    await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"fullName": fullName, "fcmToken": fcmToken}),
    );
  }

  Future<void> sendBodyFcmTokenToBackend(String authId, String fcmToken) async {
    final url = Uri.parse(ApiConstants.updateHistoriqueFcmTokenEndpoint);
    await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"authId": authId, "fcmToken": fcmToken}),
    );
  }
}
