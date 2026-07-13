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
  List _livraisons = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiService(context.read<AppState>());
      final res = await api.getLivraisonsEnCours();
      setState(() => _livraisons = res.data ?? []);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        title: const Text('Livraisons en cours'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: _livraisons.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delivery_dining, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('Aucune livraison en cours',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              const Text('Les livraisons actives apparaîtront ici.',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: _livraisons.length,
          itemBuilder: (_, i) => _livraisonCard(_livraisons[i]),
        ),
      ),
    );
  }

  Widget _livraisonCard(Map l) {
    final id         = '#${l['id'].toString().padLeft(5, '0')}';
    final client     = l['client_nom'] as String? ?? '—';
    final adresse    = l['delivery_address'] as String? ?? '—';
    final montant    = '${l['amount_to_collect'] ?? 0} FCFA';
    final livreurInfo = l['delivery_persons'];
    final livreurNom = livreurInfo?['users'] != null
        ? '${livreurInfo['users']['first_name'] ?? ''} ${livreurInfo['users']['last_name'] ?? ''}'.trim()
        : 'En attente d\'assignation';
    final vehicule   = livreurInfo?['vehicules'];
    final vehiculeInfo = vehicule != null
        ? '${vehicule['type'] ?? ''} — ${vehicule['plate_number'] ?? ''}'
        : '';
    final otp = (l['confirmations'] as List?)?.isNotEmpty == true
        ? l['confirmations'][0]['otp_code']?.toString() : null;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => CommandeDetailScreen(id: l['id'] as int)))
          .then((_) => _load()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            // Header bleu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F2FD),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Color(0xFFBBDEFB))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(id, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF20619E), fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF20619E).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      const Text('En cours', style: TextStyle(color: Color(0xFF20619E), fontSize: 10, fontWeight: FontWeight.bold)),
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
                  Row(children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text(client, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text(adresse, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.delivery_dining, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text(livreurNom, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                  ]),
                  if (vehiculeInfo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.two_wheeler, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(vehiculeInfo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ]),
                  ],
                  if (otp != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B2A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Code OTP client :', style: TextStyle(color: Colors.white60, fontSize: 11)),
                          Text(otp, style: const TextStyle(color: Color(0xFFC9952E), fontSize: 22,
                              fontWeight: FontWeight.w900, letterSpacing: 6, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(montant, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0D1B2A))),
                      ElevatedButton.icon(
                        onPressed: () => _ouvrirSuivi(l['id'] as int),
                        icon: const Icon(Icons.location_on, size: 16),
                        label: const Text('Suivre en direct'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF20619E),
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
}