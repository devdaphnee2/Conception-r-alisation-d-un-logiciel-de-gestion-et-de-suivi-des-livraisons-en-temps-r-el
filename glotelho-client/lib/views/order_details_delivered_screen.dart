
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';
import '../utils/constants.dart';
import 'delivery_completed_screen.dart';

/// Détails d'une livraison LIVRÉE
/// - N° commande, date/heure réception
/// - Articles livrés, quantité, coûts
/// - Coût livraison + mode paiement
/// - Nom + numéro livreur
/// - Avis laissé (ou bouton pour noter)
/// - PAS de tracking
class OrderDetailsDeliveredScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderDetailsDeliveredScreen({super.key, required this.order});

  String _fmt(int p) => '${p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isEn = state.language == 'English';
    final articles = order['articles'] as List<Map<String, dynamic>>;
    final int sousTotal = articles.fold(0, (s, a) => s + (a['prix'] as int) * (a['qte'] as int));
    final int livraison = order['livraison'] as int;
    final int total = sousTotal + livraison;
    final avis = order['avis'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEn ? 'Delivered Order' : 'Commande livrée',
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 17)),
        // Pas de panier ni point d'interrogation
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Badge + numéro commande
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
              child: Text(isEn ? 'DELIVERED' : 'LIVRÉ',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            ),
            const SizedBox(width: 10),
            Text('#${order['id']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
          const SizedBox(height: 12),
          Text(isEn ? 'Order Details' : 'Détails de la commande',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),

          // ── Date et heure de réception ───────────────────
          _section(child: Row(children: [
            Container(width: 36, height: 36,
                decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isEn ? 'Delivered on' : 'Livré le',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(order['date'] as String,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
              Text(order['adresse'] as String,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ])),
          ])),

          const SizedBox(height: 12),

          // ── Articles livrés ──────────────────────────────
          _section(
            title: isEn ? 'Delivered items' : 'Articles livrés',
            child: Column(children: [
              ...articles.map((a) => _articleRow(a)),
              const SizedBox(height: 8),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 8),
              _pRow(isEn ? 'Subtotal' : 'Sous-total', _fmt(sousTotal)),
              const SizedBox(height: 6),
              _pRow(isEn ? 'Delivery' : 'Livraison', _fmt(livraison)),
              const SizedBox(height: 8),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 8),
              _pRow('Total', _fmt(total), bold: true, color: AppColors.gold),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Icon(Icons.payment_outlined, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Text(isEn ? 'Payment method' : 'Mode de paiement',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const Spacer(),
                  Text(order['paiement'] as String,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Livreur ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              CircleAvatar(radius: 24, backgroundColor: Colors.white24,
                  child: const Icon(Icons.person, color: Colors.white, size: 28)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isEn ? 'YOUR COURIER' : 'VOTRE LIVREUR',
                    style: const TextStyle(fontSize: 10, color: Colors.white54, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(order['livreur'] as String,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.star, size: 13, color: AppColors.gold),
                  const SizedBox(width: 3),
                  Text('${order['livreurNote']}',
                      style: TextStyle(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                  Icon(Icons.phone_outlined, size: 13, color: Colors.white54),
                  const SizedBox(width: 3),
                  Text(order['livreurTel'] as String,
                      style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ]),
              ])),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Avis client ──────────────────────────────────
          _section(
            title: isEn ? 'Your review' : 'Votre avis',
            child: avis != null
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Étoiles
              Row(children: List.generate(5, (i) => Icon(
                  i < (avis['etoiles'] as int) ? Icons.star : Icons.star_border,
                  color: AppColors.gold, size: 22))),
              const SizedBox(height: 10),
              // Tags
              Wrap(spacing: 6, runSpacing: 6,
                  children: (avis['tags'] as List<dynamic>).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.gold, width: 1),
                    ),
                    child: Text(tag as String,
                        style: TextStyle(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w600)),
                  )).toList()),
              if ((avis['commentaire'] as String).isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('"${avis['commentaire']}"',
                    style: const TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ])
                : SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => DeliveryCompletedScreen(
                        orderId: order['id'] as String,
                        courierName: order['livreur'] as String))),
                icon: Icon(Icons.star_border, color: AppColors.gold),
                label: Text(isEn ? 'Leave a review' : 'Laisser un avis',
                    style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.gold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _section({String? title, required Widget child}) => Container(
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

  Widget _articleRow(Map<String, dynamic> a) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Container(width: 44, height: 44,
          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
          child: Icon(a['icon'] as IconData, size: 22, color: Colors.grey.shade400)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(a['nom'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        Text(a['detail'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text('Qté: ${a['qte']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ])),
      Text('${((a['prix'] as int) * (a['qte'] as int)).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
    ]),
  );

  Widget _pRow(String label, String value, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13, color: bold ? Colors.black87 : Colors.grey,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      Text(value, style: TextStyle(fontSize: 13, color: color ?? Colors.black87,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    ]),
  );
}