import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';
import '../utils/constants.dart';
import '../controllers/auth_controller.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color navy = Color(0xFF0D1B2A);
  static const Color gold = Color(0xFFC8960C);

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final state = context.read<AppState>();

    if (state.isLoggedIn) {
      // ✅ Restaurer le token dans Dio avant tout appel API
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        // Token absent → rediriger vers login
        if (mounted) {
          Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
        return;
      }
      ApiService.setToken(token);

      // ✅ Rafraîchir le profil depuis le backend (données toujours à jour)
      final result = await AuthController.getMe();
      if (!mounted) return;

      if (result['success'] == true) {
        final user = result['data'] as Map<String, dynamic>;
        state.updateFromServer(
          fullName:  user['full_name'] as String? ?? state.userName,
          email:     user['email']     as String? ?? state.userEmail,
          phone:     user['phone']     as String? ?? state.userPhone,
          avatarUrl: user['avatar_url'] as String?,
        );
      } else {
        // Token expiré ou invalide → forcer reconnexion
        state.setLoggedIn(false);
        ApiService.removeToken();
        if (mounted) {
          Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
        return;
      }

      if (!mounted) return;

      // Biométrie activée → proposer connexion par empreinte
      if (state.biometricEnabled) {
        final authenticated = await _tryBiometric();
        if (!mounted) return;
        if (authenticated) {
          Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          return;
        }
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        return;
      }

      // Déjà connecté, biométrie désactivée → accueil direct
      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      return;
    }

    // Jamais connecté → onboarding
    Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
  }

  Future<bool> _tryBiometric() async {
    final auth = LocalAuthentication();
    try {
      final bool canCheck = await auth.canCheckBiometrics;
      if (!canCheck) return false;
      return await auth.authenticate(
        localizedReason:
            'Posez votre empreinte pour vous connecter à Glotelho Express',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: gold.withOpacity(0.4),
                        blurRadius: 24,
                        spreadRadius: 4)
                  ],
                ),
                child: const Center(
                  child: Text('G',
                      style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: navy)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Glotelho',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              const SizedBox(height: 4),
              const Text('EXPRESS',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: gold)),
              const SizedBox(height: 32),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(gold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
