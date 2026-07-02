import 'package:shared_preferences/shared_preferences.dart';

/// StorageService — persiste le token JWT et les infos du client
/// entre les sessions (app fermée et rouverte).
///
/// ⚠️ Ajoutez dans pubspec.yaml :
///   dependencies:
///     shared_preferences: ^2.3.2
class StorageService {
  static const _keyToken       = 'auth_token';
  static const _keyIsLoggedIn  = 'is_logged_in';
  static const _keyBiometric   = 'biometric_enabled';
  static const _keyFirstName   = 'user_first_name';
  static const _keyLastName    = 'user_last_name';
  static const _keyEmail       = 'user_email';
  static const _keyPhone       = 'user_phone';
  static const _keyAvatarPath  = 'user_avatar_path';

  // ── Sauvegarde après connexion réussie ──────────────────────
  static Future<void> saveSession({
    required String token,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken,      token);
    await prefs.setBool  (_keyIsLoggedIn, true);
    await prefs.setString(_keyFirstName,  firstName);
    await prefs.setString(_keyLastName,   lastName);
    await prefs.setString(_keyEmail,      email);
    await prefs.setString(_keyPhone,      phone);
  }

  // ── Lecture au démarrage ────────────────────────────────────
  static Future<Map<String, dynamic>> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isLoggedIn'      : prefs.getBool  (_keyIsLoggedIn) ?? false,
      'token'           : prefs.getString(_keyToken)      ?? '',
      'biometricEnabled': prefs.getBool  (_keyBiometric)  ?? false,
      'firstName'       : prefs.getString(_keyFirstName)  ?? '',
      'lastName'        : prefs.getString(_keyLastName)   ?? '',
      'email'           : prefs.getString(_keyEmail)      ?? '',
      'phone'           : prefs.getString(_keyPhone)      ?? '',
      'avatarPath'      : prefs.getString(_keyAvatarPath),
    };
  }

  // ── Biométrie ───────────────────────────────────────────────
  static Future<void> saveBiometric(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometric, enabled);
  }

  // ── Photo de profil ─────────────────────────────────────────
  static Future<void> saveAvatarPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAvatarPath, path);
  }

  // ── Effacer la session (déconnexion) ────────────────────────
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyFirstName);
    await prefs.remove(_keyLastName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPhone);
    // On garde biometricEnabled et avatarPath intentionnellement
    // pour ne pas forcer le client à tout reconfigurer à la prochaine connexion
  }

  // ✅ Mise à jour profil SANS toucher au token
  static Future<void> updateProfileOnly({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFirstName, firstName);
    await prefs.setString(_keyLastName,  lastName);
    await prefs.setString(_keyEmail,     email);
    await prefs.setString(_keyPhone,     phone);
  }

  // ✅ Mise à jour du token seul (après changement d'email)
  static Future<void> updateToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  // ── Token seul ──────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }
}