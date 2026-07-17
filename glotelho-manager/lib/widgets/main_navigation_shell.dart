import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_state.dart';
import '../services/api_service.dart';
import '../views/dashboard/dashboard_screen.dart';
import '../views/commandes/commandes_screen.dart';
import '../views/litiges/litiges_screen.dart';
import '../views/parametres/parametres_screen.dart';
import '../views/notifications/notifications_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  int _nbNonLues = 0;
  Timer? _pollingTimer;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CommandesScreen(),
    const LitigesScreen(),
    const NotificationsScreen(),
    const ParametresScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _chargerBadge();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => _chargerBadge());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _chargerBadge() async {
    try {
      final appState = context.read<AppState>();
      final api = ApiService(appState);
      final res = await api.dio.get('/notifications');
      final List data = res.data ?? [];
      final nonLues = data.where((n) => n['is_read'] == 0 || n['is_read'] == false).length;
      if (mounted) setState(() => _nbNonLues = nonLues);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          if (i == 3) {
            Future.delayed(const Duration(milliseconds: 500), _chargerBadge);
          }
        },
        backgroundColor: const Color(0xFF0D1B2A),
        indicatorColor: const Color(0xFFC9952E).withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.home, color: Color(0xFFC9952E)),
            label: 'Accueil',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.receipt_long, color: Color(0xFFC9952E)),
            label: 'Commandes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.gavel_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.gavel, color: Color(0xFFC9952E)),
            label: 'Litiges',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _nbNonLues > 0,
              label: Text('$_nbNonLues', style: const TextStyle(fontSize: 10)),
              backgroundColor: Colors.red,
              child: const Icon(Icons.notifications_outlined, color: Colors.white54),
            ),
            selectedIcon: Badge(
              isLabelVisible: _nbNonLues > 0,
              label: Text('$_nbNonLues', style: const TextStyle(fontSize: 10)),
              backgroundColor: Colors.red,
              child: const Icon(Icons.notifications, color: Color(0xFFC9952E)),
            ),
            label: 'Notifs',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.settings, color: Color(0xFFC9952E)),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}