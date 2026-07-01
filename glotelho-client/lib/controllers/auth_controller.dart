
import '../services/api_service.dart';
import 'package:dio/dio.dart';

class AuthController {

  // Connexion
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur de connexion',
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String nom,
    required String email,
    required String telephone,
    required String password,
  }) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/register',
        data: {
          'full_name': nom,
          'email':     email,
          'phone':     telephone,
          'password':  password,
        },
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur d\'inscription',
      };
    }
  }

  // Mot de passe oublié
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur',
      };
    }
  }

  // Envoie/met à jour le token FCM de l'appareil pour ce compte,
  // afin que le backend puisse pousser des notifications push (FCM)
  // même quand l'app est fermée.
  // ⚠️ Endpoint à créer côté backend (Laravel) : PATCH /auth/fcm-token
  // Body attendu : { "fcm_token": "..." }
  static Future<Map<String, dynamic>> updateFcmToken({
    required String fcmToken,
  }) async {
    try {
      final response = await ApiService.dio.patch(
        '/auth/fcm-token',
        data: {'fcm_token': fcmToken},
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur lors de l\'envoi du token FCM',
      };
    }
  }
}