import 'package:flutter/material.dart';

/// État global de l'application, même pattern que dans glotelho-livreur :
/// gère la langue (FR/EN), le thème (clair/sombre) et l'état d'authentification
/// du manager connecté.
class AppState extends ChangeNotifier {
  String _locale = 'fr';
  ThemeMode _themeMode = ThemeMode.light;
  String? _authToken;
  Map<String, dynamic>? _currentManager;

  String get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get isAuthenticated => _authToken != null;
  Map<String, dynamic>? get currentManager => _currentManager;

  void toggleLocale() {
    _locale = _locale == 'fr' ? 'en' : 'fr';
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