import 'package:flutter/material.dart';
import '../services/storage_service.dart';

// ─────────────────────────────────────────────────────────────────
// AppState — état global partagé dans toute l'application
// ─────────────────────────────────────────────────────────────────
class AppState extends ChangeNotifier {
  String _language = 'Français';
  bool   _isDarkMode = false;
  bool   _biometricEnabled = false;
  bool   _isLoggedIn = false;
  String _userName = '';
  String _userLastName = '';
  String _userEmail = '';
  String _userPhone = '';
  String? _userAvatarPath;

  String get language          => _language;
  bool   get isDarkMode        => _isDarkMode;
  bool   get biometricEnabled  => _biometricEnabled;
  bool   get isLoggedIn        => _isLoggedIn;
  String get userName       => _userName; // contient full_name directement
  String get userFirstName     => _userName;
  String get userLastName      => _userLastName;
  String get userEmail         => _userEmail;
  String get userPhone         => _userPhone;
  String? get userAvatarPath   => _userAvatarPath;

  /// Charge la session depuis le disque au démarrage de l'app.
  /// À appeler une fois dans main() avant runApp().
  Future<void> loadFromDisk() async {
    final session = await StorageService.loadSession();
    _isLoggedIn       = session['isLoggedIn']       as bool;
    _biometricEnabled = session['biometricEnabled']  as bool;
    _userName         = session['firstName']         as String;
    _userLastName     = session['lastName']          as String;
    _userEmail        = session['email']             as String;
    _userPhone        = session['phone']             as String;
    _userAvatarPath   = session['avatarPath']        as String?;
    notifyListeners();
  }

  void setLoggedIn(bool val) {
    _isLoggedIn = val;
    if (!val) StorageService.clearSession();
    notifyListeners();
  }

  void setBiometric(bool val) {
    _biometricEnabled = val;
    StorageService.saveBiometric(val);
    notifyListeners();
  }

  /// Appelé après connexion/inscription réussie — stocke sur le disque.
  void setUser({
    required String token,
    required String firstName,
    String lastName = '',
    required String email,
    required String phone,
    String? avatarUrl,
  }) {
    _isLoggedIn   = true;
    _userName     = firstName; // contient le full_name complet
    _userLastName = lastName;
    _userEmail    = email;
    _userPhone    = phone;
    if (avatarUrl != null) _userAvatarPath = avatarUrl;
    StorageService.saveSession(
      token: token, firstName: firstName, lastName: lastName,
      email: email, phone: phone,
    );
    notifyListeners();
  }

