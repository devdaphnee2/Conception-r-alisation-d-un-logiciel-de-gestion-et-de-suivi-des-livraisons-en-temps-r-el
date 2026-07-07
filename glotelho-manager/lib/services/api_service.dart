import 'package:dio/dio.dart';
import '../config/app_state.dart';

/// Équivalent Dart de services/api.js côté web : même baseURL et même
/// logique d'intercepteur pour attacher le token Bearer.
/// ⚠️ Remplace le baseUrl par l'IP réelle du backend de ton frère
/// (localhost ne fonctionne pas depuis un appareil/émulateur Android).
class ApiService {
  final Dio dio;
  final AppState appState;

  ApiService(this.appState)
      : dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.145:5173/api')) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = appState.authToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  /// Identique à AuthContext.jsx : POST /auth/login { email, password }
  /// → { token, user }
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final token = response.data['token'] as String;
    final user = response.data['user'] as Map<String, dynamic>;
    appState.setSession(token, user);
    return user;
  }

  /// Identique à Register.jsx : POST /auth/register avec le formulaire
  /// complet → { token, user }
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await dio.post('/auth/register', data: {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'password': password,
      'confirm_password': confirmPassword,
    });
    final token = response.data['token'] as String;
    final user = response.data['user'] as Map<String, dynamic>;
    appState.setSession(token, user);
    return user;
  }

  // Endpoints alignés sur le web : /livraisons, /livreurs, /litiges, /recouvrements
  Future<Response> getLivraisons() => dio.get('/livraisons');
  Future<Response> getLivreurs({bool all = false}) =>
      dio.get('/livreurs${all ? '?all=true' : ''}');
  Future<Response> getLitiges() => dio.get('/litiges');
  Future<Response> getRecouvrements() => dio.get('/recouvrements');
  Future<Response> getCommandes() => dio.get('/orders');
  Future<Response> getProfilsEnAttente() => dio.get('/profils/en-attente');
}