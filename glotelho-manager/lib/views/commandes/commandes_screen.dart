import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/kpi_card.dart';
import 'nouvelle_commande_screen.dart';
import 'commande_detail_screen.dart';

/// Écran Commandes — liste des commandes de l'e-commerçant : KPI,
/// recherche, filtre par statut, liste avec statut coloré.
class CommandesScreen extends StatefulWidget {
  const CommandesScreen({super.key});

  @override
  State<CommandesScreen> createState() => _CommandesScreenState();
}

class _CommandesScreenState extends State<CommandesScreen> {
  bool _loading = true;
  List livraisons = [];
  String _search = '';
  String _filterStatus = '';
  final ScrollController _scrollController = ScrollController();
  bool _showFabLabel = true;
  double _lastOffset = 0;

  static const _statusConfig = {
    'En_attente': (Color(0xFFFFDEA9), Color(0xFF483100), 'Course en attente'),
    'Assigné': (Color(0xFFB5CCFF), Color(0xFF3E5682), 'Assigné'),
    'En_cours': (Color(0xFF6AA1E3), Color(0xFF003762), 'En cours'),
    'Livré': (Color(0xFFC8E6C9), Color(0xFF1B5E20), 'Livré'),
    'Suspendu': (Color(0xFFFFDAD6), Color(0xFFBA1A1A), 'Suspendu'),
    'Annulé': (Color(0xFFE8E8E8), Color(0xFF4F4536), 'Annulé'),
  };

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      if (offset <= 8) {
        if (!_showFabLabel) setState(() => _showFabLabel = true);
      } else if (offset > _lastOffset && _showFabLabel) {
        setState(() => _showFabLabel = false);
      } else if (offset < _lastOffset && !_showFabLabel) {
        setState(() => _showFabLabel = true);
      }
      _lastOffset = offset;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    final total = livraisons.length;
    final enAttente = livraisons.where((l) => l['status'] == 'En_attente').length;
    final enCours = livraisons.where((l) => l['status'] == 'En_cours').length;
    final livrees = livraisons.where((l) => l['status'] == 'Livré').length;
    final suspendues = livraisons.where((l) => l['status'] == 'Suspendu').length;

    final filtered = livraisons.where((l) {
      final matchStatus = _filterStatus.isEmpty || l['status'] == _filterStatus;
      final s = _search.toLowerCase();
      final matchSearch = s.isEmpty ||
          [
            l['customers']?['users']?['first_name'],
            l['customers']?['users']?['last_name'],
            l['delivery_persons']?['users']?['first_name'],
            l['delivery_address'],
            '#${l['id']}',
          ].any((v) => (v ?? '').toString().toLowerCase().contains(s));
      return matchStatus && matchSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Commandes')),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _showFabLabel ? 1 : 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: _showFabLabel
                  ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                  : EdgeInsets.zero,
              width: _showFabLabel ? null : 0,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _showFabLabel
                  ? Text('Nouvelle commande',
                  style: TextStyle(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600))
                  : null,
            ),
          ),
          FloatingActionButton(
            backgroundColor: AppTheme.gold,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NouvelleCommandeScreen())),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
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
                  label: 'Total',
                  value: '$total',
                  iconColor: Colors.white,
                ),
                KpiCard(
                  icon: Icons.hourglass_empty,
                  label: 'En attente',
                  value: '$enAttente',
                  iconColor: Colors.white,
                ),
                KpiCard(
                  icon: Icons.local_shipping_outlined,
                  label: 'En cours',
                  value: '$enCours',
                  iconColor: const Color(0xFF6AA1E3),
                ),
                KpiCard(
                  icon: Icons.check_circle_outline,
                  label: 'Livrées',
                  value: '$livrees',
                  iconColor: const Color(0xFF81C784),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: KpiCard(
                icon: Icons.pause_circle_outline,
                label: 'Suspendues',
                value: '$suspendues',
                iconColor: const Color(0xFFEF9A9A),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              style: TextStyle(color: AppTheme.inputText(context)),
              decoration: InputDecoration(
                hintText: 'Rechercher par client, livreur, adresse...',
                hintStyle: TextStyle(color: AppTheme.inputHint(context)),
                prefixIcon:
                Icon(Icons.search, size: 18, color: AppTheme.inputHint(context)),
                filled: true,
                fillColor: AppTheme.inputFill(context),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Tous', ''),
                  ..._statusConfig.entries
                      .map((e) => _filterChip(e.value.$3, e.key)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text('Aucune livraison trouvée.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ),
              )
            else ...[
                Text('${filtered.length} livraison${filtered.length > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                ...filtered.map((l) => _livraisonCard(l)),
              ],
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filterStatus == value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => setState(() => _filterStatus = value),
        backgroundColor: AppTheme.inputFill(context),
        selectedColor: onSurface,
        labelStyle: TextStyle(
            color: selected
                ? Theme.of(context).scaffoldBackgroundColor
                : onSurface),
        side: BorderSide(color: onSurface.withOpacity(0.2)),
      ),
    );
  }

  Widget _livraisonCard(Map l) {
    final conf = _statusConfig[l['status']] ??
        (Colors.grey.shade200, Colors.grey.shade700, '${l['status']}');
    final client =
        '${l['customers']?['users']?['first_name'] ?? ''} ${l['customers']?['users']?['last_name'] ?? ''}';
    final livreur = l['delivery_persons']?['users']?['first_name'];
    final montant = l['amount_to_collect'];
    final date = l['creation_date'];

    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => CommandeDetailScreen(livraisonId: l['id']))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('#${l['id'].toString().padLeft(5, '0')}',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.navy)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: conf.$1,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(conf.$3,
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: conf.$2)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: AppTheme.navy,
                  child: Text(client.isNotEmpty ? client[0] : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(client,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      Text(l['delivery_address'] ?? '—',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  livreur != null ? 'Livreur: $livreur' : 'Non assigné',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: livreur == null ? FontStyle.italic : FontStyle.normal,
                    color: livreur == null
                        ? Colors.grey.shade500
                        : Colors.grey.shade700,
                  ),
                ),
                Text(
                  montant != null ? '$montant F' : '—',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.navy),
                ),
              ],
            ),
            if (date != null) ...[
              const SizedBox(height: 4),
              Text('${date}'.split('T').first,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ],
        ),
      ),
    );
  }
}