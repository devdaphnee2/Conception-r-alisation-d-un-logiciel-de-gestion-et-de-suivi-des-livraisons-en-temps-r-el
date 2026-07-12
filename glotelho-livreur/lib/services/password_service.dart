/// Service de récupération de mot de passe.
/// MODE MOCK activé en attendant les routes backend.
/// Quand le backend sera prêt : passer _useMock à false et compléter les TODO.
class PasswordService {
  static const bool _useMock = true;

  // Code accepté en mode démo
  static const String _mockCode = '123456';

  /// Étape 1 : envoyer le code OTP au téléphone/e-mail du livreur.
  static Future<bool> sendResetCode(String identifiant) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (_useMock) {
      // En démo, on considère l'envoi toujours réussi.
      return true;
    }
    // TODO backend : POST /drivers/forgot-password { identifiant }
    throw UnimplementedError();
  }

  /// Étape 2 : vérifier le code saisi.
  static Future<bool> verifyCode(String identifiant, String code) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (_useMock) {
      return code.trim() == _mockCode;
    }
    // TODO backend : POST /drivers/verify-otp { identifiant, code }
    throw UnimplementedError();
  }

  /// Étape 3 : enregistrer le nouveau mot de passe.
  static Future<bool> resetPassword(String identifiant, String code, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (_useMock) {
      return true;
    }
    // TODO backend : POST /drivers/reset-password { identifiant, code, newPassword }
    throw UnimplementedError();
  }
}