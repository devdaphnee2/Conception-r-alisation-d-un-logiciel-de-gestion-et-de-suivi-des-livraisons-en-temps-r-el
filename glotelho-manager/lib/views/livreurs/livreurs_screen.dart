/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/kpi_card.dart';

/// Écran Livreurs — reprend LivreurList.jsx (onglet Actifs) et
/// ProfilsEnAttente.jsx (onglet Profils en attente) du web, avec
/// approbation/rejet de profil.
class LivreursScreen extends StatefulWidget {
  const LivreursScreen({super.key});

  @override
  State<LivreursScreen> createState() => _LivreursScreenState();
}

class _LivreursScreenState extends State<LivreursScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ApiService _api;

  bool _loadingLivreurs = true;
  bool _loadingProfils = true;
  bool _actionLoading = false;
  List livreurs = [];
  List profils = [];
  String _search = '';
  String _filterStatus = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _api = ApiService(context.read<AppState>());
    _loadLivreurs();
    _loadProfils();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLivreurs() async {
    setState(() => _loadingLivreurs = true);
    try {
      final res = await _api.getLivreurs(all: true);
      setState(() => livreurs = res.data ?? []);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingLivreurs = false);
    }
  }

  Future<void> _loadProfils() async {
    setState(() => _loadingProfils = true);
    try {
      final res = await _api.getProfilsEnAttente();
      setState(() => profils = res.data ?? []);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingProfils = false);
    }
  }

  Future<void> _approuver(Map l) async {
    final nom = '${l['users']?['first_name'] ?? ''} ${l['users']?['last_name'] ?? ''}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approuver ?'),
        content: Text('Approuver le profil de $nom ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Approuver')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _actionLoading = true);
    try {
      await _api.approuverProfil(l['id']);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Profil de $nom approuvé.')));
      }
      _loadProfils();
      _loadLivreurs();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Erreur lors de l\'approbation.')));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _rejeter(Map l) async {
    final nom = '${l['users']?['first_name'] ?? ''} ${l['users']?['last_name'] ?? ''}';
    final motifController = TextEditingController();
    final motif = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Motif du rejet pour $nom'),
        content: TextField(
          controller: motifController,
          decoration: const InputDecoration(hintText: 'Ex: dossier incomplet'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, motifController.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A)),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
    if (motif == null || motif.isEmpty) return;

    setState(() => _actionLoading = true);
    try {
      await _api.rejeterProfil(l['id'], motif);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Profil de $nom rejeté.')));
      }
      _loadProfils();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Erreur lors du rejet.')));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Livreurs'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onSurface,
          unselectedLabelColor:
          Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          indicatorColor: Theme.of(context).colorScheme.onSurface,
          tabs: [
            const Tab(text: 'Actifs'),
            Tab(text: 'En attente (${profils.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActifsTab(),
          _buildProfilsTab(),
        ],
      ),
    );
  }

  // ---------- Onglet Actifs (LivreurList.jsx) ----------

  Widget _buildActifsTab() {
    final total = livreurs.length;
    final dispo = livreurs.where((l) => l['status'] == 'Disponible').length;
    final enLivraison = livreurs.where((l) => l['status'] == 'En_livraison').length;
    final suspendus = livreurs.where((l) => l['status'] == 'Suspendu').length;

    final filtered = livreurs.where((l) {
      final matchStatus = _filterStatus.isEmpty || l['status'] == _filterStatus;
      final s = _search.toLowerCase();
      final matchSearch = s.isEmpty ||
          [
            l['users']?['first_name'],
            l['users']?['last_name'],
            l['users']?['phone'],
            l['zone_affectee'],
          ].any((v) => (v ?? '').toString().toLowerCase().contains(s));
      return matchStatus && matchSearch;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadLivreurs,
      child: ListView(
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
                icon: Icons.badge_outlined,
                label: 'Total livreurs',
                value: '$total',
                iconColor: AppTheme.navyLight,
              ),
              KpiCard(
                icon: Icons.check_circle_outline,
                label: 'Disponibles',
                value: '$dispo',
                iconColor: const Color(0xFF81C784),
              ),
              KpiCard(
                icon: Icons.local_shipping_outlined,
                label: 'En livraison',
                value: '$enLivraison',
                iconColor: const Color(0xFF6AA1E3),
              ),
              KpiCard(
                icon: Icons.report_gmailerrorred_outlined,
                label: 'Suspendus',
                value: '$suspendus',
                iconColor: const Color(0xFFEF9A9A),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            style: TextStyle(color: AppTheme.inputText(context)),
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, téléphone, zone...',
              hintStyle: TextStyle(color: AppTheme.inputHint(context)),
              prefixIcon: Icon(Icons.search, size: 18, color: AppTheme.inputHint(context)),
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
                _filterChip('Disponible', 'Disponible'),
                _filterChip('En livraison', 'En_livraison'),
                _filterChip('Suspendu', 'Suspendu'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_loadingLivreurs)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filtered.isEmpty)
            _emptyState('Aucun livreur.')
          else
            ...filtered.map((l) => _livreurCard(l)),
        ],
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

  Widget _livreurCard(Map l) {
    final status = l['status'];
    final statusConf = {
      'Disponible': (const Color(0xFFC8E6C9), const Color(0xFF1B5E20), 'Disponible'),
      'En_livraison': (
      AppTheme.navyLight.withOpacity(0.15),
      AppTheme.navy,
      'En livraison'
      ),
      'Suspendu': (const Color(0xFFFFDAD6), const Color(0xFFBA1A1A), 'Suspendu'),
    }[status] ??
        (Colors.grey.shade200, Colors.grey.shade700, '$status');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.navy,
            child: Text((l['users']?['first_name'] ?? '?')[0],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l['users']?['first_name'] ?? ''} ${l['users']?['last_name'] ?? ''}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                Text(l['users']?['phone'] ?? '—',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text(l['zone_affectee'] ?? '—',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusConf.$1,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(statusConf.$3,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: statusConf.$2)),
          ),
        ],
      ),
    );
  }

  // ---------- Onglet Profils en attente (ProfilsEnAttente.jsx) ----------

  Widget _buildProfilsTab() {
    final total = profils.length;
    final photoOk = profils.where((l) => l['photo_profil'] != null).length;
    final cautionEnAttente = profils.where((l) => l['caution_payee'] != true).length;

    return RefreshIndicator(
      onRefresh: _loadProfils,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.95,
            children: [
              KpiCard(
                icon: Icons.badge_outlined,
                label: 'En attente',
                value: '$total',
                iconColor: AppTheme.navyLight,
              ),
              KpiCard(
                icon: Icons.photo_camera_outlined,
                label: 'Photo fournie',
                value: '$photoOk',
                iconColor: const Color(0xFF81C784),
              ),
              KpiCard(
                icon: Icons.warning_amber_rounded,
                label: 'Caution due',
                value: '$cautionEnAttente',
                iconColor: const Color(0xFFEF9A9A),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (profils.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDEA9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: Color(0xFF7D5700)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${profils.length} profil(s) en attente. La photo de profil est obligatoire — un dossier sans cette photo risque le rejet.',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          if (_loadingProfils)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (profils.isEmpty)
            _emptyState('Aucun profil en attente.')
          else
            ...profils.map((l) => _profilCard(l)),
        ],
      ),
    );
  }

  Widget _profilCard(Map l) {
    final nom = '${l['users']?['first_name'] ?? ''} ${l['users']?['last_name'] ?? ''}';
    final cautionOk = l['caution_payee'] == true;
    final manquants = <String>[];
    if (l['photo_profil'] == null) manquants.add('Photo profil');
    if (l['cni_photo_avant'] == null) manquants.add('CNI recto');
    if (l['cni_photo_arriere'] == null) manquants.add('CNI verso');
    if (l['permis_photo'] == null) manquants.add('Permis');
    final dossierOk = manquants.isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.navy,
                child: Text((l['users']?['first_name'] ?? '?')[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nom, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(l['users']?['phone'] ?? '—',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${l['caution_montant'] ?? 50000} FCFA',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cautionOk
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFFBA1A1A))),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: cautionOk
                          ? const Color(0xFFC8E6C9)
                          : const Color(0xFFFFDAD6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(cautionOk ? 'PAYÉE' : 'NON PAYÉE',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: cautionOk
                                ? const Color(0xFF1B5E20)
                                : const Color(0xFFBA1A1A))),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(dossierOk ? Icons.check_circle : Icons.cancel,
                  size: 14,
                  color: dossierOk ? const Color(0xFF1B5E20) : const Color(0xFFBA1A1A)),
              const SizedBox(width: 4),
              Text(
                dossierOk ? 'Dossier complet' : '${manquants.length} document(s) manquant(s)',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: dossierOk ? const Color(0xFF1B5E20) : const Color(0xFFBA1A1A)),
              ),
            ],
          ),
          if (!dossierOk)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 18),
              child: Text(manquants.join(' • '),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: écran détail dossier (ProfilDetail.jsx)
                  },
                  child: const Text('Voir dossier', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _actionLoading ? null : () => _approuver(l),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                  child: const Text('Approuver', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _actionLoading ? null : () => _rejeter(l),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFBA1A1A),
                    side: const BorderSide(color: Color(0xFFBA1A1A)),
                  ),
                  child: const Text('Rejeter', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String text) => Padding(
    padding: const EdgeInsets.only(top: 40),
    child: Center(
      child: Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
    ),
  );
}*/


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/kpi_card.dart';

