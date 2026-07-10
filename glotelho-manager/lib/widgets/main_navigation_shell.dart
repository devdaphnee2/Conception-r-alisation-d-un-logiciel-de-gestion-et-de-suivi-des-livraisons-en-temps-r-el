import 'package:flutter/material.dart';
import '../config/app_strings.dart';
import '../config/app_routes.dart';
import '../views/dashboard/dashboard_screen.dart';
import '../views/livraisons/livraisons_screen.dart';
import '../views/tracking/tracking_screen.dart';
import '../views/livreurs/livreurs_screen.dart';
import '../views/parametres/parametres_screen.dart';

/// Coquille principale de navigation : 5 icônes en bas, toutes au même
/// niveau (Accueil, Livraisons, Suivi, Livreurs, Paramètres).
///
/// Chaque onglet a son propre Navigator imbriqué : quand un écran est
/// "poussé" depuis un onglet (ex: Notifications depuis Accueil, ou
/// Nouvelle livraison depuis Livraisons), il s'affiche AU-DESSUS du
/// contenu de l'onglet mais la barre du bas reste visible, car elle
/// vit dans le Scaffold englobant, pas dans le Navigator de l'onglet.
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _index = 0;

  static const _tabRoots = [
    DashboardScreen(),
    LivraisonsScreen(),
    TrackingScreen(),
    LivreursScreen(),
    ParametresScreen(),
  ];

  final List<GlobalKey<NavigatorState>> _navigatorKeys =
  List.generate(5, (_) => GlobalKey<NavigatorState>());

  Widget _buildTabNavigator(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        // Racine de l'onglet
        if (settings.name == '/' || settings.name == null) {
          return MaterialPageRoute(builder: (_) => _tabRoots[index]);
        }
        // Routes nommées partagées (Notifications, Litiges, etc.)
        final builder = appRoutes[settings.name];
        if (builder != null) {
          return MaterialPageRoute(builder: builder, settings: settings);
        }
        return MaterialPageRoute(builder: (_) => _tabRoots[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: List.generate(5, _buildTabNavigator),
      ),
      bottomNavigationBar: SizedBox(
        height: 88,
        child: BottomAppBar(
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_outlined, AppStrings.t(context, 'nav_home'), 0),
              _navItem(Icons.local_shipping_outlined,
                  AppStrings.t(context, 'nav_deliveries'), 1),
              _navItem(Icons.map_outlined, 'Suivi', 2),
              _navItem(Icons.badge_outlined, AppStrings.t(context, 'nav_drivers'), 3),
              _navItem(
                  Icons.settings_outlined, AppStrings.t(context, 'nav_settings'), 4),
            ],
          ),
        ),
      ),
    );
  }

  void _onTapIndex(int i) {
    if (_index == i) {
      // Re-tap sur l'onglet déjà actif : revenir à sa racine.
      _navigatorKeys[i].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _index = i);
    }
  }

  Widget _navItem(IconData icon, String label, int i) {
    final active = _index == i;
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final inactiveColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return InkWell(
      onTap: () => _onTapIndex(i),
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 42,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: active ? 1 : 0),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  builder: (context, t, child) {
                    return Transform.translate(
                      offset: Offset(0, -8 * t),
                      child: Container(
                        width: 30 + 10 * t,
                        height: 30 + 10 * t,
                        decoration: BoxDecoration(
                          color: Color.lerp(Colors.transparent, primary, t),
                          shape: BoxShape.circle,
                          boxShadow: t > 0.5
                              ? [
                            BoxShadow(
                                color: primary.withOpacity(0.35 * t),
                                blurRadius: 10,
                                offset: const Offset(0, 3)),
                          ]
                              : null,
                        ),
                        child: Icon(
                          icon,
                          color: Color.lerp(inactiveColor, onPrimary, t),
                          size: 20 + 2 * t,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: active ? primary : inactiveColor,
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}