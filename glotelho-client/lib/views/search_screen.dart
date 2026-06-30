/*import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'settings_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _cartCount = 0;
  int _notifCount = 2;
  int _currentIndex = 1; // Search actif par défaut

  // ── Salutation dynamique ──────────────────────────────────────
  String get _salutation {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bonne après-midi';
    return 'Bonsoir';
  }

  // Nom utilisateur simulé (sera remplacé par l'API)
  final String _userName = 'Marie';

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.devices_outlined,      'label': 'Électronique'},
    {'icon': Icons.checkroom_outlined,    'label': 'Mode'},
    {'icon': Icons.home_outlined,         'label': 'Maison'},
    {'icon': Icons.phone_iphone_outlined, 'label': 'Téléphones'},
    {'icon': Icons.sports_soccer_outlined,'label': 'Sports'},
    {'icon': Icons.kitchen_outlined,      'label': 'Cuisine'},
  ];

  final List<Map<String, dynamic>> _allProducts = [
    {
      'brand': 'SAMSUNG',
      'name': 'Galaxy S24 Ultra 5G - 512GB Titanium Gray',
      'price': 849000,
      'icon': Icons.phone_android,
      'isFavorite': false,
    },
    {
      'brand': 'SONY',
      'name': 'Sony WH-1000XM5 Wireless Noise Canceling Headphones',
      'price': 245000,
      'icon': Icons.headphones,
      'isFavorite': false,
    },
    {
      'brand': 'PHILIPS',
      'name': 'Essential Airfryer XL - 6.2L Capacity, Digital Touch',
      'price': 125000,
      'icon': Icons.kitchen,
      'isFavorite': false,
      'badge': 'Best Seller',
    },
    {
      'brand': 'PREMIUM GEAR',
      'name': 'Urban Strider Leather Sneakers - Navy Edition',
      'price': 45000,
      'icon': Icons.directions_run,
      'isFavorite': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return _allProducts;
    return _allProducts
        .where((p) =>
    (p['name'] as String).toLowerCase().contains(q) ||
        (p['brand'] as String).toLowerCase().contains(q))
        .toList();
  }

  String _formatPrice(int price) => price
      .toString()
      .replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')
      + ' FCFA';

  void _addToCart(String productName) {
    setState(() => _cartCount++);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$productName ajouté au panier'),
      backgroundColor: AppColors.navy,
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _openNotifications() {
    setState(() => _notifCount = 0);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _NotificationsSheet(),
    );
  }

  void _openCart() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CartSheet(count: _cartCount),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Barre de recherche ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Rechercher sur Glotelho...',
                  hintStyle: const TextStyle(
                      color: Color(0xFFAAAAAA), fontSize: 14),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFFAAAAAA), size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear,
                        color: Color(0xFFAAAAAA), size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // ── Explore Categories ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Explore Categories',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
                Text('See All',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold)),
              ],
            ),
          ),

          // ── Catégories scrollables ──────────────────────────
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(cat['icon'] as IconData,
                            size: 22, color: Colors.black87),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        cat['label'] as String,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.black87),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Trending Now ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              children: [
                const Text('Trending Now',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
                const SizedBox(width: 8),
                const Text('Filtre:',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 4),
                Text('Plus pertinent',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600)),
                Icon(Icons.keyboard_arrow_down,
                    size: 16, color: AppColors.gold),
              ],
            ),
          ),

          // ── Liste produits ──────────────────────────────────
          Expanded(
            child: _filteredProducts.isEmpty
                ? _buildEmpty()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredProducts.length + 1,
              itemBuilder: (_, i) {
                if (i == _filteredProducts.length) {
                  return _buildLoadMore();
                }
                return _buildProductCard(
                    _filteredProducts[i], i);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leadingWidth: 48,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87, size: 24),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_salutation, $_userName 👋',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            'Glotelho Express',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.gold,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        // Icône notification
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.black87, size: 24),
              onPressed: _openNotifications,
            ),
            if (_notifCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '$_notifCount',
                      style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Icône panier
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined,
                  color: Colors.black87, size: 24),
              onPressed: _openCart,
            ),
            if (_cartCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Drawer (menu hamburger) ─────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête profil
            Container(
              color: AppColors.navy,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.gold,
                    child: Text(
                      _userName[0],
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$_salutation, $_userName',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'marie.ngono@gmail.com',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _drawerItem(Icons.home_outlined, 'Accueil', () => Navigator.pop(context)),
            _drawerItem(Icons.search, 'Recherche', () => Navigator.pop(context)),
            _drawerItem(Icons.category_outlined, 'Catégories', () => Navigator.pop(context)),
            _drawerItem(Icons.local_shipping_outlined, 'Suivi livraisons', () => Navigator.pop(context)),
            _drawerItem(Icons.favorite_border_outlined, 'Mes favoris', () => Navigator.pop(context)),
            _drawerItem(Icons.receipt_long_outlined, 'Mes commandes', () => Navigator.pop(context)),
            const Divider(height: 24, indent: 16, endIndent: 16),
            _drawerItem(Icons.settings_outlined, 'Paramètres', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
            _drawerItem(Icons.help_outline, 'Aide & Support', () => Navigator.pop(context)),
            const Spacer(),
            _drawerItem(Icons.logout, 'Se déconnecter', () => Navigator.pop(context),
                color: Colors.red),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black87, size: 22),
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              color: color ?? Colors.black87,
              fontWeight: FontWeight.w500)),
      onTap: onTap,
      dense: true,
    );
  }

  // ── Bottom Nav ──────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined,          'label': 'Home'},
      {'icon': Icons.search,                  'label': 'Search'},
      {'icon': Icons.category_outlined,       'label': 'Categories'},
      {'icon': Icons.local_shipping_outlined, 'label': 'Tracking'},
      {'icon': Icons.person_outline,          'label': 'Account'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == _currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _currentIndex = i);
                    if (i == 4) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()));
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (active)
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(items[i]['icon'] as IconData,
                              color: Colors.white, size: 18),
                        )
                      else
                        Icon(items[i]['icon'] as IconData,
                            color: Colors.grey, size: 22),
                      const SizedBox(height: 3),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: active ? AppColors.gold : Colors.grey,
                          fontWeight: active
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── Carte produit ───────────────────────────────────────────
  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image produit
          Stack(
            children: [
              Container(
                height: 170,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(product['icon'] as IconData,
                      size: 72, color: Colors.grey.shade300),
                ),
              ),
              // Badge Best Seller (uniquement, pas de badge promo)
              if (product['badge'] != null)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product['badge'] as String,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              // Bouton favori
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      final idx = _allProducts.indexWhere(
                              (p) => p['name'] == product['name']);
                      if (idx != -1) {
                        _allProducts[idx]['isFavorite'] =
                        !(_allProducts[idx]['isFavorite'] as bool);
                      }
                    });
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: Icon(
                      (product['isFavorite'] as bool)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 18,
                      color: (product['isFavorite'] as bool)
                          ? Colors.red
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Infos produit
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['brand'] as String,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  product['name'] as String,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.3),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatPrice(product['price'] as int),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _addToCart(product['name'] as String),
                    icon: const Icon(Icons.shopping_cart_outlined,
                        size: 17, color: Colors.white),
                    label: const Text('Add to Cart',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMore() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
            label: const Text('Load More Products'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 6),
          Text('Showing ${_filteredProducts.length} of 240 products',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Aucun produit trouvé',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Bottom sheet Notifications
// ─────────────────────────────────────────────────────────────────
class _NotificationsSheet extends StatelessWidget {
  final List<Map<String, dynamic>> _notifs = const [
    {
      'icon': Icons.delivery_dining,
      'title': 'Votre livreur approche !',
      'body': 'Jean-Marc est à 500m de votre position',
      'time': 'Il y a 2 min',
      'isNew': true,
    },
    {
      'icon': Icons.check_circle_outline,
      'title': 'Commande #GE-902341 livrée',
      'body': 'Votre colis a été livré avec succès',
      'time': 'Il y a 1h',
      'isNew': false,
    },
  ];

  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Notifications',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._notifs.map((n) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: n['isNew'] as bool
                    ? AppColors.gold.withOpacity(0.15)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(n['icon'] as IconData,
                  color: n['isNew'] as bool
                      ? AppColors.gold
                      : Colors.grey,
                  size: 22),
            ),
            title: Text(n['title'] as String,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: n['isNew'] as bool
                        ? FontWeight.bold
                        : FontWeight.normal)),
            subtitle: Text(n['body'] as String,
                style: const TextStyle(fontSize: 12)),
            trailing: Text(n['time'] as String,
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey)),
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Bottom sheet Panier
// ─────────────────────────────────────────────────────────────────
class _CartSheet extends StatelessWidget {
  final int count;
  const _CartSheet({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Icon(Icons.shopping_cart_outlined,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            count == 0 ? 'Votre panier est vide' : '$count article(s) dans le panier',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (count > 0)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Voir le panier',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}*/


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';
import '../utils/constants.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _cartCount  = 0;
  int _notifCount = 2;
  int _currentIndex = 0; // Home actif par défaut

  final List<Map<String, dynamic>> _allProducts = [
    {'brand': 'SAMSUNG', 'name': 'Galaxy S24 Ultra 5G - 512GB Titanium Gray', 'price': 849000, 'icon': Icons.phone_android, 'isFavorite': false},
    {'brand': 'SONY', 'name': 'Sony WH-1000XM5 Wireless Noise Canceling Headphones', 'price': 245000, 'icon': Icons.headphones, 'isFavorite': false},
    {'brand': 'PHILIPS', 'name': 'Essential Airfryer XL - 6.2L Capacity, Digital Touch', 'price': 125000, 'icon': Icons.kitchen, 'isFavorite': false, 'badge': 'Best Seller'},
    {'brand': 'PREMIUM GEAR', 'name': 'Urban Strider Leather Sneakers - Navy Edition', 'price': 45000, 'icon': Icons.directions_run, 'isFavorite': false},
  ];

  List<Map<String, dynamic>> get _filtered {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return _allProducts;
    return _allProducts.where((p) =>
    (p['name'] as String).toLowerCase().contains(q) ||
        (p['brand'] as String).toLowerCase().contains(q)).toList();
  }

  String _fmt(int price) =>
      '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;

    final List<Map<String, dynamic>> categories = [
      {'icon': Icons.devices_outlined,      'label': state.language == 'Français' ? 'Électronique' : 'Electronics'},
      {'icon': Icons.checkroom_outlined,    'label': state.language == 'Français' ? 'Mode' : 'Fashion'},
      {'icon': Icons.home_outlined,         'label': state.language == 'Français' ? 'Maison' : 'Home'},
      {'icon': Icons.phone_iphone_outlined, 'label': state.language == 'Français' ? 'Téléphones' : 'Phones'},
      {'icon': Icons.sports_soccer_outlined,'label': state.language == 'Français' ? 'Sports' : 'Sports'},
      {'icon': Icons.kitchen_outlined,      'label': state.language == 'Français' ? 'Cuisine' : 'Kitchen'},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _buildDrawer(context, state),
      appBar: _buildAppBar(state),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Container(
              height: 48,
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(24)),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: t('search_hint'),
                  hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFAAAAAA), size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, color: Color(0xFFAAAAAA), size: 20),
                      onPressed: () { _searchController.clear(); setState(() {}); })
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Explore Categories
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t('explore_cat'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                Text(t('see_all'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gold)),
              ],
            ),
          ),

          // Catégories
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat = categories[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(13)),
                        child: Icon(cat['icon'] as IconData, size: 22, color: Colors.black87),
                      ),
                      const SizedBox(height: 5),
                      Text(cat['label'] as String, style: const TextStyle(fontSize: 10, color: Colors.black87)),
                    ],
                  ),
                );
              },
            ),
          ),

          // Trending
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(children: [
              Text(t('trending'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
              const SizedBox(width: 8),
              Text(t('filter'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 4),
              Text(t('relevant'), style: TextStyle(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w600)),
              Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.gold),
            ]),
          ),

          // Produits
          Expanded(
            child: _filtered.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(t('no_product'), style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
            ]))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filtered.length + 1,
              itemBuilder: (_, i) {
                if (i == _filtered.length) return _loadMore(t);
                return _productCard(_filtered[i], t);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, state),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(AppState state) {
    return AppBar(
      backgroundColor: Colors.white, elevation: 0,
      leadingWidth: 48,
      leading: Builder(builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87, size: 24),
          onPressed: () => Scaffold.of(ctx).openDrawer())),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${state.salutation}, ${state.userName} 👋',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text('Glotelho Express',
            style: TextStyle(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w500)),
      ]),
      actions: [
        // Notification
        Stack(children: [
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.black87, size: 24),
              onPressed: () { setState(() => _notifCount = 0); _openNotifications(); }),
          if (_notifCount > 0) Positioned(top: 8, right: 8,
              child: Container(width: 16, height: 16,
                  decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                  child: Center(child: Text('$_notifCount', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))))),
        ]),
        // Panier
        Stack(children: [
          IconButton(icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87, size: 24), onPressed: _openCart),
          if (_cartCount > 0) Positioned(top: 8, right: 8,
              child: Container(width: 16, height: 16,
                  decoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                  child: Center(child: Text('$_cartCount', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))))),
        ]),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Drawer ──────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context, AppState state) {
    final t = state.t;
    return Drawer(
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            color: AppColors.navy, padding: const EdgeInsets.fromLTRB(20, 20, 20, 24), width: double.infinity,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(radius: 28, backgroundColor: AppColors.gold,
                  child: Text(state.userName.isNotEmpty ? state.userName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))),
              const SizedBox(height: 10),
              Text('${state.salutation}, ${state.userName}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(state.userEmail, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 8),
          _drawerItem(Icons.home_outlined, t('home'), () => Navigator.pop(context)),
          _drawerItem(Icons.category_outlined, t('categories'), () => Navigator.pop(context)),
          _drawerItem(Icons.local_shipping_outlined, t('tracking'), () => Navigator.pop(context)),
          _drawerItem(Icons.favorite_border_outlined, t('favorites'), () => Navigator.pop(context)),
          _drawerItem(Icons.receipt_long_outlined, t('orders'), () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
          }),
          const Divider(height: 24, indent: 16, endIndent: 16),
          _drawerItem(Icons.settings_outlined, t('settings'), () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
          _drawerItem(Icons.help_outline, t('help'), () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));
          }),
          const Spacer(),
          _drawerItem(Icons.logout, t('logout'), () {
            Navigator.pop(context);
            _confirmLogout(context, state);
          }, color: Colors.red),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black87, size: 22),
      title: Text(label, style: TextStyle(fontSize: 14, color: color ?? Colors.black87, fontWeight: FontWeight.w500)),
      onTap: onTap, dense: true,
    );
  }

  // ── Bottom Nav (4 onglets, sans Search) ─────────────────────
  Widget _buildBottomNav(BuildContext context, AppState state) {
    final t = state.t;
    final items = [
      {'icon': Icons.home_outlined,          'label': t('home')},
      {'icon': Icons.shopping_bag_outlined,       'label': t('orders')},
      {'icon': Icons.local_shipping_outlined, 'label': t('tracking')},
      {'icon': Icons.person_outline,          'label': t('account')},
    ];
    return Container(
      decoration: BoxDecoration(color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, -3))]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == _currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _currentIndex = i);
                    if (i == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  },
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (active)
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                        child: Icon(items[i]['icon'] as IconData, color: Colors.white, size: 18),
                      )
                    else
                      Icon(items[i]['icon'] as IconData, color: Colors.grey, size: 22),
                    const SizedBox(height: 3),
                    Text(items[i]['label'] as String,
                        style: TextStyle(fontSize: 10, color: active ? AppColors.gold : Colors.grey,
                            fontWeight: active ? FontWeight.bold : FontWeight.normal)),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── Carte produit ───────────────────────────────────────────
  Widget _productCard(Map<String, dynamic> product, String Function(String) t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          Container(height: 170,
            decoration: BoxDecoration(color: const Color(0xFFF8F8F8),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
            child: Center(child: Icon(product['icon'] as IconData, size: 72, color: Colors.grey.shade300)),
          ),
          if (product['badge'] != null)
            Positioned(top: 10, left: 10,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(6)),
                    child: Text(product['badge'] as String, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
          Positioned(bottom: 10, right: 10,
              child: GestureDetector(
                onTap: () {
                  final idx = _allProducts.indexWhere((p) => p['name'] == product['name']);
                  if (idx != -1) setState(() => _allProducts[idx]['isFavorite'] = !(_allProducts[idx]['isFavorite'] as bool));
                },
                child: Container(width: 34, height: 34,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon((product['isFavorite'] as bool) ? Icons.favorite : Icons.favorite_border,
                        size: 18, color: (product['isFavorite'] as bool) ? Colors.red : Colors.grey)),
              )),
        ]),
        Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product['brand'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 0.4, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(product['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.3)),
          const SizedBox(height: 8),
          Text(_fmt(product['price'] as int), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 44,
            child: ElevatedButton.icon(
              onPressed: () { setState(() => _cartCount++); ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${product['name']} ajouté'), backgroundColor: AppColors.navy,
                  duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating)); },
              icon: const Icon(Icons.shopping_cart_outlined, size: 17, color: Colors.white),
              label: Text(t('add_cart'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
            ),
          ),
        ])),
      ]),
    );
  }

  Widget _loadMore(String Function(String) t) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Column(children: [
      OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          label: Text(t('load_more')),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12))),
      const SizedBox(height: 6),
      Text('${t('showing')} ${_filtered.length} ${t('of')} 240 ${t('products')}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      const SizedBox(height: 12),
    ]));
  }

  void _openNotifications() {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => ChangeNotifierProvider.value(
            value: context.read<AppState>(), child: const _NotifSheet()));
  }

  void _openCart() {
    final t = context.read<AppState>().t;
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(_cartCount == 0 ? t('cart_empty') : '$_cartCount article(s)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              if (_cartCount > 0) SizedBox(width: double.infinity, height: 48,
                  child: ElevatedButton(onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text(t('view_cart'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)))),
            ])));
  }

  void _confirmLogout(BuildContext context, AppState state) {
    final t = state.t;
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(t('logout_title')),
      content: Text(t('logout_confirm')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t('cancel'))),
        ElevatedButton(onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
        }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t('yes_logout'), style: const TextStyle(color: Colors.white))),
      ],
    ));
  }
}

