import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_state.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool   _loading  = true;
  List<Map<String, dynamic>> _livraisons = [];

  static const _colors = [
    Color(0xFFC9952E), Color(0xFF3B82F6), Color(0xFF22C55E),
    Color(0xFFEF4444), Color(0xFF8B5CF6), Color(0xFFEC4899),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiService(context.read<AppState>());
      final res = await api.getLivraisonsEnCours();
      setState(() => _livraisons = List<Map<String, dynamic>>.from(res.data ?? []));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _ouvrirSuivi(int id) async {
    final url = 'http://172.20.10.4:5173/suivi/$id';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
        title: const Text('Suivi GPS en direct'),
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
              Icon(Icons.delivery_dining, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Aucune livraison en cours',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              const Text('Les livraisons actives apparaîtront ici',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _livraisons.length,
          itemBuilder: (_, i) {
            final l     = _livraisons[i];
            final color = _colors[i % _colors.length];
            final id    = l['id'] as int;
            final client= l['client_nom'] as String? ?? '—';
            final adresse= l['delivery_address'] as String? ?? '—';
            final livreur= l['delivery_persons']?['users'];
            final livreurNom = livreur != null
                ? '${livreur['first_name'] ?? ''} ${livreur['last_name'] ?? ''}'
                : 'Non assigné';
            final vehicule = l['delivery_persons']?['vehicules'];
            final vehiculeInfo = vehicule != null
                ? '${vehicule['type'] ?? ''} — ${vehicule['plate_number'] ?? ''}'
                : '';

            return GestureDetector(
              onTap: () => _ouvrirSuivi(id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    // Header coloré
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        border: Border(bottom: BorderSide(color: color.withOpacity(0.2))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('#${id.toString().padLeft(5, '0')}',
                              style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 15)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(children: [
                              Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              const SizedBox(width: 5),
                              Text('En cours', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                            ]),
                          ),
                        ],
                      ),
                    ),
                    // Contenu
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _infoRow(Icons.person_outline, 'Client', client, color),
                          const SizedBox(height: 8),
                          _infoRow(Icons.location_on_outlined, 'Adresse', adresse, color),
                          const SizedBox(height: 8),
                          _infoRow(Icons.delivery_dining, 'Livreur', livreurNom.trim(), color),
                          if (vehiculeInfo.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _infoRow(Icons.two_wheeler, 'Véhicule', vehiculeInfo, color),
                          ],
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () => _ouvrirSuivi(id),
                            icon: const Icon(Icons.location_on, size: 18),
                            label: const Text('Suivre en temps réel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 42),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}