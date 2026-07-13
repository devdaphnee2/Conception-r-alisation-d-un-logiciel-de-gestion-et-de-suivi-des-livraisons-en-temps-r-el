import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/kpi_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiService(context.read<AppState>());
      final res = await api.getLivraisons();
      final livraisons = (res.data as List?) ?? [];

      setState(() {
        _stats = {
          'total'      : livraisons.length,
          'en_attente' : livraisons.where((l) => l['status'] == 'En_attente').length,
          'en_cours'   : livraisons.where((l) => l['status'] == 'En_cours').length,
          'livrees'    : livraisons.where((l) => l['status'] == 'Livr_').length,
          'suspendues' : livraisons.where((l) => l['status'] == 'Suspendu').length,
          'montant'    : livraisons.fold<double>(0, (s, l) => s + ((l['amount_to_collect'] ?? 0) as num).toDouble()),
          'dernieres'  : livraisons.take(4).toList(),
        };
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AppState>().currentManager;
    final prenom  = manager?['first_name'] ?? 'E-commerçant';
    final heure   = DateTime.now().hour;
    final salut   = heure < 12 ? 'Bonjour' : heure < 18 ? 'Bon après-midi' : 'Bonsoir';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.navy, AppTheme.navy.withOpacity(0.85)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$salut, $prenom 👋',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(_dateAujourdhui(),
                                style: const TextStyle(color: Colors.white60, fontSize: 13)),
                          ],
                        ),
                        CircleAvatar(
                          backgroundColor: AppTheme.gold.withOpacity(0.2),
                          child: Text(prenom[0].toUpperCase(),
                              style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Montant total
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total à collecter', style: TextStyle(color: Colors.white60, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('${(_stats['montant'] ?? 0).toStringAsFixed(0)} FCFA',
                                  style: TextStyle(color: AppTheme.gold, fontSize: 24, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          const Icon(Icons.account_balance_wallet_outlined, color: Colors.white30, size: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // KPIs
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  KpiCard(icon: Icons.inbox_outlined,       label: 'Total',       value: '${_stats['total'] ?? 0}',      iconColor: AppTheme.navy),
                  KpiCard(icon: Icons.hourglass_empty,      label: 'En attente',  value: '${_stats['en_attente'] ?? 0}', iconColor: const Color(0xFFC9952E)),
                  KpiCard(icon: Icons.delivery_dining,      label: 'En cours',    value: '${_stats['en_cours'] ?? 0}',   iconColor: const Color(0xFF20619E)),
                  KpiCard(icon: Icons.check_circle_outline, label: 'Livrées',     value: '${_stats['livrees'] ?? 0}',    iconColor: const Color(0xFF1B5E20)),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
              ),
            ),

            // Dernières livraisons
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dernières livraisons',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...(_stats['dernieres'] as List? ?? []).map((l) => _livraisonTile(l)).toList(),
                    if ((_stats['dernieres'] as List? ?? []).isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: const Text('Aucune livraison pour le moment.', style: TextStyle(color: Colors.grey)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _livraisonTile(Map l) {
    const statusColors = {
      'En_attente': Color(0xFFFFA000),
      'Assign_'   : Color(0xFF3E5682),
      'En_cours'  : Color(0xFF20619E),
      'Livr_'     : Color(0xFF1B5E20),
      'Suspendu'  : Color(0xFFBA1A1A),
      'Annul_'    : Color(0xFF817564),
    };
    const statusLabels = {
      'En_attente': 'En attente',
      'Assign_'   : 'Assigné',
      'En_cours'  : 'En cours',
      'Livr_'     : 'Livré',
      'Suspendu'  : 'Suspendu',
      'Annul_'    : 'Annulé',
    };
    final status = l['status'] as String? ?? '';
    final color  = statusColors[status] ?? Colors.grey;
    final label  = statusLabels[status] ?? status;
    final client = l['client_nom'] as String? ?? '—';
    final id     = '#${l['id'].toString().padLeft(5, '0')}';
    final montant= '${(l['amount_to_collect'] ?? 0).toString()} FCFA';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.15),
            child: Text(client.isNotEmpty ? client[0] : '?',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$id — $client', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(l['delivery_address'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Text(montant, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.navy)),
            ],
          ),
        ],
      ),
    );
  }

  String _dateAujourdhui() {
    const mois = ['', 'jan.', 'fév.', 'mar.', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sep.', 'oct.', 'nov.', 'déc.'];
    final d = DateTime.now();
    return '${d.day} ${mois[d.month]} ${d.year}';
  }
}