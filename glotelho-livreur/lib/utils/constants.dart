import 'package:flutter/material.dart';

class AppColors {
  static const Color navy       = Color(0xFF0D1B2A);
  static const Color gold       = Color(0xFFC8960C);
  static const Color background = Color(0xFFF2F4F7);
  static const Color white      = Colors.white;
  static const Color green      = Color(0xFF2E7D32);
  static const Color greenBg    = Color(0xFFE8F5E9);
  static const Color red        = Color(0xFFC62828);
  static const Color redBg      = Color(0xFFFFEBEE);
  static const Color blue       = Color(0xFF1565C0);
  static const Color blueBg     = Color(0xFFE3F2FD);
  static const Color amber      = Color(0xFF633806);
  static const Color amberBg    = Color(0xFFFAEEDA);
  static const Color cardNavy   = Color(0xFF16324A);

  // Statuts de livraison
  static const Color statusDelivered  = green;
  static const Color statusCancelled  = red;
  static const Color statusInProgress = blue;
  static const Color statusPending    = amber;
}

class AppStrings {
  static const String appName = 'Glotelho Delivery';
<<<<<<< HEAD
  static const String baseUrl = 'http://192.168.1.166:5000/api';
=======
  static const String baseUrl = 'http://172.20.10.4:5000/api/v1';
>>>>>>> origin/main

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5)  return 'Bonsoir';
    if (hour < 18) return 'Bonjour';
    return 'Bonsoir';
  }
}