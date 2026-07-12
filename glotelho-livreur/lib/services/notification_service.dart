import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/delivery_request_model.dart';

/// Service d'affichage des notifications locales.
/// Abstrait la source : aujourd'hui déclenché localement, demain par Firebase.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Callback appelé quand l'utilisateur tape la notification.
  static void Function(DeliveryRequestModel request)? onRequestTapped;

  static const String _channelId = 'delivery_requests';
  static const String _channelName = 'Demandes de livraison';

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onTap,
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifications des nouvelles courses assignées',
      importance: Importance.max,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> showDeliveryRequest(DeliveryRequestModel request) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Nouvelle course assignée',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        '${request.clientNom} · ${request.adresseLivraison}\n'
            'Frais : ${request.fraisLivraison.toStringAsFixed(0)} XAF',
        contentTitle: '🛵 Nouvelle livraison',
      ),
    );
    final details = NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails());

    await _plugin.show(
      request.id.hashCode,
      '🛵 Nouvelle livraison',
      '${request.clientNom} · ${request.fraisLivraison.toStringAsFixed(0)} XAF',
      details,
      payload: jsonEncode(request.toJson()),
    );
  }

  static void _onTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final request = DeliveryRequestModel.fromJson(jsonDecode(response.payload!));
      onRequestTapped?.call(request);
    } catch (_) {}
  }
}