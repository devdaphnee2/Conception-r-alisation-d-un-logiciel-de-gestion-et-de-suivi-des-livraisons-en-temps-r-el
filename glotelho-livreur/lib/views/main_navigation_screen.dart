import 'package:flutter/material.dart';
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

  final List<Widget> _screens = const [
    HomeScreen(),
    ActivitiesScreen(),
    _PlaceholderScreen(title: 'Services'),
    _PlaceholderScreen(title: 'Analyses'),
    _PlaceholderScreen(title: 'Paramètres'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16324A),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _navItem(0, Icons.home_outlined, 'Accueil'),
                _navItem(1, Icons.swap_horiz, 'Activités'),
                _navItem(2, Icons.storefront_outlined, 'Services'),
                _navItem(3, Icons.show_chart, 'Analyses'),
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
        onTap: () => setState(() => _index = i),
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