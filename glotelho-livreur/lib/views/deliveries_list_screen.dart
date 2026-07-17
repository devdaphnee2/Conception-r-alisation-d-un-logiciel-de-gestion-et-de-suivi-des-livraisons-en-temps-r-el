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
  int _tab = 0; // 0=Toutes 1=En cours 2=Livrées 3=Annulées

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // Courses actives + historique fusionnés pour l'onglet "Toutes"
    final actives = await TrackingService.getTodayDeliveries();
    final historique = await TrackingService.getHistorique();
    if (!mounted) return;
    // On déduplique par id
    final Map<String, DeliveryModel> map = {};
    for (final d in [...actives, ...historique]) {
      map[d.id] = d;
    }
    setState(() {
      _all = map.values.toList()
        ..sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
      _loading = false;
    });
  }

  // ── Filtrage par onglet ──
  List<DeliveryModel> get _filtered {
    switch (_tab) {
      case 1:
        return _all.where((d) =>
          d.status == DeliveryStatus.inProgress ||
          d.status == DeliveryStatus.assigned).toList();
      case 2:
        return _all.where((d) => d.status == DeliveryStatus.delivered).toList();
      case 3:
        return _all.where((d) =>
          d.status == DeliveryStatus.cancelled ||
          d.status == DeliveryStatus.suspended).toList();
      default:
        return _all;
    }
  }

  // ── Nombre de courses actives (badge) ──
  int get _activeCount => _all.where((d) =>
    d.status == DeliveryStatus.inProgress ||
    d.status == DeliveryStatus.assigned ||
    d.status == DeliveryStatus.pending).length;

  // ── Couleur par statut ──
  Color _statusColor(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.delivered:  return const Color(0xFF2E7D32);
      case DeliveryStatus.cancelled:  return const Color(0xFFC62828);
      case DeliveryStatus.inProgress: return const Color(0xFF1565C0);
      case DeliveryStatus.assigned:   return const Color(0xFF6A1B9A);
      case DeliveryStatus.suspended:  return const Color(0xFFE65100);
      case DeliveryStatus.pending:    return AppColors.gold;
    }
  }

  // ── Label par statut ──
  String _statusLabel(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.delivered:  return 'Livrée';
      case DeliveryStatus.cancelled:  return 'Annulée';
      case DeliveryStatus.inProgress: return 'En cours';
      case DeliveryStatus.assigned:   return 'Assignée';
      case DeliveryStatus.suspended:  return 'Suspendue';
      case DeliveryStatus.pending:    return 'En attente';
    }
  }

  // ── Icône par statut ──
  IconData _statusIcon(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.delivered:  return Icons.check_circle_outline;
      case DeliveryStatus.cancelled:  return Icons.cancel_outlined;
      case DeliveryStatus.inProgress: return Icons.local_shipping_outlined;
      case DeliveryStatus.assigned:   return Icons.assignment_outlined;
      case DeliveryStatus.suspended:  return Icons.pause_circle_outline;
      case DeliveryStatus.pending:    return Icons.hourglass_empty_outlined;
    }
  }

  String _fmt(double v) =>
      '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} XAF';

  String _heure(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  // ── BUILD ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Livraisons',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_activeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                      ),
                      child: Text(
                        '$_activeCount aujourd\'hui',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Text(
                      '${_all.length} aujourd\'hui',
                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                ],
              ),
            ),

            // ── Onglets filtres ──
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _tabChip('Toutes', 0, _all.length),
                  _tabChip('En cours', 1,
                    _all.where((d) =>
                      d.status == DeliveryStatus.inProgress ||
                      d.status == DeliveryStatus.assigned).length),
                  _tabChip('Livrées', 2,
                    _all.where((d) => d.status == DeliveryStatus.delivered).length),
                  _tabChip('Annulées', 3,
                    _all.where((d) =>
                      d.status == DeliveryStatus.cancelled ||
                      d.status == DeliveryStatus.suspended).length),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Contenu ──
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    )
                  : _filtered.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.gold,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _card(_filtered[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Onglet chip ──
  Widget _tabChip(String label, int i, int count) {
    final active = _tab == i;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: active ? AppColors.gold : AppColors.cardNavy,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withOpacity(0.25)
                        : AppColors.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── État vide ──
  Widget _emptyState() {
    final msgs = [
      'Aucune livraison',
      'Pas de courses en cours',
      'Aucune livraison terminée',
      'Aucune annulation',
    ];
    final icons = [
      Icons.local_shipping_outlined,
      Icons.directions_bike_outlined,
      Icons.check_circle_outline,
      Icons.cancel_outlined,
    ];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icons[_tab], color: Colors.white12, size: 64),
          const SizedBox(height: 16),
          Text(
            msgs[_tab],
            style: const TextStyle(color: Colors.white38, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tirez vers le bas pour actualiser',
            style: TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Carte livraison ──
  Widget _card(DeliveryModel d) {
    final color = _statusColor(d.status);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryRouteDetailScreen(delivery: d),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.cardNavy,
          borderRadius: BorderRadius.circular(16),
          border: d.status == DeliveryStatus.inProgress
              ? Border.all(color: const Color(0xFF1565C0).withOpacity(0.4), width: 1)
              : d.status == DeliveryStatus.assigned
                  ? Border.all(color: AppColors.gold.withOpacity(0.3), width: 1)
                  : null,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_statusIcon(d.status), color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.clientNom,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    color: Colors.white38, size: 13),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    d.adresseLivraison,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _badge(d.status),
                    ],
                  ),
                  if (d.commercantNom != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_outlined,
                              color: Colors.white38, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            d.commercantNom!,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          if (d.commercantAdresse != null) ...[
                            const Text('  ·  ',
                                style: TextStyle(color: Colors.white24)),
                            Expanded(
                              child: Text(
                                d.commercantAdresse!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _miniInfo(Icons.payments_outlined, 'Montant', _fmt(d.montant)),
                      const SizedBox(width: 20),
                      _miniInfo(Icons.directions_bike_outlined, 'Frais', _fmt(d.fraisLivraison)),
                      const Spacer(),
                      _miniInfo(Icons.access_time, 'Heure', _heure(d.dateCreation)),
                    ],
                  ),
                ],
              ),
            ),
            if (d.status == DeliveryStatus.assigned ||
                d.status == DeliveryStatus.pending)
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white12)),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DeliveryRouteDetailScreen(delivery: d),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 16,
                            color: AppColors.gold),
                        label: const Text(
                          'Voir les détails',
                          style: TextStyle(color: AppColors.gold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Mini info avec icône ──
  Widget _miniInfo(IconData icon, String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white24, size: 14),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k,
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 1),
            Text(v,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ],
    );
  }

  // ── Badge statut ──
  Widget _badge(DeliveryStatus s) {
    final color = _statusColor(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        _statusLabel(s),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}