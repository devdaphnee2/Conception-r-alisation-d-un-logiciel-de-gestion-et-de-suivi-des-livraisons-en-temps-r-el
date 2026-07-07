import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_state.dart';
import 'config/app_colors.dart';
import 'views/dashboard/dashboard_screen.dart';
// TODO: importer les autres écrans au fur et à mesure
// import 'views/auth/login_screen.dart';
// import 'views/livraisons/livraison_list_screen.dart';
// import 'views/livreurs/livreur_list_screen.dart';
// import 'views/litiges/litige_list_screen.dart';
// import 'views/recouvrements/recouvrement_list_screen.dart';
// import 'views/tracking/tracking_screen.dart';
// import 'views/parametres/parametres_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const GlotelhoManagerApp(),
    ),
  );
}

class GlotelhoManagerApp extends StatelessWidget {
  const GlotelhoManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return MaterialApp(
      title: 'Glotelho Manager',
      debugShowCheckedModeBanner: false,
      themeMode: appState.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: AppColors.primary,
      ),
      // TODO: remplacer par un login réel une fois l'écran d'auth prêt.
      initialRoute: '/dashboard',
      routes: {
        '/dashboard': (_) => const DashboardScreen(),
        // '/login': (_) => const LoginScreen(),
        // '/livraisons': (_) => const LivraisonListScreen(),
        // '/livreurs': (_) => const LivreurListScreen(),
        // '/litiges': (_) => const LitigeListScreen(),
        // '/recouvrements': (_) => const RecouvrementListScreen(),
        // '/tracking': (_) => const TrackingScreen(),
        // '/parametres': (_) => const ParametresScreen(),
      },
    );
  }
}