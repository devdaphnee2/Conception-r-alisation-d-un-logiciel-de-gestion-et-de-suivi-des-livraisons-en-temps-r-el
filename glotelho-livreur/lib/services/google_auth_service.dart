import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '1056096384522-k0e89pvhcr0l8nnr1ianlpvsm8of2j2e.apps.googleusercontent.com',
  );

  /// Lance la connexion Google, puis échange le token avec le backend
  /// (même mécanisme que côté client, endpoint /drivers/auth/google
  /// à ajuster si le chemin diffère de celui déjà utilisé côté client).
  static Future<String?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null; // annulé par l'utilisateur

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) return null;

      final response = await ApiService.dio.post('/drivers/auth/google', data: {
        'idToken': idToken,
      });

      final data = response.data;
      return data['token'] ?? data['data']?['token'];
    } on DioException {
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}