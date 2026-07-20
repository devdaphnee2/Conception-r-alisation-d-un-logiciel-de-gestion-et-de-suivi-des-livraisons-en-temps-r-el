import 'dart:async';
import 'package:dio/dio.dart';
import '../config/app_state.dart';

/// Service de polling global — tourne en arrière-plan toutes les 30 secondes.
/// Vérifie les nouvelles notifications et déclenche un callback.
class CommercantPollingService {
  static Timer? _timer;
  static final Set<int> _notifiedIds = {};
  static void Function(String message)? onNewNotification;

  static Future<void> start(AppState appState) async {
    stop();
    _poll(appState); // première vérification immédiate
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _poll(appState));
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _poll(AppState appState) async {
    if (!appState.isAuthenticated) return;
    try {
      final dio = Dio(BaseOptions(

        

        baseUrl: 'http://localhost:5000/api
        
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: { 'Authorization': 'Bearer ${appState.authToken}' },
      ));
      final res  = await dio.get('/notifications');
      final List data = res.data ?? [];
      for (final n in data) {
        final nId   = n['id'] as int;
        final isRead = n['is_read'] == 1 || n['is_read'] == true;
        if (!isRead && !_notifiedIds.contains(nId)) {
          _notifiedIds.add(nId);
          onNewNotification?.call(n['message']?.toString() ?? 'Nouvelle notification');
        }
      }
    } catch (_) {}
  }
}