import 'package:dio/dio.dart';
import 'api_service.dart';

class AuthResult {
  final bool success;
  final String? token;
  final String? errorMessage;

  AuthResult.success({this.token}) : success = true, errorMessage = null;
  AuthResult.failure(this.errorMessage) : success = false, token = null;
}

class AuthService {
  // ─── LOGIN ────────────────────────────────────────────────────
  static Future<AuthResult> login(String telephoneOrEmail, String password) async {
    try {
      final response = await ApiService.dio.post('/drivers/login', data: {
        'telephone': telephoneOrEmail,
        'password' : password,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'];
        ApiService.setToken(token);
        return AuthResult.success(token: token);
      }
      return AuthResult.failure('Erreur de connexion.');
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Identifiants incorrects.')
          : 'Erreur réseau, vérifiez votre connexion.';
      return AuthResult.failure(msg.toString());
    } catch (e) {
      return AuthResult.failure('Une erreur inattendue est survenue.');
    }
  }

  // ─── LOGOUT ───────────────────────────────────────────────────
  static Future<void> logout() async {
    try {
      await ApiService.dio.post('/drivers/logout');
    } catch (_) {}
    ApiService.removeToken();
  }

  // ─── FORGOT PASSWORD ─────────────────────────────────────────
  static Future<AuthResult> forgotPassword(String email) async {
    try {
      final response = await ApiService.dio.post(
        '/drivers/forgot-password',
        data: {'email': email},
      );
      // La réponse est 200 même si l'email n'existe pas (sécurité)
      return AuthResult.success();
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Erreur lors de l\'envoi.')
          : 'Erreur réseau, vérifiez votre connexion.';
      return AuthResult.failure(msg.toString());
    } catch (e) {
      return AuthResult.failure('Une erreur inattendue est survenue.');
    }
  }

  // ─── RESET PASSWORD ──────────────────────────────────────────
  static Future<AuthResult> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await ApiService.dio.post(
        '/drivers/reset-password',
        data: {
          'token'      : token,
          'newPassword': newPassword,
        },
      );
      return AuthResult.success();
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Token invalide ou expiré.')
          : 'Erreur réseau, vérifiez votre connexion.';
      return AuthResult.failure(msg.toString());
    } catch (e) {
      return AuthResult.failure('Une erreur inattendue est survenue.');
    }
  }

  // ─── CHANGE PASSWORD ─────────────────────────────────────────
  static Future<AuthResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await ApiService.dio.patch(
        '/drivers/change-password',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
      return AuthResult.success();
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Erreur lors du changement de mot de passe.')
          : 'Erreur réseau, vérifiez votre connexion.';
      return AuthResult.failure(msg.toString());
    } catch (e) {
      return AuthResult.failure('Une erreur inattendue est survenue.');
    }
  }
}