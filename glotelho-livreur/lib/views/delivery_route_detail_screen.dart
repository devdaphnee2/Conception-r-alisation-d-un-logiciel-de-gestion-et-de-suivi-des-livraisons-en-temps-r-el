import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../models/delivery_model.dart';
import '../services/tracking_service.dart';
import 'delivery_map_route_screen.dart';
import 'delivery_completed_screen.dart';

class DeliveryRouteDetailScreen extends StatefulWidget {
  final DeliveryModel delivery;
  const DeliveryRouteDetailScreen({super.key, required this.delivery});

  @override
  State<DeliveryRouteDetailScreen> createState() => _DeliveryRouteDetailScreenState();
}

class _DeliveryRouteDetailScreenState extends State<DeliveryRouteDetailScreen> {
  late DeliveryModel d;

  @override
  void initState() {
    super.initState();
    d = widget.delivery;
  }

  Color _statusColor(DeliveryStatus s) {
    switch (s) {
<<<<<<< HEAD
      case DeliveryStatus.delivered:
        return AppColors.statusDelivered;
      case DeliveryStatus.cancelled:
        return AppColors.statusCancelled;
      case DeliveryStatus.inProgress:
        return AppColors.statusInProgress;
      case DeliveryStatus.suspended:
        return AppColors.amber;
      case DeliveryStatus.assigned:
        return AppColors.blue;
      case DeliveryStatus.pending:
        return AppColors.statusPending;
=======
      case DeliveryStatus.delivered:  return AppColors.statusDelivered;
      case DeliveryStatus.cancelled:  return AppColors.statusCancelled;
      case DeliveryStatus.inProgress: return AppColors.statusInProgress;
      case DeliveryStatus.suspended:  return AppColors.amber;
      case DeliveryStatus.assigned:   return AppColors.blue;
      case DeliveryStatus.validated:  return AppColors.green;
      case DeliveryStatus.pending:    return AppColors.statusPending;
>>>>>>> origin/main
    }
  }

  String _statusLabel(DeliveryStatus s) {
    switch (s) {
<<<<<<< HEAD
      case DeliveryStatus.delivered:
        return 'Livrée';
      case DeliveryStatus.cancelled:
        return 'Annulée';
      case DeliveryStatus.inProgress:
        return 'En cours';
      case DeliveryStatus.suspended:
        return 'Suspendue';
      case DeliveryStatus.assigned:
        return 'Assignée';
      case DeliveryStatus.pending:
        return 'En attente';
=======
      case DeliveryStatus.delivered:  return 'Livrée';
      case DeliveryStatus.cancelled:  return 'Annulée';
      case DeliveryStatus.inProgress: return 'En cours';
      case DeliveryStatus.suspended:  return 'Suspendue';
      case DeliveryStatus.assigned:   return 'Assignée';
      case DeliveryStatus.validated:  return 'Validée';
      case DeliveryStatus.pending:    return 'En attente';
>>>>>>> origin/main
    }
  }

  String _fmt(double v) =>
      '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} XAF';

  String _heure(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _appelerClient() async {
    final uri = Uri(scheme: 'tel', path: d.clientTelephone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir l\'application téléphone')),
      );
    }
  }

  void _voirCarte() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => DeliveryMapRouteScreen(delivery: d)));
  }

  Future<void> _saisirCode() async {
    final ctrl = TextEditingController();
    bool loading = false;
    String? error;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.cardNavy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Code de clôture', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Saisissez le code que le client a reçu du manager pour clôturer la livraison.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '••••',
                  hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 8),
                  filled: true,
                  fillColor: AppColors.navy,
                  errorText: error,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: loading ? null : () async {
                setLocal(() { loading = true; error = null; });
                final ok = await TrackingService.verifierCodeCloture(d.id, ctrl.text);
                if (!ok) {
                  setLocal(() { loading = false; error = 'Code incorrect'; });
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _clotureReussie();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Valider', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _clotureReussie() {
    setState(() {
      d.status = DeliveryStatus.delivered;
      d.dateLivraison = DateTime.now();
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryCompletedScreen(
          gains: d.fraisLivraison,
          dureeMinutes: DateTime.now().difference(d.dateCreation).inMinutes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(d.status);
    final estCloturable = d.status == DeliveryStatus.inProgress || d.status == DeliveryStatus.pending;

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: Text('Livraison #${d.id}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Icon(Icons.circle, color: color, size: 12),
                const SizedBox(width: 10),
                Text(_statusLabel(d.status), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _infoCard([
            _row('Client', d.clientNom),
            _row('Téléphone', d.clientTelephone),
            _row('Adresse', d.adresseLivraison),
            if (d.modifiedAddressNote != null && d.modifiedAddressNote!.isNotEmpty)
              _row('Note adresse', d.modifiedAddressNote!),
          ]),
          const SizedBox(height: 14),
          _infoCard([
            _row('Montant produits', _fmt(d.montant)),
            _row('Frais de livraison', _fmt(d.fraisLivraison)),
            _row('Créée à', _heure(d.dateCreation)),
            if (d.dateLivraison != null) _row('Livrée à', _heure(d.dateLivraison!)),
          ]),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _actionBtn(Icons.phone, 'Appeler', AppColors.green, _appelerClient)),
              const SizedBox(width: 12),
              Expanded(child: _actionBtn(Icons.map_outlined, 'Voir carte', AppColors.blue, _voirCarte)),
            ],
          ),
          const SizedBox(height: 12),
          if (estCloturable)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saisirCode,
                icon: const Icon(Icons.lock_open, color: Colors.white),
                label: const Text('Clôturer avec le code',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: AppColors.cardNavy, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(k, style: const TextStyle(color: Colors.white54, fontSize: 14))),
          const SizedBox(width: 12),
          Expanded(child: Text(v, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}