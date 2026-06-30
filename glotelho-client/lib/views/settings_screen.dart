/*import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  String _selectedLanguage = 'Français';

  final Map<String, Map<String, String>> _strings = {
    'Français': {
      'settings': 'Paramètres',
      'subtitle': 'Gérez vos préférences',
      'account': 'COMPTE',
      'profile': 'Profil',
      'privacy': 'Confidentialité',
      'general': 'GÉNÉRAL',
      'notifications': 'Notifications',
      'language': 'Langue',
      'about': 'À propos',
      'help': 'Aide & Support',
      'logout': 'Se déconnecter',
      'dark_mode': 'Mode sombre',
    },
    'English': {
      'settings': 'Settings',
      'subtitle': 'Manage your preferences',
      'account': 'ACCOUNT',
      'profile': 'Profile',
      'privacy': 'Privacy',
      'general': 'GENERAL',
      'notifications': 'Notifications',
      'language': 'Language',
      'about': 'About',
      'help': 'Help & Support',
      'logout': 'Sign out',
      'dark_mode': 'Dark mode',
    },
  };

  String t(String key) =>
      _strings[_selectedLanguage]?[key] ?? _strings['Français']![key]!;

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: _isDarkMode ? const Color(0xFF1E2A38) : Colors.white,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _selectedLanguage == 'Français' ? 'Choisir la langue' : 'Choose Language',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              for (final lang in ['Français', 'English'])
                ListTile(
                  leading: Text(
                    lang == 'Français' ? '🇫🇷' : '🇬🇧',
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(lang,
                      style: TextStyle(
                        fontWeight: _selectedLanguage == lang
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _isDarkMode ? Colors.white : Colors.black87,
                      )),
                  trailing: _selectedLanguage == lang
                      ? Icon(Icons.check_circle,
                      color: AppColors.gold, size: 22)
                      : null,
                  onTap: () {
                    setState(() => _selectedLanguage = lang);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: _isDarkMode ? const Color(0xFF1E2A38) : Colors.white,
      builder: (_) => _NotificationSettingsSheet(
          isDark: _isDarkMode, lang: _selectedLanguage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = _isDarkMode ? const Color(0xFF0D1B2A) : const Color(0xFFF5F5F5);
    final cardBg = _isDarkMode ? const Color(0xFF1E2A38) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    final subColor = _isDarkMode ? Colors.white54 : Colors.grey;

    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: _isDarkMode ? const Color(0xFF0D1B2A) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: _isDarkMode ? Colors.white : Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            t('settings'),
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── En-tête : Titre + Toggle jour/nuit ──────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('settings'),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t('subtitle'),
                          style: TextStyle(fontSize: 13, color: subColor),
                        ),
                      ],
                    ),
                  ),
                  // Toggle jour/nuit avec icônes soleil/lune
                  GestureDetector(
                    onTap: () =>
                        setState(() => _isDarkMode = !_isDarkMode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 72,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _isDarkMode
                            ? const Color(0xFF1E3A5F)
                            : const Color(0xFFFFD54F),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        children: [
                          // Icône soleil (gauche)
                          Positioned(
                            left: 6,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Text(
                                '☀️',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _isDarkMode
                                      ? Colors.white30
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // Icône lune (droite)
                          Positioned(
                            right: 6,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Text(
                                '🌙',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _isDarkMode
                                      ? Colors.white
                                      : Colors.white30,
                                ),
                              ),
                            ),
                          ),
                          // Curseur animé
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            left: _isDarkMode ? 36 : 2,
                            top: 2,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _isDarkMode ? '🌙' : '☀️',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Section COMPTE ───────────────────────────────
              Text(t('account'),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: subColor,
                      letterSpacing: 1)),
              const SizedBox(height: 10),
              _buildCard(cardBg, [
                _buildItem(Icons.person_outline, t('profile'), textColor,
                    onTap: () {}),
                _buildDivider(cardBg),
                _buildItem(Icons.lock_outline, t('privacy'), textColor,
                    onTap: () {}),
              ]),

              const SizedBox(height: 22),

              // ── Section GÉNÉRAL ──────────────────────────────
              Text(t('general'),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: subColor,
                      letterSpacing: 1)),
              const SizedBox(height: 10),
              _buildCard(cardBg, [
                _buildItem(
                  Icons.notifications_outlined,
                  t('notifications'),
                  textColor,
                  onTap: _showNotificationSettings,
                ),
                _buildDivider(cardBg),
                _buildItem(
                  Icons.language_outlined,
                  t('language'),
                  textColor,
                  trailing: Text(
                    _selectedLanguage == 'Français' ? '🇫🇷 FR' : '🇬🇧 EN',
                    style: TextStyle(color: subColor, fontSize: 13),
                  ),
                  onTap: _showLanguagePicker,
                ),
                _buildDivider(cardBg),
                _buildItem(Icons.info_outline, t('about'), textColor,
                    onTap: () => _showAbout(context, textColor, cardBg)),
                _buildDivider(cardBg),
                _buildItem(Icons.help_outline, t('help'), textColor,
                    onTap: () {}),
              ]),

              const SizedBox(height: 22),

              // ── Section SÉCURITÉ ─────────────────────────────
              Text(
                _selectedLanguage == 'Français' ? 'SÉCURITÉ' : 'SECURITY',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: subColor,
                    letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              _buildCard(cardBg, [
                _buildItem(
                  Icons.fingerprint,
                  _selectedLanguage == 'Français'
                      ? 'Authentification biométrique'
                      : 'Biometric authentication',
                  textColor,
                  trailing: Switch(
                    value: false,
                    onChanged: (_) {},
                    activeColor: AppColors.gold,
                  ),
                ),
                _buildDivider(cardBg),
                _buildItem(
                  Icons.password_outlined,
                  _selectedLanguage == 'Français'
                      ? 'Changer le mot de passe'
                      : 'Change password',
                  textColor,
                  onTap: () {},
                ),
              ]),

              const SizedBox(height: 28),

              // ── Bouton Déconnexion ───────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.logout, color: Colors.red, size: 20),
                  label: Text(
                    t('logout'),
                    style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 1.2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Glotelho Express v1.0.0',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Color bg, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(Color bg) =>
      Divider(height: 1, color: _isDarkMode ? Colors.white10 : Colors.grey.shade100);

  Widget _buildItem(
      IconData icon,
      String label,
      Color textColor, {
        Widget? trailing,
        VoidCallback? onTap,
      }) {
    return ListTile(
      leading: Icon(icon,
          color: _isDarkMode ? Colors.white70 : Colors.black87, size: 22),
      title: Text(label,
          style: TextStyle(fontSize: 14, color: textColor)),
      trailing: trailing ??
          Icon(Icons.chevron_right,
              color: _isDarkMode ? Colors.white38 : Colors.grey.shade400,
              size: 20),
      onTap: onTap,
      dense: true,
    );
  }

  void _showAbout(BuildContext context, Color textColor, Color cardBg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Glotelho Express',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: textColor)),
        content: Text(
          _selectedLanguage == 'Français'
              ? 'Version 1.0.0\n\nApplication mobile de suivi des livraisons en temps réel.\n\n© 2025 Glotelho Cameroun'
              : 'Version 1.0.0\n\nReal-time delivery tracking mobile application.\n\n© 2025 Glotelho Cameroun',
          style: TextStyle(fontSize: 13, color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Sheet Paramètres notifications
// ─────────────────────────────────────────────────────────────────
class _NotificationSettingsSheet extends StatefulWidget {
  final bool isDark;
  final String lang;
  const _NotificationSettingsSheet(
      {required this.isDark, required this.lang});

  @override
  State<_NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends State<_NotificationSettingsSheet> {
  bool _proximity = true;
  bool _orders = true;
  bool _promos = false;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.lang == 'Français'
                ? 'Paramètres des notifications'
                : 'Notification Settings',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textColor),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _proximity,
            onChanged: (v) => setState(() => _proximity = v),
            activeColor: AppColors.gold,
            title: Text(
              widget.lang == 'Français'
                  ? 'Livreur à proximité'
                  : 'Driver nearby',
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            subtitle: Text(
              widget.lang == 'Français'
                  ? 'Alertes quand le livreur approche'
                  : 'Alerts when driver is approaching',
              style: TextStyle(
                  fontSize: 12, color: textColor.withOpacity(0.6)),
            ),
            secondary:
            Icon(Icons.delivery_dining, color: AppColors.gold),
          ),
          SwitchListTile(
            value: _orders,
            onChanged: (v) => setState(() => _orders = v),
            activeColor: AppColors.gold,
            title: Text(
              widget.lang == 'Français'
                  ? 'Mises à jour commandes'
                  : 'Order updates',
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            secondary: Icon(Icons.receipt_outlined, color: AppColors.gold),
          ),
          SwitchListTile(
            value: _promos,
            onChanged: (v) => setState(() => _promos = v),
            activeColor: AppColors.gold,
            title: Text(
              widget.lang == 'Français' ? 'Promotions' : 'Promotions',
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            secondary:
            Icon(Icons.local_offer_outlined, color: AppColors.gold),
          ),
        ],
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final isDark = state.isDarkMode;
    final bg       = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF5F5F5);
    final cardBg   = isDark ? const Color(0xFF1E2A38) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor  = isDark ? Colors.white54 : Colors.grey;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0D1B2A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t('settings'),
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête + toggle jour/nuit ───────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t('settings'),
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                      const SizedBox(height: 4),
                      Text(t('subtitle'),
                          style: TextStyle(fontSize: 13, color: subColor)),
                    ],
                  ),
                ),
                _DayNightToggle(isDark: isDark, onToggle: () {
                  context.read<AppState>().setDarkMode(!isDark);
                }),
              ],
            ),
            const SizedBox(height: 28),

            // ── COMPTE ──────────────────────────────────────
            _SectionLabel(t('section_account'), subColor),
            const SizedBox(height: 10),
            _SettingsCard(isDark: isDark, children: [
              _SettingsItem(
                icon: Icons.person_outline,
                label: t('profile'),
                textColor: textColor,
                isDark: isDark,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen())),
              ),
              _Divider(isDark),
              _SettingsItem(
                icon: Icons.lock_outline,
                label: t('privacy'),
                textColor: textColor,
                isDark: isDark,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PrivacyScreen())),
              ),
            ]),
            const SizedBox(height: 22),

            // ── GÉNÉRAL ─────────────────────────────────────
            _SectionLabel(t('section_general'), subColor),
            const SizedBox(height: 10),
            _SettingsCard(isDark: isDark, children: [
              _SettingsItem(
                icon: Icons.notifications_outlined,
                label: t('notifications'),
                textColor: textColor,
                isDark: isDark,
                onTap: () => _showNotificationSettings(context, state),
              ),
              _Divider(isDark),
              _SettingsItem(
                icon: Icons.language_outlined,
                label: t('language'),
                textColor: textColor,
                isDark: isDark,
                trailing: Text(
                  state.language == 'Français' ? '🇫🇷 FR' : '🇬🇧 EN',
                  style: TextStyle(color: subColor, fontSize: 13),
                ),
                onTap: () => _showLanguagePicker(context, state),
              ),
              _Divider(isDark),
              _SettingsItem(
                icon: Icons.info_outline,
                label: t('about'),
                textColor: textColor,
                isDark: isDark,
                onTap: () => _showAbout(context, state),
              ),
              _Divider(isDark),
              _SettingsItem(
                icon: Icons.help_outline,
                label: t('help'),
                textColor: textColor,
                isDark: isDark,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HelpScreen())),
              ),
            ]),
            const SizedBox(height: 22),

            // ── SÉCURITÉ ─────────────────────────────────────
            _SectionLabel(t('section_security'), subColor),
            const SizedBox(height: 10),
            _SettingsCard(isDark: isDark, children: [
              _SettingsItem(
                icon: Icons.fingerprint,
                label: t('biometric'),
                textColor: textColor,
                isDark: isDark,
                trailing: Switch(
                  value: state.biometricEnabled,
                  activeColor: AppColors.gold,
                  onChanged: (val) => _toggleBiometric(context, state, val),
                ),
              ),
              _Divider(isDark),
              _SettingsItem(
                icon: Icons.password_outlined,
                label: t('change_password'),
                textColor: textColor,
                isDark: isDark,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen())),
              ),
            ]),
            const SizedBox(height: 28),

            // ── Bouton déconnexion ───────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context, state),
                icon: const Icon(Icons.logout, color: Colors.red, size: 20),
                label: Text(t('logout'),
                    style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('Glotelho Express v1.0.0',
                  style: TextStyle(fontSize: 12, color: subColor)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  void _toggleBiometric(
      BuildContext context, AppState state, bool val) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(val ? state.t('biometric_enable') : state.t('biometric_disable')),
        content: Text(state.t('biometric_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(state.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              state.setBiometric(val);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold),
            child: Text(state.t('confirm'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(state.t('logout_title')),
        content: Text(state.t('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(state.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              // Ferme le dialog + revient à LoginScreen en vidant la pile
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(state.t('yes_logout'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            const SizedBox(height: 16),
            Text(state.t('choose_language'),
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            for (final lang in ['Français', 'English'])
              ListTile(
                leading: Text(lang == 'Français' ? '🇫🇷' : '🇬🇧',
                    style: const TextStyle(fontSize: 24)),
                title: Text(lang,
                    style: TextStyle(
                        fontWeight: state.language == lang
                            ? FontWeight.bold
                            : FontWeight.normal)),
                trailing: state.language == lang
                    ? Icon(Icons.check_circle, color: AppColors.gold)
                    : null,
                onTap: () {
                  state.setLanguage(lang);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ChangeNotifierProvider.value(
        value: state,
        child: const _NotificationSettingsSheet(),
      ),
    );
  }

  void _showAbout(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Glotelho Express',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(state.t('about_text'),
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  Widget _sheetHandle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// Toggle jour/nuit
// ─────────────────────────────────────────────────────────────────
class _DayNightToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;
  const _DayNightToggle({required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 72,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFFFD54F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 6, top: 0, bottom: 0,
              child: Center(child: Text('☀️', style: TextStyle(fontSize: 15, color: isDark ? Colors.white24 : Colors.white))),
            ),
            Positioned(
              right: 6, top: 0, bottom: 0,
              child: Center(child: Text('🌙', style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.white24))),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: isDark ? 36 : 2,
              top: 2,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                ),
                child: Center(child: Text(isDark ? '🌙' : '☀️', style: const TextStyle(fontSize: 16))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Widgets helpers internes
// ─────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel(this.label, this.color);
  @override
  Widget build(BuildContext context) => Text(label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 1));
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const _SettingsCard({required this.isDark, required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A38) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 8)],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final bool isDark;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsItem({
    required this.icon, required this.label,
    required this.textColor, required this.isDark,
    this.trailing, this.onTap,
  });
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black87, size: 22),
    title: Text(label, style: TextStyle(fontSize: 14, color: textColor)),
    trailing: trailing ?? Icon(Icons.chevron_right, color: isDark ? Colors.white38 : Colors.grey.shade400, size: 20),
    onTap: onTap,
    dense: true,
  );
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider(this.isDark);
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100);
}

// ─────────────────────────────────────────────────────────────────
// Notifications bottom sheet
// ─────────────────────────────────────────────────────────────────
class _NotificationSettingsSheet extends StatefulWidget {
  const _NotificationSettingsSheet();
  @override
  State<_NotificationSettingsSheet> createState() => _NotifSheetState();
}
class _NotifSheetState extends State<_NotificationSettingsSheet> {
  bool _proximity = true, _orders = true, _promos = false;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(t('notifications_title'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _proximity, activeColor: AppColors.gold,
            onChanged: (v) => setState(() => _proximity = v),
            secondary: Icon(Icons.delivery_dining, color: AppColors.gold),
            title: Text(t('driver_nearby'), style: const TextStyle(fontSize: 14)),
            subtitle: Text(t('driver_nearby_sub'), style: const TextStyle(fontSize: 12)),
          ),
          SwitchListTile(
            value: _orders, activeColor: AppColors.gold,
            onChanged: (v) => setState(() => _orders = v),
            secondary: Icon(Icons.receipt_outlined, color: AppColors.gold),
            title: Text(t('order_updates'), style: const TextStyle(fontSize: 14)),
          ),
          SwitchListTile(
            value: _promos, activeColor: AppColors.gold,
            onChanged: (v) => setState(() => _promos = v),
            secondary: Icon(Icons.local_offer_outlined, color: AppColors.gold),
            title: Text(t('promotions'), style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Écran Profil
// ─────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameCtrl, _emailCtrl, _phoneCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _nameCtrl  = TextEditingController(text: state.userName);
    _emailCtrl = TextEditingController(text: state.userEmail);
    _phoneCtrl = TextEditingController(text: state.userPhone);
  }
  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Text(t('profile_title'), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.gold,
                  child: Text(state.userName.isNotEmpty ? state.userName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(color: AppColors.navy, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _profileField(t('full_name'), _nameCtrl, Icons.person_outline),
            const SizedBox(height: 16),
            _profileField(t('email'), _emailCtrl, Icons.email_outlined, type: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _profileField(t('phone'), _phoneCtrl, Icons.phone_outlined, type: TextInputType.phone),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () async {
                  setState(() => _isSaving = true);
                  await Future.delayed(const Duration(seconds: 1));
                  context.read<AppState>().updateProfile(
                    name: _nameCtrl.text, email: _emailCtrl.text, phone: _phoneCtrl.text,
                  );
                  setState(() => _isSaving = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(t('save')), backgroundColor: Colors.green));
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(t('save'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileField(String label, TextEditingController ctrl, IconData icon, {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl, keyboardType: type,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.navy, size: 20),
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.gold, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Écran Confidentialité
// ─────────────────────────────────────────────────────────────────
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});
  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}
class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _shareLocation = true, _dataAnalytics = false;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Text(t('privacy_title'), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _shareLocation, activeColor: AppColors.gold,
                    onChanged: (v) => setState(() => _shareLocation = v),
                    secondary: Icon(Icons.location_on_outlined, color: AppColors.gold),
                    title: Text(t('share_location'), style: const TextStyle(fontSize: 14)),
                    subtitle: Text(t('share_location_sub'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  SwitchListTile(
                    value: _dataAnalytics, activeColor: AppColors.gold,
                    onChanged: (v) => setState(() => _dataAnalytics = v),
                    secondary: Icon(Icons.analytics_outlined, color: AppColors.gold),
                    title: Text(t('data_analytics'), style: const TextStyle(fontSize: 14)),
                    subtitle: Text(t('data_analytics_sub'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Écran Changer mot de passe
// ─────────────────────────────────────────────────────────────────
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePwdState();
}
class _ChangePwdState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController(), _newCtrl = TextEditingController(), _confirmCtrl = TextEditingController();
  bool _oldHidden = true, _newHidden = true, _confirmHidden = true, _isSaving = false;

  @override
  void dispose() { _oldCtrl.dispose(); _newCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Text(t('change_password'), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              _pwdField(t('old_password'), _oldCtrl, _oldHidden, () => setState(() => _oldHidden = !_oldHidden),
                      (v) => (v == null || v.isEmpty) ? 'Obligatoire' : null),
              const SizedBox(height: 16),
              _pwdField(t('new_password'), _newCtrl, _newHidden, () => setState(() => _newHidden = !_newHidden),
                      (v) => (v == null || v.length < 6) ? 'Au moins 6 caractères' : null),
              const SizedBox(height: 16),
              _pwdField(t('confirm_password'), _confirmCtrl, _confirmHidden, () => setState(() => _confirmHidden = !_confirmHidden),
                      (v) => v != _newCtrl.text ? 'Les mots de passe ne correspondent pas' : null),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _isSaving = true);
                    await Future.delayed(const Duration(seconds: 1));
                    setState(() => _isSaving = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(t('password_changed')), backgroundColor: Colors.green));
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(t('save'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pwdField(String label, TextEditingController ctrl, bool hidden, VoidCallback toggle, String? Function(String?) validator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl, obscureText: hidden, validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline, color: AppColors.navy, size: 20),
            suffixIcon: IconButton(icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: Colors.grey), onPressed: toggle),
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.gold, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Écran Aide & Support
// ─────────────────────────────────────────────────────────────────
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final faqs = state.language == 'Français'
        ? [
      {'q': 'Comment suivre ma livraison ?', 'a': 'Allez dans l\'onglet Suivi et entrez votre numéro de commande.'},
      {'q': 'Comment annuler une commande ?', 'a': 'Ouvrez votre commande dans l\'historique et appuyez sur Annuler.'},
      {'q': 'Comment contacter un livreur ?', 'a': 'Dans les détails de la commande, appuyez sur le bouton Contacter.'},
      {'q': 'Quels modes de paiement sont acceptés ?', 'a': 'Orange Money, MTN MoMo et espèces à la livraison.'},
    ]
        : [
      {'q': 'How to track my delivery?', 'a': 'Go to the Tracking tab and enter your order number.'},
      {'q': 'How to cancel an order?', 'a': 'Open your order in history and tap Cancel.'},
      {'q': 'How to contact a driver?', 'a': 'In order details, tap the Contact button.'},
      {'q': 'What payment methods are accepted?', 'a': 'Orange Money, MTN MoMo and cash on delivery.'},
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Text(t('help'), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('faq'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            ...faqs.map((faq) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                title: Text(faq['q']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Text(faq['a']!, style: const TextStyle(fontSize: 13, color: Colors.grey)))],
              ),
            )),
            const SizedBox(height: 20),
            Text(t('contact_us'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(leading: Icon(Icons.email_outlined, color: AppColors.gold), title: const Text('support@glotelho.cm'), dense: true),
                  Divider(height: 1, color: Colors.grey.shade100),
                  ListTile(leading: Icon(Icons.phone_outlined, color: AppColors.gold), title: const Text('+237 6XX XXX XXX'), dense: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}