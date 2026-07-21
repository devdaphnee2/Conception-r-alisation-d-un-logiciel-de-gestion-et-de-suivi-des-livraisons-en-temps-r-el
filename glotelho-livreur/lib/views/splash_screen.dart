import 'dart:async';
import 'package:flutter/material.dart';
import 'package:glotelho_livreur/views/pending_verification_screen.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/driver_state.dart';
import '../services/polling_service.dart';
import '../models/driver_model.dart';
import 'main_navigation_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final driverState = context.read<DriverState>();

    // 1. Charger le token en local
    await driverState.loadSession();

    bool profileValid = false;

    // 2. Si un token existe, valider la session auprès du backend
    if (driverState.isLoggedIn) {
      profileValid = await driverState.refreshProfile();
    }

    // Un petit délai d'affichage pour éviter un flash visuel trop rapide du SplashScreen
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    // 3. Si aucun token n'est stocké OU si le token est invalide / expiré
    if (!driverState.isLoggedIn || !profileValid) {
      // Nettoyer toute donnée résiduelle
      await driverState.logout();

      if (!mounted) return;
      // Rediriger impérativement vers l'écran de connexion
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    // 4. Si le livreur est connecté et que son compte est approuvé
    if (driverState.driver?.status == DriverStatus.approved) {
      await PollingService.start();
    }

    // 5. Redirection selon le statut de vérification du profil
    if (driverState.driver?.isVerified == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PendingVerificationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/glotelho_delivery_logo_high_contrast.png',
              width: 140,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}