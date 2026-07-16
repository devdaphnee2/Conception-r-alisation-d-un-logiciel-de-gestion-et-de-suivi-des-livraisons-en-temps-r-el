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
<<<<<<< Updated upstream
  int _tab = 0; // 0 Toutes, 1 En cours, 2 Livrées, 3 Annulées
=======
  int _tab = 0; // 0=Toutes 1=En cours 2=Livrées 3=Annulées
>>>>>>> Stashed changes

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
<<<<<<< Updated upstream
    final data = await TrackingService.getTodayDeliveries();
    if (!mounted) return;
    setState(() {
      _all = data;
=======
    // Courses actives + historique fusionnés pour l'onglet "Toutes"
    final actives   = await TrackingService.getTodayDeliveries();
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
>>>>>>> Stashed changes
      _loading = false;
    });
  }

<<<<<<< Updated upstream
  List<DeliveryModel> get _filtered {
    switch (_tab) {
      case 1:
        return _all.where((d) => d.status == DeliveryStatus.inProgress).toList();
      case 2:
        return _all.where((d) => d.status == DeliveryStatus.delivered).toList();
      case 3:
        return _all.where((d) => d.status == DeliveryStatus.cancelled).toList();
=======
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
>>>>>>> Stashed changes
      default:
        return _all;
    }
  }

<<<<<<< Updated upstream
  // ---- Helpers statut ----
  Color _statusColor(DeliveryStatus s) {
    switch (s) {
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
    }
  }

  String _statusLabel(DeliveryStatus s) {
    switch (s) {
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
>>>>>>> Stashed changes
    }
  }

  String _fmt(double v) =>
      '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} XAF';

  String _heure(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

<<<<<<< Updated upstream
=======
  // ── BUILD ──────────────────────────────────────────────────────
>>>>>>> Stashed changes
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
<<<<<<< Updated upstream
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
            // Onglets de filtre
=======
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
                  // Badge compteur actif
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
>>>>>>> Stashed changes
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
<<<<<<< Updated upstream
                  _tabChip('Toutes', 0),
                  _tabChip('En cours', 1),
                  _tabChip('Livrées', 2),
                  _tabChip('Annulées', 3),
=======
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
>>>>>>> Stashed changes
                ],
              ),
            ),
            const SizedBox(height: 8),
<<<<<<< Updated upstream
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
=======

 
>>>>>>> Stashed changes
        ),
      ),
    );
  }

<<<<<<< Updated upstream
  Widget _card(DeliveryModel d) {
    final color = _statusColor(d.status);
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DeliveryRouteDetailScreen(delivery: d)),
      ),
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

  // ---- Feuille de détail ----
  void _showDetail(DeliveryModel d) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Livraison #${d.id}',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                _badge(d.status),
              ],
            ),
            const SizedBox(height: 20),
            _detailRow('Client', d.clientNom),
            _detailRow('Téléphone', d.clientTelephone),
            _detailRow('Adresse', d.adresseLivraison),
            _detailRow('Montant produits', _fmt(d.montant)),
            _detailRow('Frais de livraison', _fmt(d.fraisLivraison)),
            _detailRow('Statut', _statusLabel(d.status)),
            _detailRow('Créée à', _heure(d.dateCreation)),
            if (d.dateLivraison != null) _detailRow('Livrée à', _heure(d.dateLivraison!)),
            if (d.modifiedAddressNote != null && d.modifiedAddressNote!.isNotEmpty)
              _detailRow('Note adresse', d.modifiedAddressNote!),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(k, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(v,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
=======
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
          Text(
            'Tirez vers le bas pour actualiser',
            style: const TextStyle(color: Colors.white24, fontSize: 13),
>>>>>>> Stashed changes
          ),
        ],
      ),
    );
  }
<<<<<<< Updated upstream
=======

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
                  // ── Ligne 1 : icône + nom client + badge ──
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

                  // ── Infos commerçant (si disponible) ──
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

                  // ── Ligne 2 : montant / frais / heure ──
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

            // ── Bouton d'action rapide pour courses assignées ──
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
>>>>>>> Stashed changes
}