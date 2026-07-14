import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_state.dart';
import 'config/app_theme.dart';
import 'config/app_routes.dart';
import 'widgets/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.loadSession();
  runApp(
    ChangeNotifierProvider.value(
      value: appState,
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
      theme    : AppTheme.lightTheme,
      darkTheme: AppTheme.navyTheme,
      // Toujours démarrer sur /login — redirection gérée dans login_screen
      initialRoute: '/login',
      routes: {
        ...appRoutes,
        '/home': (_) => const MainNavigationShell(),
      },
    );
  }
}