import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driver_model.dart';
import '../services/api_service.dart';
import '../services/driver_service.dart';
import '../services/polling_service.dart';

class DriverState extends ChangeNotifier {
  DriverModel? _driver;
  String? _token;
  bool _isOnline = false;
  bool _isLoading = true; // Permet de savoir si la vérification initiale est en cours

  DriverModel? get driver => _driver;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _driver != null; // Sécurité : il faut un token ET un profil
  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;

  DriverState() {
    initSession(); // Vérifie la session dès la création de la classe
  }

  /// Initialise la session au lancement de l'application
  Future<void> initSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('driver_token');

      if (_token != null && _token!.isNotEmpty) {
        // Appliquer le token à l'API et charger le profil
        ApiService.setToken(_token!);
        final profileLoaded = await refreshProfile();

        // Si le profil échoue (ex: token expiré), on réinitialise la session
        if (!profileLoaded) {
          await logout();
        }
      }
    } catch (e) {
      await logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setDriver(DriverModel driver, String token) {
    _driver = driver;
    _token = token;
    ApiService.setToken(token);
    notifyListeners();
  }

  void toggleOnline(bool value) {
    _isOnline = value;
    notifyListeners();
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('driver_token');
    notifyListeners();
  }

  Future<void> saveSession(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver_token', token);
    _token = token;
    ApiService.setToken(token);
    notifyListeners();
  }

  Future<void> logout() async {
    PollingService.stop(); // Arrêter le polling à la déconnexion
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('driver_token');
    _driver = null;
    _token = null;
    _isOnline = false;
    notifyListeners();
  }

  Future<bool> refreshProfile() async {
    if (_token == null) return false;
    ApiService.setToken(_token!);
    final updated = await DriverService.fetchProfile();
    if (updated != null) {
      _driver = updated;
      notifyListeners();
      return true;
    }
    return false;
  }
}