import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../config/app_strings.dart';
import '../../config/app_theme.dart';
import 'change_password_screen.dart';

/// Écran Paramètres — adaptatif au thème (clair par défaut, navy en
/// mode sombre), sections en cartes : Préférences (Notifications,
/// Langue, Thème), Sécurité (Authentification biométrique, Mot de
/// passe), Gestion (Litiges, Recouvrements), Compte (Déconnexion).
class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});

  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  // TODO: persister ce choix (secure storage) et le brancher sur une
  // vraie API biométrique (package local_auth) une fois prêt.
  bool _biometricEnabled = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.themeMode == ThemeMode.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(AppStrings.t(context, 'settings_title'),
                style: TextStyle(
                    color: onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5)),
            const SizedBox(height: 24),

            _sectionLabel(context, AppStrings.t(context, 'settings_preferences')),
            const SizedBox(height: 10),
            _SettingsCard(children: [
              _SettingsRow(
                icon: Icons.notifications_none,
                title: AppStrings.t(context, 'settings_notifications'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => Navigator.pushNamed(context, '/notifications'),
              ),
              _SettingsRow(
                icon: Icons.language,
                title: AppStrings.t(context, 'settings_language'),
                trailing: _LanguageBadge(locale: appState.locale),
                onTap: () => context.read<AppState>().toggleLocale(),
              ),
              _SettingsRow(
                icon: isDark ? Icons.nightlight_round : Icons.wb_sunny_outlined,
                title: AppStrings.t(context, 'settings_theme'),
                subtitle: isDark
                    ? AppStrings.t(context, 'settings_theme_dark')
                    : AppStrings.t(context, 'settings_theme_light'),
                trailing: Switch(
                  value: isDark,
                  onChanged: (_) => context.read<AppState>().toggleTheme(),
                ),
              ),
            ]),

            const SizedBox(height: 24),
            _sectionLabel(context, AppStrings.t(context, 'settings_security')),
            const SizedBox(height: 10),
            _SettingsCard(children: [
              _SettingsRow(
                icon: Icons.fingerprint,
                title: AppStrings.t(context, 'settings_biometric'),
                trailing: Switch(
                  value: _biometricEnabled,
                  onChanged: (v) => setState(() => _biometricEnabled = v),
                ),
              ),
              _SettingsRow(
                icon: Icons.lock_outline,
                title: AppStrings.t(context, 'settings_password'),
                subtitle: AppStrings.t(context, 'settings_password_sub'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
              ),
            ]),

            const SizedBox(height: 24),
            _sectionLabel(context, AppStrings.t(context, 'settings_management')),
            const SizedBox(height: 10),
            _SettingsCard(children: [
              _SettingsRow(
                icon: Icons.report_gmailerrorred_outlined,
                title: AppStrings.t(context, 'settings_disputes'),
                subtitle: AppStrings.t(context, 'settings_disputes_sub'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => Navigator.pushNamed(context, '/litiges'),
              ),
              _SettingsRow(
                icon: Icons.payments_outlined,
                title: AppStrings.t(context, 'settings_collections'),
                subtitle: AppStrings.t(context, 'settings_collections_sub'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => Navigator.pushNamed(context, '/recouvrements'),
              ),
            ]),

            const SizedBox(height: 24),
            _sectionLabel(context, AppStrings.t(context, 'settings_account')),
            const SizedBox(height: 10),
            _SettingsCard(children: [
              _SettingsRow(
                icon: Icons.logout,
                title: AppStrings.t(context, 'settings_logout'),
                iconColor: const Color(0xFFEF5350),
                titleColor: const Color(0xFFEF5350),
                onTap: () {
                  context.read<AppState>().logout();
                  Navigator.of(context, rootNavigator: true)
                  .pushNamedAndRemoveUntil('/login', (r) => false);
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(
    text,
    style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
        fontSize: 13,
        fontWeight: FontWeight.w600),
  );
}

/// Petit badge drapeau + code langue, comme sur la maquette (🇫🇷 FR).
class _LanguageBadge extends StatelessWidget {
  final String locale;
  const _LanguageBadge({required this.locale});

  @override
  Widget build(BuildContext context) {
    final flag = locale == 'fr' ? '🇫🇷' : '🇬🇧';
    final code = locale.toUpperCase();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(flag, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(code,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }
}

/// Carte adaptative (blanche avec ombre légère en thème clair,
/// translucide sur navy en thème sombre) contenant des _SettingsRow.
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
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(
                  height: 1,
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                  indent: 20,
                  endIndent: 20),
          ],
        ],
      ),
    );
  }
}

/// Ligne de paramètre adaptative : icône dans un carré arrondi, titre,
/// sous-titre optionnel, élément trailing (switch, chevron, badge...).
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : AppTheme.navy).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor ?? onSurface, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: titleColor ?? onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(
                            color: onSurface.withOpacity(0.55), fontSize: 12)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}