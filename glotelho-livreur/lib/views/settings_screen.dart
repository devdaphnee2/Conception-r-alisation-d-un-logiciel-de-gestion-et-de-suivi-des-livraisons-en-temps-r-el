import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/driver_state.dart';
import '../views/splash_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _locationEnabled = true;
  String _selectedTheme = 'Sombre';
  String _selectedLanguage = 'Français';

  // Modal BottomSheet moderne pour la sélection (Thème / Langue)
  void _showSelectionBottomSheet({
    required String title,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map((option) {
                  final isSelected = option == currentValue;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? AppColors.gold : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.gold)
                        : null,
                    onTap: () {
                      onSelected(option);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // Confirmation et processus de déconnexion
  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter de votre compte livreur ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    // 1. Déconnexion et nettoyage de la session / polling
    await context.read<DriverState>().logout();

    if (!mounted) return;

    // 2. Redirection DIRECTE vers l'écran de connexion sans passer par le Splash
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false, // Efface tout l'historique de navigation
    );
  }

  void _navigateToProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouverture du profil du livreur...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(color: Colors.white70, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverState = context.watch<DriverState>();
    final driver = driverState.driver;
    final nom = driver != null ? '${driver.prenom} ${driver.nom}' : 'Livreur Glotelho';
    final phone = driver?.telephone ?? '+237 --- --- ---';
    final photo = driver?.photoPath;
    final isOnline = driverState.isOnline;

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: const Text(
          'Paramètres',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          children: [
            // --- CARTE PROFIL EN TÊTE ---
            Material(
              color: AppColors.cardNavy,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _navigateToProfile,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white10,
                            backgroundImage: photo != null ? NetworkImage(photo) : null,
                            child: photo == null
                                ? const Icon(Icons.person, color: Colors.white70, size: 36)
                                : null,
                          ),
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: isOnline ? Colors.greenAccent : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.cardNavy, width: 2),
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nom,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              phone,
                              style: const TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isOnline ? Colors.green : Colors.orange).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isOnline ? 'En service' : 'Hors service',
                                style: TextStyle(
                                  color: isOnline ? Colors.greenAccent : Colors.orangeAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white38),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- SECTION COMPTE ---
            _buildSectionHeader('COMPTE'),
            _buildGroupedContainer([
              _buildTileItem(
                icon: Icons.person_outline,
                iconColor: Colors.blueAccent,
                label: 'Informations du profil',
                onTap: _navigateToProfile,
              ),
              _buildDivider(),
              _buildTileItem(
                icon: Icons.lock_outline,
                iconColor: Colors.amberAccent,
                label: 'Sécurité & Mot de passe',
                onTap: () => _showInfoDialog(
                  'Sécurité',
                  'Pour modifier votre mot de passe ou mettre à jour vos identifiants, veuillez contacter le support administrateur Glotelho.',
                ),
              ),
              _buildDivider(),
              _buildTileItem(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: Colors.greenAccent,
                label: 'Moyens de retrait',
                trailingText: 'Mobile Money',
                onTap: () => _showInfoDialog(
                  'Moyens de retrait',
                  'Les gains de vos livraisons sont automatiquement transférés vers votre compte Mobile Money/Orange Money enregistré.',
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // --- SECTION PREFERENCES ---
            _buildSectionHeader('PRÉFÉRENCES'),
            _buildGroupedContainer([
              _buildSwitchItem(
                icon: Icons.location_on_outlined,
                iconColor: Colors.redAccent,
                label: 'Activer ma localisation',
                value: _locationEnabled,
                onChanged: (v) => setState(() => _locationEnabled = v),
              ),
              _buildDivider(),
              _buildSwitchItem(
                icon: Icons.notifications_none,
                iconColor: Colors.purpleAccent,
                label: 'Notifications Push',
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
              ),
              _buildDivider(),
              _buildTileItem(
                icon: Icons.language,
                iconColor: Colors.tealAccent,
                label: 'Langue de l\'application',
                trailingText: _selectedLanguage,
                onTap: () {
                  _showSelectionBottomSheet(
                    title: 'Langue de l\'application',
                    options: ['Français', 'English'],
                    currentValue: _selectedLanguage,
                    onSelected: (val) => setState(() => _selectedLanguage = val),
                  );
                },
              ),
              _buildDivider(),
              _buildTileItem(
                icon: Icons.dark_mode_outlined,
                iconColor: Colors.orangeAccent,
                label: 'Thème d\'affichage',
                trailingText: _selectedTheme,
                onTap: () {
                  _showSelectionBottomSheet(
                    title: 'Thème d\'affichage',
                    options: ['Sombre', 'Clair', 'Système'],
                    currentValue: _selectedTheme,
                    onSelected: (val) => setState(() => _selectedTheme = val),
                  );
                },
              ),
            ]),
            const SizedBox(height: 24),

            // --- SECTION SUPPORT ---
            _buildSectionHeader('SUPPORT & À PROPOS'),
            _buildGroupedContainer([
              _buildTileItem(
                icon: Icons.help_outline,
                iconColor: Colors.cyanAccent,
                label: 'Aide & FAQ',
                onTap: () => _showInfoDialog(
                  'Aide & Support',
                  'Besoin d\'assistance durant une course ?\nContactez le dispatch au +237 600 000 000 ou via le Backoffice.',
                ),
              ),
              _buildDivider(),
              _buildTileItem(
                icon: Icons.info_outline,
                iconColor: Colors.indigoAccent,
                label: 'À propos de Glotelho Delivery',
                onTap: () => _showInfoDialog(
                  'Glotelho Delivery',
                  'Application officielle de suivi et gestion des livraisons en temps réel.\nVersion 1.0.0 (Build 2026)',
                ),
              ),
            ]),
            const SizedBox(height: 32),

            // --- BOUTON DECONNEXION ---
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                label: const Text(
                  'Déconnexion',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.redAccent.withOpacity(0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Glotelho Express © 2026 • v1.0.0',
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE COMPOSANTS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildGroupedContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: Colors.white10, indent: 56);
  }

  Widget _buildTileItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
        ],
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: Switch.adaptive(
        value: value,
        activeColor: AppColors.gold,
        onChanged: onChanged,
      ),
    );
  }
}