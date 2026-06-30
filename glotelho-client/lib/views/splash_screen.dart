import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:async';
import '../utils/constants.dart';
import '../controllers/auth_controller.dart';
import 'package:glotelho_client/views/login_screen.dart';
import '../views/onboarding_screen.dart';
import 'onboarding_screen.dart';

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

    // Dans le timer
    Timer(const Duration(seconds: 3), () {
      if(mounted){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
      // Navigator.pushReplacement(...)
    });
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
              SvgPicture.asset(
                'assets/images/delivery_splash.svg',
                width: 280,
              ),
              const SizedBox(height: 32),

              const Text(
                'Glotelho',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'EXPRESS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  color: gold,
                ),
              ),
              const SizedBox(height: 24),

              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(gold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}