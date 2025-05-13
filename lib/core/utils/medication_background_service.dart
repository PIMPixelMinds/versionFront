import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_background_service_ios/flutter_background_service_ios.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pim/core/utils/medication_notification_helper.dart';
import 'package:pim/data/model/medication_models.dart';
import 'package:pim/data/repositories/medication_repository.dart';
import 'package:pim/data/repositories/shared_prefs_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;

@pragma('vm:entry-point')
class MedicationBackgroundService {
  // Utiliser la même instance que MedicationNotificationHelper
  static FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin =>
      MedicationNotificationHelper.flutterLocalNotificationsPlugin;

  static final MedicationRepository _repository = MedicationRepository();
  static final SharedPrefsService _prefsService = SharedPrefsService();

  // Constantes pour le canal de notification du service
  static const String serviceChannelId = 'medication_service_channel';
  static const String serviceChannelName = 'Service de rappel de médicaments';
  static const String serviceChannelDesc =
      'Service qui gère les rappels de médicaments en arrière-plan';

  // Stocker les IDs des notifications déjà affichées pour éviter les doublons
  static final Set<int> _shownNotificationIds = {};

  @pragma('vm:entry-point')
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // S'assurer que les fuseaux horaires sont initialisés
    tz_init.initializeTimeZones();

    // Configuration Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      serviceChannelId,
      serviceChannelName,
      description: serviceChannelDesc,
      importance: Importance.high,
    );

    // Créer le canal de notification pour le service
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Configuration du service
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: serviceChannelId,
        initialNotificationTitle: serviceChannelName,
        initialNotificationContent: 'Service actif en arrière-plan',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    // Démarrer le service
    service.startService();

    print("Service d'arrière-plan de médicaments initialisé");
  }

  // Fonction appelée lorsque le service démarre
  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // S'assurer que les fuseaux horaires sont initialisés
    tz_init.initializeTimeZones();

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    // Vérifier les rappels toutes les minutes
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      await checkAndShowMedicationReminders(service);
    });

    // Vérifier immédiatement au démarrage du service
    await checkAndShowMedicationReminders(service);

    print("Service d'arrière-plan de médicaments démarré");
  }

  // Fonction pour iOS qui s'exécute en arrière-plan
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    // S'assurer que les fuseaux horaires sont initialisés
    tz_init.initializeTimeZones();

    return true;
  }

  // Fonction qui vérifie s'il y a des rappels à afficher
  @pragma('vm:entry-point')
  static Future<void> checkAndShowMedicationReminders(
      ServiceInstance service) async {
    try {
      // Récupérer le token d'authentification
      final token = await _prefsService.getAccessToken();
      if (token == null) {
        print("Token d'authentification non disponible");
        return;
      }

      // Récupérer la date actuelle
      final now = DateTime.now();
      print("Vérification des rappels à ${now.hour}:${now.minute}");

      // Récupérer les rappels pour aujourd'hui
      final reminders = await _repository.getRemindersForDate(now);
      print("${reminders.length} rappels trouvés pour aujourd'hui");

      // Filtrer les rappels qui doivent être affichés maintenant
      for (final reminder in reminders) {
        if (!reminder.isCompleted && !reminder.isSkipped) {
          final timeString = reminder.scheduledTime;
          final parts = timeString.split(':');

          if (parts.length == 2) {
            final hour = int.tryParse(parts[0]);
            final minute = int.tryParse(parts[1]);

            if (hour != null && minute != null) {
              final scheduledTime =
                  DateTime(now.year, now.month, now.day, hour, minute);

              // Créer un ID unique pour cette notification basé sur l'heure et l'ID du médicament
              final notificationId =
                  "${reminder.medicationId}_${hour}_${minute}".hashCode;

              // Vérifier si c'est l'heure exacte de la notification ou si nous avons raté une notification
              final bool isExactTime = now.hour == hour && now.minute == minute;
              final bool isMissedTime =
                  now.hour > hour || (now.hour == hour && now.minute > minute);

              print(
                  "Rappel pour ${reminder.medication.name} prévu à ${hour}:${minute}, heure exacte: $isExactTime, manqué: $isMissedTime");

              // Afficher la notification si c'est l'heure exacte ou si nous avons raté la notification
              // et qu'elle n'a pas encore été affichée
              if ((isExactTime || isMissedTime) &&
                  !_shownNotificationIds.contains(notificationId)) {
                print(
                    "Affichage de la notification pour ${reminder.medication.name}");

                // Ajouter l'ID à la liste des notifications affichées
                _shownNotificationIds.add(notificationId);

                // Utiliser directement la méthode showNotification au lieu de passer par le helper
                await _showDirectNotification(
                  id: notificationId,
                  title: 'Rappel de médicament',
                  body:
                      'Il est temps de prendre ${reminder.medication.name} (${reminder.medication.dosage})',
                );

                // Mettre à jour l'état du service
                if (service is AndroidServiceInstance) {
                  service.setForegroundNotificationInfo(
                    title: 'Rappel de médicament actif',
                    content: 'Rappel pour ${reminder.medication.name}',
                  );
                }
              }
            }
          }
        }
      }

      // Nettoyer les IDs de notification à minuit
      if (now.hour == 0 && now.minute == 0) {
        _shownNotificationIds.clear();
      }
    } catch (e) {
      print('Erreur lors de la vérification des rappels: $e');
    }
  }

  // Méthode pour afficher directement une notification sans passer par le helper
  @pragma('vm:entry-point')
  static Future<void> _showDirectNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      // Utiliser le canal de notification des médicaments défini dans le helper
      const androidDetails = AndroidNotificationDetails(
        MedicationNotificationHelper.medicationChannelId,
        MedicationNotificationHelper.medicationChannelName,
        channelDescription: MedicationNotificationHelper.medicationChannelDesc,
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('alarme'),
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        icon:
            '@mipmap/ic_launcher', // Utiliser l'icône par défaut de l'application
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: 'medication_$id',
      );

      print(
          "Notification affichée depuis le service d'arrière-plan: $title - $body");
    } catch (e) {
      print("Erreur lors de l'affichage de la notification: $e");
    }
  }
}
