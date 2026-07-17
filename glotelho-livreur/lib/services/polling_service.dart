import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/tracking_service.dart';
import '../models/delivery_model.dart';

/// Service de polling — vérifie toutes les 30 secondes les nouvelles courses.
/// Affiche une notification locale si une nouvelle course assignée apparaît.
class PollingService {
  static Timer? _timer;
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  // IDs des courses déjà notifiées (pour éviter les doublons)
  static final Set<String> _notifiedIds = {};

  static const _channelId   = 'glotelho_courses';
  static const _channelName = 'Courses & Livraisons';

  /// Démarre le polling. Appeler après connexion.
  static Future<void> start() async {
    await _setupChannel();
    stop(); // arrête un éventuel timer existant
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _poll());
    _poll(); // première vérification immédiate
  }

  /// Arrête le polling. Appeler à la déconnexion.
  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _setupChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifications des courses et livraisons Glotelho',
      importance: Importance.max,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _poll() async {
    try {
      final courses = await TrackingService.getTodayDeliveries();
      for (final course in courses) {
        // Notifie les nouvelles courses assignées
        if (course.status == DeliveryStatus.assigned && !_notifiedIds.contains(course.id)) {
          _notifiedIds.add(course.id);
          await _notifier(
            id: course.id.hashCode,
            titre: '🛵 Nouvelle course assignée !',
            corps: '${course.clientNom} · ${course.adresseLivraison}',
            bigText: '${course.clientNom}\n${course.adresseLivraison}\n'
                'Montant : ${course.montant.toStringAsFixed(0)} XAF',
          );
        }

        // Notifie le démarrage d'une course (statut En_cours)
        if (course.status == DeliveryStatus.inProgress &&
            !_notifiedIds.contains('start_${course.id}')) {
          _notifiedIds.add('start_${course.id}');
          await _notifier(
            id: 'start_${course.id}'.hashCode,
            titre: '🚀 Course démarrée',
            corps: 'La course #${course.id} est en cours.',
            bigText: 'Client : ${course.clientNom}\nAdresse : ${course.adresseLivraison}',
          );
        }
      }
    } catch (_) {}
  }

  static Future<void> _notifier({
    required int id,
    required String titre,
    required String corps,
    required String bigText,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Notifications Glotelho',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(bigText, contentTitle: titre),
      playSound: true,
    );
    await _plugin.show(
      id,
      titre,
      corps,
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
    );
  }
}