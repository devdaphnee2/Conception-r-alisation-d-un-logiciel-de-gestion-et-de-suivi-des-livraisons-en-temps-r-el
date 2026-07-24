/// Configuration centralisée — CHANGE L'IP ICI UNIQUEMENT.
/// Tous les autres fichiers du projet importent cette classe
/// au lieu de coder l'adresse IP en dur.
///
/// Pour trouver ton IP locale :
///   Windows : ipconfig  → cherche "Adresse IPv4"
///   Mac/Linux : ifconfig ou ip addr
class AppConfig {
  // ── SEULE LIGNE À MODIFIER À CHAQUE CHANGEMENT DE RÉSEAU ──────
  static const String _ip = '10.203.155.25';

  static const int backendPort  = 5000;
  static const int frontendPort = 5173;

  static String get baseUrl       => 'http://$_ip:$backendPort/api';
  static String get frontendUrl   => 'http://$_ip:$frontendPort';
  static String get trackingUrl   => '$frontendUrl/suivi';
  static String get paiementUrl   => '$frontendUrl/paiement';
}