import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_state.dart';
import 'config/app_theme.dart';
import 'config/app_routes.dart';
import 'services/commercant_polling_service.dart';
import 'widgets/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.loadSession();

  // Démarrer le polling si déjà connecté
  if (appState.isAuthenticated) {
    CommercantPollingService.start(appState);
  }

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const GlotelhoManagerApp(),
    ),
  );
}

class GlotelhoManagerApp extends StatefulWidget {
  const GlotelhoManagerApp({super.key});

  @override
  State<GlotelhoManagerApp> createState() => _GlotelhoManagerAppState();
}

class _GlotelhoManagerAppState extends State<GlotelhoManagerApp> {
  final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    // Callback global pour afficher les nouvelles notifs comme bannière
    CommercantPollingService.onNewNotification = (message) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(message,
                  style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'))),
            ],
          ),
          backgroundColor: const Color(0xFF7d5700),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Voir',
            textColor: const Color(0xFFFFDEA9),
            onPressed: () {},
          ),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Démarrer/arrêter le polling selon l'état de connexion
    if (appState.isAuthenticated) {
      CommercantPollingService.start(appState);
    } else {
      CommercantPollingService.stop();
    }

    return MaterialApp(
      title: 'Glotelho Manager',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      themeMode: appState.themeMode,
      theme    : AppTheme.lightTheme,
      darkTheme: AppTheme.navyTheme,
      initialRoute: '/onboarding',
      routes: {
        ...appRoutes,
        '/home': (_) => const MainNavigationShell(),
      },
    );
  }
}