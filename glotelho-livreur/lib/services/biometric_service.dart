import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gère l'authentification biométrique (empreinte / visage) et le stockage
/// sécurisé du token de session pour la connexion rapide.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage();

  static const _kBiometricEnabled = 'biometric_enabled';
  static const _kSavedToken = 'biometric_token';

  /// L'appareil possède-t-il un capteur biométrique utilisable ?
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Demande l'empreinte / le visage à l'utilisateur.
  static Future<bool> authenticate({String reason = 'Confirmez votre identité'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// La biométrie est-elle activée par le livreur dans les paramètres ?
  static Future<bool> isEnabled() async {
    return (await _storage.read(key: _kBiometricEnabled)) == 'true';
  }

  /// Active la biométrie : on mémorise le token de session pour les connexions futures.
  static Future<void> enable(String token) async {
    await _storage.write(key: _kBiometricEnabled, value: 'true');
    await _storage.write(key: _kSavedToken, value: token);
  }

  /// Désactive la biométrie et efface le token stocké.
  static Future<void> disable() async {
    await _storage.write(key: _kBiometricEnabled, value: 'false');
    await _storage.delete(key: _kSavedToken);
  }

  /// Récupère le token stocké (après une authentification biométrique réussie).
  static Future<String?> getSavedToken() async {
    return await _storage.read(key: _kSavedToken);
  }
}