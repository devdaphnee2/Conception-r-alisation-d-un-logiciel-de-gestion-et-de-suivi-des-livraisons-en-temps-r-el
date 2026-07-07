import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Bandeau "Bonjour, [Prénom] 👋" en haut de l'Accueil, style navy
/// avec avatar rond, repris de la maquette fournie.
class WelcomeBanner extends StatelessWidget {
  final String firstName;
  const WelcomeBanner({super.key, required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bonjour,',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              Row(
                children: [
                  Text(firstName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 6),
                  const Text('👋', style: TextStyle(fontSize: 18)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}