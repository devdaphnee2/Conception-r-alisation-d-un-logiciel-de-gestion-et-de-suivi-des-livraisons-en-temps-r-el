import '../services/api_service.dart';
import 'package:dio/dio.dart';

class AuthController {

  // ── Connexion Google ───────────────────────────────────────────
  static Future<Map<String, dynamic>> googleLogin({
    required String idToken,
  }) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/google',
        data: {'idToken': idToken},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur connexion Google',
      };
    }
  }

  // ── Connexion email/password ───────────────────────────────────
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
        'data': e.response?.data,
      };
    }
  }

  // ── Inscription ────────────────────────────────────────────────
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

  // ── Mot de passe oublié ────────────────────────────────────────
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur',
      };
    }
  }

  // ── Changement de mot de passe (utilisateur connecté) ─────────
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await ApiService.dio.patch(
        '/auth/change-password',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur changement mot de passe',
      };
    }
  }

  // ✅ Récupérer le profil frais depuis le backend
  static Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await ApiService.dio.get('/auth/me');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur récupération profil',
      };
    }
  }

  // ── Mise à jour du token FCM ───────────────────────────────────
  static Future<Map<String, dynamic>> updateFcmToken({
    required String fcmToken,
  }) async {
    try {
      final response = await ApiService.dio.patch(
        '/auth/fcm-token',
        data: {'fcm_token': fcmToken},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur FCM',
      };
    }
  }
}
