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
  List<DeliveryModel> _historique = [];
  bool _loading = true;
<<<<<<< HEAD
  int _tab = 0; // 0=Toutes 1=En cours 2=Livrées 3=Annulées
=======
  int _tab = 0;

  final Set<String> _actionEnCours = {};
>>>>>>> origin/main

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
<<<<<<< HEAD
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
=======
    final courses    = await TrackingService.getTodayDeliveries();
    final historique = await TrackingService.getHistorique();
    if (!mounted) return;
    setState(() { _all = courses; _historique = historique; _loading = false; });
  }

  List<DeliveryModel> get _toutes => [..._all, ..._historique];

  List<DeliveryModel> get _filtered {
    switch (_tab) {
      case 1: return _toutes.where((d) => d.status == DeliveryStatus.inProgress).toList();
      case 2: return _toutes.where((d) => d.status == DeliveryStatus.delivered).toList();
      case 3: return _toutes.where((d) => d.status == DeliveryStatus.cancelled).toList();
      case 4: return _toutes.where((d) => d.status == DeliveryStatus.assigned).toList();
      case 5: return _toutes.where((d) => d.status == DeliveryStatus.validated).toList();
      default: return _toutes;
    }
  }

  Future<void> _accepter(DeliveryModel d) async {
    setState(() => _actionEnCours.add(d.id));
    try {
      final ok = await TrackingService.accepterCourse(d.id);
      if (ok) {
        setState(() { d.status = DeliveryStatus.validated; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Course acceptée ! Le manager a été notifié.'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ));
          setState(() => _tab = 5);
        }
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Erreur lors de l'acceptation."),
        backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _actionEnCours.remove(d.id));
    }
  }

  Future<void> _refuser(DeliveryModel d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Refuser la course ?', style: TextStyle(color: Colors.white)),
        content: const Text('Le manager sera notifié et la course sera réassignée.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _actionEnCours.add(d.id));
    try {
      await TrackingService.refuserCourse(d.id);
      setState(() { d.status = DeliveryStatus.cancelled; _all.remove(d); });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Course refusée. Le manager a été notifié.'),
        backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {} finally {
      if (mounted) setState(() => _actionEnCours.remove(d.id));
    }
  }

  Future<void> _demarrer(DeliveryModel d) async {
    setState(() => _actionEnCours.add(d.id));
    try {
      await TrackingService.demarrerCourse(d.id);
      setState(() { d.status = DeliveryStatus.inProgress; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🚀 Course démarrée ! Le client a été notifié.'),
          backgroundColor: Color(0xFF1565C0), behavior: SnackBarBehavior.floating,
        ));
        setState(() => _tab = 1);
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erreur lors du démarrage.'),
        backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _actionEnCours.remove(d.id));
    }
  }

  Color _statusColor(DeliveryStatus s) {
    switch (s) {
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

  // ── Label par statut ──
  String _statusLabel(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.delivered:  return 'Livrée';
      case DeliveryStatus.cancelled:  return 'Annulée';
      case DeliveryStatus.inProgress: return 'En cours';
<<<<<<< HEAD
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
=======
      case DeliveryStatus.suspended:  return 'Suspendue';
      case DeliveryStatus.assigned:   return 'Assignée';
      case DeliveryStatus.validated:  return 'Validée';
      case DeliveryStatus.pending:    return 'En attente';
>>>>>>> origin/main
    }
  }

  String _fmt(double v) =>
      '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} XAF';

  String _heure(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  // ── BUILD ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final nbAssignees = _toutes.where((d) => d.status == DeliveryStatus.assigned).length;

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
<<<<<<< HEAD
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
=======
                  const Text('Livraisons',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('${_toutes.length} au total',
                      style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
>>>>>>> origin/main
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
<<<<<<< HEAD
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
=======
                  _tabChip('Toutes', 0),
                  _tabChip('En cours', 1),
                  _tabChip('Livrées', 2),
                  _tabChip('Annulées', 3),
                  _tabChip('Assignées', 4, badge: nbAssignees),
                  _tabChip('Validées', 5),
>>>>>>> origin/main
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
<<<<<<< HEAD
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
=======
                  ? Center(child: Text(
                      _tab == 4 ? 'Aucune course assignée'
                          : _tab == 5 ? 'Aucune course validée'
                          : 'Aucune livraison',
                      style: const TextStyle(color: Colors.white38)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.gold,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        children: _filtered.map((d) {
                          if (_tab == 4) return _cardAssignee(d);
                          if (_tab == 5) return _cardValidee(d);
                          return _card(d);
                        }).toList(),
                      ),
                    ),
>>>>>>> origin/main
            ),
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  // ── Onglet chip ──
  Widget _tabChip(String label, int i, int count) {
=======
  Widget _tabChip(String label, int i, {int badge = 0}) {
>>>>>>> origin/main
    final active = _tab == i;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
<<<<<<< HEAD
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
=======
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: active ? AppColors.gold : AppColors.cardNavy,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(label, style: TextStyle(
                  color: active ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            if (badge > 0)
              Positioned(
                top: -4, right: -4,
                child: Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Center(child: Text('$badge',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _card(DeliveryModel d) {
    final color = _statusColor(d.status);
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DeliveryRouteDetailScreen(delivery: d))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.cardNavy, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 44, height: 44,
                    decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(Icons.inventory_2_outlined, color: color, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.clientNom, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(d.adresseLivraison, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                )),
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
>>>>>>> origin/main
        ),
      ),
    );
  }

<<<<<<< HEAD
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
=======
  Widget _cardAssignee(DeliveryModel d) {
    final loading = _actionEnCours.contains(d.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardNavy, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.local_shipping_outlined, color: AppColors.blue, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.clientNom, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(d.adresseLivraison, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Text('Assignée', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w600, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.attach_money, color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Text('${_fmt(d.montant)} à collecter', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              const Icon(Icons.access_time, color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Text(_heure(d.dateCreation), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          if (d.instructions != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white38, size: 13),
                const SizedBox(width: 4),
                Expanded(child: Text(d.instructions!, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white38, fontSize: 11))),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: loading ? null : () => _refuser(d),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Refuser'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(
                onPressed: loading ? null : () => _accepter(d),
                icon: loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check, size: 16),
                label: Text(loading ? '...' : 'Accepter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardValidee(DeliveryModel d) {
    final loading = _actionEnCours.contains(d.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardNavy, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.green.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.green.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_outline, color: AppColors.green, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.clientNom, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(d.adresseLivraison, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Text('Validée', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.attach_money, color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Text('${_fmt(d.montant)} à collecter', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              const Icon(Icons.access_time, color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Text(_heure(d.dateCreation), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: loading ? null : () => _demarrer(d),
              icon: loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.play_arrow, size: 18),
              label: Text(loading ? 'Démarrage...' : 'Démarrer la course'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
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
      child: Text(_statusLabel(s), style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
>>>>>>> origin/main
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