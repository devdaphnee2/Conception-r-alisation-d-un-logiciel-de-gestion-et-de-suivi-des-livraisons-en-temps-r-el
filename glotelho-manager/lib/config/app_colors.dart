import 'package:flutter/material.dart';

/// Palette reprise du frontend web glotelho-backoffice (variables `P` dans
/// Dashboard.jsx, LivraisonShow.jsx, etc.) pour garder une identité visuelle
/// cohérente entre le web manager et le mobile manager.
class AppColors {
  static const primary = Color(0xFF7D5700);
  static const primaryContainer = Color(0xFFC9952E);
  static const primaryFixed = Color(0xFFFFDEA9);
  static const onPrimaryContainer = Color(0xFF483100);

  static const secondary = Color(0xFF475E8B);
  static const secondaryContainer = Color(0xFFB5CCFF);
  static const onSecondaryContainer = Color(0xFF3E5682);

  static const tertiary = Color(0xFF20619E);
  static const tertiaryContainer = Color(0xFF6AA1E3);
  static const onTertiaryContainer = Color(0xFF003762);

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF9F9F9);
  static const surfaceContainerLow = Color(0xFFF3F3F3);
  static const surfaceContainerHigh = Color(0xFFE8E8E8);

  static const inverseSurface = Color(0xFF2F3131);
  static const inverseSurfaceOn = Color(0xFFF1F1F1);

  static const onSurface = Color(0xFF1A1C1C);
  static const onSurfaceVariant = Color(0xFF4F4536);
  static const outline = Color(0xFF817564);
  static const outlineVariant = Color(0xFFD3C4B0);

  // Statuts livraison (repris de statusLivraison côté web)
  static const statutEnAttenteBg = primaryFixed;
  static const statutAssigneBg = secondaryContainer;
  static const statutEnCoursBg = tertiaryContainer;
  static const statutLivreBg = Color(0xFFC8E6C9);
  static const statutSuspenduBg = errorContainer;
  static const statutAnnuleBg = surfaceContainerHigh;
}