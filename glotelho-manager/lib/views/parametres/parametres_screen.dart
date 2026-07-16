import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../config/app_strings.dart';
import '../../config/app_theme.dart';
import 'change_password_screen.dart';

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});
  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  bool _biometricEnabled  = false;
  bool _notifEnabled      = true;
  bool _positionEnabled   = false;

  @override
  Widget build(BuildContext context) {
    final appState  = context.watch<AppState>();
    final isDark    = appState.themeMode == ThemeMode.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final manager   = appState.currentManager;
    final prenom    = manager?['first_name'] ?? '';
    final nom       = manager?['last_name']  ?? '';
    final email     = manager?['email']      ?? '';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [

            // ── EN-TÊTE ──────────────────────────────────────
            Text(AppStrings.t(context, 'settings_title'),
                style: TextStyle(color: onSurface, fontSize: 24,
                    fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            const SizedBox(height: 20),

            // Carte profil
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFF0D1B2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFC9952E).withOpacity(0.2),
                    child: Text(prenom.isNotEmpty ? prenom[0].toUpperCase() : 'C',
                        style: const TextStyle(color: Color(0xFFC9952E), fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$prenom $nom',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC9952E).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Commerçant',
                              style: TextStyle(color: Color(0xFFC9952E), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── PRÉFÉRENCES ───────────────────────────────────
            _sectionLabel(context, AppStrings.t(context, 'settings_preferences')),
            const SizedBox(height: 10),
            _SettingsCard(children: [
              // Notifications
              _SettingsRow(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Recevoir les alertes de livraison',
                trailing: Switch(
                  value: _notifEnabled,
                  activeColor: const Color(0xFFC9952E),
                  onChanged: (v) => setState(() => _notifEnabled = v),
                ),
              ),
              // Position GPS
              _SettingsRow(
                icon: Icons.my_location_outlined,
                title: 'Activer ma position',
                subtitle: 'Permet de suivre vos livraisons en temps réel',
                trailing: Switch(
                  value: _positionEnabled,
                  activeColor: const Color(0xFFC9952E),
                  onChanged: (v) => setState(() => _positionEnabled = v),
                ),
              ),
              // Langue
              _SettingsRow(
                icon: Icons.language,
                title: AppStrings.t(context, 'settings_language'),
                subtitle: appState.locale == 'fr' ? 'Français' : 'English',
                trailing: _LanguageBadge(locale: appState.locale),
                onTap: () => context.read<AppState>().toggleLocale(),
              ),
              // Thème
              _SettingsRow(
                icon: isDark ? Icons.nightlight_round : Icons.wb_sunny_outlined,
                title: AppStrings.t(context, 'settings_theme'),
                subtitle: isDark ? 'Sombre (Navy)' : 'Clair',
                trailing: Switch(
                  value: isDark,
                  activeColor: const Color(0xFFC9952E),
                  onChanged: (_) => context.read<AppState>().toggleTheme(),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            // ── SÉCURITÉ ──────────────────────────────────────
            _sectionLabel(context, AppStrings.t(context, 'settings_security')),
            const SizedBox(height: 10),
            _SettingsCard(children: [
              // Biométrie
              _SettingsRow(
                icon: Icons.fingerprint,
                title: AppStrings.t(context, 'settings_biometric'),
                subtitle: 'Face ID, empreinte digitale',
                trailing: Switch(
                  value: _biometricEnabled,
                  activeColor: const Color(0xFFC9952E),
                  onChanged: (v) => setState(() => _biometricEnabled = v),
                ),
              ),
              // Mot de passe
              _SettingsRow(
                icon: Icons.lock_outline,
                title: AppStrings.t(context, 'settings_password'),
                subtitle: 'Modifier votre mot de passe de connexion',
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
              ),
            ]),

            const SizedBox(height: 24),

            // ── SUPPORT ───────────────────────────────────────
            _sectionLabel(context, 'Support & Informations'),
            const SizedBox(height: 10),
            _SettingsCard(children: [
              _SettingsRow(
                icon: Icons.help_outline,
                title: 'Aide & Support',
                subtitle: 'FAQ, contact Glotelho',
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _showInfo(context, 'Aide', 'Pour toute assistance, contactez-nous sur\nglotelho@gmail.com'),
              ),
              _SettingsRow(
                icon: Icons.privacy_tip_outlined,
                title: 'Confidentialité',
                subtitle: 'Politique de confidentialité',
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _showInfo(context, 'Confidentialité', 'Vos données sont protégées et ne sont jamais revendues à des tiers.'),
              ),
              _SettingsRow(
                icon: Icons.info_outline,
                title: 'À propos',
                subtitle: 'Glotelho Commerçant v1.0',
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _showInfo(context, 'À propos', 'Glotelho Commerçant\nVersion 1.0.0\n\nPlateforme de gestion, et de suivi des livraisons.'),
              ),
            ]),

            const SizedBox(height: 24),

            // ── COMPTE ────────────────────────────────────────
            _sectionLabel(context, AppStrings.t(context, 'settings_account')),
            const SizedBox(height: 10),
            _SettingsCard(children: [
              _SettingsRow(
                icon: Icons.logout,
                title: AppStrings.t(context, 'settings_logout'),
                iconColor: const Color(0xFFEF5350),
                titleColor: const Color(0xFFEF5350),
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      title: const Text('Déconnexion'),
                      content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          child: const Text('Déconnecter'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    context.read<AppState>().logout();
                    Navigator.of(context, rootNavigator: true)
                        .pushNamedAndRemoveUntil('/login', (r) => false);
                  }
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showInfo(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title),
        content: Text(content),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(text,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
          fontSize: 13, fontWeight: FontWeight.w600));
}

class _LanguageBadge extends StatelessWidget {
  final String locale;
  const _LanguageBadge({required this.locale});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(locale == 'fr' ? '🇫🇷' : '🇬🇧', style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(locale.toUpperCase(),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1)
            Divider(height: 1,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.07),
                indent: 20, endIndent: 20),
        ],
      ]),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon, required this.title,
    this.subtitle, this.trailing, this.iconColor, this.titleColor, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : AppTheme.navy).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor ?? onSurface, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: titleColor ?? onSurface,
                  fontSize: 14, fontWeight: FontWeight.w700)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 11)),
              ],
            ],
          )),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}