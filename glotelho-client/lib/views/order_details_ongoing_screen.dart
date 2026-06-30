
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';
import '../utils/constants.dart';
import 'cancel_delivery_screen.dart';
import 'live_tracking_screen.dart';

/// Détails d'une livraison EN COURS
/// - Articles + coûts + livraison + paiement
/// - Livreur (nom + téléphone)
/// - Signaler un problème → CancelDeliveryScreen
/// - Suivre ma livraison → LiveTrackingScreen (position temps réel)
/// - Timeline : Colis récupéré → En cours de livraison → Commande validée
class OrderDetailsOngoingScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderDetailsOngoingScreen({super.key, required this.order});

  String _fmt(int p) => '${p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isEn = state.language == 'English';
    final articles = order['articles'] as List<Map<String, dynamic>>;
    final int sousTotal = articles.fold(0, (s, a) => s + (a['prix'] as int) * (a['qte'] as int));
    final int livraison = order['livraison'] as int;
    final int total = sousTotal + livraison;
    final int etape = order['etapeActuelle'] as int? ?? 1;
    // 0 = Colis récupéré, 1 = En cours de livraison, 2 = Commande validée

    final List<Map<String, String>> timeline = isEn
        ? [
      {'title': 'Package collected', 'sub': 'The driver picked up your order from the warehouse'},
      {'title': 'Out for delivery', 'sub': 'The driver is on the way to you'},
      {'title': 'Order confirmed', 'sub': 'You received your order and payment is settled'},
    ]
        : [
      {'title': 'Colis récupéré', 'sub': 'Le livreur a récupéré votre commande à l\'entrepôt'},
      {'title': 'En cours de livraison', 'sub': 'Le livreur est en chemin vers vous'},
      {'title': 'Commande validée', 'sub': 'Vous avez perçu votre colis et le livreur le paiement'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEn ? 'Ongoing Order' : 'Commande en cours',
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
              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
              child: Text(isEn ? 'ONGOING' : 'EN COURS',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
            ),
            const SizedBox(width: 10),
            Text('#${order['id']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
          const SizedBox(height: 12),
          Text(isEn ? 'Order Details' : 'Détails de la livraison',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 14),

          // ── Boutons Signaler + Suivre ─────────────────────
          Row(children: [
            Expanded(
              child: SizedBox(height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => CancelDeliveryScreen(
                          orderId: order['id'] as String,
                          productName: order['nom'] as String))),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isEn ? 'Report a problem' : 'Signaler un problème',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                      textAlign: TextAlign.center),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => LiveTrackingScreen(order: order))),
                  icon: Icon(Icons.location_on_outlined, size: 16, color: AppColors.navy),
                  label: Text(isEn ? 'Live tracking' : 'Suivre ma livraison',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy),
                      textAlign: TextAlign.center),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 14),

          // ── Articles commandés ───────────────────────────
          _section(
            title: isEn ? 'Ordered items' : 'Articles commandés',
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
                  Text(isEn ? 'Payment' : 'Paiement',
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
            child: Column(children: [
              Row(children: [
                Stack(children: [
                  CircleAvatar(radius: 24, backgroundColor: Colors.white24,
                      child: const Icon(Icons.person, color: Colors.white, size: 28)),
                  Positioned(bottom: 0, right: 0,
                      child: Container(width: 16, height: 16,
                        decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle,
                            border: Border.all(color: AppColors.navy, width: 2)),
                      )),
                ]),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isEn ? 'YOUR COURIER' : 'VOTRE LIVREUR',
                      style: const TextStyle(fontSize: 10, color: Colors.white54, letterSpacing: 1)),
                  const SizedBox(height: 3),
                  Text(order['livreur'] as String,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  Row(children: [
                    Icon(Icons.star, size: 13, color: AppColors.gold),
                    const SizedBox(width: 3),
                    Text('${order['livreurNote']}',
                        style: TextStyle(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Icon(Icons.phone_outlined, size: 13, color: Colors.white54),
                    const SizedBox(width: 3),
                    Text(order['livreurTel'] as String,
                        style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ]),
                ])),
              ]),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, height: 40,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone_outlined, size: 16, color: Colors.white),
                  label: Text(isEn ? 'Contact courier' : 'Contacter le livreur',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 12),

          // ── État de la commande (timeline) ───────────────
          _section(
            title: isEn ? 'Order status' : 'État de la commande',
            child: Column(
              children: List.generate(timeline.length, (i) {
                final isDone  = i < etape;
                final isActive = i == etape;
                final isLast  = i == timeline.length - 1;
                return IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Column(children: [
                      Container(width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.gold : isDone ? const Color(0xFF2E7D32) : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isActive ? Icons.local_shipping : isDone ? Icons.check : Icons.circle,
                          size: isActive ? 14 : isDone ? 14 : 6,
                          color: isActive ? AppColors.navy : isDone ? Colors.white : Colors.grey,
                        ),
                      ),
                      if (!isLast)
                        Expanded(child: Container(width: 2,
                            color: isDone ? const Color(0xFF2E7D32) : Colors.grey.shade200)),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(timeline[i]['title']!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive ? Colors.black87 : isDone ? const Color(0xFF2E7D32) : Colors.grey.shade500,
                            )),
                        const SizedBox(height: 3),
                        Text(timeline[i]['sub']!,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ]),
                    )),
                  ]),
                );
              }),
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
      Text(label, style: TextStyle(fontSize: 13,
          color: bold ? Colors.black87 : Colors.grey,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      Text(value, style: TextStyle(fontSize: 13,
          color: color ?? Colors.black87,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    ]),
  );
}

