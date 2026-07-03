import 'package:dio/dio.dart';
import '../utils/constants.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppStrings.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Setter pour le token d'auth
  static void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Supprimer le token
  static void removeToken() {
    _dio.options.headers.remove('Authorization');
  }

  static Dio get dio => _dio;
}