import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/delivery_model.dart';
import '../services/tracking_service.dart';
import 'delivery_route_detail_screen.dart';


class DeliveriesListScreen extends StatefulWidget {
  const DeliveriesListScreen({super.key});

  @override
  State<DeliveriesListScreen> createState() => _DeliveriesListScreenState();
}

class _DeliveriesListScreenState extends State<DeliveriesListScreen> {
  List<DeliveryModel> _all = [];
  bool _loading = true;
  int _tab = 0; // 0 Toutes, 1 En cours, 2 Livrées, 3 Annulées, 4 Assignées

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await TrackingService.getTodayDeliveries();
    if (!mounted) return;
    setState(() { _all = data; _loading = false; });
  }

  List<DeliveryModel> get _filtered {
    switch (_tab) {
      case 1: return _all.where((d) => d.status == DeliveryStatus.inProgress).toList();
      case 2: return _all.where((d) => d.status == DeliveryStatus.delivered).toList();
      case 3: return _all.where((d) => d.status == DeliveryStatus.cancelled).toList();
      case 4: return _all.where((d) => d.status == DeliveryStatus.assigned).toList();
      default: return _all;
    }
  }

  Color _statusColor(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.delivered:  return AppColors.statusDelivered;
      case DeliveryStatus.cancelled:  return AppColors.statusCancelled;
      case DeliveryStatus.inProgress: return AppColors.statusInProgress;
      case DeliveryStatus.suspended:  return AppColors.amber;
      case DeliveryStatus.assigned:   return AppColors.blue;
      case DeliveryStatus.pending:    return AppColors.statusPending;
    }
  }

  String _statusLabel(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.delivered:  return 'Livrée';
      case DeliveryStatus.cancelled:  return 'Annulée';
      case DeliveryStatus.inProgress: return 'En cours';
      case DeliveryStatus.suspended:  return 'Suspendue';
      case DeliveryStatus.assigned:   return 'Assignée';
      case DeliveryStatus.pending:    return 'En attente';
    }
  }

  String _fmt(double v) =>
      '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} XAF';

  String _heure(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Livraisons',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('${_all.length} aujourd\'hui',
                      style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _tabChip('Toutes', 0),
                  _tabChip('En cours', 1),
                  _tabChip('Livrées', 2),
                  _tabChip('Annulées', 3),
                  _tabChip('Assignées', 4),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                  : _filtered.isEmpty
                  ? const Center(child: Text('Aucune livraison', style: TextStyle(color: Colors.white38)))
                  : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.gold,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: _filtered.map(_card).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabChip(String label, int i) {
    final active = _tab == i;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: active ? AppColors.gold : AppColors.cardNavy,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(label,
              style: TextStyle(
                  color: active ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ),
      ),
    );
  }

  Widget _card(DeliveryModel d) {
    final color = _statusColor(d.status);
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => DeliveryRouteDetailScreen(delivery: d))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.cardNavy, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(Icons.inventory_2_outlined, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.clientNom,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(d.adresseLivraison,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                _badge(d.status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniInfo('Montant', _fmt(d.montant)),
                _miniInfo('Frais', _fmt(d.fraisLivraison)),
                _miniInfo('Heure', _heure(d.dateCreation)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniInfo(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 2),
        Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Widget _badge(DeliveryStatus s) {
    final color = _statusColor(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(_statusLabel(s),
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }
}