import 'package:flutter/material.dart';
import '../../widgets/base_scaffold.dart';

/// Écran d'accueil manager — à remplir avec les KPIs (livraisons,
/// livreurs, litiges, recouvrements, profils en attente), même logique
/// que Dashboard.jsx côté web (appels Promise.all sur /livraisons,
/// /livreurs, /litiges, /orders, /recouvrements).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Dashboard',
      currentRoute: '/dashboard',
      body: const Center(child: Text('KPIs à venir')),
    );
  }
}