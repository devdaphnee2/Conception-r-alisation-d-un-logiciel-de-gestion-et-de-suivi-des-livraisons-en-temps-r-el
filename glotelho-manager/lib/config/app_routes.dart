import 'package:flutter/material.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/notifications/notifications_screen.dart';
import '../views/litiges/litiges_screen.dart';
//import '../views/litiges/nouveau_litige_screen.dart';
import '../views/recouvrements/recouvrements_screen.dart';
import '../views/livraisons/nouvelle_livraison_screen.dart';
import '../views/parametres/parametres_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (_) => const LoginScreen(),
  '/register': (_) => const RegisterScreen(),
  '/notifications': (_) => const NotificationsScreen(),
  '/litiges': (_) => const LitigesScreen(),
  //'/litiges/nouveau': (_) => const NouveauLitigeScreen(),
  '/recouvrements': (_) => const RecouvrementsScreen(),
  '/livraisons/nouvelle': (_) => const NouvelleLivraisonScreen(),
  '/parametres': (_) => const ParametresScreen(),
};