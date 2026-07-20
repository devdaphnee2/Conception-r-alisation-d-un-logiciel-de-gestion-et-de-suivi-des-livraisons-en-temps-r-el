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

  int _tab = 0; // 0=Toutes, 1=En cours, 2=Livrées, 3=Annulées, 4=Assignées, 5=Validées

  final Set<String> _actionEnCours = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final courses = await TrackingService.getTodayDeliveries();
    final historique = await TrackingService.getHistorique();
    if (!mounted) return;
    setState(() {
      _all = courses;
      _historique = historique;
      _loading = false;
    });
  }

  List<DeliveryModel> get _toutes => [..._all, ..._historique];

  // ── Filtrage par onglet ──
  List<DeliveryModel> get _filtered {
    switch (_tab) {
      case 1:
        return _toutes.where((d) => d.status == DeliveryStatus.inProgress).toList();
      case 2:
        return _toutes.where((d) => d.status == DeliveryStatus.delivered).toList();
      case 3:
        return _toutes.where((d) => d.status == DeliveryStatus.cancelled).toList();
      case 4:
        return _toutes.where((d) => d.status == DeliveryStatus.assigned).toList();
      case 5:
        return _toutes.where((d) => d.status == DeliveryStatus.validated).toList();
      default:
        return _toutes;
    }
  }

  Future<void> _accepter(DeliveryModel d) async {
    setState(() => _actionEnCours.add(d.id));
    try {
      final ok = await TrackingService.accepterCourse(d.id);
      if (ok) {
        setState(() {
          d.status = DeliveryStatus.validated;
        });
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Erreur lors de l'acceptation."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
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
        content: const Text(
          'Le manager sera notifié et la course sera réassignée.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _actionEnCours.add(d.id));
    try {
      await TrackingService.refuserCourse(d.id);
      setState(() {
        d.status = DeliveryStatus.cancelled;
        _all.remove(d);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Course refusée. Le manager a été notifié.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _actionEnCours.remove(d.id));
    }
  }

  Future<void> _demarrer(DeliveryModel d) async {
    setState(() => _actionEnCours.add(d.id));
    try {
      await TrackingService.demarrerCourse(d.id);
      setState(() {
        d.status = DeliveryStatus.inProgress;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🚀 Course démarrée ! Le client a été notifié.'),
          backgroundColor: Color(0xFF1565C0),
          behavior: SnackBarBehavior.floating,
        ));
        setState(() => _tab = 1);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erreur lors du démarrage.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _actionEnCours.remove(d.id));
    }
  }

  // ── Couleur par statut ──
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
      case DeliveryStatus.validated:
        return AppColors.green;
      case DeliveryStatus.pending:
        return AppColors.statusPending;
    }
  }

  // ── Label par statut ──
  String _statusLabel(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.delivered:
        return 'Livrée';
      case DeliveryStatus.cancelled:
        return 'Annulée';
      case DeliveryStatus.inProgress:
        return 'En cours';
      case DeliveryStatus.assigned:
        return 'Assignée';
      case DeliveryStatus.suspended:
        return 'Suspendue';
      case DeliveryStatus.validated:
        return 'Validée';
      case DeliveryStatus.pending:
        return 'En attente';
    }
  }

  // ── Icône par statut ──
  IconData _statusIcon(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.delivered:
        return Icons.check_circle_outline;
      case DeliveryStatus.cancelled:
        return Icons.cancel_outlined;
      case DeliveryStatus.inProgress:
        return Icons.local_shipping_outlined;
      case DeliveryStatus.assigned:
        return Icons.assignment_outlined;
      case DeliveryStatus.suspended:
        return Icons.pause_circle_outline;
      case DeliveryStatus.validated:
        return Icons.verified_outlined;
      case DeliveryStatus.pending:
        return Icons.hourglass_empty_outlined;
    }
  }

  String _fmt(double v) =>
      '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} XAF';

  String _heure(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  // ── BUILD ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final nbAssignees =
        _toutes.where((d) => d.status == DeliveryStatus.assigned).length;

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
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_toutes.length} au total',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
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
                  _tabChip('Toutes', 0),
                  _tabChip('En cours', 1),
                  _tabChip('Livrées', 2),
                  _tabChip('Annulées', 3),
                  _tabChip('Assignées', 4, badge: nbAssignees),
                  _tabChip('Validées', 5),
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
                  ? Center(
                child: Text(
                  _tab == 4
                      ? 'Aucune course assignée'
                      : _tab == 5
                      ? 'Aucune course validée'
                      : 'Aucune livraison',
                  style: const TextStyle(color: Colors.white38),
                ),
              )
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
            ),
          ],
        ),
      ),
    );
  }

  // ── Onglet chip ──
  Widget _tabChip(String label, int i, {int badge = 0}) {
    final active = _tab == i;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
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
              child: Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            if (badge > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Carte classique ──
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardNavy,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_statusIcon(d.status), color: color, size: 20),
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
                      const SizedBox(height: 2),
                      Text(
                        d.adresseLivraison,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
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

  // ── Carte Assignée ──
  Widget _cardAssignee(DeliveryModel d) {
    final loading = _actionEnCours.contains(d.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.blue,
                  size: 20,
                ),
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
                    Text(
                      d.adresseLivraison,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Assignée',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.attach_money, color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Text(
                '${_fmt(d.montant)} à collecter',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              const Icon(Icons.access_time, color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Text(
                _heure(d.dateCreation),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          if (d.instructions != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white38, size: 13),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    d.instructions!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loading ? null : () => _refuser(d),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Refuser'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: loading ? null : () => _accepter(d),
                  icon: loading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.check, size: 16),
                  label: Text(loading ? '...' : 'Accepter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Carte Validée ──
  Widget _cardValidee(DeliveryModel d) {
    final loading = _actionEnCours.contains(d.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.green.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.green,
                  size: 20,
                ),
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
                    Text(
                      d.adresseLivraison,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Validée',
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.attach_money, color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Text(
                '${_fmt(d.montant)} à collecter',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              const Icon(Icons.access_time, color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Text(
                _heure(d.dateCreation),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: loading ? null : () => _demarrer(d),
              icon: loading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.play_arrow, size: 18),
              label: Text(loading ? 'Démarrage...' : 'Démarrer la course'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
        Text(
          v,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _badge(DeliveryStatus s) {
    final color = _statusColor(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _statusLabel(s),
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}