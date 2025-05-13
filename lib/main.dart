import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pim/core/utils/medication_notification_helper.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'core/utils/locale_provider.dart';
import 'core/utils/theme_provider.dart';
import 'core/utils/notification_provider.dart'; // NEW

import 'view/home/splash_screen.dart';
import 'view/home/check_login_page.dart';
import 'view/home/home_page.dart';

import 'view/auth/login_page.dart';
import 'view/auth/register_page.dart';
import 'view/auth/password_security_page.dart';
import 'view/auth/perso_information_page.dart';
import 'view/auth/medical_history_page.dart';
import 'view/auth/primary_caregiver_page.dart';
import 'view/auth/profile_page.dart';

import 'view/appointment/add_appointment.dart';
import 'view/appointment/appointment_view.dart';
import 'view/appointment/notification_page.dart';

import 'view/medication/add_medication_screen.dart';
import 'view/medication/medication_home_screen.dart';
import 'view/medication/medication_detail_screen.dart';
import 'view/medication/medication_notification_screen.dart';

import 'view/notifications/notification_firebase_api.dart';
import 'view/tracking_log/HealthTrackerPage.dart';
import 'view/tracking_log/health_page.dart';

import 'viewmodel/auth_viewmodel.dart';
import 'viewmodel/appointment_viewmodel.dart';
import 'viewmodel/healthTracker_viewmodel.dart';
import 'viewmodel/medication_viewmodel.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }
  debugPrint(
      "📥 [BG] Message: ${message.notification?.title} - ${message.notification?.body}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      debugPrint("✅ Firebase initialized");
    }
  } catch (e) {
    debugPrint("❌ Firebase init failed: $e");
  }

  await _setupNotifications();

  final appointmentViewModel = AppointmentViewModel();
  await appointmentViewModel.fetchMyAppointmentUserId();
  final userId = appointmentViewModel.userId;

  final authViewModel = AuthViewModel();

  // Ensure you await the result of fetchMyUserId
  await authViewModel.fetchMyUserId();

  // Now that the async operation has completed, get the authId
  final authId = authViewModel.authId;
  print("authId is: $authId");

  print("User Id is : $userId");
  print("Auth ID is : $authId");
  await NotificationFirebaseApi().initNotifications(authId.toString(), 'notif');

  final localeProvider = LocaleProvider();
  await localeProvider.loadLocaleFromPreferences();

  final themeProvider = ThemeProvider();
  await themeProvider.loadThemeMode();

  final notificationProvider = NotificationProvider();
  await notificationProvider.loadNotificationsPreference();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => AppointmentViewModel()),
        ChangeNotifierProvider(create: (_) => MedicationViewModel()),
        ChangeNotifierProvider(create: (_) => HealthTrackerViewModel()),
        ChangeNotifierProvider(create: (_) => localeProvider),
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (_) => notificationProvider), // NEW
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _setupNotifications() async {
  // 🔔 Init locale notifications (medication alerts, etc.)
  await MedicationNotificationHelper.initialize();

  // 🔙 Background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 🔊 Foreground presentation
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // 📢 Android channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'health_channel',
    'Health Notifications',
    description: 'Notifications for health predictions',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // ⚙️ Init settings
  const InitializationSettings initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    ),
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // 🔐 Demander permission iOS
  final iosImpl =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
  final granted = await iosImpl?.requestPermissions(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint("🔐 iOS notification permission granted: $granted");

  // 🔔 Foreground message handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notificationProvider =
        navigatorKey.currentContext?.read<NotificationProvider>();

    if (notificationProvider?.notificationsEnabled == true &&
        message.notification != null) {
      flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification!.title,
        message.notification!.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      themeMode: themeProvider.themeMode,
      locale: localeProvider.locale,
      supportedLocales: const [Locale('en'), Locale('fr')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primaryBlue,
        fontFamily: 'Montserrat',
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // ✅ Fond blanc
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primaryBlue,
        fontFamily: 'Montserrat',
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/checkLogin': (context) => const CheckLoginPage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => const HomePage(),
        '/passwordSecurity': (context) => const PasswordSecurityPage(),
        '/personalInformation': (context) => const PersonalInformationPage(),
        '/medicalHistory': (context) => const MedicalHistoryPage(),
        '/primaryCaregiver': (context) => const PrimaryCaregiverPage(),
        '/addAppointment': (context) => const AddAppointmentSheet(),
        '/displayAppointment': (context) => const AppointmentPage(),
        '/notification_screen': (context) => const NotificationPage(),
        '/medications': (context) => const MedicationHomeScreen(),
        '/add_medication': (context) => AddMedicationScreen(),
        '/medication_notifications': (context) =>
            const MedicationNotificationScreen(),
        '/medication_detail': (context) => MedicationDetailScreen(
            medicationId: ModalRoute.of(context)!.settings.arguments as String),
        '/profile': (context) => const ProfilePage(),
        '/healthPage': (context) => HealthPage(),
        '/HealthTrack': (context) => HealthTrackerPage(),
      },
    );
  }
}
