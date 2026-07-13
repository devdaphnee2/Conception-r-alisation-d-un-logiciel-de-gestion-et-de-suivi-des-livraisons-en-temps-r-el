import 'package:flutter/material.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/notifications/notifications_screen.dart';
import '../views/parametres/parametres_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (_) => const LoginScreen(),
  '/register': (_) => const RegisterScreen(),
  '/notifications': (_) => const NotificationsScreen(),
  '/parametres': (_) => const ParametresScreen(),
};