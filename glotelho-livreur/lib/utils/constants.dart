import 'package:flutter/material.dart';

class AppColors {
  static const Color navy = Color(0xFF0D1B2A);
  static const Color gold = Color(0xFFC8960C);
  static const Color background = Color(0xFFF2F4F7);
  static const Color white = Colors.white;
  static const Color green = Color(0xFF2E7D32);
  static const Color greenBg = Color(0xFFE8F5E9);
  static const Color red = Color(0xFFC62828);
  static const Color redBg = Color(0xFFFFEBEE);
  static const Color blue = Color(0xFF1565C0);
  static const Color blueBg = Color(0xFFE3F2FD);
  static const Color amber = Color(0xFF633806);
  static const Color amberBg = Color(0xFFFAEEDA);

  // Statuts de livraison sur la carte (point 7 du cahier des charges)
  static const Color statusDelivered = green;   // vert
  static const Color statusCancelled = red;     // rouge
  static const Color statusInProgress = blue;   // bleu
  static const Color statusPending = amber;     // orange/jaune
}

class AppStrings {
  static const String appName = 'Glotelho Delivery';
  // Même backend que l'app client — à garder synchronisé si l'IP change
  static const String baseUrl = 'http://192.168.1.166:3002/api/v1'; 
}