  // ── Traductions ──────────────────────────────────────────────
  static const Map<String, Map<String, String>> _tr = {
    'Français': {
      'hello_morning'  : 'Bonjour',
      'hello_afternoon': 'Bonne après-midi',
      'hello_evening'  : 'Bonsoir',
      'search_hint'    : 'Rechercher sur Glotelho...',
      'explore_cat'    : 'Explorer les catégories',
      'see_all'        : 'Voir tout',
      'trending'       : 'Tendances',
      'filter'         : 'Filtre :',
      'relevant'       : 'Plus pertinent',
      'add_cart'       : 'Ajouter au panier',
      'load_more'      : 'Charger plus',
      'showing'        : 'Affichage de',
      'of'             : 'sur',
      'products'       : 'produits',
      'no_product'     : 'Aucun produit trouvé',
      'home'           : 'Accueil',
      'categories'     : 'Catégories',
      'tracking'       : 'Suivi',
      'account'        : 'Compte',
      'settings'       : 'Paramètres',
      'subtitle'       : 'Gérez vos préférences',
      'section_account': 'COMPTE',
      'profile'        : 'Profil',
      'privacy'        : 'Confidentialité',
      'section_general': 'GÉNÉRAL',
      'notifications'  : 'Notifications',
      'language'       : 'Langue',
      'about'          : 'À propos',
      'help'           : 'Aide & Support',
      'section_security': 'SÉCURITÉ',
      'biometric'      : 'Authentification biométrique',
      'change_password': 'Changer le mot de passe',
      'logout'         : 'Se déconnecter',
      'dark_mode'      : 'Mode sombre',
      'favorites'      : 'Mes favoris',
      'orders'         : 'Mes commandes',
      'cart_empty'     : 'Votre panier est vide',
      'view_cart'      : 'Voir le panier',
      'notifications_title': 'Notifications',
      'driver_nearby'  : 'Livreur à proximité',
      'driver_nearby_sub': 'Alertes quand le livreur approche',
      'order_updates'  : 'Mises à jour commandes',
      'promotions'     : 'Promotions',
      'choose_language': 'Choisir la langue',
      'about_text'     : 'Version 1.0.0\n\nApplication mobile de suivi des livraisons en temps réel.\n\n© 2025 Glotelho Cameroun',
      'contact_us'     : 'Nous contacter',
      'faq'            : 'Questions fréquentes',
      'profile_title'  : 'Mon profil',
      'full_name'      : 'Nom complet',
      'email'          : 'Adresse email',
      'phone'          : 'Numéro de téléphone',
      'save'           : 'Enregistrer',
      'privacy_title'  : 'Confidentialité',
      'share_location' : 'Partager ma position',
      'share_location_sub': 'Permet le suivi en temps réel',
      'data_analytics' : 'Analyses & données',
      'data_analytics_sub': 'Aide à améliorer l\'application',
      'old_password'   : 'Ancien mot de passe',
      'new_password'   : 'Nouveau mot de passe',
      'confirm_password': 'Confirmer le mot de passe',
      'password_changed': 'Mot de passe modifié avec succès !',
      'biometric_enable': 'Activer la biométrie',
      'biometric_disable': 'Désactiver la biométrie',
      'biometric_confirm': 'Voulez-vous activer l\'authentification biométrique pour sécuriser votre compte ?',
      'cancel'         : 'Annuler',
      'confirm'        : 'Confirmer',
      'logout_confirm' : 'Voulez-vous vraiment vous déconnecter ?',
      'logout_title'   : 'Déconnexion',
      'yes_logout'     : 'Oui, déconnecter',
    },
    'English': {
      'hello_morning'  : 'Good morning',
      'hello_afternoon': 'Good afternoon',
      'hello_evening'  : 'Good evening',
      'search_hint'    : 'Search on Glotelho...',
      'explore_cat'    : 'Explore Categories',
      'see_all'        : 'See All',
      'trending'       : 'Trending',
      'filter'         : 'Filter:',
      'relevant'       : 'Most Relevant',
      'add_cart'       : 'Add to Cart',
      'load_more'      : 'Load More',
      'showing'        : 'Showing',
      'of'             : 'of',
      'products'       : 'products',
      'no_product'     : 'No products found',
      'home'           : 'Home',
      'categories'     : 'Categories',
      'tracking'       : 'Tracking',
      'account'        : 'Account',
      'settings'       : 'Settings',
      'subtitle'       : 'Manage your preferences',
      'section_account': 'ACCOUNT',
      'profile'        : 'Profile',
      'privacy'        : 'Privacy',
      'section_general': 'GENERAL',
      'notifications'  : 'Notifications',
      'language'       : 'Language',
      'about'          : 'About',
      'help'           : 'Help & Support',
      'section_security': 'SECURITY',
      'biometric'      : 'Biometric authentication',
      'change_password': 'Change password',
      'logout'         : 'Sign out',
      'dark_mode'      : 'Dark mode',
      'favorites'      : 'My favorites',
      'orders'         : 'My orders',
      'cart_empty'     : 'Your cart is empty',
      'view_cart'      : 'View cart',
      'notifications_title': 'Notifications',
      'driver_nearby'  : 'Driver nearby',
      'driver_nearby_sub': 'Alerts when driver is approaching',
      'order_updates'  : 'Order updates',
      'promotions'     : 'Promotions',
      'choose_language': 'Choose Language',
      'about_text'     : 'Version 1.0.0\n\nReal-time delivery tracking mobile application.\n\n© 2025 Glotelho Cameroun',
      'contact_us'     : 'Contact us',
      'faq'            : 'FAQ',
      'profile_title'  : 'My Profile',
      'full_name'      : 'Full name',
      'email'          : 'Email address',
      'phone'          : 'Phone number',
      'save'           : 'Save',
      'privacy_title'  : 'Privacy',
      'share_location' : 'Share my location',
      'share_location_sub': 'Enables real-time tracking',
      'data_analytics' : 'Analytics & data',
      'data_analytics_sub': 'Helps improve the app',
      'old_password'   : 'Current password',
      'new_password'   : 'New password',
      'confirm_password': 'Confirm password',
      'password_changed': 'Password changed successfully!',
      'biometric_enable': 'Enable biometrics',
      'biometric_disable': 'Disable biometrics',
      'biometric_confirm': 'Do you want to enable biometric authentication to secure your account?',
      'cancel'         : 'Cancel',
      'confirm'        : 'Confirm',
      'logout_confirm' : 'Are you sure you want to sign out?',
      'logout_title'   : 'Sign out',
      'yes_logout'     : 'Yes, sign out',
    },
  };

  String t(String key) => _tr[_language]?[key] ?? _tr['Français']![key] ?? key;

  String get salutation {
    final h = DateTime.now().hour;
    if (h < 12) return t('hello_morning');
    if (h < 18) return t('hello_afternoon');
    return t('hello_evening');
  }

  void setLanguage(String lang) {
    if (_language != lang) {
      _language = lang;
      notifyListeners();
    }
  }

  void setDarkMode(bool val) {
    _isDarkMode = val;
    notifyListeners();
  }

  // ✅ updateProfile — corrigé : n'écrase PLUS le token
  void updateProfile({String? firstName, String? lastName, String? name, String? email, String? phone, String? avatarPath}) {
    if (firstName  != null) _userName     = firstName;
    if (lastName   != null) _userLastName = lastName;
    if (name       != null) _userName     = name;
    if (email      != null) _userEmail    = email;
    if (phone      != null) _userPhone    = phone;
    if (avatarPath != null) {
      _userAvatarPath = avatarPath;
      StorageService.saveAvatarPath(avatarPath);
    }
    if (_isLoggedIn) {
      StorageService.updateProfileOnly(
        firstName: _userName,
        lastName:  _userLastName,
        email:     _userEmail,
        phone:     _userPhone,
      );
    }
    notifyListeners();
  }

  // ✅ Mise à jour depuis le serveur (GET /auth/me) — n'écrase pas le token
  void updateFromServer({
    required String fullName,
    required String email,
    required String phone,
    String? avatarUrl,
  }) {
    _userName     = fullName;
    _userLastName = '';
    _userEmail    = email;
    _userPhone    = phone;
    if (avatarUrl != null) _userAvatarPath = avatarUrl;
    StorageService.updateProfileOnly(
      firstName: fullName,
      lastName:  '',
      email:     email,
      phone:     phone,
    );
    notifyListeners();
  }

  // ✅ Mise à jour du token seul (après changement d'email)
  void updateToken(String newToken) {
    StorageService.updateToken(newToken);
    notifyListeners();
  }
}