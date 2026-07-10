import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';

/// Écran Suivi (Tracking) — reprend la logique de Tracking.jsx :
/// liste des livreurs actuellement en livraison (status En_cours),
/// sélection d'un livreur pour voir ses détails.
///
/// ⚠️ Le web utilise Mapbox GL + Firebase Realtime Database pour la
/// position GPS en direct. Ici, la carte est un espace réservé —
/// intègre `google_maps_flutter` (ou `mapbox_maps_flutter`) et
/// `firebase_database` pour brancher le vrai suivi temps réel (voir
/// les TODO ci-dessous, aux endroits exacts où ça se branche).
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> livreurs = [];
  int? _selectedId;

  static const _colors = [
    Color(0xFFC9952E),
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
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
      final data = (res.data as List?) ?? [];

      // Même logique que le web : une entrée par livreur (le premier
      // trouvé), à partir des livraisons En_cours.
      final Map<int, Map<String, dynamic>> byLivreur = {};
      for (final l in data) {
        final dp = l['delivery_persons'];
        final id = l['delivery_person_id'];
        if (dp != null && id != null && !byLivreur.containsKey(id)) {
          byLivreur[id] = {
            'id': id,
            'nom': '${dp['users']?['first_name'] ?? ''} ${dp['users']?['last_name'] ?? ''}',
            'vehicule': dp['vehicules']?['type'] ?? 'moto',
            'zone': dp['zone_affectee'] ?? '',
            'livraison_id': l['id'],
            'livraison_ref': 'LIV-${l['id'].toString().padLeft(5, '0')}',
            'client':
            '${l['customers']?['users']?['first_name'] ?? ''} ${l['customers']?['users']?['last_name'] ?? ''}',
            'client_phone': l['customers']?['users']?['phone'] ?? '',
            'adresse': l['delivery_address'] ?? '',
            'montant': l['amount_to_collect'] ?? 0,
          };
        }
      }
      setState(() {
        livreurs = byLivreur.values.toList();
        if (livreurs.isNotEmpty) _selectedId = livreurs.first['id'];
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? get _selected =>
      livreurs.where((l) => l['id'] == _selectedId).firstOrNull;

  Color _colorFor(int index) => _colors[index % _colors.length];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = livreurs.indexWhere((l) => l['id'] == _selectedId);
    final selectedColor =
    selectedIndex >= 0 ? _colorFor(selectedIndex) : AppTheme.navyLight;

    return Scaffold(
      appBar: AppBar(title: const Text('Suivi')),
      body: Stack(
        children: [
          // ── Zone carte (placeholder) ──────────────────────────
          // TODO: remplacer ce Container par un GoogleMap/MapboxMap
          // dont les marqueurs sont mis à jour depuis un stream
          // firebase_database (`FirebaseDatabase.instance.ref('positions')`)
          // équivalent à `onValue` côté web.
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF3F3F3),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    Text('Carte GPS à intégrer',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    Text('(google_maps_flutter / mapbox_maps_flutter)',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),

          // ── Badge "EN DIRECT" ──────────────────────────────────
          Positioned(
            top: 12,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        color: Color(0xFF22C55E), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('EN DIRECT',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF22C55E))),
                ],
              ),
            ),
          ),

          // ── Panneau bas coulissant ─────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.32,
            minChildSize: 0.14,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Text('Livreurs actifs (${livreurs.length})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),

                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (livreurs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Aucune livraison en cours.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      )
                    else
                      ...livreurs.asMap().entries.map((entry) {
                        final i = entry.key;
                        final l = entry.value;
                        final color = _colorFor(i);
                        final selected = _selectedId == l['id'];
                        return InkWell(
                          onTap: () => setState(() => _selectedId = l['id']),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? color.withOpacity(0.08) : null,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: selected ? color.withOpacity(0.3) : Colors.transparent),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: color,
                                  child: Text(
                                      (l['nom'] as String).isNotEmpty
                                          ? (l['nom'] as String)[0]
                                          : '?',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(l['nom'],
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight:
                                              selected ? FontWeight.w700 : FontWeight.w500)),
                                      Text('Position GPS non connectée',
                                          style: TextStyle(
                                              fontSize: 10, color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    if (_selected != null) ...[
                      const SizedBox(height: 16),
                      _detailCard(_selected!, selectedColor),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _detailCard(Map<String, dynamic> l, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l['livraison_ref'],
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              TextButton(
                onPressed: () {
                  // TODO: naviguer vers le détail de la livraison
                },
                child: Text('Voir', style: TextStyle(color: color, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statBox('Vitesse', '— km/h', const Color(0xFF22C55E)),
              const SizedBox(width: 8),
              _statBox('GPS', 'Inactif', Colors.grey.shade600),
              const SizedBox(width: 8),
              _statBox('Montant', '${l['montant']} F', color),
            ],
          ),
          const SizedBox(height: 12),
          Text('ADRESSE DE LIVRAISON',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
          const SizedBox(height: 2),
          Text(l['adresse'], style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.navy,
                child: Text((l['client'] as String).isNotEmpty ? l['client'][0] : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l['client'],
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    Text(l['client_phone'],
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}