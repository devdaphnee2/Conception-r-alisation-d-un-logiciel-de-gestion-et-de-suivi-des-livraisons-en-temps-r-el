import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_state.dart';
import '../../services/api_service.dart';
import 'nouvelle_commande_screen.dart';
import 'commande_detail_screen.dart';

class CommandesScreen extends StatefulWidget {
  const CommandesScreen({super.key});
  @override
  State<CommandesScreen> createState() => _CommandesScreenState();
}

class _CommandesScreenState extends State<CommandesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List _all = [];
  String _search = '';

  static const _statusColors = <String, Color>{
    'Commande'  : Color(0xFF9E9E9E),
    'En_attente': Color(0xFFE65100),
    'Assign_'   : Color(0xFF3E5682),
    'Valide_'   : Color(0xFF2E7D32),
    'En_cours'  : Color(0xFF20619E),
    'Livr_'     : Color(0xFF1B5E20),
    'Suspendu'  : Color(0xFFBA1A1A),
    'Annul_'    : Color(0xFF817564),
  };
  static const _statusLabels = <String, String>{
    'Commande'  : 'Brouillon',
    'En_attente': 'En attente assignation',
    'Assign_'   : 'Assignée',
    'Valide_'   : 'Validée',
    'En_cours'  : 'En cours de livraison',
    'Livr_'     : 'Livré',
    'Suspendu'  : 'Suspendu',
    'Annul_'    : 'Annulé',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiService(context.read<AppState>());
      final res = await api.getMesCommandes();
      setState(() => _all = res.data ?? []);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List get _brouillons  => _all.where((l) => ['Commande', 'En_attente'].contains(l['status'])).toList();
  List get _assignees   => _all.where((l) => l['status'] == 'Assign_').toList();
  List get _enCours     => _all.where((l) => ['Valide_', 'En_cours'].contains(l['status'])).toList();
  List get _historique  => _all.where((l) => ['Livr_', 'Annul_', 'Suspendu'].contains(l['status'])).toList();

  List _filter(List list) {
    if (_search.isEmpty) return list;
    return list.where((l) =>
        (l['client_nom'] ?? '').toString().toLowerCase().contains(_search.toLowerCase()) ||
        '#${l['id'].toString().padLeft(5,'0')}'.contains(_search) ||
        (l['delivery_address'] ?? '').toString().toLowerCase().contains(_search.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NouvelleLivraisonScreen()))
            .then((_) => _load()),
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle commande'),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        title: const Text('Mes commandes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Rechercher client, #ID, adresse...',
                    hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFC9952E),
                labelColor: const Color(0xFFC9952E),
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                isScrollable: true,
                tabs: [
                  Tab(text: 'Brouillons (${_brouillons.length})'),
                  Tab(text: 'Assignées (${_assignees.length})'),
                  Tab(text: 'En cours (${_enCours.length})'),
                  const Tab(text: 'Historique'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_filter(_brouillons), showCourseBtn: true),
                _buildList(_filter(_assignees)),            // Assignées — sans bouton suivre
                _buildList(_filter(_enCours), showSuivreBtn: true), // En cours — avec bouton suivre
                _buildList(_filter(_historique)),
              ],
            ),
    );
  }

  Widget _buildList(List items, {bool showCourseBtn = false, bool showSuivreBtn = false}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(_search.isNotEmpty ? 'Aucun résultat' : 'Aucune commande',
                style: const TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        itemCount: items.length,
        itemBuilder: (_, i) => _commandeCard(items[i],
            showCourseBtn: showCourseBtn, showSuivreBtn: showSuivreBtn),
      ),
    );
  }

  Widget _commandeCard(Map l, {bool showCourseBtn = false, bool showSuivreBtn = false}) {
    final status    = l['status'] as String? ?? '';
    final color     = _statusColors[status] ?? Colors.grey;
    final label     = _statusLabels[status] ?? status;
    final client    = l['client_nom'] as String? ?? '—';
    final adresse   = l['delivery_address'] as String? ?? '—';
    final montant   = '${l['amount_to_collect'] ?? 0} FCFA';
    final id        = '#${l['id'].toString().padLeft(5, '0')}';
    final articles  = (l['delivery_items'] as List?) ?? [];
    final livreurInfo = l['delivery_persons'];
    final livreurNom  = livreurInfo?['users'] != null
        ? '${livreurInfo['users']['first_name'] ?? ''} ${livreurInfo['users']['last_name'] ?? ''}'.trim()
        : null;
    final paymentStatus = l['payment_status'] as String? ?? 'unpaid';
    final estPaye = paymentStatus == 'paid';

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => CommandeDetailScreen(id: l['id'] as int)))
          .then((_) => _load()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                border: Border(bottom: BorderSide(color: color.withOpacity(0.15))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Text(id, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 15)),
                    const SizedBox(width: 8),
                    // ── Badge statut de paiement ────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: estPaye ? const Color(0xFFC8E6C9) : const Color(0xFFFFDAD6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(estPaye ? Icons.check_circle : Icons.hourglass_empty,
                            size: 11, color: estPaye ? const Color(0xFF1B5E20) : const Color(0xFFBA1A1A)),
                        const SizedBox(width: 3),
                        Text(estPaye ? 'Payé' : 'Non payé',
                            style: TextStyle(
                                fontSize: 9, fontWeight: FontWeight.bold,
                                color: estPaye ? const Color(0xFF1B5E20) : const Color(0xFFBA1A1A))),
                      ]),
                    ),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            // Contenu
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(Icons.person_outline, client),
                  const SizedBox(height: 6),
                  _infoRow(Icons.location_on_outlined, adresse),
                  if (articles.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _infoRow(Icons.shopping_bag_outlined,
                        articles.map((a) => '${a['product_name']} x${a['quantity'] ?? 1}').join(' · ')),
                  ],
                  if (livreurNom != null && livreurNom.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _infoRow(Icons.delivery_dining, 'Livreur : $livreurNom'),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(montant, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0D1B2A))),
                      Row(
                        children: [
                          if (showCourseBtn && status == 'Commande')
                            ElevatedButton.icon(
                              onPressed: () => _commanderCourse(l['id'] as int),
                              icon: const Icon(Icons.send, size: 14),
                              label: const Text('Commander', style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D1B2A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          if (showCourseBtn && ['Commande', 'En_attente'].contains(status))
                            IconButton(
                              onPressed: () => _supprimerCommande(l['id'] as int),
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A), size: 20),
                              tooltip: 'Annuler',
                            ),
                          // Bouton Suivre uniquement sur En cours
                          if (showSuivreBtn && status == 'En_cours')
                            ElevatedButton.icon(
                              onPressed: () => _ouvrirSuivi(l['id'] as int),
                              icon: const Icon(Icons.location_on, size: 14),
                              label: const Text('Suivre', style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF20619E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _commanderCourse(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Commander une course ?'),
        content: const Text('Un lien de paiement sera envoyé au client par WhatsApp. La course sera transmise à l\'administration une fois le paiement confirmé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1B2A), foregroundColor: Colors.white),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      final api = ApiService(context.read<AppState>());
      final res = await api.commanderCourse(id);
      if (!mounted) return;

      // Ouvrir automatiquement WhatsApp avec le lien de paiement
      final waLink = res.data['whatsapp_link'] as String?;
      if (waLink != null && waLink.isNotEmpty) {
        final uri = Uri.parse(waLink);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('💳 Lien de paiement envoyé au client par WhatsApp.'),
        backgroundColor: Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
      ));
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erreur lors de la commande.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _supprimerCommande(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Annuler la commande ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final api = ApiService(context.read<AppState>());
      await api.supprimerCommande(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Commande annulée.'),
        backgroundColor: Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
      ));
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erreur lors de l\'annulation.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _ouvrirSuivi(int id) async {
    final url = Uri.parse('http://192.168.1.145:5173/suivi/$id');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(child: Text(text,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}