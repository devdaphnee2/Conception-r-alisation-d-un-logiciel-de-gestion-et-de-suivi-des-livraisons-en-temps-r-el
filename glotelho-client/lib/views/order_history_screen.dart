/*import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'order_details_screen.dart';
import 'delivery_completed_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String _selectedFilter = 'Toutes';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = ['Toutes', 'En cours', 'Livré', 'Annulé'];

  final List<Map<String, dynamic>> _orders = [
    {
      'id': '#GE-902341',
      'statut': 'Livré',
      'nom': 'iPhone 15 Pro Max - Natural Titanium',
      'detail': 'Livré le 12 Octobre 2023 à Douala, Bonapriso',
      'prix': 895000,
      'icon': Icons.phone_android,
    },
    {
      'id': '#GE-902558',
      'statut': 'En cours',
      'nom': 'Smart TV Samsung 55" QLED 4K',
      'detail': "Arrivée prévue aujourd'hui avant 18:00",
      'prix': 450000,
      'icon': Icons.tv_outlined,
    },
    {
      'id': '#GE-882110',
      'statut': 'Annulé',
      'nom': 'Cafetière Nespresso Pixie',
      'detail': 'Annulé le 05 Octobre 2023 - Rupture de stock',
      'prix': 125000,
      'icon': Icons.coffee_outlined,
    },
    {
      'id': '#GE-871190',
      'statut': 'Livré',
      'nom': 'MacBook Air M2 13" - Gris Sidéral',
      'detail': 'Livré le 28 Septembre 2023 à Yaoundé, Bastos',
      'prix': 780000,
      'icon': Icons.laptop_mac_outlined,
    },
  ];

  List<Map<String, dynamic>> get _filteredOrders {
    List<Map<String, dynamic>> list = _orders;
    if (_selectedFilter != 'Toutes') {
      list = list
          .where((o) => o['statut'] == _selectedFilter)
          .toList();
    }
    if (_searchController.text.isNotEmpty) {
      list = list
          .where((o) =>
      (o['nom'] as String)
          .toLowerCase()
          .contains(_searchController.text.toLowerCase()) ||
          (o['id'] as String)
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    }
    return list;
  }

  Color _borderColor(String statut) {
    switch (statut) {
      case 'Livré':
        return const Color(0xFF2E7D32);
      case 'En cours':
        return const Color(0xFF1565C0);
      case 'Annulé':
        return Colors.grey.shade400;
      default:
        return Colors.grey;
    }
  }

  Color _badgeColor(String statut) {
    switch (statut) {
      case 'Livré':
        return const Color(0xFF2E7D32);
      case 'En cours':
        return const Color(0xFF1565C0);
      case 'Annulé':
        return Colors.grey.shade600;
      default:
        return Colors.grey;
    }
  }

  Color _badgeBg(String statut) {
    switch (statut) {
      case 'Livré':
        return const Color(0xFFE8F5E9);
      case 'En cours':
        return const Color(0xFFE3F2FD);
      case 'Annulé':
        return Colors.grey.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Icon(Icons.menu, color: Colors.black87, size: 22),
        ),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Glotelho Express',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.shopping_cart_outlined,
                color: Colors.black87, size: 22),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                const Text(
                  'Historique des commandes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Retrouvez le détail de vos livraisons passées et en cours.',
                  style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 16),

                // Filtres pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final isSelected = _selectedFilter == f;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedFilter = f),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.gold
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.gold
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Barre de recherche
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une commande...',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: Icon(Icons.search,
                          color: Colors.grey.shade400, size: 20),
                      border: InputBorder.none,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),

          // Liste des commandes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filteredOrders.length + 1,
              itemBuilder: (context, i) {
                if (i == _filteredOrders.length) {
                  return _filteredOrders.isEmpty
                      ? _buildEmpty()
                      : _buildVoirPlus();
                }
                return _buildOrderCard(_filteredOrders[i]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final statut = order['statut'] as String;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: _borderColor(statut), width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : ID + badge statut
              Row(
                children: [
                  Text(
                    order['id'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _badgeBg(statut),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statut.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _badgeColor(statut),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Produit
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(order['icon'] as IconData,
                        size: 24, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['nom'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order['detail'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 10),

              // Prix + actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _formatPrice(order['prix'] as int),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  _buildActions(order),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(Map<String, dynamic> order) {
    final statut = order['statut'] as String;

    if (statut == 'Livré') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Laisser un avis
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeliveryCompletedScreen(
                    orderId: order['id'].toString().replaceAll('#', ''),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.star_border, size: 14),
            label: const Text('Laisser un avis',
                style: TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          // Recommander
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.view_list_outlined, size: 14),
            label: const Text('Recommander',
                style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      );
    } else if (statut == 'En cours') {
      return ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailsScreen(order: order),
            ),
          );
        },
        icon: const Icon(Icons.location_on_outlined, size: 14),
        label: const Text('Suivre le colis',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    } else {
      return OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailsScreen(order: order),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.shade300),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Détails',
            style: TextStyle(fontSize: 12)),
      );
    }
  }

  Widget _buildVoirPlus() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          label: const Text('Voir plus de commandes'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black87,
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Aucune commande trouvée',
              style: TextStyle(
                  fontSize: 15, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}*/


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';
import '../utils/constants.dart';
import 'order_details_cancelled_screen.dart';
import 'order_details_delivered_screen.dart';
import 'order_details_ongoing_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});
  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String _selectedFilter = 'Toutes';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'GE-902341',
      'statut': 'Livré',
      'nom': 'iPhone 15 Pro Max - Natural Titanium',
      'date': '12 Oct. 2023 · 14:32',
      'adresse': 'Douala, Bonapriso',
      'prix': 895000,
      'livraison': 2500,
      'paiement': 'Orange Money',
      'icon': Icons.phone_android,
      'livreur': 'Jean-Marc Talla',
      'livreurTel': '+237 655 123 456',
      'livreurNote': 4.9,
      'avis': {'etoiles': 5, 'tags': ['Fast delivery', 'Friendly driver'], 'commentaire': 'Excellent service !'},
      'articles': [
        {'nom': 'iPhone 15 Pro Max - 256GB', 'detail': 'Titane Naturel', 'qte': 1, 'prix': 892500, 'icon': Icons.phone_android},
      ],
    },
    {
      'id': 'GE-902558',
      'statut': 'En cours',
      'nom': 'Smart TV Samsung 55" QLED 4K',
      'date': "Aujourd'hui · arrivée avant 18:00",
      'adresse': 'Yaoundé, Bastos',
      'prix': 450000,
      'livraison': 2500,
      'paiement': 'MTN MoMo',
      'icon': Icons.tv_outlined,
      'livreur': 'Moussa Koulibaly',
      'livreurTel': '+237 677 987 654',
      'livreurNote': 4.7,
      'articles': [
        {'nom': 'Smart TV Samsung 55" QLED 4K', 'detail': 'Résolution 4K UHD', 'qte': 1, 'prix': 447500, 'icon': Icons.tv_outlined},
      ],
      'etapeActuelle': 1, // 0=Colis récupéré, 1=En cours, 2=Validée
    },
    {
      'id': 'GE-882110',
      'statut': 'Annulé',
      'nom': 'Cafetière Nespresso Pixie',
      'date': '05 Oct. 2023 · 09:15',
      'adresse': 'Douala, Akwa',
      'prix': 125000,
      'livraison': 0,
      'paiement': 'Orange Money',
      'icon': Icons.coffee_outlined,
      'livreur': 'Pierre Abanda',
      'livreurTel': '+237 699 456 789',
      'livreurNote': 4.5,
      'raisonAnnulation': 'Rupture de stock',
      'articles': [
        {'nom': 'Cafetière Nespresso Pixie', 'detail': 'Couleur Rouge', 'qte': 1, 'prix': 125000, 'icon': Icons.coffee_outlined},
      ],
    },
    {
      'id': 'GE-871190',
      'statut': 'Livré',
      'nom': 'MacBook Air M2 13" - Gris Sidéral',
      'date': '28 Sep. 2023 · 11:45',
      'adresse': 'Yaoundé, Bastos',
      'prix': 780000,
      'livraison': 2500,
      'paiement': 'Espèces',
      'icon': Icons.laptop_mac_outlined,
      'livreur': 'Samuel Nkeng',
      'livreurTel': '+237 655 789 012',
      'livreurNote': 4.8,
      'avis': null, // pas encore noté
      'articles': [
        {'nom': 'MacBook Air M2 13"', 'detail': 'Gris Sidéral, 8GB RAM', 'qte': 1, 'prix': 777500, 'icon': Icons.laptop_mac_outlined},
      ],
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    List<Map<String, dynamic>> list = _orders;
    if (_selectedFilter != 'Toutes') {
      list = list.where((o) => o['statut'] == _selectedFilter).toList();
    }
    final q = _searchController.text.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((o) =>
      (o['nom'] as String).toLowerCase().contains(q) ||
          (o['id'] as String).toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Color _borderColor(String s) {
    switch (s) {
      case 'Livré':   return const Color(0xFF2E7D32);
      case 'En cours': return const Color(0xFF1565C0);
      case 'Annulé':  return Colors.grey;
      default:        return Colors.grey;
    }
  }

  Color _badgeColor(String s) {
    switch (s) {
      case 'Livré':   return const Color(0xFF2E7D32);
      case 'En cours': return const Color(0xFF1565C0);
      case 'Annulé':  return Colors.grey.shade600;
      default:        return Colors.grey;
    }
  }

  Color _badgeBg(String s) {
    switch (s) {
      case 'Livré':   return const Color(0xFFE8F5E9);
      case 'En cours': return const Color(0xFFE3F2FD);
      case 'Annulé':  return Colors.grey.shade100;
      default:        return Colors.grey.shade100;
    }
  }

  String _fmt(int p) => '${p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

  void _openDetail(Map<String, dynamic> order) {
    switch (order['statut'] as String) {
      case 'Annulé':
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => OrderDetailsCancelledScreen(order: order)));
        break;
      case 'Livré':
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => OrderDetailsDeliveredScreen(order: order)));
        break;
      case 'En cours':
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => OrderDetailsOngoingScreen(order: order)));
        break;
    }
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filters = state.language == 'Français'
        ? ['Toutes', 'En cours', 'Livré', 'Annulé']
        : ['All', 'Ongoing', 'Delivered', 'Cancelled'];

    // Synchroniser le filtre si langue change
    final localFilter = _selectedFilter;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          state.language == 'Français' ? 'Historique des commandes' : 'Order History',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        // Pas de panier ni point d'interrogation
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.language == 'Français'
                      ? 'Retrouvez le détail de vos livraisons passées et en cours.'
                      : 'Find the details of your past and ongoing deliveries.',
                  style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 14),

                // Filtres pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((f) {
                      // Map filtre affiché → valeur interne
                      final internalVal = _toInternal(f);
                      final isSelected = _selectedFilter == internalVal;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = internalVal),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.gold : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: isSelected ? AppColors.gold : Colors.grey.shade200),
                          ),
                          child: Text(f,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : Colors.black87)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Barre de recherche
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: state.language == 'Français'
                          ? 'Rechercher une commande...'
                          : 'Search an order...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () { _searchController.clear(); setState(() {}); })
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Liste
          Expanded(
            child: _filtered.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(state.language == 'Français' ? 'Aucune commande' : 'No orders found',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
            ]))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _buildCard(_filtered[i], state),
            ),
          ),
        ],
      ),
    );
  }

  String _toInternal(String label) {
    switch (label) {
      case 'All': return 'Toutes';
      case 'Ongoing': return 'En cours';
      case 'Delivered': return 'Livré';
      case 'Cancelled': return 'Annulé';
      default: return label;
    }
  }

  Widget _buildCard(Map<String, dynamic> order, AppState state) {
    final statut = order['statut'] as String;
    final isEn = state.language == 'English';
    final statutLabel = isEn
        ? (statut == 'Livré' ? 'DELIVERED' : statut == 'En cours' ? 'ONGOING' : 'CANCELLED')
        : statut.toUpperCase();

    return GestureDetector(
      onTap: () => _openDetail(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: _borderColor(statut), width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ID + badge
              Row(children: [
                Text('#${order['id']}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _badgeBg(statut), borderRadius: BorderRadius.circular(6)),
                  child: Text(statutLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _badgeColor(statut), letterSpacing: 0.5)),
                ),
              ]),
              const SizedBox(height: 8),

              // Produit
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 46, height: 46,
                    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
                    child: Icon(order['icon'] as IconData, size: 24, color: Colors.grey.shade500)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(order['nom'] as String,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.3)),
                  const SizedBox(height: 3),
                  Text(order['date'] as String,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ])),
              ]),

              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 10),

              // Prix + action
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_fmt(order['prix'] as int),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                _buildAction(order, state),
              ]),

              // Raison annulation visible directement
              if (statut == 'Annulé' && order['raisonAnnulation'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      '${isEn ? 'Reason' : 'Raison'}: ${order['raisonAnnulation']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction(Map<String, dynamic> order, AppState state) {
    final statut = order['statut'] as String;
    final isEn = state.language == 'English';

    if (statut == 'En cours') {
      return ElevatedButton.icon(
        onPressed: () => _openDetail(order),
        icon: const Icon(Icons.location_on_outlined, size: 14, color: Colors.white),
        label: Text(isEn ? 'Track' : 'Suivre', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }
    if (statut == 'Livré') {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        if (order['avis'] == null)
          OutlinedButton.icon(
            onPressed: () => _openDetail(order),
            icon: const Icon(Icons.star_border, size: 14),
            label: Text(isEn ? 'Review' : 'Avis', style: const TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          )
        else
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.star, size: 14, color: AppColors.gold),
            const SizedBox(width: 3),
            Text('${order['avis']['etoiles']}/5',
                style: TextStyle(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
          ]),
        ElevatedButton.icon(
          onPressed: () => _openDetail(order),
          icon: const Icon(Icons.receipt_long_outlined, size: 14, color: Colors.white),
          label: Text(isEn ? 'Details' : 'Détails', style: const TextStyle(fontSize: 11, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ]);
    }
    // Annulé
    return OutlinedButton(
      onPressed: () => _openDetail(order),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(isEn ? 'Details' : 'Détails', style: const TextStyle(fontSize: 12)),
    );
  }
}
