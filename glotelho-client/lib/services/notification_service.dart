import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service centralisant l'affichage de vraies notifications système
/// (visibles même si l'app est en arrière-plan), via flutter_local_notifications.
///
/// IMPORTANT : ceci reste une notification LOCALE déclenchée par le téléphone
/// du client lui-même (ici, quand la simulation de suivi atteint 100%).
/// Pour qu'une notification arrive même quand l'app est totalement fermée et
/// déclenchée par le SERVEUR (ex: le livreur valide l'arrivée sur son app),
/// il faudra brancher Firebase Cloud Messaging (FCM) côté backend, qui enverra
/// un push au `fcm_token` de l'utilisateur (déjà présent dans UserModel).
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// À appeler une fois, au démarrage de l'app (ex: dans main.dart ou
  /// dans initState() de SplashScreen).
  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings);

    // Demande explicite des permissions Android 13+ (POST_NOTIFICATIONS).
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> showDeliveryArrived({required String title, required String body}) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'delivery_tracking', // id du canal
      'Suivi de livraison', // nom du canal (visible dans les réglages Android)
      channelDescription: 'Notifications liées au suivi de vos livraisons en temps réel',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // id unique
      title,
      body,
      details,
    );
  }
}