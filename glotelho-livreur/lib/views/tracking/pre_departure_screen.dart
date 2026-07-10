import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'tracking_map_screen.dart';

class PreDepartureScreen extends StatefulWidget {
  const PreDepartureScreen({super.key});

  @override
  State<PreDepartureScreen> createState() => _PreDepartureScreenState();
}

class _PreDepartureScreenState extends State<PreDepartureScreen> {
  final Map<String, bool> _checks = {
    'Confirmer la commande': false,
    'Préparer le sac': false,
    'Vérifier les boissons': false,
    'Prêt à partir': false,
  };

  bool get _allChecked => _checks.values.every((v) => v);

  void _startTracking() {
    // Enregistre l'heure de sortie (point 7 du cahier des charges)
    final heureSortie = DateTime.now();
    debugPrint('Heure de sortie enregistrée : $heureSortie');
    // TODO : POST /drivers/me/depart avec heureSortie vers le backend

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TrackingMapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Préparation',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Étapes à suivre avant le départ',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: _checks.keys.map((label) => _buildCheckTile(label)).toList(),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _allChecked ? _startTracking : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    disabledBackgroundColor: Colors.white12,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Tout est prêt',
                      style: TextStyle(
                          color: _allChecked ? Colors.white : Colors.white38,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckTile(String label) {
    final checked = _checks[label]!;
    return GestureDetector(
      onTap: () => setState(() => _checks[label] = !checked),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardNavy,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: checked ? AppColors.gold : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: checked ? AppColors.gold : Colors.white10,
                shape: BoxShape.circle,
              ),
              child: Icon(
                checked ? Icons.check : Icons.circle_outlined,
                color: checked ? Colors.white : Colors.white38,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}