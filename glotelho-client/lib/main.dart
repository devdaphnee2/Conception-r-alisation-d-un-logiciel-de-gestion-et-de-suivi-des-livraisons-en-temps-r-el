/*import 'package:flutter/material.dart';
import 'views/splash_screen.dart';

void main() {
  runApp(const MyApp());
}*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'services/storage_service.dart';
import 'utils/app_state.dart';
import 'utils/app_theme.dart';
import 'utils/cart_state.dart';
import 'utils/notification_state.dart';
import 'views/splash_screen.dart';

// IMPORTANT : ajouter dans pubspec.yaml :
//   dependencies:
//     provider: ^6.1.2
//     flutter_local_notifications: ^18.0.1
//     firebase_core: ^3.8.0
//     firebase_messaging: ^15.1.5
//     shared_preferences: ^2.3.2
//     local_auth: ^2.3.0

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();

  // ── Charger la session persistée (token, profil, biométrie) ──────
  final appState = AppState();
  await appState.loadFromDisk();

  // Réinjecter le token dans Dio si le client était déjà connecté
  if (appState.isLoggedIn) {
    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      ApiService.setToken(token);
    }
  }

  // ── FCM (notifications push, même app fermée) ────────────────────
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
  await FcmService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider(create: (_) => CartState()),
        ChangeNotifierProvider(create: (_) => NotificationState()),
      ],
      child: const GloteloApp(),
    ),
  );
}

class GloteloApp extends StatelessWidget {
  const GloteloApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Glotelho Express',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}