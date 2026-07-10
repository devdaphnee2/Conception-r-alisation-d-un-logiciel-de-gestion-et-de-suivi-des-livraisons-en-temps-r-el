import 'package:flutter/material.dart';

/// Deux thèmes de marque, uniquement navy + blanc/noir (pas de doré) :
/// - Navy (par défaut) : fond navy, accents blancs
/// - Clair : fond blanc, accents navy
class AppTheme {
  static const navy = Color(0xFF0D1B2A);
  static const navyLight = Color(0xFF1C3D56);

  /// Exception à la règle navy/blanc : couleur dorée réservée
  /// uniquement au bouton flottant d'action principale ("+").
  static const gold = Color(0xFFC9952E);

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

  /// Fond des champs de saisie/recherche, harmonisé avec les champs
  /// de l'écran mot de passe : translucide sur navy en thème sombre,
  /// gris clair en thème clair.
  static Color inputFill(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100;
  }

  /// Couleur du texte saisi/placeholder, adaptée au thème.
  static Color inputText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : navy;
  }

  static Color inputHint(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white54 : Colors.grey.shade500;
  }
}