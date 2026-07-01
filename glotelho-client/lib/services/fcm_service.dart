import 'package:firebase_messaging/firebase_messaging.dart';
import '../controllers/auth_controller.dart';
import 'notification_service.dart';

/// Gère l'intégration Firebase Cloud Messaging (FCM) :
/// - récupère le token unique de l'appareil
/// - l'envoie au backend (pour que le serveur puisse pousser des
///   notifications même app fermée)
/// - écoute les notifications reçues quand l'app est ouverte (foreground)
///   et les affiche via NotificationService (flutter_local_notifications)
///
/// PRÉREQUIS AVANT UTILISATION :
/// 1. Créer un projet Firebase (console.firebase.google.com)
/// 2. Lancer `flutterfire configure` à la racine du projet Flutter
///    (génère lib/firebase_options.dart + google-services.json / GoogleService-Info.plist)
/// 3. Appeler `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
///    dans main.dart AVANT FcmService.init()
/// 4. Côté backend : exposer PATCH /auth/fcm-token (déjà prévu dans AuthController.updateFcmToken)
///    et déclencher l'envoi du push via l'API FCM (HTTP v1) quand le statut
///    d'une commande passe à "arrivé".
class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _cachedToken;

  /// À appeler une seule fois au démarrage de l'app (après Firebase.initializeApp()).
  static Future<void> init() async {
    // Demande la permission d'envoyer des notifications (obligatoire sur iOS,
    // et recommandé sur Android 13+ — flutter_local_notifications gère déjà
    // la demande Android, FirebaseMessaging gère le reste).
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Notification reçue alors que l'app est OUVERTE (foreground) :
    // FCM ne l'affiche pas tout seul dans ce cas, il faut l'afficher nous-mêmes.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;
      if (notif != null) {
        NotificationService.showDeliveryArrived(
          title: notif.title ?? 'Glotelho Express',
          body: notif.body ?? '',
        );
      }
    });

    // Si le token change (réinstallation, changement d'appareil...),
    // on le renvoie automatiquement au backend.
    _messaging.onTokenRefresh.listen((newToken) {
      _cachedToken = newToken;
      _sendTokenToBackend(newToken);
    });
  }

  /// Récupère le token FCM de cet appareil et l'envoie au backend.
  /// À appeler juste après une connexion réussie (voir LoginScreen).
  static Future<void> registerTokenWithBackend() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      _cachedToken = token;
      await _sendTokenToBackend(token);
    } catch (_) {
      // Échec silencieux : l'app reste utilisable sans notifications push,
      // seules les notifications locales (in-app + flutter_local_notifications)
      // resteront actives.
    }
  }

  static Future<void> _sendTokenToBackend(String token) async {
    await AuthController.updateFcmToken(fcmToken: token);
  }

  static String? get cachedToken => _cachedToken;
}

/// Handler appelé par le système quand une notification FCM arrive alors que
/// l'app est COMPLÈTEMENT FERMÉE ou en arrière-plan. Doit être une fonction
/// top-level (pas une méthode de classe) et annotée @pragma comme ci-dessous.
/// À enregistrer dans main.dart via :
///   FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  // Rien à faire ici : sur Android/iOS, le système affiche automatiquement
  // la notification "notification" envoyée par FCM même app fermée.
  // Ce handler sert seulement si on veut exécuter du code additionnel
  // (ex: mettre à jour un cache local) en arrière-plan.
}