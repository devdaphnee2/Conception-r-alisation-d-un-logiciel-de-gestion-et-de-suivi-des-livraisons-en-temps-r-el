import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'cancel_delivery_screen.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final statut = order['statut'] as String? ?? 'En cours';
    final orderId = order['id'] as String? ?? '#CMD-88291023';
    final isEnCours = statut == 'En cours';

    // Données simulées des articles
    final List<Map<String, dynamic>> articles = [
      {
        'nom': 'iPhone 15 Pro Max - 256GB',
        'detail': 'Couleur: Titane Naturel',
        'quantite': 1,
        'prix': 850000,
        'icon': Icons.phone_android,
      },
      {
        'nom': 'Sony WH-1000XM5',
        'detail': 'Réduction de bruit active',
        'quantite': 1,
        'prix': 215000,
        'icon': Icons.headphones,
      },
    ];

    final int sousTotal =
    articles.fold(0, (sum, a) => sum + (a['prix'] as int));
    final int livraison = 2500;
    final int taxes = 0;
    final int total = sousTotal + livraison + taxes;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Glotelho Express',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline,
                color: Colors.black87, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined,
                color: Colors.black87, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge statut + numéro CMD
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isEnCours
                        ? const Color(0xFFE3F2FD)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statut.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isEnCours
                          ? const Color(0xFF1565C0)
                          : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  orderId.replaceAll('#', 'CMD-'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            const Text(
              'Détails de la livraison',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 14),

            // Boutons Signaler + Suivre
            if (isEnCours)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CancelDeliveryScreen(
                                orderId: orderId.replaceAll('#', ''),
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Signaler un problème',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.location_on_outlined,
                            size: 16, color: AppColors.navy),
                        label: Text(
                          'Suivre en\ntemps réel',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 18),

            // Articles commandés
            _buildSection(
              title: 'Articles commandés',
              child: Column(
                children: articles.map((article) {
                  final isLast = articles.last == article;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(article['icon'] as IconData,
                                  size: 28, color: Colors.grey.shade400),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article['nom'] as String,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    article['detail'] as String,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Quantité: ${article['quantite']}    ${_formatPrice(article['prix'] as int)} FCFA',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        const Divider(
                            height: 1, color: Color(0xFFF0F0F0)),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // Résumé du paiement
            _buildSection(
              title: 'RÉSUMÉ DU PAIEMENT',
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1,
              ),
              child: Column(
                children: [
                  _buildPaymentRow(
                      'Sous-total', '${_formatPrice(sousTotal)},000 FCFA'),
                  const SizedBox(height: 8),
                  _buildPaymentRow(
                      'Livraison', '${_formatPrice(livraison)} FCFA'),
                  const SizedBox(height: 8),
                  _buildPaymentRow('Taxes', '${taxes} FCFA'),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${_formatPrice(total)},500 FCFA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.payment_outlined,
                            size: 18, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        const Text(
                          'Mode de paiement',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                        const Spacer(),
                        const Text(
                          'Orange Money (Payé)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Votre livreur
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VOTRE LIVREUR',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white54,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white24,
                            ),
                            child: const Icon(Icons.person,
                                color: Colors.white, size: 28),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.navy, width: 2),
                              ),
                              child: const Icon(Icons.check,
                                  size: 10, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Moussa Koulibaly',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(Icons.star,
                                    color: AppColors.gold, size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  '4.9 · 1.2k livraisons',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.phone_outlined,
                          size: 16, color: Colors.white),
                      label: const Text(
                        'Contacter',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Colors.white24, width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // État de la commande (timeline)
            _buildSection(
              title: 'État de la commande',
              child: Column(
                children: [
                  _buildTimelineItem(
                    isActive: true,
                    icon: Icons.local_shipping_outlined,
                    title: 'En cours de livraison',
                    subtitle: 'Moussa est à 2.4 km de votre position',
                    time: "Aujourd'hui, 14:32",
                    isLast: false,
                  ),
                  _buildTimelineItem(
                    isActive: false,
                    icon: Icons.inventory_2_outlined,
                    title: 'Colis récupéré',
                    subtitle: 'Le livreur a récupéré votre commande à l\'entrepôt',
                    time: "Aujourd'hui, 13:45",
                    isLast: false,
                  ),
                  _buildTimelineItem(
                    isActive: false,
                    icon: Icons.check_circle_outline,
                    title: 'Commande validée',
                    subtitle: 'Paiement reçu et préparation terminée',
                    time: "Aujourd'hui, 11:20",
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Mini-carte
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFD4E8D0),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Fond carte stylisé
                  Positioned.fill(
                    child: CustomPaint(painter: _MapPainter()),
                  ),
                  // Pin livreur
                  const Positioned(
                    top: 60,
                    left: 70,
                    child: Text('🏍️', style: TextStyle(fontSize: 22)),
                  ),
                  // Pin destination
                  Positioned(
                    bottom: 30,
                    right: 60,
                    child: Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on,
                              color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                  // Badge "Direct · Live Tracking"
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Direct · Live Tracking',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    TextStyle? titleStyle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: titleStyle ??
                const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value,
            style: const TextStyle(
                fontSize: 13, color: Colors.black87)),
      ],
    );
  }

  Widget _buildTimelineItem({
    required bool isActive,
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne verticale + point
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.gold
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive ? icon : Icons.circle,
                  size: isActive ? 12 : 6,
                  color: isActive ? AppColors.navy : Colors.grey,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isActive
                          ? Colors.black87
                          : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    time,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter pour la mini-carte
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fond vert clair (eau/ville)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFD4E8D0),
    );

    // Routes principales
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.35, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 4,
    );

    // Blocs de bâtiments
    final buildingPaint = Paint()
      ..color = const Color(0xFFBDD8B8)
      ..style = PaintingStyle.fill;

    for (var rect in [
      Rect.fromLTWH(10, 10, 60, 30),
      Rect.fromLTWH(80, 10, 80, 30),
      Rect.fromLTWH(10, 60, 50, 40),
      Rect.fromLTWH(size.width * 0.4, 10, 70, 25),
      Rect.fromLTWH(size.width * 0.75, 60, 60, 40),
      Rect.fromLTWH(size.width * 0.4, 90, 80, 35),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        buildingPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}