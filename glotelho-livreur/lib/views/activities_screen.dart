import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/earnings_service.dart';
import '../models/activity_model.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  List<ActivityModel> _all = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() {}));
  }

  Future<void> _load() async {
    final activities = await EarningsService.getActivities(limit: 0);
    if (!mounted) return;
    setState(() {
      _all = activities;
      _isLoading = false;
    });
  }

  String _dateKey(DateTime d) => '${d.day} ${_moisComplet(d.month)} ${d.year}';
  String _moisComplet(int m) => const ['', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'][m];

  Map<String, List<ActivityModel>> get _grouped {
    final q = _searchCtrl.text.toLowerCase();
    final filtered = q.isEmpty
        ? _all
        : _all.where((a) => a.label.toLowerCase().contains(q) || a.subLabel.toLowerCase().contains(q)).toList();

    final map = <String, List<ActivityModel>>{};
    for (final a in filtered) {
      final key = _dateKey(a.date);
      map.putIfAbsent(key, () => []).add(a);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('ACTIVITÉS', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: const Color(0xFF16324A), borderRadius: BorderRadius.circular(14)),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une transaction ...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                    : grouped.isEmpty
                    ? const Center(child: Text('Aucune transaction', style: TextStyle(color: Colors.white38)))
                    : ListView(
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(entry.key, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        ...entry.value.map((a) => _buildTile(a)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(ActivityModel a) {
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
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
              Text('${a.date.hour.toString().padLeft(2, '0')}:${a.date.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}