class _NotifSheet extends StatelessWidget {
  const _NotifSheet();
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final notifs = [
      {'icon': Icons.delivery_dining, 'title': state.language == 'Français' ? 'Votre livreur approche !' : 'Your driver is approaching!',
        'body': state.language == 'Français' ? 'Jean-Marc est à 500m de votre position' : 'Jean-Marc is 500m from your location',
        'time': state.language == 'Français' ? 'Il y a 2 min' : '2 min ago', 'isNew': true},
      {'icon': Icons.check_circle_outline, 'title': state.language == 'Français' ? 'Commande #GE-902341 livrée' : 'Order #GE-902341 delivered',
        'body': state.language == 'Français' ? 'Votre colis a été livré avec succès' : 'Your package was delivered successfully',
        'time': state.language == 'Français' ? 'Il y a 1h' : '1h ago', 'isNew': false},
    ];
    return Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(t('notifications_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...notifs.map((n) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(width: 42, height: 42,
                decoration: BoxDecoration(color: (n['isNew'] as bool) ? AppColors.gold.withOpacity(0.15) : Colors.grey.shade100, shape: BoxShape.circle),
                child: Icon(n['icon'] as IconData, color: (n['isNew'] as bool) ? AppColors.gold : Colors.grey, size: 22)),
            title: Text(n['title'] as String, style: TextStyle(fontSize: 13, fontWeight: (n['isNew'] as bool) ? FontWeight.bold : FontWeight.normal)),
            subtitle: Text(n['body'] as String, style: const TextStyle(fontSize: 12)),
            trailing: Text(n['time'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          )),
        ]));
  }
}