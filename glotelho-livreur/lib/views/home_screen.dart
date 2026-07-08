/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/constants.dart';
import '../utils/driver_state.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(4.0511, 9.7679), // Douala, Akwa
    zoom: 14,
  );

  @override
  Widget build(BuildContext context) {
    final driverState = context.watch<DriverState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: const Text('Glotelho Delivery', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Bienvenue ${driverState.driver?.prenom ?? ""} 👋',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: _initialPosition,
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: {
                const Marker(
                  markerId: MarkerId('depart'),
                  position: LatLng(4.0511, 9.7679),
                  infoWindow: InfoWindow(title: 'Point de départ - Douala Akwa'),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    await Permission.location.request();
  }
}*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/driver_state.dart';
import '../services/earnings_service.dart';
import '../models/activity_model.dart';
import 'activities_screen.dart';
import 'widgets/donut_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  EarningsSummary? _summary;
  List<ActivityModel> _activities = [];
  bool _isLoading = true;
  bool _isRepaying = false;
  bool _hideBalances = false;

  @override
  void initState() {
    super.initState();
    _load();
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

  @override
  Widget build(BuildContext context) {
    final driverState = context.watch<DriverState>();
    final prenom = driverState.driver?.prenom ?? '';

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
              _buildHeader(prenom),
              
              // 👇 Ajout du composant de la bannière de caution juste ici
              _buildCautionBanner(driverState.driver),
              
              const SizedBox(height: 20),
              _buildCommissionCard(),
              const SizedBox(height: 14),
              if (_summary != null && _summary!.emprunt > 0) ...[
                _buildEmpruntCard(),
                const SizedBox(height: 20),
              ] else
                const SizedBox(height: 6),
              _buildActivitiesSection(),
              const SizedBox(height: 24),
              _buildStatsSection(),
            ],
          ),
        ),
      ),
    );
  }

  // 👇 Méthode pour afficher la bannière de caution
  Widget _buildCautionBanner(dynamic driver) {
    // On cache si le driver est null, si la caution est payée (1), ou s'il n'y a pas de date d'activation
    if (driver == null || driver.cautionPayee == 1 || driver.dateActivation == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    DateTime activationDate;
    
    // Parse de la date d'activation en sécurité
    try {
      activationDate = driver.dateActivation is DateTime 
          ? driver.dateActivation 
          : DateTime.parse(driver.dateActivation.toString());
    } catch (e) {
      return const SizedBox.shrink();
    }

    final joursEcoules = now.difference(activationDate).inDays;
    final joursRestants = 14 - joursEcoules;

    if (joursRestants <= 0) {
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent),
        ),
        child: const Text(
          'Délai dépassé ! Votre compte risque la suspension. Réglez votre caution immédiatement.',
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Caution requise — Plus que $joursRestants jour(s)',
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Pour éviter la suspension de votre compte et recevoir vos commissions, veuillez régler votre caution :\n\n'
            '• OM : *144*1*1*698000000*50000#\n'
            '• MoMo : *126*1*1*677000000*50000#',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ],
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
                const Text('Bonjour,', style: TextStyle(color: Colors.white60, fontSize: 13)),
                Text('$prenom 👋', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Gains', style: TextStyle(color: Colors.white60, fontSize: 12)),
            Text('+${_fmt(_summary?.totalGains ?? 0)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildCommissionCard() {
    final montant = _summary?.soldeCommission ?? 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF16324A), borderRadius: BorderRadius.circular(20)),
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
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivitiesScreen())),
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
        color: const Color(0xFF3A1414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
              SizedBox(width: 8),
              Text('Emprunt (dette)', style: TextStyle(color: Colors.white60, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_hideBalances ? '•••••• XAF' : _fmt(montant),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isRepaying ? null : _repay,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isRepaying
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('RÉGLER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivitiesScreen())),
              child: const Text('Plus', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: const Color(0xFF16324A), borderRadius: BorderRadius.circular(16)),
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
    final ventes = _summary?.totalVentes ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF16324A), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          DonutChart(
            value1: ventes,
            value2: gains,
            centerLabel: 'Total Gain',
            centerValue: _compact(gains),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legendDot(const Color(0xFF7C6FF0), 'Ventes', _compact(ventes)),
                const SizedBox(height: 10),
                _legendDot(AppColors.gold, 'Gain', _compact(gains)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _compact(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  Widget _legendDot(Color color, String label, String value) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('$label  ', style: const TextStyle(color: Colors.white60, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}