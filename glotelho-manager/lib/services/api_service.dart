import 'package:dio/dio.dart';
import '../config/app_state.dart';

class ApiService {
  final Dio dio;
  final AppState appState;

  static const String _baseUrl = 'http://192.168.1.145:5000/api';

  ApiService(this.appState)
      : dio = Dio(BaseOptions(
    baseUrl        : _baseUrl,
    connectTimeout : const Duration(seconds: 15),
    receiveTimeout : const Duration(seconds: 15),
  )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = appState.authToken;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      },
    ));
  }

  // AUTH
  Future<Map<String, dynamic>> login(String email, String password) async {
    final r = await dio.post('/auth/login', data: {'email': email, 'password': password});
    appState.setSession(r.data['token'], r.data['user']);
    return r.data['user'];
  }

  Future<Map<String, dynamic>> register({required String firstName, required String lastName,
    required String email, required String phone, required String password,
    String? confirmPassword}) async {
    final r = await dio.post('/auth/register', data: {
      'first_name': firstName, 'last_name': lastName,
      'email': email, 'phone': phone, 'password': password,
    });
    appState.setSession(r.data['token'], r.data['user']);
    return r.data['user'];
  }

  Future<void> logout() async {
    try { await dio.post('/auth/logout'); } catch (_) {}
    appState.logout();
  }

  Future<Response> supprimerCommande(int id) =>
      dio.delete('/v1/commercant/livraisons/$id');

  Future<Response> changePassword(String current, String newPwd) =>
      dio.post('/auth/change-password', data: {'old_password': current, 'new_password': newPwd});

  // COMPAT — anciennes methodes toujours utilisees par dashboard et nouvelle_commande
  Future<Response> getLivraisons({String? status}) => getMesCommandes();
  Future<Response> getLivreurs({bool disponiblesOnly = false}) => getLivreursDisponibles();
  Future<Response> createLivraison(Map<String, dynamic> payload) => creerCommande(payload);

  // COMMANDES (créées par le commerçant)
  Future<Response> getMesCommandes() => dio.get('/v1/commercant/livraisons');
  Future<Response> getCommande(int id) => dio.get('/v1/commercant/livraisons/$id');

  Future<Response> creerCommande(Map<String, dynamic> payload) =>
      dio.post('/v1/commercant/livraisons', data: payload);

  Future<Response> commanderCourse(int id) =>
      dio.post('/v1/commercant/livraisons/$id/commander-course');

  Future<Response> annulerCommande(int id) =>
      dio.post('/livraisons/$id/annuler');

  Future<Response> declarerLitige(int id, String motif, String description) =>
      dio.post('/v1/commercant/livraisons/$id/litige',
          data: {'motif': motif, 'description': description});

  // LIVRAISONS EN COURS du jour
  Future<Response> getLivraisonsEnCours() =>
      dio.get('/v1/commercant/livraisons/en-cours');

  // LITIGES
  Future<Response> getMesLitiges() => dio.get('/litiges');

  // LIVREURS DISPONIBLES
  Future<Response> getLivreursDisponibles() =>
      dio.get('/v1/commercant/livreurs-disponibles');
}