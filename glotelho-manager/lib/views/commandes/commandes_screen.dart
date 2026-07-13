import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/kpi_card.dart';
import 'nouvelle_commande_screen.dart';
import 'commande_detail_screen.dart';

class CommandesScreen extends StatefulWidget {
  const CommandesScreen({super.key});
  @override
  State<CommandesScreen> createState() => _CommandesScreenState();
}

class _CommandesScreenState extends State<CommandesScreen> {
  bool   _loading  = true;
  List   livraisons = [];
  String _search   = '';
  String _filterStatus = '';

  static const _statusConfig = <String, (Color, Color, String)>{
    'En_attente': (Color(0xFFFFDEA9), Color(0xFF483100), 'En attente'),
    'Assign_'   : (Color(0xFFB5CCFF), Color(0xFF3E5682), 'Assigné'),
    'En_cours'  : (Color(0xFF6AA1E3), Color(0xFF003762), 'En cours'),
    'Livr_'     : (Color(0xFFC8E6C9), Color(0xFF1B5E20), 'Livré'),
    'Suspendu'  : (Color(0xFFFFDAD6), Color(0xFFBA1A1A), 'Suspendu'),
    'Annul_'    : (Color(0xFFE8E8E8), Color(0xFF4F4536), 'Annulé'),
  };

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
      setState(() => livraisons = res.data ?? []);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total      = livraisons.length;
    final enAttente  = livraisons.where((l) => l['status'] == 'En_attente').length;
    final enCours    = livraisons.where((l) => l['status'] == 'En_cours').length;
    final livrees    = livraisons.where((l) => l['status'] == 'Livr_').length;

    final filtered = livraisons.where((l) {
      final client  = (l['client_nom'] ?? '') as String;
      final adresse = (l['delivery_address'] ?? '') as String;
      final matchSearch = _search.isEmpty ||
          client.toLowerCase().contains(_search.toLowerCase()) ||
          adresse.toLowerCase().contains(_search.toLowerCase()) ||
          '#${l['id'].toString().padLeft(5,'0')}'.contains(_search);
      final matchStatus = _filterStatus.isEmpty || l['status'] == _filterStatus;
      return matchSearch && matchStatus;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NouvelleLivraisonScreen()))
            .then((_) => _load()),
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle commande'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              backgroundColor: AppTheme.navy,
              foregroundColor: Colors.white,
              pinned: true,
              title: const Text('Mes commandes'),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Rechercher client, adresse, #ID...',
                      hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
            ),

            // KPIs
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  KpiCard(icon: Icons.inbox_outlined,  label: 'Total',     value: '$total',     iconColor: AppTheme.navy),
                  KpiCard(icon: Icons.hourglass_empty, label: 'En attente',value: '$enAttente', iconColor: const Color(0xFFC9952E)),
                  KpiCard(icon: Icons.delivery_dining, label: 'En cours',  value: '$enCours',   iconColor: const Color(0xFF20619E)),
                  KpiCard(icon: Icons.check_circle_outline, label: 'Livrées', value: '$livrees', iconColor: const Color(0xFF1B5E20)),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.4,
                ),
              ),
            ),

            // Filtre statut
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              sliver: SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('Tous', ''),
                      _chip('En attente', 'En_attente'),
                      _chip('Assigné', 'Assign_'),
                      _chip('En cours', 'En_cours'),
                      _chip('Livré', 'Livr_'),
                      _chip('Annulé', 'Annul_'),
                    ],
                  ),
                ),
              ),
            ),

            // Liste
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              sliver: filtered.isEmpty
                  ? SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(_search.isNotEmpty ? 'Aucun résultat pour "$_search"' : 'Aucune commande',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              )
                  : SliverList(
                delegate: SliverChildBuilderDelegate(
                      (_, i) => _livraisonCard(filtered[i]),
                  childCount: filtered.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.navy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.navy : Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade700)),
      ),
    );
  }

  Widget _livraisonCard(Map l) {
    final status    = l['status'] as String? ?? '';
    final cfg       = _statusConfig[status];
    final bgColor   = cfg?.$1 ?? const Color(0xFFE8E8E8);
    final txtColor  = cfg?.$2 ?? Colors.grey;
    final label     = cfg?.$3 ?? status;
    final client    = l['client_nom'] as String? ?? '—';
    final adresse   = l['delivery_address'] as String? ?? '—';
    final montant   = '${l['amount_to_collect'] ?? 0} FCFA';
    final id        = '#${l['id'].toString().padLeft(5, '0')}';
    final livreur   = l['delivery_persons']?['users'];
    final livreurNom= livreur != null ? '${livreur['first_name'] ?? ''} ${livreur['last_name'] ?? ''}' : null;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => CommandeDetailScreen(id: l['id'] as int)))
          .then((_) => _load()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(id, style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.navy, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
                  child: Text(label, style: TextStyle(color: txtColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(client, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(child: Text(adresse, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
            ]),
            if (livreurNom != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.delivery_dining, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(livreurNom.trim(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(montant, style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.navy, fontSize: 14)),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}