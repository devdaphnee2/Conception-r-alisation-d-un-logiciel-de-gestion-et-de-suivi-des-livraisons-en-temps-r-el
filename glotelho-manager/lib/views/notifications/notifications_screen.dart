import 'package:flutter/material.dart';

/// Écran des notifications — recevra les soumissions des livreurs
/// (preuves de livraison, signalements, demandes de validation de profil)
/// une fois le backend/notifications temps réel de ton frère branché.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text('Aucune notification pour le moment.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 4),
              Text('Les soumissions des livreurs apparaîtront ici.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}