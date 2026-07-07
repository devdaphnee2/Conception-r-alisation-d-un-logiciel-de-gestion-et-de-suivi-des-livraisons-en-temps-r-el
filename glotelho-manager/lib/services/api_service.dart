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
      : dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:5000/api')) {
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

  // Endpoints alignés sur le web : /livraisons, /livreurs, /litiges, /recouvrements
  Future<Response> getLivraisons() => dio.get('/livraisons');
  Future<Response> getLivreurs({bool all = false}) =>
      dio.get('/livreurs${all ? '?all=true' : ''}');
  Future<Response> getLitiges() => dio.get('/litiges');
  Future<Response> getRecouvrements() => dio.get('/recouvrements');
}