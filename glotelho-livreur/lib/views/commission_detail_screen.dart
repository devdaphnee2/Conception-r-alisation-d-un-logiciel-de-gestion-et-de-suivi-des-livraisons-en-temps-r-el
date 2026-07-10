import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../services/earnings_service.dart';
import 'delivery_detail_screen.dart';

class CommissionDetailScreen extends StatelessWidget {
  final ActivityModel commission;
  const CommissionDetailScreen({super.key, required this.commission});

  static const Color _bg = Color(0xFF1F3A4D);
  static const Color _teal = Color(0xFF35D0B8);
  static const Color _gold = Color(0xFFE0A400);

  String _fmt(double v) =>
      '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} XAF';

  String _dateLong(DateTime d) {
    const mois = ['', 'Jan', 'Fev', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aou', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${mois[d.month]} ${d.year.toString().substring(2)} à '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = commission;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          children: [
            const SizedBox(height: 10),
            IconButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 18),
            Text(_dateLong(c.date), style: const TextStyle(color: Color(0xFFC5D2DD), fontSize: 16)),
            const SizedBox(height: 8),
            Text('+${_fmt(c.amount)}',
                style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),

            _row('ID', c.id, mono: true),
            _rowBadge('Statut', 'Effectué'),
            _row('Operation', 'Commission'),
            _row('Opérateur (Manager)', c.manager),
            _row('Solde de', _fmt(c.soldeAvant ?? 0)),
            _row('Solde à', _fmt(c.soldeApres ?? 0)),

            const SizedBox(height: 20),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 22),
            const Text('TRANSACTION SOURCE',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 6),

            _row('ID', c.linkedId ?? '—', mono: true),
            _row('Montant', '+${_fmt(c.amount)}'),
            _row('Service', 'Livraison à domicile'),
            _row('Opérateur (Manager)', c.manager),
            _row('Client', c.clientName ?? '—'),
            _row('Numéro Client', c.clientPhone ?? '—'),

            const SizedBox(height: 20),
            _linkButton(
              context,
              'Voir la livraison source →',
              _gold,
                  () async {
                final all = await EarningsService.getActivities();
                final deliv = all.firstWhere(
                      (a) => a.id == c.linkedId,
                  orElse: () => c,
                );
                if (deliv.isLivraison && context.mounted) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => DeliveryDetailScreen(delivery: deliv)));
                }
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 42, child: Text(k, style: const TextStyle(color: Color(0xFF9DB2C2), fontSize: 16))),
          const SizedBox(width: 16),
          Expanded(
            flex: 58,
            child: Text(v,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: mono ? 15 : 16,
                    fontWeight: mono ? FontWeight.w600 : FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _rowBadge(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 42, child: Text(k, style: const TextStyle(color: Color(0xFF9DB2C2), fontSize: 16))),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: _teal.withOpacity(0.16), borderRadius: BorderRadius.circular(8)),
            child: Text(v, style: const TextStyle(color: _teal, fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _linkButton(BuildContext c, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }
}