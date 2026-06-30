/*import 'package:flutter/material.dart';
import 'views/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}*/


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/app_state.dart';
import 'views/splash_screen.dart';

// IMPORTANT : ajouter dans pubspec.yaml :
//   dependencies:
//     provider: ^6.1.2

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
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
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}