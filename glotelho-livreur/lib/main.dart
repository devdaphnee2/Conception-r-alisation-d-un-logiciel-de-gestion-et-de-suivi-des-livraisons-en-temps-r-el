import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'utils/constants.dart';
import 'utils/driver_state.dart';
import 'views/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/delivery_request_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Pointer vers la bonne Realtime Database
  FirebaseDatabase.instance.databaseURL =
      'https://glotelho-livraison-default-rtdb.europe-west1.firebasedatabase.app';

  await NotificationService.init();
  await NotificationService.requestPermission();
  DeliveryRequestManager.init();
  runApp(const GlotelhoDeliveryApp());
}

class GlotelhoDeliveryApp extends StatelessWidget {
  const GlotelhoDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DriverState()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        navigatorKey: DeliveryRequestManager.navigatorKey,
        theme: ThemeData(
          primaryColor: AppColors.navy,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.gold),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}