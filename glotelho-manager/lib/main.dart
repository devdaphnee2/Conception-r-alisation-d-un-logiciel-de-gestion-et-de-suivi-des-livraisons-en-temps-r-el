import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_state.dart';
import 'config/app_theme.dart';
import 'widgets/main_navigation_shell.dart';
import 'views/parametres/parametres_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/register_screen.dart';
// TODO: importer au fur et à mesure
// import 'views/litiges/litige_list_screen.dart';
// import 'views/recouvrements/recouvrement_list_screen.dart';

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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.navyTheme,
      initialRoute: appState.isAuthenticated ? '/home' : '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const MainNavigationShell(),
        '/parametres': (_) => const ParametresScreen(),
        // '/litiges': (_) => const LitigeListScreen(),
        // '/recouvrements': (_) => const RecouvrementListScreen(),
      },
    );
  }
}