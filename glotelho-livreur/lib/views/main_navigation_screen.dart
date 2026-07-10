import 'package:flutter/material.dart';
import 'package:glotelho_livreur/views/tracking/tracking_screen.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'activities_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _index = 0;

  void _goToTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateTab: _goToTab),
      const ActivitiesScreen(),
      const TrackingScreen(),
      const _PlaceholderScreen(title: 'Livraisons'),
      const _PlaceholderScreen(title: 'Paramètres'),
    ];

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardNavy,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _navItem(0, Icons.home_outlined, 'Accueil'),
                _navItem(1, Icons.swap_horiz, 'Activités'),
                _navItem(2, Icons.location_on_outlined, 'Tracking'),
                _navItem(3, Icons.local_shipping_outlined, 'Livraisons'),
                _navItem(4, Icons.settings_outlined, 'Paramètres'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    final active = _index == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => _goToTab(i),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? AppColors.gold : Colors.white38, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: active ? AppColors.gold : Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('$title — à construire', style: const TextStyle(color: Colors.white38)),
    );
  }
}