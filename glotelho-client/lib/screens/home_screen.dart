import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color navy = Color(0xFF0D1B2A);
  static const Color gold = Color(0xFFC8960C);

  int _currentIndex = 0;

  // Données simulées (seront remplacées par l'API Laravel)
  final Map<String, dynamic> _client = {
    'nom': 'Marie',
    'prenom': 'Ngono',
  };

  final List<Map<String, dynamic>> _commandes = [
    {
      'id': 'CMD-2025-0847',
      'statut': 'En_cours',
      'adresse': 'Bastos, Yaoundé',
      'livreur': 'Jean-Paul Kamga',
      'eta': '15 min',
      'distance': '2.3 km',
      'etape': 2, // 0=confirmé, 1=préparé, 2=en route, 3=livré
    },
    {
      'id': 'CMD-2025-0831',
      'statut': 'Livré',
      'adresse': 'Melen, Yaoundé',
      'livreur': 'Pierre Abanda',
      'eta': null,
      'distance': null,
      'etape': 3,
    },
    {
      'id': 'CMD-2025-0812',
      'statut': 'Livré',
      'adresse': 'Mvog-Mbi, Yaoundé',
      'livreur': 'Marie-Claire N.',
      'eta': null,
      'distance': null,
      'etape': 3,
    },
    {
      'id': 'CMD-2025-0798',
      'statut': 'Annulé',
      'adresse': 'Nlongkak, Yaoundé',
      'livreur': 'Jean-Paul Kamga',
      'eta': null,
      'distance': null,
      'etape': 0,
    },
  ];

  // Commande active (en cours)
  Map<String, dynamic>? get _commandeActive => _commandes.firstWhere(
        (c) => c['statut'] == 'En_cours',
    orElse: () => {},
  );

  int get _commandesLivrees =>
      _commandes.where((c) => c['statut'] == 'Livré').length;

  int get _commandesActives =>
      _commandes.where((c) => c['statut'] == 'En_cours').length;

  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'En_cours':
        return const Color(0xFF1565C0);
      case 'Livré':
        return const Color(0xFF2E7D32);
      case 'Annulé':
        return const Color(0xFFC62828);
      default:
        return Colors.grey;
    }
  }

  Color _bgStatut(String statut) {
    switch (statut) {
      case 'En_cours':
        return const Color(0xFFE3F2FD);
      case 'Livré':
        return const Color(0xFFE8F5E9);
      case 'Annulé':
        return const Color(0xFFFFEBEE);
      default:
        return Colors.grey.shade100;
    }
  }

  String _labelStatut(String statut) {
    switch (statut) {
      case 'En_cours':
        return 'En cours';
      case 'Livré':
        return 'Livré';
      case 'Annulé':
        return 'Annulé';
      default:
        return statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildAccueil();
      case 1:
        return _buildSuivi();
      case 2:
        return _buildHistorique();
      case 3:
        return _buildProfil();
      default:
        return _buildAccueil();
    }
  }

  // ═══════════════════════════════════════════
  // ACCUEIL
  // ═══════════════════════════════════════════
  Widget _buildAccueil() {
    final commande = _commandeActive;
    final aCommandeActive = commande != null && commande.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Bar personnalisée
          Container(
            color: navy,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, ${_client['nom']} 👋',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Glotelho Express',
                        style: TextStyle(
                          fontSize: 11,
                          color: gold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Logo G
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: gold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'G',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Cloche notif
                Stack(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Carte commande active
                if (aCommandeActive) ...[
                  _buildCarteCommandeActive(commande!),
                  const SizedBox(height: 14),
                ],

                // Stats rapides
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icone: Icons.local_shipping_outlined,
                        valeur: '$_commandesActives',
                        label: 'En cours',
                        couleur: const Color(0xFF1565C0),
                        bg: const Color(0xFFE3F2FD),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icone: Icons.check_circle_outline,
                        valeur: '$_commandesLivrees',
                        label: 'Livrées',
                        couleur: const Color(0xFF2E7D32),
                        bg: const Color(0xFFE8F5E9),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icone: Icons.receipt_long_outlined,
                        valeur: '${_commandes.length}',
                        label: 'Total',
                        couleur: gold,
                        bg: const Color(0xFFFAEEDA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Historique récent
                const Text(
                  'Commandes récentes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 12),

                ..._commandes.map((cmd) => _buildItemHistorique(cmd)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarteCommandeActive(Map<String, dynamic> commande) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Commande en cours',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white60,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gold.withOpacity(0.5)),
                ),
                child: Text(
                  '⏱ ${commande['eta']}',
                  style: const TextStyle(
                    color: gold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '#${commande['id']}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: gold, size: 14),
              const SizedBox(width: 4),
              Text(
                commande['adresse'],
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Barre de progression
          _buildBarreProgression(commande['etape']),
          const SizedBox(height: 14),

          // Mini carte placeholder
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFC8D8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Grille carte
                Positioned.fill(
                  child: CustomPaint(painter: _MapGridPainter()),
                ),
                // Routes
                Positioned(
                  left: 0,
                  right: 0,
                  top: 42,
                  child: Container(height: 4,
                      color: Colors.white.withOpacity(0.7)),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 60,
                  child: Container(width: 4,
                      color: Colors.white.withOpacity(0.7)),
                ),
                // Pin livreur
                const Positioned(
                  top: 20,
                  left: 45,
                  child:
                  Text('🏍️', style: TextStyle(fontSize: 18)),
                ),
                // Pin destination
                const Positioned(
                  top: 28,
                  right: 50,
                  child:
                  Text('📍', style: TextStyle(fontSize: 16)),
                ),
                // ETA pill
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: navy,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${commande['distance']} · ${commande['eta']}',
                      style: const TextStyle(
                        color: gold,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Livreur
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: gold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person,
                    color: navy, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      commande['livreur'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const Text(
                      'Votre livreur',
                      style: TextStyle(
                          color: Colors.white60, fontSize: 10),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: gold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Suivre',
                    style: TextStyle(
                      color: navy,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarreProgression(int etape) {
    final etapes = ['Confirmé', 'Préparé', 'En route', 'Livré'];
    return Row(
      children: List.generate(etapes.length, (i) {
        final fait = i <= etape;
        final actif = i == etape;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: fait ? gold : Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: actif
                          ? const Icon(Icons.local_shipping,
                          color: navy, size: 12)
                          : fait
                          ? const Icon(Icons.check,
                          color: navy, size: 12)
                          : const SizedBox(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    etapes[i],
                    style: TextStyle(
                      fontSize: 8,
                      color: fait ? gold : Colors.white38,
                      fontWeight: fait
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              if (i < etapes.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: i < etape ? gold : Colors.white24,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatCard({
    required IconData icone,
    required String valeur,
    required String label,
    required Color couleur,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icone, color: couleur, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            valeur,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: couleur,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style:
            const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildItemHistorique(Map<String, dynamic> cmd) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _bgStatut(cmd['statut']),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              cmd['statut'] == 'Livré'
                  ? Icons.check_circle_outline
                  : cmd['statut'] == 'Annulé'
                  ? Icons.cancel_outlined
                  : Icons.local_shipping_outlined,
              color: _couleurStatut(cmd['statut']),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${cmd['id']}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  cmd['adresse'],
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _bgStatut(cmd['statut']),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _labelStatut(cmd['statut']),
              style: TextStyle(
                color: _couleurStatut(cmd['statut']),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SUIVI (placeholder)
  // ═══════════════════════════════════════════
  Widget _buildSuivi() {
    return const Center(
      child: Text('Page Suivi — à venir',
          style: TextStyle(color: navy, fontSize: 16)),
    );
  }

  // ═══════════════════════════════════════════
  // HISTORIQUE (placeholder)
  // ═══════════════════════════════════════════
  Widget _buildHistorique() {
    return const Center(
      child: Text('Page Historique — à venir',
          style: TextStyle(color: navy, fontSize: 16)),
    );
  }

  // ═══════════════════════════════════════════
  // PROFIL (placeholder)
  // ═══════════════════════════════════════════
  Widget _buildProfil() {
    return const Center(
      child: Text('Page Profil — à venir',
          style: TextStyle(color: navy, fontSize: 16)),
    );
  }

  // ═══════════════════════════════════════════
  // BOTTOM NAV
  // ═══════════════════════════════════════════
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'label': 'Accueil'},
      {'icon': Icons.location_on_outlined, 'label': 'Suivi'},
      {'icon': Icons.receipt_long_outlined, 'label': 'Historique'},
      {'icon': Icons.person_outline, 'label': 'Profil'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final actif = i == _currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (actif)
                        Container(
                          width: 24,
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: gold,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      Icon(
                        items[i]['icon'] as IconData,
                        color: actif ? gold : Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: actif ? gold : Colors.grey,
                          fontWeight: actif
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// Painter pour la grille de la mini carte
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0D1B2A).withOpacity(0.06)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 16) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}