import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_state.dart';
import 'package:provider/provider.dart';

/// Menu latéral principal — reprend les 7 sections du back-office web
/// (Dashboard, Livraisons, Livreurs, Litiges, Recouvrements, Tracking,
/// Paramètres) définies dans App.jsx côté frontend.
class AppDrawer extends StatelessWidget {
  final String currentRoute;
  const AppDrawer({super.key, required this.currentRoute});

  static const _items = [
    _DrawerItem('/dashboard', Icons.dashboard_outlined, 'Dashboard'),
    _DrawerItem('/livraisons', Icons.local_shipping_outlined, 'Livraisons'),
    _DrawerItem('/livreurs', Icons.badge_outlined, 'Livreurs'),
    _DrawerItem('/litiges', Icons.report_gmailerrorred_outlined, 'Litiges'),
    _DrawerItem('/recouvrements', Icons.payments_outlined, 'Recouvrements'),
    _DrawerItem('/tracking', Icons.map_outlined, 'Tracking'),
    _DrawerItem('/parametres', Icons.settings_outlined, 'Paramètres'),
  ];

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AppState>().currentManager;

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              color: AppColors.inverseSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(radius: 24, child: Icon(Icons.person)),
                  const SizedBox(height: 10),
                  Text(manager?['name'] ?? 'Manager',
                      style: TextStyle(
                          color: AppColors.inverseSurfaceOn,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _items
                    .map((item) => ListTile(
                  leading: Icon(item.icon,
                      color: currentRoute == item.route
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant),
                  title: Text(item.label,
                      style: TextStyle(
                          fontWeight: currentRoute == item.route
                              ? FontWeight.bold
                              : FontWeight.normal)),
                  selected: currentRoute == item.route,
                  selectedTileColor: AppColors.primaryFixed,
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != item.route) {
                      Navigator.pushReplacementNamed(context, item.route);
                    }
                  },
                ))
                    .toList(),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Déconnexion'),
              onTap: () {
                context.read<AppState>().logout();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem {
  final String route;
  final IconData icon;
  final String label;
  const _DrawerItem(this.route, this.icon, this.label);
}