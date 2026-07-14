import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  String    _locale    = 'fr';
  ThemeMode _themeMode = ThemeMode.light;
  bool      _biometricEnabled = false;
  String?   _authToken;
  Map<String, dynamic>? _currentManager;

  String    get locale           => _locale;
  ThemeMode get themeMode        => _themeMode;
  bool      get biometricEnabled => _biometricEnabled;
  bool      get isAuthenticated  => _authToken != null;
  Map<String, dynamic>? get currentManager => _currentManager;
  String?   get authToken        => _authToken;

  void setLocale(String locale)   { _locale = locale; notifyListeners(); }
  void toggleLocale()             { _locale = _locale == 'fr' ? 'en' : 'fr'; notifyListeners(); }
  void toggleBiometric()          { _biometricEnabled = !_biometricEnabled; notifyListeners(); }
  void toggleTheme()              {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Sauvegarde session avec SharedPreferences
  Future<void> setSession(String token, Map<String, dynamic> manager) async {
    _authToken      = token;
    _currentManager = manager;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('manager_email',      manager['email']?.toString() ?? '');
    await prefs.setString('manager_first_name', manager['first_name']?.toString() ?? '');
    await prefs.setString('manager_last_name',  manager['last_name']?.toString() ?? '');
    await prefs.setString('manager_role',       manager['role']?.toString() ?? '');
    await prefs.setInt   ('manager_id',         (manager['id'] as num?)?.toInt() ?? 0);
    notifyListeners();
  }

  // Charger la session au démarrage
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      _authToken = token;
      _currentManager = {
        'id'        : prefs.getInt('manager_id') ?? 0,
        'email'     : prefs.getString('manager_email') ?? '',
        'first_name': prefs.getString('manager_first_name') ?? '',
        'last_name' : prefs.getString('manager_last_name') ?? '',
        'role'      : prefs.getString('manager_role') ?? 'manager',
      };
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _authToken      = null;
    _currentManager = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('manager_email');
    await prefs.remove('manager_first_name');
    await prefs.remove('manager_last_name');
    await prefs.remove('manager_role');
    await prefs.remove('manager_id');
    notifyListeners();
  }
}