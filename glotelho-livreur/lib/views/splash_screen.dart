import 'dart:async';
import 'package:flutter/material.dart';
import 'package:glotelho_livreur/views/pending_verification_screen.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/driver_state.dart';
import '../services/polling_service.dart';
import '../models/driver_model.dart';
import 'onboarding_screen.dart';
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
    await driverState.loadSession();

    if (driverState.isLoggedIn) {
      await driverState.refreshProfile();
    }

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (!driverState.isLoggedIn) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()));
      return;
    }

    // Démarrer le polling si le livreur est approuvé
    if (driverState.driver?.status == DriverStatus.approved) {
      await PollingService.start();
    }

    if (driverState.driver?.isVerified == true) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const PendingVerificationScreen()));
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
            Image.asset('assets/images/glotelho_delivery_logo_high_contrast.png', width: 140),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}