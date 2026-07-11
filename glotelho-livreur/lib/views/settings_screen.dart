import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Paramètres',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // Profil
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.cardNavy, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const CircleAvatar(radius: 28, backgroundColor: Colors.white12,
                      child: Icon(Icons.person, color: Colors.white70, size: 30)),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Livreur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                      SizedBox(height: 2),
                      Text('Voir le profil', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.white38),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _section('Compte'),
            _tile(Icons.person_outline, 'Profil'),
            _tile(Icons.lock_outline, 'Sécurité'),
            _tile(Icons.account_balance_wallet_outlined, 'Moyens de retrait'),
            const SizedBox(height: 20),
            _section('Préférences'),
            _switchTile(Icons.notifications_none, 'Notifications', true),
            _tile(Icons.language, 'Langue', trailing: 'Français'),
            _tile(Icons.dark_mode_outlined, 'Thème', trailing: 'Sombre'),
            const SizedBox(height: 20),
            _section('Support'),
            _tile(Icons.help_outline, 'Aide & FAQ'),
            _tile(Icons.info_outline, 'À propos'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('Déconnexion', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('Version 1.0.0', style: TextStyle(color: Colors.white24, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
  );

  Widget _tile(IconData icon, String label, {String? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: AppColors.cardNavy, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: Colors.white70),
        title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) Text(trailing, style: const TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
        onTap: () {},
      ),
    );
  }

  Widget _switchTile(IconData icon, String label, bool value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppColors.cardNavy, borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon, color: Colors.white70),
        title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
        value: value,
        activeColor: AppColors.gold,
        onChanged: (_) {},
      ),
    );
  }
}