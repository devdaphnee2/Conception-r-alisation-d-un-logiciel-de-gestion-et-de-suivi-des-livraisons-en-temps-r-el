import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';
import '../utils/constants.dart';
import '../models/product_model.dart';
import '../utils/cart_state.dart';

class CatalogueScreen extends StatefulWidget {
  final String? initialCategory;
  const CatalogueScreen({super.key, this.initialCategory});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'Tout';

  static const List<Map<String, dynamic>> _categories = [
    {'label': 'Tout',         'icon': Icons.apps_outlined},
    {'label': 'Téléphones',   'icon': Icons.phone_android},
    {'label': 'Électronique', 'icon': Icons.laptop_outlined},
    {'label': 'Maison',       'icon': Icons.home_outlined},
    {'label': 'Mode',         'icon': Icons.checkroom_outlined},
    {'label': 'Sports',       'icon': Icons.sports_soccer_outlined},
  ];

  final List<ProductModel> _allProducts = [
    ProductModel(id: 1,  brand: 'SAMSUNG',       name: 'Galaxy S24 Ultra 5G - 512GB Titanium Gray',                 price: 849000,  icon: Icons.phone_android,    category: 'Téléphones',   badge: 'Populaire'),
    ProductModel(id: 2,  brand: 'APPLE',          name: 'iPhone 15 Pro Max - 256GB Natural Titanium',               price: 1200000, icon: Icons.phone_iphone,     category: 'Téléphones'),
    ProductModel(id: 3,  brand: 'TECNO',          name: 'Tecno Spark 20 Pro - 8GB RAM, 256GB',                      price: 95000,   icon: Icons.phone_android,    category: 'Téléphones'),
    ProductModel(id: 4,  brand: 'SONY',           name: 'WH-1000XM5 Wireless Noise Canceling Headphones',           price: 245000,  icon: Icons.headphones,       category: 'Électronique'),
    ProductModel(id: 5,  brand: 'DELL',           name: 'Laptop Inspiron 15 - Intel Core i7, 16GB RAM, 512GB SSD',  price: 650000,  icon: Icons.laptop_outlined,  category: 'Électronique', badge: 'Best Seller'),
    ProductModel(id: 6,  brand: 'SAMSUNG',        name: 'Smart TV 55" QLED 4K - UHD, HDR10+',                      price: 480000,  icon: Icons.tv_outlined,      category: 'Électronique'),
    ProductModel(id: 7,  brand: 'PHILIPS',        name: 'Essential Airfryer XL - 6.2L Capacity, Digital Touch',     price: 125000,  icon: Icons.kitchen,          category: 'Maison',       badge: 'Best Seller'),
    ProductModel(id: 8,  brand: 'TEFAL',          name: 'Fer à repasser vapeur Express Steam 2800W',                price: 45000,   icon: Icons.iron_outlined,    category: 'Maison'),
    ProductModel(id: 9,  brand: 'MOULINEX',       name: 'Blender Smoothie Mix & Drink 1.2L 600W',                   price: 35000,   icon: Icons.blender,          category: 'Maison'),
    ProductModel(id: 10, brand: 'PREMIUM GEAR',   name: 'Urban Strider Leather Sneakers - Navy Edition',            price: 45000,   icon: Icons.directions_run,   category: 'Mode'),
    ProductModel(id: 11, brand: 'ADIDAS',         name: 'T-Shirt Running Aeroready Moisture-Wicking',               price: 18000,   icon: Icons.checkroom_outlined, category: 'Mode',       badge: 'Nouveau'),
    ProductModel(id: 12, brand: 'NIKE',           name: 'Air Max 270 React - Black/White, Taille 42',               price: 85000,   icon: Icons.directions_run,   category: 'Mode'),
    ProductModel(id: 13, brand: 'DECATHLON',      name: 'Vélo de route Triban RC 500 - Shimano 7V',                 price: 320000,  icon: Icons.directions_bike,  category: 'Sports'),
    ProductModel(id: 14, brand: 'WILSON',         name: 'Raquette de tennis Blade 98 V8 16x19',                     price: 95000,   icon: Icons.sports_tennis,    category: 'Sports'),
  ];

