import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_state.dart';
import '../../services/api_service.dart';
import '../commandes/commande_detail_screen.dart';

class LivraisonsScreen extends StatefulWidget {
  const LivraisonsScreen({super.key});
  @override
  State<LivraisonsScreen> createState() => _LivraisonsScreenState();
}

class _LivraisonsScreenState extends State<LivraisonsScreen> {
  bool _loading = true;
  List _toutes = [];
  int _tab = 0; // 0 = Assignées, 1 = En cours

  static const _navy    = Color(0xFF0D1B2A);
  static const _gold    = Color(0xFFC9952E);
  static const _blue    = Color(0xFF20619E);
  static const _blueBg  = Color(0xFFE3F2FD);
  static const _green   = Color(0xFF2E7D32);
  static const _greenBg = Color(0xFFE8F5E9);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiService(context.read<AppState>());
      final res = await api.getMesCommandes();
      final List all = res.data ?? [];
      setState(() {
        _toutes = all.where((l) {
          final s = l['status'] as String? ?? '';
          return ['Assign_', 'En_cours', 'Valide_'].contains(s);
        }).toList();
      });
    } catch (_) {}
    finally { if (mounted) setState(() => _loading = false); }
  }

  List get _filtered {
    if (_tab == 0) {
      return _toutes.where((l) => l['status'] == 'Assign_').toList();
    } else {
      return _toutes.where((l) => ['En_cours', 'Valide_'].contains(l['status'])).toList();
    }
  }

  Future<void> _ouvrirSuivi(int id) async {
    final url = Uri.parse('http://192.168.1.145:5173/suivi/$id');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nbAssignees = _toutes.where((l) => l['status'] == 'Assign_').length;
    final nbEnCours   = _toutes.where((l) => ['En_cours','Valide_'].contains(l['status'])).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Livraisons'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // Onglets
          Container(
            color: _navy,
            child: Row(
              children: [
                _tabBtn('Assignées', 0, nbAssignees),
                _tabBtn('En cours', 1, nbEnCours),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delivery_dining, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  _tab == 0 ? 'Aucune livraison assignée' : 'Aucune livraison en cours',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(14),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _tab == 0
                                ? _cardAssignee(_filtered[i])
                                : _cardEnCours(_filtered[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, int i, int count) {
    final active = _tab == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(
              color: active ? _gold : Colors.transparent, width: 2.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(
                color: active ? _gold : Colors.white54,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              )),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: active ? _gold : Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text('$count',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Carte onglet Assignées — sans bouton Suivre
  Widget _cardAssignee(Map l) {
    final id      = '#${l['id'].toString().padLeft(5, '0')}';
    final client  = l['client_nom'] as String? ?? '—';
    final adresse = l['delivery_address'] as String? ?? '—';
    final montant = '${(double.tryParse(l['amount_to_collect']?.toString() ?? '0') ?? 0).toStringAsFixed(0)} FCFA';
    final livreurInfo = l['delivery_persons'];
    final livreurNom  = livreurInfo != null && livreurInfo['users'] != null
        ? '${livreurInfo['users']['first_name'] ?? ''} ${livreurInfo['users']['last_name'] ?? ''}'.trim()
        : 'Livreur assigné';

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => CommandeDetailScreen(id: l['id'] as int)))
          .then((_) => _load()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _blue.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: _blueBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Color(0xFFBBDEFB))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(id, style: const TextStyle(fontWeight: FontWeight.w900, color: _blue, fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _blue.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Assignée', style: TextStyle(color: _blue, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(Icons.person_outline, client),
                  const SizedBox(height: 6),
                  _infoRow(Icons.location_on_outlined, adresse),
                  const SizedBox(height: 6),
                  _infoRow(Icons.delivery_dining, livreurNom),
                  const SizedBox(height: 10),
                  Text(montant, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _navy)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Carte onglet En cours — avec bouton Suivre
  Widget _cardEnCours(Map l) {
    final id      = '#${l['id'].toString().padLeft(5, '0')}';
    final client  = l['client_nom'] as String? ?? '—';
    final adresse = l['delivery_address'] as String? ?? '—';
    final montant = '${(double.tryParse(l['amount_to_collect']?.toString() ?? '0') ?? 0).toStringAsFixed(0)} FCFA';
    final livreurInfo = l['delivery_persons'];
    final livreurNom  = livreurInfo != null && livreurInfo['users'] != null
        ? '${livreurInfo['users']['first_name'] ?? ''} ${livreurInfo['users']['last_name'] ?? ''}'.trim()
        : 'Livreur';
    final vehicule    = livreurInfo?['vehicules'];
    final vehiculeInfo = vehicule != null
        ? '${vehicule['type'] ?? ''} — ${vehicule['plate_number'] ?? ''}'
        : '';

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => CommandeDetailScreen(id: l['id'] as int)))
          .then((_) => _load()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _green.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: _greenBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Color(0xFFA5D6A7))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(id, style: const TextStyle(fontWeight: FontWeight.w900, color: _green, fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _green.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      const Text('En cours', style: TextStyle(color: _green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(Icons.person_outline, client),
                  const SizedBox(height: 6),
                  _infoRow(Icons.location_on_outlined, adresse),
                  const SizedBox(height: 6),
                  _infoRow(Icons.delivery_dining, livreurNom),
                  if (vehiculeInfo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _infoRow(Icons.two_wheeler, vehiculeInfo),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(montant, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _navy)),
                      ElevatedButton.icon(
                        onPressed: () => _ouvrirSuivi(l['id'] as int),
                        icon: const Icon(Icons.location_on, size: 16),
                        label: const Text('Suivre en direct'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        ),
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

  Widget _infoRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 14, color: Colors.grey),
      const SizedBox(width: 6),
      Expanded(child: Text(text,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          overflow: TextOverflow.ellipsis)),
    ]);
  }
}