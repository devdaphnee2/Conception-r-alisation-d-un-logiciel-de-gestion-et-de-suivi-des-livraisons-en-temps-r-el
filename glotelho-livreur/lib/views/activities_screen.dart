import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/earnings_service.dart';
import '../models/activity_model.dart';
import 'commission_detail_screen.dart';
import 'delivery_route_detail_screen.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  List<ActivityModel> _all = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() {}));
  }

  Future<void> _load() async {
    final activities = await EarningsService.getActivities(limit: 0);
    if (!mounted) return;
    setState(() {
      _all = activities;
      _isLoading = false;
    });
  }

  String _dateKey(DateTime d) => '${d.day} ${_moisComplet(d.month)} ${d.year}';
  String _moisComplet(int m) => const ['', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'][m];

  // Libellés dérivés du type (remplace label/subLabel).
  String _titleOf(ActivityModel a) => a.isCommission ? 'Commission' : 'Livraison';
  String _subOf(ActivityModel a) =>
      a.isCommission ? a.manager : '${a.clientName ?? '—'} · ${a.clientPhone ?? ''}';

  Map<String, List<ActivityModel>> get _grouped {
    final q = _searchCtrl.text.toLowerCase();
    final filtered = q.isEmpty
        ? _all
        : _all.where((a) =>
    _titleOf(a).toLowerCase().contains(q) ||
        _subOf(a).toLowerCase().contains(q)).toList();

    final map = <String, List<ActivityModel>>{};
    for (final a in filtered) {
      final key = _dateKey(a.date);
      map.putIfAbsent(key, () => []).add(a);
    }
    return map;
  }

  void _openDetail(ActivityModel a) {
    if (a.isCommission) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => CommissionDetailScreen(commission: a)));
      return;
    }
    // Livraison — afficher les détails directement
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardNavy,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Livraison #${a.id}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            _detailRow('Client', a.clientName ?? '—'),
            _detailRow('Téléphone', a.clientPhone ?? '—'),
            _detailRow('Adresse', a.clientAddress ?? '—'),
            _detailRow('Montant', '${a.amount.toStringAsFixed(0)} XAF'),
            if (a.fraisLivraison != null) _detailRow('Commission', '${a.fraisLivraison!.toStringAsFixed(0)} XAF'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(width: 110, child: Text(k, style: const TextStyle(color: Colors.white54, fontSize: 13))),
        Expanded(child: Text(v, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('ACTIVITÉS', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: const Color(0xFF16324A), borderRadius: BorderRadius.circular(14)),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une transaction ...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                    : grouped.isEmpty
                    ? const Center(child: Text('Aucune transaction', style: TextStyle(color: Colors.white38)))
                    : ListView(
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(entry.key, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        ...entry.value.map((a) => _buildTile(a)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(ActivityModel a) {
    final isCommission = a.isCommission;

    IconData icon;
    Color iconColor;
    Color iconBg;

    if (isCommission) {
      icon = Icons.arrow_downward;
      iconColor = Colors.tealAccent;
      iconBg = Colors.teal.withOpacity(0.15);
    } else {
      icon = Icons.inventory_2_outlined; // colis
      iconColor = Colors.white;
      iconBg = Colors.orange;
    }

    final amountText = isCommission
        ? '+${a.amount.toStringAsFixed(a.amount.truncateToDouble() == a.amount ? 0 : 1)} XAF'
        : '${a.amount.toStringAsFixed(a.amount.truncateToDouble() == a.amount ? 0 : 1)} XAF';

    return InkWell(
      onTap: () => _openDetail(a),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_titleOf(a), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(_subOf(a), maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amountText,
                    style: TextStyle(color: isCommission ? Colors.tealAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${a.date.hour.toString().padLeft(2, '0')}:${a.date.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}