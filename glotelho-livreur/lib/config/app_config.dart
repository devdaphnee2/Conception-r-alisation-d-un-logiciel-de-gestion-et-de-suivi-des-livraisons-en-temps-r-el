/// Configuration centralisée — CHANGE L'IP ET LA CLÉ GOOGLE MAPS ICI.
/// Tous les autres fichiers du projet importent cette classe
/// au lieu de coder ces informations en dur.
///
/// Pour trouver ton IP locale :
///   Windows : ipconfig  → cherche "Adresse IPv4"
///   Mac/Linux : ifconfig ou ip addr
class AppConfig {
  // ── SEULE LIGNE À MODIFIER À CHAQUE CHANGEMENT DE RÉSEAU ──────
  static const String _ip = '172.20.10.4';

  // ── CLÉ D'API GOOGLE MAPS ─────────────────────────────────────
  static const String googleMapsApiKey = 'AIzaSyB0tqd53ed5Ek7omU0ty9Cdj6vED39z0z4';

  static const int backendPort  = 5000;
  static const int frontendPort = 5173;

  static String get baseUrl       => 'http://$_ip:$backendPort/api';
  static String get frontendUrl   => 'http://$_ip:$frontendPort';
  static String get trackingUrl   => '$frontendUrl/suivi';
  static String get paiementUrl   => '$frontendUrl/paiement';
}