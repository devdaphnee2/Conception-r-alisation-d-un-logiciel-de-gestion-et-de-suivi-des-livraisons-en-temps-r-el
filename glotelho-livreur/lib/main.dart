import 'package:flutter/material.dart';
import 'package:glotelho_livreur/services/driver_service.dart';
import 'package:provider/provider.dart';
import 'utils/constants.dart';
import 'utils/driver_state.dart';
import 'views/splash_screen.dart';

void main() {
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