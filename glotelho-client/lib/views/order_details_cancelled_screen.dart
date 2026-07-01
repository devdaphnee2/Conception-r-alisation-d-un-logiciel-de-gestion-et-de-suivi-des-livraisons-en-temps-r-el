
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';
import '../utils/constants.dart';

/// Détails d'une livraison ANNULÉE
class OrderDetailsCancelledScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderDetailsCancelledScreen({super.key, required this.order});

  String _fmt(int p) => '${p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isEn = state.language == 'English';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0B0F17) : const Color(0xFFF5F5F5);
    final appBarBg = isDark ? const Color(0xFF161D29) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.grey;
    final cardBg = isDark ? const Color(0xFF161D29) : Colors.white;
    final dividerColor = isDark ? const Color(0xFF26303F) : Colors.grey.shade100;
    final iconBg = isDark ? const Color(0xFF1E2733) : const Color(0xFFF5F5F5);

    final articles = order['articles'] as List<Map<String, dynamic>>;
    final int sousTotal = articles.fold(0, (s, a) => s + (a['prix'] as int) * (a['qte'] as int));

    Widget section({String? title, required Widget child}) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (title != null) ...[
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor)),
          const SizedBox(height: 12),
        ],
        child,
      ]),
    );

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: titleColor), onPressed: () => Navigator.pop(context)),
        title: Text(isEn ? 'Cancelled Order' : 'Commande annulée',
            style: TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2733) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(isEn ? 'CANCELLED' : 'ANNULÉ',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.grey.shade700)),
            ),
            const SizedBox(width: 10),
            Text('#${order['id']}', style: TextStyle(fontSize: 13, color: subColor)),
          ]),
          const SizedBox(height: 12),
          Text(isEn ? 'Order Details' : 'Détails de la commande',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: titleColor)),
          const SizedBox(height: 16),

          section(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.cancel_outlined, color: Colors.red.shade400, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isEn ? 'Cancellation reason' : 'Raison de l\'annulation',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: titleColor)),
                const SizedBox(height: 3),
                Text(order['raisonAnnulation'] as String? ?? '-',
                    style: TextStyle(fontSize: 13, color: Colors.red.shade400)),
              ])),
            ]),
            const SizedBox(height: 10),
            Divider(height: 1, color: dividerColor),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: subColor),
              const SizedBox(width: 6),
              Text(order['date'] as String, style: TextStyle(fontSize: 12, color: subColor)),
            ]),
          ])),

          section(
            title: isEn ? 'Ordered items' : 'Articles commandés',
            child: Column(children: [
              ...articles.map((a) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Container(width: 44, height: 44,
                      decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                      child: Icon(a['icon'] as IconData, size: 22, color: isDark ? Colors.white38 : Colors.grey.shade400)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a['nom'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: titleColor)),
                    Text(a['detail'] as String, style: TextStyle(fontSize: 11, color: subColor)),
                    Text('Qté: ${a['qte']}', style: TextStyle(fontSize: 11, color: subColor)),
                  ])),
                  Text(_fmt((a['prix'] as int) * (a['qte'] as int)),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: titleColor)),
                ]),
              )),
              const SizedBox(height: 8),
              Divider(height: 1, color: dividerColor),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Total', style: TextStyle(fontSize: 13, color: titleColor, fontWeight: FontWeight.bold)),
                Text(_fmt(sousTotal), style: TextStyle(fontSize: 13, color: titleColor, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(isEn ? 'Payment method' : 'Mode de paiement', style: TextStyle(fontSize: 13, color: subColor)),
                Text(order['paiement'] as String, style: TextStyle(fontSize: 13, color: titleColor)),
              ]),
            ]),
          ),

          section(
            title: isEn ? 'Assigned courier' : 'Livreur assigné',
            child: Row(children: [
              CircleAvatar(radius: 22, backgroundColor: isDark ? const Color(0xFF1E2733) : Colors.grey.shade200,
                  child: Icon(Icons.person, color: isDark ? Colors.white54 : Colors.grey, size: 26)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(order['livreur'] as String,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: titleColor)),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.star, size: 13, color: AppColors.gold),
                  const SizedBox(width: 3),
                  Text('${order['livreurNote']}',
                      style: TextStyle(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Icon(Icons.phone_outlined, size: 13, color: subColor),
                  const SizedBox(width: 3),
                  Text(order['livreurTel'] as String, style: TextStyle(fontSize: 12, color: subColor)),
                ]),
              ])),
            ]),
          ),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}