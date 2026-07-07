import 'package:flutter/material.dart';

/// Deux thèmes de marque, uniquement navy + blanc/noir (pas de doré) :
/// - Navy (par défaut) : fond navy, accents blancs
/// - Clair : fond blanc, accents navy
class AppTheme {
  static const navy = Color(0xFF0D1B2A);
  static const navyLight = Color(0xFF1C3D56);

  static ThemeData get navyTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: navy,
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      onPrimary: navy,
      secondary: navyLight,
      surface: navyLight,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomAppBarTheme: const BottomAppBarThemeData(color: navyLight),
  );

  /// Thème clair : fond blanc, l'accent est le navy (boutons,
  /// icône active, switch) — aucun doré.
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: navy,
      onPrimary: Colors.white,
      secondary: navyLight,
      surface: Colors.white,
      onSurface: navy,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: navy,
      elevation: 0,
    ),
    bottomAppBarTheme: const BottomAppBarThemeData(color: Colors.white),
  );
}