  List<ProductModel> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    return _allProducts.where((p) {
      final matchCat = _selectedCategory == 'Tout' || p.category == _selectedCategory;
      final matchQ   = q.isEmpty || p.name.toLowerCase().contains(q) || p.brand.toLowerCase().contains(q);
      return matchCat && matchQ;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fmt(int p) => '${p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

  @override
  Widget build(BuildContext context) {
    final state  = context.watch<AppState>();
    final cart   = context.watch<CartState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0B0F17) : const Color(0xFFF2F4F7);
    final appBarBg   = isDark ? const Color(0xFF161D29) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final cardBg     = isDark ? const Color(0xFF161D29) : Colors.white;
    final subColor   = isDark ? Colors.white54 : Colors.grey;
    final fieldBg    = isDark ? const Color(0xFF1E2733) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E3A4D) : Colors.grey.shade200;

    final products = _filtered;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: titleColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Catalogue', style: TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Stack(children: [
            IconButton(icon: Icon(Icons.shopping_cart_outlined, color: titleColor), onPressed: () {}),
            if (cart.itemCount > 0)
              Positioned(right: 6, top: 6,
                child: Container(width: 16, height: 16,
                    decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                    child: Center(child: Text('${cart.itemCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))),
              ),
          ]),
        ],
      ),
      body: Column(
        children: [
          // ── Barre de recherche ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(fontSize: 14, color: titleColor),
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit...',
                  hintStyle: TextStyle(color: subColor, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: subColor, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(icon: Icon(Icons.clear, size: 18, color: subColor),
                      onPressed: () { _searchCtrl.clear(); setState(() {}); })
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // ── Catégories ────────────────────────────────────────
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat['label'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['label']),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.gold : cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isSelected ? AppColors.gold : borderColor),
                      boxShadow: isSelected ? [BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 6)] : [],
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(cat['icon'] as IconData,
                          color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                          size: 22),
                      const SizedBox(height: 4),
                      Text(cat['label'],
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : titleColor)),
                    ]),
                  ),
                );
              },
            ),
          ),

          // ── Résultats ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(children: [
              Text('${products.length} article${products.length > 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 13, color: subColor)),
              const Spacer(),
              Text(_selectedCategory == 'Tout' ? 'Toutes catégories' : _selectedCategory,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gold)),
            ]),
          ),

          // ── Liste des produits ────────────────────────────────
          Expanded(
            child: products.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.search_off, size: 56, color: isDark ? Colors.white24 : Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('Aucun produit trouvé', style: TextStyle(color: subColor, fontSize: 15)),
            ]))
                : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (_, i) => _buildProductCard(products[i], cart, isDark, cardBg, titleColor, subColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel p, CartState cart, bool isDark, Color cardBg, Color titleColor, Color subColor) {
    final inCart = cart.items.any((e) => e.product.id == p.id);
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / icône
          Expanded(
            child: Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Container(
                  width: double.infinity,
                  color: isDark ? const Color(0xFF1E2733) : const Color(0xFFF5F5F5),
                  child: Icon(p.icon, size: 56, color: isDark ? Colors.white24 : Colors.grey.shade400),
                ),
              ),
              if (p.badge != null)
                Positioned(top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(6)),
                    child: Text(p.badge!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
              Positioned(top: 8, right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => p.isFavorite = !p.isFavorite),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                    child: Icon(p.isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 16, color: p.isFavorite ? Colors.red : Colors.grey),
                  ),
                ),
              ),
            ]),
          ),
          // Infos
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.brand, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                  color: AppColors.gold, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(p.name, style: TextStyle(fontSize: 11, color: titleColor, fontWeight: FontWeight.w500),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(_fmt(p.price), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.gold)),
            ]),
          ),
          // Bouton Ajouter
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: SizedBox(
              width: double.infinity, height: 32,
              child: ElevatedButton(
                onPressed: () {
                  cart.add(p);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${p.name.split(' ').first} ajouté au panier'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ));
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: inCart ? Colors.green : AppColors.gold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(inCart ? Icons.check : Icons.add_shopping_cart_outlined,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(inCart ? 'Ajouté' : 'Ajouter',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}