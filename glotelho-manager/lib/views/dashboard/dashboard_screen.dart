import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool   _loading      = true;
  int    _total        = 0;
  int    _enAttente    = 0;
  int    _enCours      = 0;
  int    _livrees      = 0;
  double _montantTotal = 0;
  List   _dernieres    = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiService(context.read<AppState>());
      final res = await api.getMesCommandes();
      final all = (res.data as List?) ?? [];
      setState(() {
        _total        = all.length;
        _enAttente    = all.where((l) => l['status'] == 'En_attente').length;
        _enCours      = all.where((l) => l['status'] == 'En_cours').length;
        _livrees      = all.where((l) => l['status'] == 'Livr_').length;
        _montantTotal = all.fold(0.0, (s, l) => s + ((l['amount_to_collect'] ?? 0) as num).toDouble());
        _dernieres    = all.take(5).toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final txtColor = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final manager  = context.watch<AppState>().currentManager;
    final prenom   = manager?['first_name'] ?? 'Commerçant';
    final heure    = DateTime.now().hour;
    final salut    = heure < 12 ? 'Bonjour' : heure < 18 ? 'Bon après-midi' : 'Bonsoir';

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // HEADER
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF0D1B2A), Color(0xFF1C3D56)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      // Avatar à gauche
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFC9952E).withOpacity(0.2),
                        child: Text(prenom[0].toUpperCase(),
                            style: const TextStyle(color: Color(0xFFC9952E),
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$salut, $prenom 👋',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(_dateAujourdhui(),
                              style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      )),
                      // Cloche notifications
                      Stack(children: [
                        IconButton(
                          onPressed: () => Navigator.pushNamed(context, '/notifications'),
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                        ),
                        if (_enAttente > 0)
                          Positioned(right: 8, top: 8,
                              child: Container(
                                width: 16, height: 16,
                                decoration: const BoxDecoration(color: Color(0xFFC9952E), shape: BoxShape.circle),
                                child: Center(child: Text('$_enAttente',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                              )),
                      ]),
                    ]),
                    const SizedBox(height: 20),
                    // Total
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Total à collecter', style: TextStyle(color: Colors.white60, fontSize: 12)),
                            const Text('Cumul de toutes vos commandes', style: TextStyle(color: Colors.white38, fontSize: 10)),
                            const SizedBox(height: 6),
                            Text('${_montantTotal.toStringAsFixed(0)} XAF',
                                style: const TextStyle(color: Color(0xFFC9952E), fontSize: 28, fontWeight: FontWeight.w900)),
                          ]),
                          const Icon(Icons.account_balance_wallet_outlined, color: Colors.white24, size: 36),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // KPIs
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  _kpi('Total',      '$_total',    Icons.inbox_outlined,          const Color(0xFF0D1B2A), isDark),
                  _kpi('En attente', '$_enAttente',Icons.hourglass_empty,         const Color(0xFFC9952E), isDark),
                  _kpi('En cours',   '$_enCours',  Icons.delivery_dining,         const Color(0xFF20619E), isDark),
                  _kpi('Livrées',    '$_livrees',  Icons.check_circle_outline,    const Color(0xFF1B5E20), isDark),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2,
                ),
              ),
            ),

            // Dernières commandes
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dernières commandes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: txtColor)),
                    const SizedBox(height: 12),
                    ..._dernieres.map((l) => _commandeTile(l, isDark, txtColor)).toList(),
                    if (_dernieres.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(30),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C3D56) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(children: [
                          Icon(Icons.inbox_outlined, size: 40, color: isDark ? Colors.white38 : Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Aucune commande.', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
                        ]),
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

  Widget _kpi(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C3D56) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey)),
        ]),
      ]),
    );
  }

  Widget _commandeTile(Map l, bool isDark, Color txtColor) {
    const statusColors = <String, Color>{
      'En_attente': Color(0xFFC9952E), 'Assign_': Color(0xFF3E5682),
      'En_cours': Color(0xFF20619E), 'Livr_': Color(0xFF1B5E20),
      'Suspendu': Color(0xFFBA1A1A), 'Annul_': Color(0xFF817564),
    };
    const statusLabels = <String, String>{
      'En_attente': 'En attente', 'Assign_': 'Assigné',
      'En_cours': 'En cours', 'Livr_': 'Livré',
      'Suspendu': 'Suspendu', 'Annul_': 'Annulé',
    };
    final status = l['status'] as String? ?? '';
    final color  = statusColors[status] ?? Colors.grey;
    final label  = statusLabels[status] ?? status;
    final client = l['client_nom'] as String? ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C3D56) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        CircleAvatar(radius: 16, backgroundColor: color.withOpacity(0.15),
            child: Text(client.isNotEmpty ? client[0] : '?',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('#${l['id'].toString().padLeft(5,'0')} — $client',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: txtColor)),
          Text(l['delivery_address'] ?? '', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey),
              overflow: TextOverflow.ellipsis),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text('${l['amount_to_collect'] ?? 0} XAF',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: txtColor)),
        ]),
      ]),
    );
  }

  String _dateAujourdhui() {
    const mois = ['','jan.','fév.','mar.','avr.','mai','juin','juil.','août','sep.','oct.','nov.','déc.'];
    final d = DateTime.now();
    return '${d.day} ${mois[d.month]} ${d.year}';
  }
}