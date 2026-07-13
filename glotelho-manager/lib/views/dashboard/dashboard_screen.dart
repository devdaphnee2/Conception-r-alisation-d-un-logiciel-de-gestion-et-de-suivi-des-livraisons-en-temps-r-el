import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/dashboard_header.dart';
import '../commandes/nouvelle_commande_screen.dart';
import '../commandes/commande_detail_screen.dart';
import '../tracking/tracking_screen.dart';
//import '../litiges/litiges_screen.dart';

/// Écran d'accueil — app E-COMMERÇANT : KPIs sur SES propres commandes
/// (pas de gestion livreurs/recouvrements), accès rapide à la création
/// de commande, au suivi GPS, et à la consultation des litiges.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  List commandes = [];
  List litiges = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final api = ApiService(context.read<AppState>());
    try {
      final results = await Future.wait([
        api.getLivraisons().catchError((_) => null),
        api.getLitiges().catchError((_) => null),
      ]);
      setState(() {
        commandes = results[0]?.data ?? [];
        litiges = results[1]?.data ?? [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> get stats {
    num caTotal = 0;
    for (final c in commandes) {
      caTotal += num.tryParse('${c['amount_to_collect'] ?? 0}') ?? 0;
    }
    return {
      'total': commandes.length,
      'en_attente': commandes.where((c) => c['status'] == 'En_attente').length,
      'en_cours': commandes.where((c) => c['status'] == 'En_cours').length,
      'livrees': commandes.where((c) => c['status'] == 'Livré').length,
      'litiges_ouverts': litiges.where((l) => l['status'] == 'En_attente').length,
      'ca_total': caTotal,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = stats;
    final recentCommandes = [...commandes]
      ..sort((a, b) => (b['creation_date'] ?? '')
          .toString()
          .compareTo((a['creation_date'] ?? '').toString()));
    final recent = recentCommandes.take(8).toList();

    final alertes = <String>[];
    if (s['en_attente'] > 0) {
      alertes.add('${s['en_attente']} course(s) en attente de traitement par l\'administration');
    }
    if (s['litiges_ouverts'] > 0) {
      alertes.add('${s['litiges_ouverts']} litige(s) ouvert(s) concernant vos commandes');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          DashboardHeader(
            firstName:
            context.watch<AppState>().currentManager?['first_name'] ?? 'Commerçant',
            hasUnreadNotifications: false,
            onNotificationTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                children: [
                  ...alertes.map((msg) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDEA9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: Color(0xFF7D5700)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(msg,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.85,
                    children: [
                      KpiCard(
                        icon: Icons.inventory_2_outlined,
                        label: 'Commandes totales',
                        value: '${s['total']}',
                        sub: 'CA: ${(s['ca_total'] / 1000).toStringAsFixed(0)}k FCFA',
                        iconColor: Colors.white,
                      ),
                      KpiCard(
                        icon: Icons.hourglass_empty,
                        label: 'Courses en attente',
                        value: '${s['en_attente']}',
                        iconColor: Colors.white,
                      ),
                      KpiCard(
                        icon: Icons.local_shipping_outlined,
                        label: 'En cours',
                        value: '${s['en_cours']}',
                        iconColor: const Color(0xFF6AA1E3),
                      ),
                      KpiCard(
                        icon: Icons.check_circle_outline,
                        label: 'Livrées',
                        value: '${s['livrees']}',
                        iconColor: const Color(0xFF81C784),
                      ),
                      KpiCard(
                        icon: Icons.report_gmailerrorred_outlined,
                        label: 'Litiges ouverts',
                        value: '${s['litiges_ouverts']}',
                        iconColor: const Color(0xFFEF9A9A),
                      ),
                      KpiCard(
                        icon: Icons.payments_outlined,
                        label: 'Chiffre d\'affaires',
                        value: '${(s['ca_total'] / 1000).toStringAsFixed(0)}k',
                        sub: 'FCFA',
                        iconColor: const Color(0xFFFFB74D),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _sectionTitle(context, 'Commandes récentes', '/livraisons'),
                  const SizedBox(height: 8),
                  if (recent.isEmpty)
                    _emptyCard('Aucune commande pour le moment.')
                  else
                    ...recent.map((c) => _commandeTile(c)),

                  const SizedBox(height: 20),
                  const Text('Actions rapides',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.6,
                    children: [
                      _quickAction(
                        'Nouvelle commande',
                        AppTheme.navy,
                        Colors.white,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NouvelleCommandeScreen())),
                      ),
                      _quickAction(
                        'Suivi GPS',
                        Colors.grey.shade200,
                        AppTheme.navy,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const TrackingScreen())),
                      ),
                      _quickAction(
                        'Mes litiges',
                        const Color(0xFFFFDAD6),
                        const Color(0xFFBA1A1A),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const LitigesScreen())),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, String route) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _emptyCard(String text) => Container(
    padding: const EdgeInsets.all(20),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
  );

  Widget _commandeTile(Map c) {
    const statusLabels = {
      'En_attente': 'Course en attente',
      'Assigné': 'Assigné',
      'En_cours': 'En cours',
      'Livré': 'Livré',
      'Suspendu': 'Suspendu',
      'Annulé': 'Annulé',
    };
    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => CommandeDetailScreen(livraisonId: c['id']))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text('#${c['id']}',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.navy)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${c['customers']?['users']?['first_name'] ?? ''} ${c['customers']?['users']?['last_name'] ?? ''}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(statusLabels[c['status']] ?? '${c['status']}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(String label, Color bg, Color fg, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}