import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
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
      body: IndexedStack(
        index: _index,
        children: screens,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _index,
        height: 60.0,
        // Les 5 icônes correspondant à tes 5 menus
        items: <Widget>[
          Icon(
            Icons.home_outlined,
            size: 26,
            color: _index == 0 ? Colors.white : Colors.black87,
          ),
          Icon(
            Icons.swap_horiz,
            size: 26,
            color: _index == 1 ? Colors.white : Colors.black87,
          ),
          Icon(
            Icons.location_on_outlined,
            size: 26,
            color: _index == 2 ? Colors.white : Colors.black87,
          ),
          Icon(
            Icons.local_shipping_outlined,
            size: 26,
            color: _index == 3 ? Colors.white : Colors.black87,
          ),
          Icon(
            Icons.settings_outlined,
            size: 26,
            color: _index == 4 ? Colors.white : Colors.black87,
          ),
        ],
        // Style & Couleurs
        color: Colors.white, // Fond blanc de la barre de navigation
        buttonBackgroundColor: AppColors.gold, // Couleur du cercle flottant actif (utilise ton AppColors.gold ou la couleur rose si tu préfères)
        backgroundColor: AppColors.navy, // Couleur de fond sous le creux (s'aligne parfaitement avec l'arrière-plan de l'écran)
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 350),
        onTap: (index) {
          _goToTab(index);
        },
      ),
    );
  }
}