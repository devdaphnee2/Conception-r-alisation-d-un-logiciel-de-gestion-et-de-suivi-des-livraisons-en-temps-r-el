
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';
import '../utils/constants.dart';

/// Détails d'une livraison ANNULÉE
/// - Raison de l'annulation
/// - Articles commandés + coûts
/// - Livreur assigné
/// - PAS de tracking, PAS d'état de commande
/// - PAS d'icône panier ni point d'interrogation
class OrderDetailsCancelledScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderDetailsCancelledScreen({super.key, required this.order});

  String _fmt(int p) => '${p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isEn = state.language == 'English';
    final articles = order['articles'] as List<Map<String, dynamic>>;
    final int sousTotal = articles.fold(0, (s, a) => s + (a['prix'] as int) * (a['qte'] as int));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEn ? 'Cancelled Order' : 'Commande annulée',
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 17)),
        // Pas de panier ni point d'interrogation
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Badge + numéro
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text(isEn ? 'CANCELLED' : 'ANNULÉ',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            ),
            const SizedBox(width: 10),
            Text('#${order['id']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
          const SizedBox(height: 12),
          Text(isEn ? 'Order Details' : 'Détails de la commande',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),

          // ── Raison annulation ────────────────────────────
          _section(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                    child: Icon(Icons.cancel_outlined, color: Colors.red.shade400, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isEn ? 'Cancellation reason' : 'Raison de l\'annulation',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 3),
                  Text(order['raisonAnnulation'] as String? ?? '-',
                      style: TextStyle(fontSize: 13, color: Colors.red.shade600)),
                ])),
              ]),
              const SizedBox(height: 10),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(order['date'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Articles commandés ───────────────────────────
          _section(
            title: isEn ? 'Ordered items' : 'Articles commandés',
            child: Column(children: [
              ...articles.map((a) => _articleRow(a)),
              const SizedBox(height: 8),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 8),
              _paiementRow(isEn ? 'Total' : 'Total', _fmt(sousTotal), bold: true, color: Colors.black87),
              const SizedBox(height: 6),
              _paiementRow(isEn ? 'Payment method' : 'Mode de paiement',
                  order['paiement'] as String),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Livreur assigné ──────────────────────────────
          _section(
            title: isEn ? 'Assigned courier' : 'Livreur assigné',
            child: Row(children: [
              CircleAvatar(radius: 22, backgroundColor: Colors.grey.shade200,
                  child: const Icon(Icons.person, color: Colors.grey, size: 26)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(order['livreur'] as String,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.star, size: 13, color: AppColors.gold),
                  const SizedBox(width: 3),
                  Text('${order['livreurNote']}',
                      style: TextStyle(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Icon(Icons.phone_outlined, size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 3),
                  Text(order['livreurTel'] as String,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ]),
              ])),
            ]),
          ),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _section({String? title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (title != null) ...[
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
        ],
        child,
      ]),
    );
  }

  Widget _articleRow(Map<String, dynamic> a) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(width: 44, height: 44,
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
            child: Icon(a['icon'] as IconData, size: 22, color: Colors.grey.shade400)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a['nom'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          Text(a['detail'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text('Qté: ${a['qte']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ])),
        Text('${(a['prix'] as int) * (a['qte'] as int)} FCFA'.replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} '),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
      ]),
    );
  }

  Widget _paiementRow(String label, String value, {bool bold = false, Color? color}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13, color: bold ? Colors.black87 : Colors.grey,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      Text(value, style: TextStyle(fontSize: 13, color: color ?? Colors.black87,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    ]);
  }
}
