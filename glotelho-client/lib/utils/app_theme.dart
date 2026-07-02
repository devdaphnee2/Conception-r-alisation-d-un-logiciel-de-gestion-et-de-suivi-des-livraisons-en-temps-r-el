import 'package:flutter/material.dart';
import 'constants.dart';

/// Thèmes clair et sombre de l'application, construits autour des couleurs
/// de marque (navy/gold) définies dans constants.dart.
///
/// Pattern utilisé dans les écrans : `final isDark = Theme.of(context).brightness == Brightness.dark;`
/// puis utiliser `Theme.of(context).scaffoldBackgroundColor`, `.cardColor`,
/// `.colorScheme.onSurface` etc. au lieu de couleurs codées en dur
/// (Colors.white, Colors.black87...), afin que l'écran réagisse au switch
/// jour/nuit dans Paramètres.
class AppTheme {
  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    cardColor: Colors.white,
    dividerColor: Colors.grey.shade200,
    colorScheme: ColorScheme.light(
      primary: AppColors.gold,
      secondary: AppColors.navy,
      surface: Colors.white,
      onSurface: Colors.black87,
      onSurfaceVariant: Colors.grey.shade600,
      error: AppColors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
    ),
    textTheme: const TextTheme().apply(bodyColor: Colors.black87, displayColor: Colors.black87),
  );

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0D1B2A),
    cardColor: const Color(0xFF1E2A38),
    dividerColor: Colors.white10,
    colorScheme: ColorScheme.dark(
      primary: AppColors.gold,
      secondary: AppColors.gold,
      surface: const Color(0xFF1E2A38),
      onSurface: Colors.white,
      onSurfaceVariant: Colors.white60,
      error: AppColors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0D1B2A),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E2A38),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF1E2A38),
      hintStyle: TextStyle(color: Colors.white38),
    ),
    textTheme: const TextTheme().apply(bodyColor: Colors.white, displayColor: Colors.white),
  );
}