import 'dart:async';
import 'package:dio/dio.dart';
import '../config/app_state.dart';
import '../config/app_config.dart';

/// Service de polling global — tourne en arrière-plan toutes les 30 secondes.
/// Ne tourne QUE si l'utilisateur est authentifié ET que le polling a été
/// explicitement démarré après la connexion (pas au démarrage de l'app).
class CommercantPollingService {
  static Timer? _timer;
  static final Set<int> _notifiedIds = {};
  static void Function(String message)? onNewNotification;
  static bool _running = false;
  static bool _started = false; // true uniquement après connexion explicite

  /// À appeler après connexion réussie — PAS dans main() ni dans build()
  static Future<void> start(AppState appState) async {
    if (!appState.isAuthenticated) return;
    if (_running && _timer != null) return;
    _started = true;
    stop();
    _running = true;
    // Délai de 2 secondes avant le premier poll
    // pour laisser le temps à l'UI de naviguer vers la page d'accueil
    await Future.delayed(const Duration(seconds: 2));
    if (!appState.isAuthenticated || !_started) return;
    await _poll(appState);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _poll(appState));
  }

  /// À appeler à la déconnexion
  static void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    _started = false;
    _notifiedIds.clear();
  }

  static Future<void> _poll(AppState appState) async {
    if (!appState.isAuthenticated || !_started) {
      stop();
      return;
    }
    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl + '/',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Authorization': 'Bearer ${appState.authToken}'},
      ));
      final res = await dio.get('notifications');
      final List data = res.data ?? [];
      for (final n in data) {
        final nId = n['id'] as int;
        final isRead = n['is_read'] == 1 || n['is_read'] == true;
        if (!isRead && !_notifiedIds.contains(nId)) {
          _notifiedIds.add(nId);
          onNewNotification?.call(n['message']?.toString() ?? 'Nouvelle notification');
        }
      }
    } catch (_) {}
  }
}