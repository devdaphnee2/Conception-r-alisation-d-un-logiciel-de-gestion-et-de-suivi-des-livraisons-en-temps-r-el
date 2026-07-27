import 'package:dio/dio.dart';
import '../config/app_state.dart';

class ApiService {
  final Dio dio;
  final AppState appState;

  // ⚠️ Pense à vérifier que 192.168.1.152 est bien l'IP actuelle de ton PC Debian
  static const String _baseUrl = 'http://10.229.165.203:5000/api';

  ApiService(this.appState)
      : dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = appState.authToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        // Log utile dans la console Flutter pour suivre les erreurs
        print('❌ [API ERROR] ${error.requestOptions.method} ${error.requestOptions.path}');
        if (error.response != null) {
          print('   Status: ${error.response?.statusCode}');
          print('   Data: ${error.response?.data}');
        } else {
          print('   Message: ${error.message}');
        }
        return handler.next(error);
      },
    ));
  }

  // ── AUTHENTIFICATION ──────────────────────────────────────────────────

  /// Connexion
  Future<Map<String, dynamic>> login(String emailOrUsername, String password) async {
    try {
      final r = await dio.post('/auth/login', data: {
        'email': emailOrUsername.trim(),
        'password': password,
      });

      if (r.data['token'] != null) {
        appState.setSession(r.data['token'], r.data['user']);
      }
      return Map<String, dynamic>.from(r.data['user']);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ??
          (e.error.toString().contains('No route to host')
              ? 'Impossible de joindre le serveur. Vérifiez l\'adresse IP et le Wi-Fi.'
              : 'Identifiants incorrects ou erreur réseau.');
      throw msg; // On lance directement la chaîne du message !
    }
  }

  /// Inscription Commerçant
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    String? confirmPassword,
  }) async {
    try {
      final r = await dio.post('/auth/register', data: {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
        'role': 'commercant',
      });
      if (r.data['token'] != null) {
        appState.setSession(r.data['token'], r.data['user']);
      }
      return Map<String, dynamic>.from(r.data['user']);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ??
          (e.error.toString().contains('No route to host')
              ? 'Impossible de joindre le serveur. Vérifiez la connexion Wi-Fi.'
              : 'Erreur lors de l\'inscription.');
      throw msg; // On lance le message pour qu'il soit attrapé par le catch de ton interface
    }
  }

  /// Mot de passe oublié
  Future<Response> forgotPassword(String email) async {
    try {
      return await dio.post('/auth/forgot-password', data: {
        'email': email.trim(),
      });
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Impossible d\'envoyer le lien pour le moment.';
      throw Exception(msg);
    }
  }

  /// Changer de mot de passe
  Future<Response> changePassword(String current, String newPwd) async {
    try {
      return await dio.post('/auth/change-password', data: {
        'old_password': current,
        'new_password': newPwd,
      });
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Erreur lors du changement de mot de passe.';
      throw Exception(msg);
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      await dio.post('/auth/logout');
    } catch (_) {
      // On ignore si le serveur ne répond pas au logout
    } finally {
      appState.logout();
    }
  }

  // ── COMMANDES & LIVRAISONS (COMMERÇANT) ─────────────────────────────────

  Future<Response> getMesCommandes() => dio.get('/v1/commercant/livraisons');

  Future<Response> getLivraisons({String? status}) => getMesCommandes();

  Future<Response> getCommande(int id) => dio.get('/v1/commercant/livraisons/$id');

  Future<Response> getLivraisonsEnCours() =>
      dio.get('/v1/commercant/livraisons/en-cours');

  Future<Response> creerCommande(Map<String, dynamic> payload) =>
      dio.post('/v1/commercant/livraisons', data: payload);

  Future<Response> createLivraison(Map<String, dynamic> payload) => creerCommande(payload);

  Future<Response> supprimerCommande(int id) =>
      dio.delete('/v1/commercant/livraisons/$id');

  Future<Response> commanderCourse(int id) =>
      dio.post('/v1/commercant/livraisons/$id/commander-course');

  Future<Response> annulerCommande(int id) =>
      dio.post('/livraisons/$id/annuler');

  // ── LIVREURS ─────────────────────────────────────────────────────────

  Future<Response> getLivreursDisponibles() =>
      dio.get('/v1/commercant/livreurs-disponibles');

  Future<Response> getLivreurs({bool disponiblesOnly = false}) => getLivreursDisponibles();

  // ── LITIGES ──────────────────────────────────────────────────────────

  Future<Response> declarerLitige(int id, String motif, String description) =>
      dio.post('/v1/commercant/livraisons/$id/litige',
          data: {'motif': motif, 'description': description});

  Future<Response> getMesLitiges() => dio.get('/litiges');

  // ── NOTIFICATIONS ────────────────────────────────────────────────────

  Future<Response> getNotifications() => dio.get('/notifications');

  Future<Response> supprimerNotification(int id) => dio.delete('/notifications/$id');

  Future<Response> marquerNotificationLue(int id) => dio.patch('/notifications/$id/lire');
}