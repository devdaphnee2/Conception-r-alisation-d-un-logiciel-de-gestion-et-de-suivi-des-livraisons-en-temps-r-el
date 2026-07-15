import 'package:flutter/material.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/auth/forgot_password_screen.dart';
import '../views/notifications/notifications_screen.dart';
import '../views/parametres/parametres_screen.dart';
import '../views/onboaring/onboaring_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (_) => const LoginScreen(),
  '/register': (_) => const RegisterScreen(),
  '/forgot-password': (_) => const ForgotPasswordScreen(),
  '/notifications': (_) => const NotificationsScreen(),
  '/parametres': (_) => const ParametresScreen(),
  '/onboarding': (_) => const OnboardingScreen(),
};