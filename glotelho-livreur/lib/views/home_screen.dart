import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/driver_state.dart';
import '../services/earnings_service.dart';
import '../models/activity_model.dart';
import 'widgets/donut_chart.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  EarningsSummary? _summary;
  List<ActivityModel> _activities = [];
  bool _isLoading = true;
  bool _isRepaying = false;
  bool _hideBalances = false;
  int _cardIndex = 0;
  final PageController _cardController = PageController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final summary = await EarningsService.getSummary();
    final activities = await EarningsService.getActivities(limit: 4);
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _activities = activities;
      _isLoading = false;
    });
  }

  String _fmt(double p) =>
      '${p.toStringAsFixed(p.truncateToDouble() == p ? 0 : 1).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} XAF';

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 18) return 'Bonjour';
    return 'Bonsoir';
  }

  Future<void> _repay() async {
    setState(() => _isRepaying = true);
    final ok = await EarningsService.repayDebt();
    setState(() => _isRepaying = false);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Emprunt réglé avec succès ✓'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Impossible de régler l\'emprunt pour le moment'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _withdraw() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Retrait Mobile Money — à venir'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _goToActivities() {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverState = context.watch<DriverState>();
    final prenom = driverState.driver?.prenom;
    final displayName = (prenom == null || prenom.isEmpty) ? 'Livreur' : prenom;
    final hasDebt = (_summary?.emprunt ?? 0) > 0;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : RefreshIndicator(
          onRefresh: _load,
          color: AppColors.gold,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildHeader(displayName),
              const SizedBox(height: 20),
              _buildCardCarousel(hasDebt),
              const SizedBox(height: 24),
              _buildActivitiesSection(),
              const SizedBox(height: 24),
              _buildStatsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String prenom) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
              child: const Icon(Icons.person_outline, color: Colors.white70),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_greeting()},', style: const TextStyle(color: Colors.white60, fontSize: 13)),
                Row(
                  children: [
                    Text(prenom, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    const Text('👋', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Gains', style: TextStyle(color: Colors.white60, fontSize: 12)),
                SizedBox(width: 4),
                Icon(Icons.diamond, color: Colors.pinkAccent, size: 14),
              ],
            ),
            // Total cumulatif de toutes les commissions gagnées,
            // ne varie jamais suite à un retrait ou un remboursement d'emprunt.
            Text('+${_fmt(_summary?.totalGains ?? 0)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildCardCarousel(bool hasDebt) {
    if (!hasDebt) {
      // Un seul badge, pas besoin de carrousel.
      return _buildCommissionCard();
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView(
            controller: _cardController,
            onPageChanged: (i) => setState(() => _cardIndex = i),
            children: [
              _buildCommissionCard(),
              _buildEmpruntCard(),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _cardIndex == i ? 20 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: _cardIndex == i ? AppColors.gold : Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildCommissionCard() {
    final montant = _summary?.soldeCommission ?? 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Solde commission', style: TextStyle(color: Colors.white60, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(_hideBalances ? '•••••• XAF' : _fmt(montant),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => _hideBalances = !_hideBalances),
                child: Icon(_hideBalances ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.white54, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _goToActivities,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('VOIR PLUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _withdraw,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('RETIRER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpruntCard() {
    final montant = _summary?.emprunt ?? 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Emprunt (dette)', style: TextStyle(color: Colors.white60, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(_hideBalances ? '•••••• XAF' : _fmt(montant),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => _hideBalances = !_hideBalances),
                child: Icon(_hideBalances ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.white54, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _isRepaying ? null : _repay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isRepaying
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('RÉGLER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Activités récentes', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: _goToActivities,
              child: const Text('Plus', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cardNavy,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: _activities.asMap().entries.map((entry) {
              final isLast = entry.key == _activities.length - 1;
              return _buildActivityTile(entry.value, isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTile(ActivityModel a, bool isLast) {
    final isPositive = a.amount >= 0;
    IconData icon;
    Color iconColor;
    Color iconBg;

    if (a.type == ActivityType.commission) {
      icon = Icons.arrow_downward;
      iconColor = Colors.tealAccent;
      iconBg = Colors.teal.withOpacity(0.15);
    } else if (a.provider == 'orange') {
      icon = Icons.phone_android;
      iconColor = Colors.white;
      iconBg = Colors.orange;
    } else {
      icon = Icons.phone_android;
      iconColor = Colors.white;
      iconBg = Colors.blue;
    }

    final dateStr = '${a.date.day} ${_moisAbrege(a.date.month)} ${a.date.year.toString().substring(2)}, '
        '${a.date.hour.toString().padLeft(2, '0')}:${a.date.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(a.subLabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${isPositive ? '+' : ''}${a.amount.toStringAsFixed(1)} XAF',
                  style: TextStyle(color: isPositive ? Colors.tealAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(dateStr, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  String _moisAbrege(int m) => const ['', 'Jan', 'Fev', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aou', 'Sep', 'Oct', 'Nov', 'Dec'][m];

  Widget _buildStatsSection() {
    final gains = _summary?.totalGains ?? 0;
    final emprunt = _summary?.emprunt ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          DonutChart(
            value1: emprunt > 0 ? emprunt : 1,
            value2: gains,
            centerLabel: 'Total Gain',
            centerValue: _compact(gains),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _legendItem(const Color(0xFF7C6FF0), 'Emprunt', _compact(emprunt)),
              _legendItem(AppColors.gold, 'Gain', _compact(gains)),
            ],
          ),
        ],
      ),
    );
  }

  String _compact(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  Widget _legendItem(Color color, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}