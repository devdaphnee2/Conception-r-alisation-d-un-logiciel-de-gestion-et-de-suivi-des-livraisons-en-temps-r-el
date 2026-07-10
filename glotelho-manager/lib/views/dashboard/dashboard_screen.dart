/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/dashboard_header.dart';

/// Écran d'accueil manager — reprend la logique et les KPIs exacts de
/// Dashboard.jsx : appels en parallèle sur /livraisons, /livreurs,
/// /litiges, /orders, /recouvrements, /profils/en-attente, puis calcul
/// des statistiques côté client (comme le `stats` du web).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  List livraisons = [];
  List livreurs = [];
  List litiges = [];
  List commandes = [];
  List recouvrements = [];
  List profils = [];

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
        api.getLivreurs(all: true).catchError((_) => null),
        api.getLitiges().catchError((_) => null),
        api.getCommandes().catchError((_) => null),
        api.getRecouvrements().catchError((_) => null),
        api.getProfilsEnAttente().catchError((_) => null),
      ]);
      setState(() {
        livraisons = results[0]?.data ?? [];
        livreurs = results[1]?.data ?? [];
        litiges = results[2]?.data ?? [];
        commandes = results[3]?.data ?? [];
        recouvrements = results[4]?.data ?? [];
        profils = results[5]?.data ?? [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Même calcul que `stats` dans Dashboard.jsx
  Map<String, dynamic> get stats {
    num detteTotal = 0;
    for (final r in recouvrements) {
      detteTotal += (num.tryParse('${r['amount_to_collect'] ?? 0}') ?? 0) -
          (num.tryParse('${r['amount_collected'] ?? 0}') ?? 0);
    }
    num caTotal = 0;
    for (final c in commandes) {
      caTotal += num.tryParse('${c['total_amount'] ?? 0}') ?? 0;
    }
    return {
      'livraisons_total': livraisons.length,
      'en_cours': livraisons.where((l) => l['status'] == 'En_cours').length,
      'en_attente': livraisons.where((l) => l['status'] == 'En_attente').length,
      'livrees': livraisons.where((l) => l['status'] == 'Livré').length,
      'suspendues': livraisons.where((l) => l['status'] == 'Suspendu').length,
      'livreurs_actifs':
      livreurs.where((l) => l['status'] == 'En_livraison').length,
      'livreurs_dispo':
      livreurs.where((l) => l['status'] == 'Disponible').length,
      'litiges_ouverts':
      litiges.where((l) => l['status'] == 'En_attente').length,
      'commandes_total': commandes.length,
      'profils_attente': profils.length,
      'dette_total': detteTotal,
      'ca_total': caTotal,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = stats;
    final recentLivraisons = [...livraisons]
      ..sort((a, b) => (b['creation_date'] ?? '')
          .toString()
          .compareTo((a['creation_date'] ?? '').toString()));
    final recent = recentLivraisons.take(8).toList();

    // Alertes, identiques à la logique du web
    final alertes = <Map<String, dynamic>>[];
    if (s['profils_attente'] > 0) {
      alertes.add({
        'type': 'warning',
        'msg': '${s['profils_attente']} profil(s) livreur en attente de validation'
      });
    }
    if (s['litiges_ouverts'] > 0) {
      alertes.add({
        'type': 'error',
        'msg': '${s['litiges_ouverts']} litige(s) non traité(s)'
      });
    }
    if (s['suspendues'] > 0) {
      alertes.add({
        'type': 'error',
        'msg': '${s['suspendues']} livraison(s) suspendue(s) — réassignation requise'
      });
    }
    if (s['dette_total'] > 0) {
      alertes.add({
        'type': 'warning',
        'msg': '${s['dette_total']} FCFA de dettes livreurs non recouvrées'
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          DashboardHeader(
            firstName:
            context.watch<AppState>().currentManager?['first_name'] ?? 'Manager',
            hasUnreadNotifications: false, // TODO: brancher sur le vrai flux
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
                  // Alertes
                  ...alertes.map((a) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: a['type'] == 'error'
                          ? const Color(0xFFFFDAD6)
                          : const Color(0xFFFFDEA9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 16,
                            color: a['type'] == 'error'
                                ? const Color(0xFFBA1A1A)
                                : const Color(0xFF7D5700)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(a['msg'],
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),

                  // KPI grid (2 colonnes en mobile au lieu de 4)
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
                        label: 'Livraisons totales',
                        value: '${s['livraisons_total']}',
                        sub: '${s['en_cours']} en cours',
                        iconColor: AppTheme.navyLight,
                      ),
                      KpiCard(
                        icon: Icons.local_shipping_outlined,
                        label: 'Livreurs actifs',
                        value: '${s['livreurs_actifs']}',
                        sub: '${s['livreurs_dispo']} disponibles',
                        iconColor: const Color(0xFF81C784),
                      ),
                      KpiCard(
                        icon: Icons.report_gmailerrorred_outlined,
                        label: 'Litiges ouverts',
                        value: '${s['litiges_ouverts']}',
                        sub: 'À traiter',
                        iconColor: const Color(0xFFEF9A9A),
                      ),
                      KpiCard(
                        icon: Icons.receipt_long_outlined,
                        label: 'Commandes',
                        value: '${s['commandes_total']}',
                        sub: 'CA: ${(s['ca_total'] / 1000).toStringAsFixed(0)}k FCFA',
                        iconColor: const Color(0xFF6AA1E3),
                      ),
                      KpiCard(
                        icon: Icons.check_circle_outline,
                        label: 'Livrées',
                        value: '${s['livrees']}',
                        iconColor: const Color(0xFF81C784),
                      ),
                      KpiCard(
                        icon: Icons.hourglass_empty,
                        label: 'En attente',
                        value: '${s['en_attente']}',
                        iconColor: AppTheme.navyLight,
                      ),
                      KpiCard(
                        icon: Icons.pause_circle_outline,
                        label: 'Suspendues',
                        value: '${s['suspendues']}',
                        iconColor: const Color(0xFFEF9A9A),
                      ),
                      KpiCard(
                        icon: Icons.person_search_outlined,
                        label: 'Profils en attente',
                        value: '${s['profils_attente']}',
                        iconColor: AppTheme.navyLight,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Livraisons récentes
                  _sectionTitle(context, 'Livraisons récentes', '/livraisons'),
                  const SizedBox(height: 8),
                  if (recent.isEmpty)
                    _emptyCard('Aucune livraison.')
                  else
                    ...recent.map((l) => _livraisonTile(l)),

                  const SizedBox(height: 20),

                  // Livreurs
                  _sectionTitle(context, 'Livreurs (${livreurs.length})', '/livreurs'),
                  const SizedBox(height: 8),
                  if (livreurs.isEmpty)
                    _emptyCard('Aucun livreur.')
                  else
                    ...livreurs.take(6).map((l) => _livreurTile(l)),

                  // Dettes
                  if (s['dette_total'] > 0) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDAD6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dettes livreurs',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text('${s['dette_total']} FCFA',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFBA1A1A))),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Actions rapides
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
                      _quickAction('Nouvelle livraison', AppTheme.navy, Colors.white),
                      _quickAction('Tracking GPS', Colors.grey.shade200, AppTheme.navy),
                      _quickAction('Nouveau litige', const Color(0xFFFFDAD6),
                          const Color(0xFFBA1A1A)),
                      _quickAction('Profils à valider', const Color(0xFFFFDEA9),
                          const Color(0xFF7D5700)),
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
        TextButton(
          onPressed: () => Navigator.pushNamed(context, route),
          child: const Text('Voir tout →', style: TextStyle(fontSize: 12)),
        ),
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

  Widget _livraisonTile(Map l) {
    const statusLabels = {
      'En_attente': 'En attente',
      'Assigné': 'Assigné',
      'En_cours': 'En cours',
      'Livré': 'Livré',
      'Suspendu': 'Suspendu',
      'Annulé': 'Annulé',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text('#${l['id']}',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.navy)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${l['customers']?['users']?['first_name'] ?? ''} ${l['customers']?['users']?['last_name'] ?? ''}',
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
            child: Text(statusLabels[l['status']] ?? '${l['status']}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _livreurTile(Map l) {
    final status = l['status'];
    final dotColor = status == 'En_livraison'
        ? const Color(0xFFC9952E)
        : status == 'Disponible'
        ? const Color(0xFF4CAF50)
        : Colors.grey;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppTheme.navy,
            child: Text(
              (l['users']?['first_name'] ?? '?')[0],
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${l['users']?['first_name'] ?? ''} ${l['users']?['last_name'] ?? ''}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(String label, Color bg, Color fg) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/dashboard_header.dart';
import '../livraisons/nouvelle_livraison_screen.dart';
import '../livraisons/livraison_detail_screen.dart';
//import '../litiges/nouveau_litige_screen.dart';
import '../livreurs/livreurs_screen.dart';
import '../tracking/tracking_screen.dart';

/// Écran d'accueil manager — reprend la logique et les KPIs exacts de
/// Dashboard.jsx : appels en parallèle sur /livraisons, /livreurs,
/// /litiges, /orders, /recouvrements, /profils/en-attente, puis calcul
/// des statistiques côté client (comme le `stats` du web).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  List livraisons = [];
  List livreurs = [];
  List litiges = [];
  List commandes = [];
  List recouvrements = [];
  List profils = [];

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
        api.getLivreurs(all: true).catchError((_) => null),
        api.getLitiges().catchError((_) => null),
        api.getCommandes().catchError((_) => null),
        api.getRecouvrements().catchError((_) => null),
        api.getProfilsEnAttente().catchError((_) => null),
      ]);
      setState(() {
        livraisons = results[0]?.data ?? [];
        livreurs = results[1]?.data ?? [];
        litiges = results[2]?.data ?? [];
        commandes = results[3]?.data ?? [];
        recouvrements = results[4]?.data ?? [];
        profils = results[5]?.data ?? [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Même calcul que `stats` dans Dashboard.jsx
  Map<String, dynamic> get stats {
    num detteTotal = 0;
    for (final r in recouvrements) {
      detteTotal += (num.tryParse('${r['amount_to_collect'] ?? 0}') ?? 0) -
          (num.tryParse('${r['amount_collected'] ?? 0}') ?? 0);
    }
    num caTotal = 0;
    for (final c in commandes) {
      caTotal += num.tryParse('${c['total_amount'] ?? 0}') ?? 0;
    }
    return {
      'livraisons_total': livraisons.length,
      'en_cours': livraisons.where((l) => l['status'] == 'En_cours').length,
      'en_attente': livraisons.where((l) => l['status'] == 'En_attente').length,
      'livrees': livraisons.where((l) => l['status'] == 'Livré').length,
      'suspendues': livraisons.where((l) => l['status'] == 'Suspendu').length,
      'livreurs_actifs':
      livreurs.where((l) => l['status'] == 'En_livraison').length,
      'livreurs_dispo':
      livreurs.where((l) => l['status'] == 'Disponible').length,
      'litiges_ouverts':
      litiges.where((l) => l['status'] == 'En_attente').length,
      'commandes_total': commandes.length,
      'profils_attente': profils.length,
      'dette_total': detteTotal,
      'ca_total': caTotal,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = stats;
    final recentLivraisons = [...livraisons]
      ..sort((a, b) => (b['creation_date'] ?? '')
          .toString()
          .compareTo((a['creation_date'] ?? '').toString()));
    final recent = recentLivraisons.take(8).toList();

    // Alertes, identiques à la logique du web
    final alertes = <Map<String, dynamic>>[];
    if (s['profils_attente'] > 0) {
      alertes.add({
        'type': 'warning',
        'msg': '${s['profils_attente']} profil(s) livreur en attente de validation'
      });
    }
    if (s['litiges_ouverts'] > 0) {
      alertes.add({
        'type': 'error',
        'msg': '${s['litiges_ouverts']} litige(s) non traité(s)'
      });
    }
    if (s['suspendues'] > 0) {
      alertes.add({
        'type': 'error',
        'msg': '${s['suspendues']} livraison(s) suspendue(s) — réassignation requise'
      });
    }
    if (s['dette_total'] > 0) {
      alertes.add({
        'type': 'warning',
        'msg': '${s['dette_total']} FCFA de dettes livreurs non recouvrées'
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          DashboardHeader(
            firstName:
            context.watch<AppState>().currentManager?['first_name'] ?? 'Manager',
            hasUnreadNotifications: false, // TODO: brancher sur le vrai flux
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
                  // Alertes
                  ...alertes.map((a) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: a['type'] == 'error'
                          ? const Color(0xFFFFDAD6)
                          : const Color(0xFFFFDEA9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 16,
                            color: a['type'] == 'error'
                                ? const Color(0xFFBA1A1A)
                                : const Color(0xFF7D5700)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(a['msg'],
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),

                  // KPI grid (2 colonnes en mobile au lieu de 4)
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
                        label: 'Livraisons totales',
                        value: '${s['livraisons_total']}',
                        sub: '${s['en_cours']} en cours',
                        iconColor: Colors.white,
                      ),
                      KpiCard(
                        icon: Icons.local_shipping_outlined,
                        label: 'Livreurs actifs',
                        value: '${s['livreurs_actifs']}',
                        sub: '${s['livreurs_dispo']} disponibles',
                        iconColor: const Color(0xFF81C784),
                      ),
                      KpiCard(
                        icon: Icons.report_gmailerrorred_outlined,
                        label: 'Litiges ouverts',
                        value: '${s['litiges_ouverts']}',
                        sub: 'À traiter',
                        iconColor: const Color(0xFFEF9A9A),
                      ),
                      KpiCard(
                        icon: Icons.receipt_long_outlined,
                        label: 'Commandes',
                        value: '${s['commandes_total']}',
                        sub: 'CA: ${(s['ca_total'] / 1000).toStringAsFixed(0)}k FCFA',
                        iconColor: const Color(0xFF6AA1E3),
                      ),
                      KpiCard(
                        icon: Icons.check_circle_outline,
                        label: 'Livrées',
                        value: '${s['livrees']}',
                        iconColor: const Color(0xFF81C784),
                      ),
                      KpiCard(
                        icon: Icons.hourglass_empty,
                        label: 'En attente',
                        value: '${s['en_attente']}',
                        iconColor: Colors.white,
                      ),
                      KpiCard(
                        icon: Icons.pause_circle_outline,
                        label: 'Suspendues',
                        value: '${s['suspendues']}',
                        iconColor: const Color(0xFFEF9A9A),
                      ),
                      KpiCard(
                        icon: Icons.person_search_outlined,
                        label: 'Profils en attente',
                        value: '${s['profils_attente']}',
                        iconColor: Colors.white,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Livraisons récentes
                  _sectionTitle(context, 'Livraisons récentes', '/livraisons'),
                  const SizedBox(height: 8),
                  if (recent.isEmpty)
                    _emptyCard('Aucune livraison.')
                  else
                    ...recent.map((l) => _livraisonTile(l)),

                  const SizedBox(height: 20),

                  // Livreurs
                  _sectionTitle(context, 'Livreurs (${livreurs.length})', '/livreurs'),
                  const SizedBox(height: 8),
                  if (livreurs.isEmpty)
                    _emptyCard('Aucun livreur.')
                  else
                    ...livreurs.take(6).map((l) => _livreurTile(l)),

                  // Dettes
                  if (s['dette_total'] > 0) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDAD6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dettes livreurs',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text('${s['dette_total']} FCFA',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFBA1A1A))),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Actions rapides
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
                        'Nouvelle livraison',
                        AppTheme.navy,
                        Colors.white,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const NouvelleLivraisonScreen())),
                      ),
                      _quickAction(
                        'Tracking GPS',
                        Colors.grey.shade200,
                        AppTheme.navy,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const TrackingScreen())),
                      ),
                     /*_quickAction(
                        'Nouveau litige',
                        const Color(0xFFFFDAD6),
                        const Color(0xFFBA1A1A),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const NouveauLitigeScreen())),
                      ),*/
                      _quickAction(
                        'Profils à valider',
                        const Color(0xFFFFDEA9),
                        const Color(0xFF7D5700),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LivreursScreen(initialTabIndex: 1))),
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
        TextButton(
          onPressed: () => Navigator.pushNamed(context, route),
          child: const Text('Voir tout →', style: TextStyle(fontSize: 12)),
        ),
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

  Widget _livraisonTile(Map l) {
    const statusLabels = {
      'En_attente': 'En attente',
      'Assigné': 'Assigné',
      'En_cours': 'En cours',
      'Livré': 'Livré',
      'Suspendu': 'Suspendu',
      'Annulé': 'Annulé',
    };
    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => LivraisonDetailScreen(livraisonId: l['id']))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text('#${l['id']}',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.navy)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${l['customers']?['users']?['first_name'] ?? ''} ${l['customers']?['users']?['last_name'] ?? ''}',
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
              child: Text(statusLabels[l['status']] ?? '${l['status']}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _livreurTile(Map l) {
    final status = l['status'];
    final dotColor = status == 'En_livraison'
        ? const Color(0xFFC9952E)
        : status == 'Disponible'
        ? const Color(0xFF4CAF50)
        : Colors.grey;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppTheme.navy,
            child: Text(
              (l['users']?['first_name'] ?? '?')[0],
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${l['users']?['first_name'] ?? ''} ${l['users']?['last_name'] ?? ''}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ],
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