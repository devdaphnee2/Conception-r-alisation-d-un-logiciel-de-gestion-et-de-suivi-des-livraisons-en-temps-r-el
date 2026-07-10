import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

/// Système de traduction minimal. Usage : `AppStrings.t(context, 'nav_home')`.
/// Pour ajouter un nouvel écran à la traduction : ajouter les clés ici
/// dans 'fr' ET 'en', puis remplacer le texte en dur par `AppStrings.t(...)`
/// dans le widget concerné. C'est le seul endroit à modifier pour ajouter
/// une langue ou un texte.
class AppStrings {
  static const Map<String, Map<String, String>> _strings = {
    'fr': {
      'nav_home': 'Accueil',
      'nav_deliveries': 'Livraisons',
      'nav_drivers': 'Livreurs',
      'nav_settings': 'Paramètres',
      'settings_title': 'PARAMÈTRES',
      'settings_preferences': 'Préférences',
      'settings_notifications': 'Notifications',
      'settings_language': 'Langue',
      'settings_theme': 'Thème',
      'settings_theme_dark': 'Sombre (Navy)',
      'settings_theme_light': 'Clair',
      'settings_security': 'Sécurité',
      'settings_biometric': 'Authentification biométrique',
      'settings_password': 'Mot de passe de connexion',
      'settings_password_sub': 'Mise à jour du mot de passe de connexion',
      'settings_management': 'Gestion',
      'settings_disputes': 'Litiges',
      'settings_disputes_sub': 'Suivre et traiter les litiges clients',
      'settings_collections': 'Recouvrements',
      'settings_collections_sub': 'Suivre les dettes livreurs',
      'settings_account': 'Compte',
      'settings_logout': 'Déconnexion',
      'change_password_subtitle': 'Changer votre',
      'change_password_title': 'MOT DE PASSE',
      'current_password': 'Mot de passe actuel',
      'new_password': 'Nouveau mot de passe',
      'confirm_password': 'Valider',
      'update': 'METTRE À JOUR',
      'password_update_success': 'Mise à jour du mot de passe réussie',
    },
    'en': {
      'nav_home': 'Home',
      'nav_deliveries': 'Deliveries',
      'nav_drivers': 'Drivers',
      'nav_settings': 'Settings',
      'settings_title': 'SETTINGS',
      'settings_preferences': 'Preferences',
      'settings_notifications': 'Notifications',
      'settings_language': 'Language',
      'settings_theme': 'Theme',
      'settings_theme_dark': 'Dark (Navy)',
      'settings_theme_light': 'Light',
      'settings_security': 'Security',
      'settings_biometric': 'Biometric authentication',
      'settings_password': 'Login password',
      'settings_password_sub': 'Update your login password',
      'settings_management': 'Management',
      'settings_disputes': 'Disputes',
      'settings_disputes_sub': 'Track and handle customer disputes',
      'settings_collections': 'Collections',
      'settings_collections_sub': 'Track driver debts',
      'settings_account': 'Account',
      'settings_logout': 'Log out',
      'change_password_subtitle': 'Change your',
      'change_password_title': 'PASSWORD',
      'current_password': 'Current password',
      'new_password': 'New password',
      'confirm_password': 'Confirm',
      'update': 'UPDATE',
      'password_update_success': 'Password updated successfully',
    },
  };

  /// Lit la langue courante depuis AppState et retourne le texte traduit.
  static String t(BuildContext context, String key) {
    final locale = context.watch<AppState>().locale;
    return _strings[locale]?[key] ?? _strings['fr']![key] ?? key;
  }
}