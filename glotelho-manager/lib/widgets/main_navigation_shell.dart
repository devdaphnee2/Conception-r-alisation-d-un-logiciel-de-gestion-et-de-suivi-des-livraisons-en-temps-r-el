import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
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
    // Teinte sombre de fond
    const Color backgroundColor = Color(0xFF0D1B2A);
    const Color goldColor = Color(0xFFC9952E);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        height: 60.0,
        items: <Widget>[
          Icon(
            Icons.home_outlined,
            size: 26,
            color: _currentIndex == 0 ? Colors.white : Colors.black87,
          ),
          Icon(
            Icons.receipt_long_outlined,
            size: 26,
            color: _currentIndex == 1 ? Colors.white : Colors.black87,
          ),
          Icon(
            Icons.gavel_outlined,
            size: 26,
            color: _currentIndex == 2 ? Colors.white : Colors.black87,
          ),
          Badge(
            isLabelVisible: _nbNonLues > 0,
            label: Text('$_nbNonLues', style: const TextStyle(fontSize: 10)),
            backgroundColor: Colors.red,
            child: Icon(
              Icons.notifications_outlined,
              size: 26,
              color: _currentIndex == 3 ? Colors.white : Colors.black87,
            ),
          ),
          Icon(
            Icons.settings_outlined,
            size: 26,
            color: _currentIndex == 4 ? Colors.white : Colors.black87,
          ),
        ],
        color: Colors.white,
        buttonBackgroundColor: goldColor, // Cercle flottant doré
        backgroundColor: backgroundColor, // Reçoit le bleu sombre du Scaffold pour l'effet de creux
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 350),
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 3) {
            Future.delayed(const Duration(milliseconds: 500), _chargerBadge);
          }
        },
      ),
    );
  }
}