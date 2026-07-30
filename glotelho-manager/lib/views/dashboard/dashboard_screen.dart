import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  Map<String, int> _stats = {};
  double _montantTotal = 0;
  List _dernieres = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiService(context.read<AppState>());
      final res = await api.getMesCommandes();
      final all = (res.data as List?) ?? [];
      setState(() {
        _stats = {
          'total': all.length,
          'en_attente': all.where((l) => l['status'] == 'En_attente').length,
          'en_cours': all.where((l) => l['status'] == 'En_cours').length,
          'livrees': all.where((l) => l['status'] == 'Livr_').length,
        };
        _montantTotal = all.fold(
            0.0,
                (s, l) =>
            s +
                (double.tryParse(l['amount_to_collect']?.toString() ?? '0') ??
                    0));
        _dernieres = all.take(5).toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    // Si isDarkTheme n'existe pas encore dans ton AppState, met à 'true' ou à la bonne propriété
    final isDark = true;

    final manager = appState.currentManager;
    final prenom = manager?['first_name'] ?? 'Commerçant';
    final heure = DateTime.now().hour;
    final salut = heure < 12
        ? 'Bonjour'
        : heure < 18
        ? 'Bon après-midi'
        : 'Bonsoir';

    // Palette dynamique Navy / Clair
    final bgColor = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF2F4F7);
    final cardColor = isDark ? const Color(0xFF1B2A4A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1D1B1E);
    final textMuted = isDark ? Colors.white54 : Colors.grey;

    return Scaffold(
      backgroundColor: bgColor,
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFFC9952E)))
          : RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // --- HEADER GRADIENT ---
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D1B2A), Color(0xFF1C3D56)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$salut, $prenom 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _dateAujourdhui(),
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                          const Color(0xFFC9952E).withOpacity(0.2),
                          child: Text(
                            prenom.isNotEmpty
                                ? prenom[0].toUpperCase()
                                : 'C',
                            style: const TextStyle(
                              color: Color(0xFFC9952E),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total à collecter',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_montantTotal.toStringAsFixed(0)} XAF',
                                style: const TextStyle(
                                  color: Color(0xFFC9952E),
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white24,
                            size: 36,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- KPIS ---
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  _kpiCard(
                    'Total',
                    '${_stats['total'] ?? 0}',
                    Icons.inbox_outlined,
                    isDark ? Colors.white : const Color(0xFF0D1B2A),
                    cardColor,
                    textColor,
                  ),
                  _kpiCard(
                    'En attente',
                    '${_stats['en_attente'] ?? 0}',
                    Icons.hourglass_empty,
                    const Color(0xFFC9952E),
                    cardColor,
                    textColor,
                  ),
                  _kpiCard(
                    'En cours',
                    '${_stats['en_cours'] ?? 0}',
                    Icons.delivery_dining_rounded,
                    const Color(0xFF20619E),
                    cardColor,
                    textColor,
                  ),
                  _kpiCard(
                    'Livrées',
                    '${_stats['livrees'] ?? 0}',
                    Icons.check_circle_outline,
                    const Color(0xFF2E7D32),
                    cardColor,
                    textColor,
                  ),
                ]),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
              ),
            ),

            // --- DERNIÈRES COMMANDES ---
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dernières commandes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor, // Texte blanc sur fond sombre
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._dernieres
                        .map((l) =>
                        _commandeTile(l, cardColor, textColor, isDark))
                        .toList(),
                    if (_dernieres.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: isDark
                              ? Border.all(color: Colors.white10)
                              : null,
                        ),
                        child: Text(
                          'Aucune commande.',
                          style: TextStyle(color: textMuted),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color iconColor,
      Color cardBg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: iconColor,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _commandeTile(
      Map l, Color cardBg, Color textColor, bool isDark) {
    const statusColors = {
      'En_attente': Color(0xFFC9952E),
      'Assign_': Color(0xFF3E5682),
      'En_cours': Color(0xFF20619E),
      'Livr_': Color(0xFF2E7D32),
      'Suspendu': Color(0xFFBA1A1A),
      'Annul_': Color(0xFF817564),
    };
    const statusLabels = {
      'En_attente': 'En attente',
      'Assign_': 'Assigné',
      'En_cours': 'En cours',
      'Livr_': 'Livré',
      'Suspendu': 'Suspendu',
      'Annul_': 'Annulé',
    };
    final status = l['status'] as String? ?? '';
    final color = statusColors[status] ?? Colors.grey;
    final label = statusLabels[status] ?? status;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.15),
            child: Text(
              (l['client_nom'] as String? ?? '?')[0].toUpperCase(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${l['id'].toString().padLeft(5, '0')} — ${l['client_nom'] ?? '—'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
                Text(
                  l['delivery_address'] ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withOpacity(0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dateAujourdhui() {
    const mois = [
      '',
      'jan.',
      'fév.',
      'mar.',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sep.',
      'oct.',
      'nov.',
      'déc.'
    ];
    final d = DateTime.now();
    return '${d.day} ${mois[d.month]} ${d.year}';
  }
}