import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_state.dart';
import '../../services/api_service.dart';
import 'nouvelle_commande_screen.dart';
import 'commande_detail_screen.dart';
import '../../config/app_config.dart';

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

  // Couleurs du thème Navy & Gold
  static const Color navyBackground = Color(0xFF0D1B2A);
  static const Color cardNavy = Color(0xFF1B2A4A);
  static const Color goldAccent = Color(0xFFC9952E);

  static const _statusColors = <String, Color>{
    'Commande'  : Color(0xFF9E9E9E),
    'En_attente': Color(0xFFFF9800),
    'Assign_'   : Color(0xFF64B5F6),
    'Valide_'   : Color(0xFF81C784),
    'En_cours'  : Color(0xFF4FC3F7),
    'Livr_'     : Color(0xFF66BB6A),
    'Suspendu'  : Color(0xFFE57373),
    'Annul_'    : Color(0xFFB0BEC5),
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
      backgroundColor: navyBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NouvelleCommandeScreen()))
            .then((_) => _load()),
        backgroundColor: goldAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add, fontWeight: FontWeight.bold),
        label: const Text('Nouvelle commande', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      appBar: AppBar(
        backgroundColor: navyBackground,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Mes commandes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Rechercher client, #ID, adresse...',
                    hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                    filled: true,
                    fillColor: cardNavy,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: goldAccent),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: goldAccent,
                labelColor: goldAccent,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
          ? const Center(child: CircularProgressIndicator(color: goldAccent))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildList(_filter(_brouillons), showCourseBtn: true),
          _buildList(_filter(_assignees)),
          _buildList(_filter(_enCours), showSuivreBtn: true),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardNavy.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_outlined, size: 48, color: Colors.white38),
            ),
            const SizedBox(height: 14),
            Text(
              _search.isNotEmpty ? 'Aucun résultat' : 'Aucune commande',
              style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: goldAccent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: items.length,
        itemBuilder: (_, i) => _commandeCard(
          items[i],
          showCourseBtn: showCourseBtn,
          showSuivreBtn: showSuivreBtn,
        ),
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
          color: cardNavy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: const Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Text(id, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 15)),
                    const SizedBox(width: 8),
                    // Badge statut de paiement
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: estPaye ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: estPaye ? Colors.green : Colors.redAccent),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(estPaye ? Icons.check_circle : Icons.hourglass_empty,
                            size: 11, color: estPaye ? Colors.greenAccent : Colors.redAccent),
                        const SizedBox(width: 3),
                        Text(
                          estPaye ? 'Payé' : 'Non payé',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: estPaye ? Colors.greenAccent : Colors.redAccent,
                          ),
                        ),
                      ]),
                    ),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
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
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        montant,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      Row(
                        children: [
                          if (showCourseBtn && status == 'Commande')
                            ElevatedButton.icon(
                              onPressed: () => _commanderCourse(l['id'] as int),
                              icon: const Icon(Icons.send, size: 14),
                              label: const Text('Commander', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: goldAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          if (showCourseBtn && ['Commande', 'En_attente'].contains(status))
                            IconButton(
                              onPressed: () => _supprimerCommande(l['id'] as int),
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              tooltip: 'Annuler',
                            ),
                          if (showSuivreBtn && status == 'En_cours')
                            ElevatedButton.icon(
                              onPressed: () => _ouvrirSuivi(l['id'] as int),
                              icon: const Icon(Icons.location_on, size: 14),
                              label: const Text('Suivre', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
        backgroundColor: cardNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Commander une course ?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Un lien de paiement sera envoyé au client par WhatsApp. La course sera transmise à l\'administration une fois le paiement confirmé.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: goldAccent, foregroundColor: Colors.black),
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

      final waLink = res.data['whatsapp_link'] as String?;
      if (waLink != null && waLink.isNotEmpty) {
        final uri = Uri.parse(waLink);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('💳 Lien de paiement envoyé au client par WhatsApp.'),
        backgroundColor: Colors.green,
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
        backgroundColor: cardNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Annuler la commande ?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Cette action est irréversible.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
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
        backgroundColor: Colors.green,
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
    final url = Uri.parse('${AppConfig.trackingUrl}/$id');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}