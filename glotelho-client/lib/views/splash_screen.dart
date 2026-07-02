import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';
import '../utils/constants.dart';
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

    // Cas 1 : Client déjà connecté + biométrie activée → proposer connexion par empreinte
    if (state.isLoggedIn && state.biometricEnabled) {
      final authenticated = await _tryBiometric();
      if (!mounted) return;
      if (authenticated) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        return;
      }
      // Échec biométrie → page de connexion classique
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    // Cas 2 : Déjà connecté, biométrie désactivée → accueil direct
    if (state.isLoggedIn) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      return;
    }

    // Cas 3 : Jamais connecté → onboarding
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
  }

  Future<bool> _tryBiometric() async {
    final auth = LocalAuthentication();
    try {
      final bool canCheck = await auth.canCheckBiometrics;
      if (!canCheck) return false;

      return await auth.authenticate(
        localizedReason: 'Posez votre empreinte pour vous connecter à Glotelho Express',
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
              // Logo G animé
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: gold.withOpacity(0.4), blurRadius: 24, spreadRadius: 4)],
                ),
                child: const Center(
                  child: Text('G', style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: navy)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Glotelho',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('EXPRESS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 4, color: gold)),
              const SizedBox(height: 32),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(gold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}