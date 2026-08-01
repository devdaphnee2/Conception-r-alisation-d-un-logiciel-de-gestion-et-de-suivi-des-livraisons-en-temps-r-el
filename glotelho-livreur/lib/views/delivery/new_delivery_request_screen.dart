import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../models/delivery_request_model.dart';
import '../../services/api_service.dart';

class NewDeliveryRequestScreen extends StatefulWidget {
  final DeliveryRequestModel request;
  const NewDeliveryRequestScreen({super.key, required this.request});

  @override
  State<NewDeliveryRequestScreen> createState() => _NewDeliveryRequestScreenState();
}

class _NewDeliveryRequestScreenState extends State<NewDeliveryRequestScreen> {
  bool _isLoading = false;

  DeliveryRequestModel get request => widget.request;

  String _fmt(double v) =>
      '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} XAF';

  Future<void> _accepter() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.dio.post('/livraisons/${request.id}/accepter');
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Livraison acceptée ✓'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : impossible d\'accepter la course ($e)'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.delivery_dining, color: AppColors.gold, size: 42),
              ),
              const SizedBox(height: 16),
              const Text('Nouvelle livraison',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Assignée par ${request.managerNom}',
                  style: const TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.cardNavy, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  children: [
                    _row(Icons.person_outline, 'Client', request.clientNom),
                    _divider(),
                    _row(Icons.location_on_outlined, 'Adresse', request.adresseLivraison),
                    _divider(),
                    _row(Icons.shopping_bag_outlined, 'Articles', request.articles),
                    _divider(),
                    _row(Icons.route_outlined, 'Distance', '${request.distanceKm.toStringAsFixed(1)} km'),
                    _divider(),
                    _row(Icons.payments_outlined, 'Montant produits', _fmt(request.montant)),
                    _divider(),
                    _row(Icons.account_balance_wallet_outlined, 'Vos frais', _fmt(request.fraisLivraison),
                        highlight: true),
                  ],
                ),
              ),

              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('Livraison refusée'), behavior: SnackBarBehavior.floating));
                            },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 54),
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Refuser',
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _accepter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        minimumSize: const Size(0, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                            )
                          : const Text('Accepter',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: highlight ? AppColors.gold : Colors.white54, size: 20),
          const SizedBox(width: 12),
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13))),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: highlight ? AppColors.gold : Colors.white,
                    fontSize: 14,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(color: Colors.white12, height: 16);
}