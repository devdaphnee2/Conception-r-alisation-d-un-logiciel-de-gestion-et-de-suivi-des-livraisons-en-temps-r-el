import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'activities_screen.dart';
import 'delivery_map_screen.dart';
import 'settings_screen.dart';
import 'deliveries_list_screen.dart';

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
    final List<Widget> screens = [
      HomeScreen(onNavigateTab: _goToTab),
      const ActivitiesScreen(),
      const DeliveryMapScreen(),
      DeliveriesListScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardNavy,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            )
          ],
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
            Icon(icon,
                color: active ? AppColors.gold : Colors.white38, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: active ? AppColors.gold : Colors.white38,
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }
}