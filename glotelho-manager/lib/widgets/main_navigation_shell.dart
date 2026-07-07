import 'package:flutter/material.dart';
import 'plus_menu_sheet.dart';
import '../views/dashboard/dashboard_screen.dart';
import '../views/livraisons/livraisons_screen.dart';
import '../views/livreurs/livreurs_screen.dart';
import '../views/tracking/tracking_screen.dart';

/// Coquille principale de navigation : 5 icônes en bas
/// (Accueil, Livraisons, Suivi au centre en relief, Livreurs, Plus).
/// "Plus" ouvre un menu (Litiges, Recouvrements, Paramètres, Déconnexion)
/// plutôt que de changer d'onglet.
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    //LivraisonsScreen(),
    //TrackingScreen(), // "Suivi" - onglet central
    //LivreursScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () => setState(() => _index = 2),
        child: Icon(Icons.map_outlined,
            color: Theme.of(context).colorScheme.onPrimary),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_outlined, 'Accueil', 0),
            _navItem(Icons.local_shipping_outlined, 'Livraisons', 1),
            const SizedBox(width: 40), // espace pour le FAB "Suivi"
            _navItem(Icons.badge_outlined, 'Livreurs', 3),
            _plusItem(),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int i) {
    final active = _index == i;
    final color = active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return InkWell(
      onTap: () => setState(() => _index = i),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _plusItem() {
    final color = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return InkWell(
      onTap: () => showPlusMenu(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.more_horiz, color: color, size: 24),
            const SizedBox(height: 2),
            Text('Plus', style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}