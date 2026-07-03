import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driver_model.dart';
import '../services/api_service.dart';
import '../services/driver_service.dart';

class DriverState extends ChangeNotifier {
  DriverModel? _driver;
  String? _token;
  bool _isOnline = false; // disponible / indisponible

  DriverModel? get driver => _driver;
  String? get token => _token;
  bool get isLoggedIn => _token != null;
  bool get isOnline => _isOnline;

  void setDriver(DriverModel driver, String token) {
    _driver = driver;
    _token = token;
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
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('driver_token');
    _driver = null;
    _token = null;
    notifyListeners();
  }

  /// Récupère le profil à jour du livreur (dont son statut de validation).
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