/// Écran Livreurs — reprend LivreurList.jsx (onglet Actifs) et
/// ProfilsEnAttente.jsx (onglet Profils en attente) du web, avec
/// approbation/rejet de profil.
class LivreursScreen extends StatefulWidget {
  final int initialTabIndex;
  const LivreursScreen({super.key, this.initialTabIndex =0});

  @override
  State<LivreursScreen> createState() => _LivreursScreenState();
}

class _LivreursScreenState extends State<LivreursScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ApiService _api;

  bool _loadingLivreurs = true;
  bool _loadingProfils = true;
  bool _actionLoading = false;
  List livreurs = [];
  List profils = [];
  String _search = '';
  String _filterStatus = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _api = ApiService(context.read<AppState>());
    _loadLivreurs();
    _loadProfils();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLivreurs() async {
    setState(() => _loadingLivreurs = true);
    try {
      final res = await _api.getLivreurs(all: true);
      setState(() => livreurs = res.data ?? []);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingLivreurs = false);
    }
  }

  Future<void> _loadProfils() async {
    setState(() => _loadingProfils = true);
    try {
      final res = await _api.getProfilsEnAttente();
      setState(() => profils = res.data ?? []);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingProfils = false);
    }
  }

  Future<void> _approuver(Map l) async {
    final nom = '${l['users']?['first_name'] ?? ''} ${l['users']?['last_name'] ?? ''}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approuver ?'),
        content: Text('Approuver le profil de $nom ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Approuver')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _actionLoading = true);
    try {
      await _api.approuverProfil(l['id']);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Profil de $nom approuvé.')));
      }
      _loadProfils();
      _loadLivreurs();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Erreur lors de l\'approbation.')));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _rejeter(Map l) async {
    final nom = '${l['users']?['first_name'] ?? ''} ${l['users']?['last_name'] ?? ''}';
    final motifController = TextEditingController();
    final motif = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Motif du rejet pour $nom'),
        content: TextField(
          controller: motifController,
          decoration: const InputDecoration(hintText: 'Ex: dossier incomplet'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, motifController.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A)),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
    if (motif == null || motif.isEmpty) return;

    setState(() => _actionLoading = true);
    try {
      await _api.rejeterProfil(l['id'], motif);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Profil de $nom rejeté.')));
      }
      _loadProfils();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Erreur lors du rejet.')));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Livreurs'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onSurface,
          unselectedLabelColor:
          Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          indicatorColor: Theme.of(context).colorScheme.onSurface,
          tabs: [
            const Tab(text: 'Actifs'),
            Tab(text: 'En attente (${profils.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActifsTab(),
          _buildProfilsTab(),
        ],
      ),
    );
  }

  // ---------- Onglet Actifs (LivreurList.jsx) ----------

  Widget _buildActifsTab() {
    final total = livreurs.length;
    final dispo = livreurs.where((l) => l['status'] == 'Disponible').length;
    final enLivraison = livreurs.where((l) => l['status'] == 'En_livraison').length;
    final suspendus = livreurs.where((l) => l['status'] == 'Suspendu').length;

    final filtered = livreurs.where((l) {
      final matchStatus = _filterStatus.isEmpty || l['status'] == _filterStatus;
      final s = _search.toLowerCase();
      final matchSearch = s.isEmpty ||
          [
            l['users']?['first_name'],
            l['users']?['last_name'],
            l['users']?['phone'],
            l['zone_affectee'],
          ].any((v) => (v ?? '').toString().toLowerCase().contains(s));
      return matchStatus && matchSearch;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadLivreurs,
      child: ListView(
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
                icon: Icons.badge_outlined,
                label: 'Total livreurs',
                value: '$total',
                iconColor: Colors.white,
              ),
              KpiCard(
                icon: Icons.check_circle_outline,
                label: 'Disponibles',
                value: '$dispo',
                iconColor: const Color(0xFF81C784),
              ),
              KpiCard(
                icon: Icons.local_shipping_outlined,
                label: 'En livraison',
                value: '$enLivraison',
                iconColor: const Color(0xFF6AA1E3),
              ),
              KpiCard(
                icon: Icons.report_gmailerrorred_outlined,
                label: 'Suspendus',
                value: '$suspendus',
                iconColor: const Color(0xFFEF9A9A),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            style: TextStyle(color: AppTheme.inputText(context)),
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, téléphone, zone...',
              hintStyle: TextStyle(color: AppTheme.inputHint(context)),
              prefixIcon: Icon(Icons.search, size: 18, color: AppTheme.inputHint(context)),
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
                _filterChip('Disponible', 'Disponible'),
                _filterChip('En livraison', 'En_livraison'),
                _filterChip('Suspendu', 'Suspendu'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_loadingLivreurs)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filtered.isEmpty)
            _emptyState('Aucun livreur.')
          else
            ...filtered.map((l) => _livreurCard(l)),
        ],
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

  Widget _livreurCard(Map l) {
    final status = l['status'];
    final statusConf = {
      'Disponible': (const Color(0xFFC8E6C9), const Color(0xFF1B5E20), 'Disponible'),
      'En_livraison': (
      AppTheme.navyLight.withOpacity(0.15),
      AppTheme.navy,
      'En livraison'
      ),
      'Suspendu': (const Color(0xFFFFDAD6), const Color(0xFFBA1A1A), 'Suspendu'),
    }[status] ??
        (Colors.grey.shade200, Colors.grey.shade700, '$status');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.navy,
            child: Text((l['users']?['first_name'] ?? '?')[0],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l['users']?['first_name'] ?? ''} ${l['users']?['last_name'] ?? ''}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                Text(l['users']?['phone'] ?? '—',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text(l['zone_affectee'] ?? '—',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusConf.$1,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(statusConf.$3,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: statusConf.$2)),
          ),
        ],
      ),
    );
  }

  // ---------- Onglet Profils en attente (ProfilsEnAttente.jsx) ----------

  Widget _buildProfilsTab() {
    final total = profils.length;
    final photoOk = profils.where((l) => l['photo_profil'] != null).length;
    final cautionEnAttente = profils.where((l) => l['caution_payee'] != true).length;

    return RefreshIndicator(
      onRefresh: _loadProfils,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.95,
            children: [
              KpiCard(
                icon: Icons.badge_outlined,
                label: 'En attente',
                value: '$total',
                iconColor: Colors.white,
              ),
              KpiCard(
                icon: Icons.photo_camera_outlined,
                label: 'Photo fournie',
                value: '$photoOk',
                iconColor: const Color(0xFF81C784),
              ),
              KpiCard(
                icon: Icons.warning_amber_rounded,
                label: 'Caution due',
                value: '$cautionEnAttente',
                iconColor: const Color(0xFFEF9A9A),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (profils.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDEA9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: Color(0xFF7D5700)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${profils.length} profil(s) en attente. La photo de profil est obligatoire — un dossier sans cette photo risque le rejet.',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          if (_loadingProfils)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (profils.isEmpty)
            _emptyState('Aucun profil en attente.')
          else
            ...profils.map((l) => _profilCard(l)),
        ],
      ),
    );
  }

  Widget _profilCard(Map l) {
    final nom = '${l['users']?['first_name'] ?? ''} ${l['users']?['last_name'] ?? ''}';
    final cautionOk = l['caution_payee'] == true;
    final manquants = <String>[];
    if (l['photo_profil'] == null) manquants.add('Photo profil');
    if (l['cni_photo_avant'] == null) manquants.add('CNI recto');
    if (l['cni_photo_arriere'] == null) manquants.add('CNI verso');
    if (l['permis_photo'] == null) manquants.add('Permis');
    final dossierOk = manquants.isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.navy,
                child: Text((l['users']?['first_name'] ?? '?')[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nom, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(l['users']?['phone'] ?? '—',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${l['caution_montant'] ?? 50000} FCFA',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cautionOk
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFFBA1A1A))),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: cautionOk
                          ? const Color(0xFFC8E6C9)
                          : const Color(0xFFFFDAD6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(cautionOk ? 'PAYÉE' : 'NON PAYÉE',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: cautionOk
                                ? const Color(0xFF1B5E20)
                                : const Color(0xFFBA1A1A))),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(dossierOk ? Icons.check_circle : Icons.cancel,
                  size: 14,
                  color: dossierOk ? const Color(0xFF1B5E20) : const Color(0xFFBA1A1A)),
              const SizedBox(width: 4),
              Text(
                dossierOk ? 'Dossier complet' : '${manquants.length} document(s) manquant(s)',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: dossierOk ? const Color(0xFF1B5E20) : const Color(0xFFBA1A1A)),
              ),
            ],
          ),
          if (!dossierOk)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 18),
              child: Text(manquants.join(' • '),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: écran détail dossier (ProfilDetail.jsx)
                  },
                  child: const Text('Voir dossier', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _actionLoading ? null : () => _approuver(l),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                  child: const Text('Approuver', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _actionLoading ? null : () => _rejeter(l),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFBA1A1A),
                    side: const BorderSide(color: Color(0xFFBA1A1A)),
                  ),
                  child: const Text('Rejeter', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String text) => Padding(
    padding: const EdgeInsets.only(top: 40),
    child: Center(
      child: Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
    ),
  );
}