import 'package:flutter/material.dart';

/// État global de l'application, même pattern que dans glotelho-livreur :
/// gère la langue (FR/EN), le thème (clair/sombre) et l'état d'authentification
/// du manager connecté.
class AppState extends ChangeNotifier {
  String _locale = 'fr';
  // Clair = thème par défaut de l'app manager.
  ThemeMode _themeMode = ThemeMode.light;
  bool _biometricEnabled = false;
  String? _authToken;
  Map<String, dynamic>? _currentManager;

  String get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get biometricEnabled => _biometricEnabled;
  bool get isAuthenticated => _authToken != null;
  Map<String, dynamic>? get currentManager => _currentManager;

  void setLocale(String locale) {
    _locale = locale;
    notifyListeners();
  }

  void toggleLocale() {
    _locale = _locale == 'fr' ? 'en' : 'fr';
    notifyListeners();
  }

  void toggleBiometric() {
    _biometricEnabled = !_biometricEnabled;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setSession(String token, Map<String, dynamic> manager) {
    _authToken = token;
    _currentManager = manager;
    notifyListeners();
  }

  void logout() {
    _authToken = null;
    _currentManager = null;
    notifyListeners();
  }

  String? get authToken => _authToken;
}