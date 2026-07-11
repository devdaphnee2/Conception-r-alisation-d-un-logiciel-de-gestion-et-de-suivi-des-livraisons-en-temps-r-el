import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/order_model.dart';
import '../services/orders_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<OrderModel> _all = [];
  bool _loading = true;
  int _tab = 0; // 0 Nouvelles, 1 En cours, 2 Livrées

  @override
  void initState() {
    super.initState();
    OrdersService.getOrders().then((v) {
      if (mounted) setState(() { _all = v; _loading = false; });
    });
  }

  List<OrderModel> get _filtered {
    switch (_tab) {
      case 1:
        return _all.where((o) => o.status == OrderStatus.enCours).toList();
      case 2:
        return _all.where((o) => o.status == OrderStatus.livree).toList();
      default:
        return _all.where((o) => o.status == OrderStatus.nouvelle).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text('Mes commandes',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _tabChip('Nouvelles', 0),
                  const SizedBox(width: 10),
                  _tabChip('En cours', 1),
                  const SizedBox(width: 10),
                  _tabChip('Livrées', 2),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                    : _filtered.isEmpty
                    ? const Center(child: Text('Aucune commande', style: TextStyle(color: Colors.white38)))
                    : ListView(children: _filtered.map(_card).toList()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabChip(String label, int i) {
    final active = _tab == i;
    return GestureDetector(
      onTap: () => setState(() => _tab = i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.gold : AppColors.cardNavy,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(label,
            style: TextStyle(color: active ? Colors.white : Colors.white54, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  Widget _card(OrderModel o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.cardNavy, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Commande #${o.id}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${o.date.day} ${_mois(o.date.month)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          _line('Paiement', o.paymentType),
          _line('Montant total', '${o.total.toStringAsFixed(0)} XAF'),
          _line('Produits', o.products),
          const SizedBox(height: 14),
          if (o.status == OrderStatus.nouvelle)
            Row(
              children: [
                Expanded(child: _btn('Accepter', const Color(0xFF2ECC71), () => _accept(o))),
                const SizedBox(width: 10),
                Expanded(child: _btn('Refuser', const Color(0xFFE74C3C), () => _reject(o))),
                const SizedBox(width: 10),
                Expanded(child: _btnOutline('Détails', () => _details(o))),
              ],
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: _btnOutline('Détails', () => _details(o)),
            ),
        ],
      ),
    );
  }

  Widget _line(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, height: 1.4),
          children: [
            TextSpan(text: '$k : ', style: const TextStyle(color: Colors.white38)),
            TextSpan(text: v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _btnOutline(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white24),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text('Détails', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  String _mois(int m) => const ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'][m];

  void _accept(OrderModel o) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Commande #${o.id} acceptée'), behavior: SnackBarBehavior.floating));
  void _reject(OrderModel o) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Commande #${o.id} refusée'), behavior: SnackBarBehavior.floating));
  void _details(OrderModel o) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Détails commande #${o.id}'), behavior: SnackBarBehavior.floating));
}