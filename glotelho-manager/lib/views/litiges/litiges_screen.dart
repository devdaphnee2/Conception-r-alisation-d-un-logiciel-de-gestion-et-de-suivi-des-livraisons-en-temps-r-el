import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../services/api_service.dart';

class LitigesScreen extends StatefulWidget {
  const LitigesScreen({super.key});
  @override
  State<LitigesScreen> createState() => _LitigesScreenState();
}

class _LitigesScreenState extends State<LitigesScreen> {
  bool _loading = true;
  List _litiges = [];

  static const _statusColors = <String, Color>{
    'Ouvert'  : Color(0xFFC9952E),
    'En_cours': Color(0xFF20619E),
    'Resolu'  : Color(0xFF1B5E20),
    'Ferme'   : Color(0xFF817564),
  };
  static const _statusLabels = <String, String>{
    'Ouvert'  : 'Ouvert',
    'En_cours': 'En traitement',
    'Resolu'  : 'Résolu ✓',
    'Ferme'   : 'Fermé',
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiService(context.read<AppState>());
      final res = await api.getMesLitiges();
      setState(() => _litiges = res.data ?? []);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolus = _litiges.where((l) => l['statut'] == 'Resolu').length;
    final ouverts = _litiges.where((l) => l['statut'] == 'Ouvert').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        title: const Text('Litiges'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // Stats
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(child: _statCard('Total', '${_litiges.length}', const Color(0xFF0D1B2A))),
                    const SizedBox(width: 10),
                    Expanded(child: _statCard('Ouverts', '$ouverts', const Color(0xFFC9952E))),
                    const SizedBox(width: 10),
                    Expanded(child: _statCard('Résolus', '$resolus', const Color(0xFF1B5E20))),
                  ],
                ),
              ),
            ),

            if (_litiges.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gavel_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('Aucun litige', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) => _litigeCard(_litiges[i]),
                    childCount: _litiges.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _litigeCard(Map l) {
    final statut  = l['statut'] as String? ?? 'Ouvert';
    final color   = _statusColors[statut] ?? Colors.grey;
    final label   = _statusLabels[statut] ?? statut;
    final livraisonId = l['deliveryorder_id'];
    final description = l['description'] as String? ?? '—';
    final motif   = l['motif'] as String? ?? '';
    final date    = l['created_at'] != null
        ? DateTime.tryParse(l['created_at'].toString()) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        border: statut == 'Resolu'
            ? Border.all(color: const Color(0xFF1B5E20).withOpacity(0.3))
            : null,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: color.withOpacity(0.15))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(livraisonId != null ? 'Livraison #${livraisonId.toString().padLeft(5,'0')}' : 'Litige',
                    style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (motif.isNotEmpty) ...[
                  Text('Motif : $motif', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                ],
                Text(description, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4)),
                if (date != null) ...[
                  const SizedBox(height: 8),
                  Text('${date.day}/${date.month}/${date.year}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
                // Note de resolution
                if (statut == 'Resolu' && l['note_resolution'] != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1B5E20).withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFF1B5E20), size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Résolution : ${l['note_resolution']}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF1B5E20)))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}