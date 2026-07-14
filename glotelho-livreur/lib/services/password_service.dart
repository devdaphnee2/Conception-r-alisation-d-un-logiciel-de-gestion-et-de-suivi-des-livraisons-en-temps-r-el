import 'package:dio/dio.dart';
import 'api_service.dart';

/// Service de récupération et modification de mot de passe.
/// Branché sur le backend fusionné (port 5000).
class PasswordService {

  // ─────────────────────────────────────────────────────────────
  // Étape 1 — Envoyer le lien de réinitialisation par email
  //
  // Backend : POST /api/v1/drivers/forgot-password
  // Body    : { "email": "..." }
  // Réponse : { "message": "..." }
  // ─────────────────────────────────────────────────────────────
  static Future<bool> sendResetCode(String identifiant) async {
    try {
      await ApiService.dio.post(
        '/drivers/forgot-password',
        data: {'email': identifiant},
      );
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Erreur lors de l\'envoi.')
          : 'Erreur réseau, vérifiez votre connexion.';
      throw Exception(msg.toString());
    } catch (_) {
      throw Exception('Une erreur inattendue est survenue.');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Étape 2 — Vérifier le token reçu par email
  //
  // Backend : GET /api/v1/auth/verify-reset-token?token=...
  // Réponse : { "valid": true } ou 400
  // ─────────────────────────────────────────────────────────────
  static Future<bool> verifyCode(String identifiant, String code) async {
    try {
      final response = await ApiService.dio.get(
        '/auth/verify-reset-token',
        queryParameters: {'token': code},
      );
      return response.data['valid'] == true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) return false;
      throw Exception('Erreur réseau, vérifiez votre connexion.');
    } catch (_) {
      throw Exception('Une erreur inattendue est survenue.');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Étape 3 — Réinitialiser le mot de passe avec le token
  //
  // Backend : POST /api/v1/drivers/reset-password
  // Body    : { "token": "...", "newPassword": "..." }
  // Réponse : { "message": "Mot de passe reinitialise avec succes." }
  // ─────────────────────────────────────────────────────────────
  static Future<bool> resetPassword(
      String identifiant, String code, String newPassword) async {
    try {
      await ApiService.dio.post(
        '/drivers/reset-password',
        data: {
          'token'      : code,
          'newPassword': newPassword,
        },
      );
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Token invalide ou expiré.')
          : 'Erreur réseau, vérifiez votre connexion.';
      throw Exception(msg.toString());
    } catch (_) {
      throw Exception('Une erreur inattendue est survenue.');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Changer le mot de passe (livreur connecté)
  //
  // Backend : PATCH /api/v1/drivers/change-password
  // Body    : { "old_password": "...", "new_password": "..." }
  // Réponse : { "message": "Mot de passe modifie." }
  // ─────────────────────────────────────────────────────────────
  static Future<bool> changePassword(
      String oldPassword, String newPassword) async {
    try {
      await ApiService.dio.patch(
        '/drivers/change-password',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Erreur lors du changement.')
          : 'Erreur réseau, vérifiez votre connexion.';
      throw Exception(msg.toString());
    } catch (_) {
      throw Exception('Une erreur inattendue est survenue.');
    }
  }
}