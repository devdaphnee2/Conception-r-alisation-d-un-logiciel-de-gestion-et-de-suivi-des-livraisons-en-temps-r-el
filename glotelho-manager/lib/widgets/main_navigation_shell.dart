import 'package:flutter/material.dart';
import '../views/home/home_screen.dart';
import '../views/livraisons/livraisons_screen.dart';
import '../views/commandes/commandes_screen.dart';
import '../views/litiges/litiges_screen.dart';
import '../views/parametres/parametres_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LivraisonsScreen(),
    CommandesScreen(),
    LitigesScreen(),
    ParametresScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF0D1B2A),
        indicatorColor: const Color(0xFFC9952E).withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.home, color: Color(0xFFC9952E)),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.local_shipping, color: Color(0xFFC9952E)),
            label: 'Livraisons',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.receipt_long, color: Color(0xFFC9952E)),
            label: 'Commandes',
          ),
          NavigationDestination(
            icon: Icon(Icons.gavel_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.gavel, color: Color(0xFFC9952E)),
            label: 'Litiges',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.settings, color: Color(0xFFC9952E)),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}