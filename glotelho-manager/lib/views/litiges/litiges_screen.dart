import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../services/api_service.dart';

class LitigeModel {
  final int id;
  final String referenceCommande;
  final String motif;
  final String statut; // 'OUVERT', 'RESOLU', etc.
  final DateTime dateCreation;

  LitigeModel({
    required this.id,
    required this.referenceCommande,
    required this.motif,
    required this.statut,
    required this.dateCreation,
  });

  factory LitigeModel.fromJson(Map<String, dynamic> json) {
    return LitigeModel(
      id: json['id'] ?? 0,
      referenceCommande: json['commande_ref'] ?? json['commande_id']?.toString() ?? 'N/A',
      motif: json['motif'] ?? json['description'] ?? 'Aucun motif précisé',
      statut: (json['statut'] ?? 'OUVERT').toString().toUpperCase(),
      dateCreation: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class LitigesScreen extends StatefulWidget {
  const LitigesScreen({super.key});

  @override
  State<LitigesScreen> createState() => _LitigesScreenState();
}

class _LitigesScreenState extends State<LitigesScreen> {
  List<LitigeModel> _litiges = [];
  bool _loading = true;
  String _filtreStatut = 'TOUS'; // 'TOUS', 'OUVERT', 'RESOLU'

  // Couleurs du thème Navy & Gold
  static const Color navyBackground = Color(0xFF0D1B2A);
  static const Color cardNavy = Color(0xFF1B2A4A);
  static const Color goldAccent = Color(0xFFC9952E);
  static const Color greenSuccess = Color(0xFF2E7D32);
  static const Color orangeWarning = Color(0xFFE65100);

  @override
  void initState() {
    super.initState();
    _chargerLitiges();
  }

  Future<void> _chargerLitiges() async {
    setState(() => _loading = true);
    try {
      final appState = context.read<AppState>();
      final api = ApiService(appState);
      final res = await api.dio.get('/litiges');
      final List data = res.data ?? [];
      setState(() {
        _litiges = data.map((j) => LitigeModel.fromJson(j)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<LitigeModel> get _litigesFitres {
    if (_filtreStatut == 'OUVERT') {
      return _litiges.where((l) => l.statut == 'OUVERT' || l.statut == 'EN_COURS').toList();
    } else if (_filtreStatut == 'RESOLU') {
      return _litiges.where((l) => l.statut == 'RESOLU' || l.statut == 'FERME').toList();
    }
    return _litiges;
  }

  @override
  Widget build(BuildContext context) {
    final total = _litiges.length;
    final ouverts = _litiges.where((l) => l.statut == 'OUVERT' || l.statut == 'EN_COURS').length;
    final resolus = _litiges.where((l) => l.statut == 'RESOLU' || l.statut == 'FERME').length;

    return Scaffold(
      backgroundColor: navyBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- EN-TÊTE ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Gestion des Litiges',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    onPressed: _chargerLitiges,
                  ),
                ],
              ),
            ),

            // --- CARTES KPI DE STATISTIQUES ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(child: _buildKpiCard('Total', '$total', Icons.gavel_rounded, Colors.blueAccent)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildKpiCard('Ouverts', '$ouverts', Icons.error_outline_rounded, goldAccent)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildKpiCard('Résolus', '$resolus', Icons.check_circle_outline_rounded, Colors.greenAccent)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- FILTRES PAR PUCE (CHIPS) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildFilterChip('Tous', 'TOUS'),
                  const SizedBox(width: 10),
                  _buildFilterChip('En cours', 'OUVERT'),
                  const SizedBox(width: 10),
                  _buildFilterChip('Résolus', 'RESOLU'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- LISTE DES LITIGES OU ÉTAT VIDE ---
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: goldAccent))
                  : _litigesFitres.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: _chargerLitiges,
                color: goldAccent,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _litigesFitres.length,
                  itemBuilder: (context, index) {
                    final litige = _litigesFitres[index];
                    return _buildLitigeCard(litige);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget KPI
  Widget _buildKpiCard(String title, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w500),
              ),
              Icon(icon, size: 18, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Widget Filtre Chip
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filtreStatut == value;
    return GestureDetector(
      onTap: () => setState(() => _filtreStatut = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? goldAccent : cardNavy,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? goldAccent : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Widget État Vide Moderne
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardNavy.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.gavel_rounded,
              size: 64,
              color: Colors.white24,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun litige trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Les contestations ou réclamations apparaîtront ici.',
            style: TextStyle(fontSize: 13, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  // Widget Carte Litige
  Widget _buildLitigeCard(LitigeModel litige) {
    final isOuvert = litige.statut == 'OUVERT' || litige.statut == 'EN_COURS';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Commande #${litige.referenceCommande}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOuvert ? orangeWarning.withOpacity(0.2) : greenSuccess.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isOuvert ? orangeWarning : greenSuccess),
                ),
                child: Text(
                  isOuvert ? 'En cours' : 'Résolu',
                  style: TextStyle(
                    color: isOuvert ? Colors.orangeAccent : Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            litige.motif,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: Colors.white38),
              const SizedBox(width: 4),
              Text(
                '${litige.dateCreation.day}/${litige.dateCreation.month}/${litige.dateCreation.year}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}