import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_state.dart';

/// Menu "Plus" ouvert depuis la bottom nav : donne accès aux sections
/// secondaires non présentes dans la barre du bas (Litiges, Recouvrements),
/// plus Paramètres et Déconnexion.
void showPlusMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Wrap(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.report_gmailerrorred_outlined),
            title: const Text('Litiges'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/litiges');
            },
          ),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Recouvrements'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/recouvrements');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Paramètres'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/parametres');
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(ctx);
              context.read<AppState>().logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}