import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/driver_state.dart';
import 'login_screen.dart';
import '../models/driver_model.dart';

/// Écran affiché tant que le manager n'a pas validé le compte du livreur.
/// Ne redirige vers aucune autre interface tant que le statut n'est pas "approved".
class PendingVerificationScreen extends StatefulWidget {
  const PendingVerificationScreen({super.key});

  @override
  State<PendingVerificationScreen> createState() => _PendingVerificationScreenState();
}

class _PendingVerificationScreenState extends State<PendingVerificationScreen> {
  bool _checking = false;

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    final state = context.read<DriverState>();
    await state.refreshProfile();
    setState(() => _checking = false);

    if (!mounted) return;

    if (state.driver?.status == DriverStatus.approved) {
      // La vérification côté app principale (main.dart / splash) gère
      // la redirection vers HomeScreen dès que le statut est "approved".
      // Ici on informe simplement l'utilisateur.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Votre compte a été validé ! Reconnectez-vous.'),
        backgroundColor: Colors.green,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Toujours en attente de validation par le manager.'),
        backgroundColor: Colors.orange,
      ));
    }
  }

  void _logout() async {
    await context.read<DriverState>().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.hourglass_top_rounded, size: 56, color: AppColors.gold),
              ),
              const SizedBox(height: 28),
              const Text(
                'Vérifiez votre soumission',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              const Text(
                'Votre dossier est en cours d\'examen par notre équipe. '
                    'Vous recevrez une notification dès que votre compte sera validé.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _checking ? null : _checkStatus,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.gold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _checking
                      ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
                      : const Text('Vérifier mon statut', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _logout,
                child: const Text('Se déconnecter', style: TextStyle(color: Colors.white38)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}