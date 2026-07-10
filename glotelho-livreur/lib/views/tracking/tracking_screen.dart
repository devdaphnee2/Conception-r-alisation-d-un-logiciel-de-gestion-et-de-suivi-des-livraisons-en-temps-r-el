import 'package:flutter/material.dart';
import 'pre_departure_screen.dart';

/// Point d'entrée de l'onglet "Tracking" — la checklist ne s'affiche
/// qu'une seule fois avant de commencer les livraisons du jour.
class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PreDepartureScreen();
  }
}