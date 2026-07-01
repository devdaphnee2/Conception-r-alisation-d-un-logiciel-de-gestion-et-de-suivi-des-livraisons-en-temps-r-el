import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../utils/app_state.dart';
import '../utils/cart_state.dart';
import '../utils/notification_state.dart';
import 'notification_screen.dart';
import '../utils/constants.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';
import 'live_tracking_screen.dart';
import '../utils/mock_orders.dart';

/// Page d'accueil de l'app client — catalogue produit type marketplace.
/// Le suivi en temps réel d'une livraison se fait depuis l'historique
/// des commandes (OrderHistoryScreen → détails commande → LiveTrackingScreen).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;

  // Catalogue simulé — à remplacer par un appel ProductController/ApiService
  // (GET /products) une fois l'API backend disponible.
  final List<ProductModel> _allProducts = [
    ProductModel(id: 1, brand: 'SAMSUNG', name: 'Galaxy S24 Ultra 5G - 512GB Titanium Gray', price: 849000, icon: Icons.phone_android),
    ProductModel(id: 2, brand: 'SONY', name: 'Sony WH-1000XM5 Wireless Noise Canceling Headphones', price: 245000, icon: Icons.headphones),
    ProductModel(id: 3, brand: 'PHILIPS', name: 'Essential Airfryer XL - 6.2L Capacity, Digital Touch', price: 125000, icon: Icons.kitchen, badge: 'Best Seller'),
    ProductModel(id: 4, brand: 'PREMIUM GEAR', name: 'Urban Strider Leather Sneakers - Navy Edition', price: 45000, icon: Icons.directions_run),
  ];

  List<ProductModel> get _filtered {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return _allProducts;
    return _allProducts
        .where((p) => p.name.toLowerCase().contains(q) || p.brand.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cart = context.watch<CartState>();
    final notif = context.watch<NotificationState>();
    final t = state.t;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _buildDrawer(context, state, isDark),
      appBar: _buildAppBar(context, state, cart, notif, isDark),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(t, isDark),
          _buildCategoriesHeader(t, isDark),
          _buildCategoriesList(state, isDark),
          _buildTrendingHeader(t, isDark),
          Expanded(
            child: _filtered.isEmpty
                ? _buildEmptyState(t, isDark)
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filtered.length + 1,
              itemBuilder: (_, i) {
                if (i == _filtered.length) return _buildLoadMore(t, isDark);
                return _buildProductCard(_filtered[i], t, cart, isDark);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, state, isDark),
    );
  }

  // ── Barre de recherche ──────────────────────────────────────────
  Widget _buildSearchBar(String Function(String) t, bool isDark) {
    final fill = isDark ? const Color(0xFF1E2A38) : const Color(0xFFF5F5F5);
    final hint = isDark ? Colors.white38 : const Color(0xFFAAAAAA);
    final textColor = isDark ? Colors.white : Colors.black87;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(24)),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 14, color: textColor),
          decoration: InputDecoration(
            hintText: t('search_hint'),
            hintStyle: TextStyle(color: hint, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: hint, size: 22),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: hint, size: 20),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesHeader(String Function(String) t, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(t('explore_cat'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
          Text(t('see_all'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gold)),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(AppState state, bool isDark) {
    final tileBg = isDark ? const Color(0xFF1E2A38) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black87;
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        itemCount: defaultCategories.length,
        itemBuilder: (_, i) {
          final cat = defaultCategories[i];
          return Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: tileBg, borderRadius: BorderRadius.circular(13)),
                  child: Icon(cat.icon, size: 22, color: textColor),
                ),
                const SizedBox(height: 5),
                Text(cat.label(state.language), style: TextStyle(fontSize: 10, color: textColor)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingHeader(String Function(String) t, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.grey;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Text(t('trending'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(width: 8),
          Text(t('filter'), style: TextStyle(fontSize: 12, color: subColor)),
          const SizedBox(width: 4),
          Text(t('relevant'), style: TextStyle(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w600)),
          Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.gold),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String Function(String) t, bool isDark) {
    final subColor = isDark ? Colors.white38 : Colors.grey.shade500;
    final iconColor = isDark ? Colors.white24 : Colors.grey.shade300;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: iconColor),
          const SizedBox(height: 12),
          Text(t('no_product'), style: TextStyle(fontSize: 15, color: subColor)),
        ],
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context, AppState state, CartState cart, NotificationState notif, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final bg = isDark ? const Color(0xFF0D1B2A) : Colors.white;
    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      leadingWidth: 48,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.menu, color: textColor, size: 24),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${state.salutation}, ${state.userName} 👋',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
          Text('Glotelho Express', style: TextStyle(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w500)),
        ],
      ),
      actions: [
        Stack(children: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: textColor, size: 24),
            onPressed: () {
              context.read<NotificationState>().markAllAsRead();
              _openNotifications();
            },
          ),
          if (notif.unreadCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: bg, width: 1.5)),
                child: Center(child: Text('${notif.unreadCount}', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))),
              ),
            ),
        ]),
        Stack(children: [
          IconButton(icon: Icon(Icons.shopping_cart_outlined, color: textColor, size: 24), onPressed: () => _openCart(cart)),
          if (cart.itemCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle, border: Border.all(color: bg, width: 1.5)),
                child: Center(child: Text('${cart.itemCount}', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))),
              ),
            ),
        ]),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Drawer ───────────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context, AppState state, bool isDark) {
    final t = state.t;
    final bg = isDark ? const Color(0xFF1E2A38) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    return Drawer(
      backgroundColor: bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    backgroundImage: state.userAvatarPath != null
                        ? (state.userAvatarPath!.startsWith('http')
                        ? NetworkImage(state.userAvatarPath!) as ImageProvider
                        : FileImage(File(state.userAvatarPath!)))
                        : null,
                    child: state.userAvatarPath == null
                        ? Text(state.userName.isNotEmpty ? state.userName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text('${state.salutation}, ${state.userName}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(state.userEmail, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _drawerItem(Icons.home_outlined, t('home'), () => Navigator.pop(context), textColor),
            _drawerItem(Icons.category_outlined, t('categories'), () => Navigator.pop(context), textColor),
            _drawerItem(Icons.local_shipping_outlined, t('tracking'), () {
              Navigator.pop(context);
              _goToTracking(context);
            }, textColor),
            _drawerItem(Icons.favorite_border_outlined, t('favorites'), () => Navigator.pop(context), textColor),
            _drawerItem(Icons.receipt_long_outlined, t('orders'), () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
            }, textColor),
            Divider(height: 24, indent: 16, endIndent: 16, color: isDark ? Colors.white10 : null),
            _drawerItem(Icons.settings_outlined, t('settings'), () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }, textColor),
            _drawerItem(Icons.help_outline, t('help'), () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));
            }, textColor),
            const Spacer(),
            _drawerItem(Icons.logout, t('logout'), () {
              Navigator.pop(context);
              _confirmLogout(context, state);
            }, Colors.red),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap, Color color) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500)),
      onTap: onTap,
      dense: true,
    );
  }

  // ── Bottom Nav ───────────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context, AppState state, bool isDark) {
    final t = state.t;
    final bg = isDark ? const Color(0xFF1E2A38) : Colors.white;
    final inactiveColor = isDark ? Colors.white38 : Colors.grey;
    final items = [
      {'icon': Icons.home_outlined, 'label': t('home')},
      {'icon': Icons.shopping_bag_outlined, 'label': t('orders')},
      {'icon': Icons.local_shipping_outlined, 'label': t('tracking')},
      {'icon': Icons.person_outline, 'label': t('account')},
    ];
    return Container(
      decoration: BoxDecoration(color: bg, boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.07), blurRadius: 12, offset: const Offset(0, -3))]),
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
                    switch (i) {
                      case 1:
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()))
                            .then((_) => setState(() => _currentIndex = 0));
                        break;
                      case 2:
                        _goToTracking(context);
                        setState(() => _currentIndex = 0);
                        break;
                      case 3:
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))
                            .then((_) => setState(() => _currentIndex = 0));
                        break;
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (active)
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                          child: Icon(items[i]['icon'] as IconData, color: Colors.white, size: 18),
                        )
                      else
                        Icon(items[i]['icon'] as IconData, color: inactiveColor, size: 22),
                      const SizedBox(height: 3),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(fontSize: 10, color: active ? AppColors.gold : inactiveColor, fontWeight: active ? FontWeight.bold : FontWeight.normal),
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

  // ── Carte produit ────────────────────────────────────────────────
  Widget _buildProductCard(ProductModel product, String Function(String) t, CartState cart, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E2A38) : Colors.white;
    final imageBg = isDark ? const Color(0xFF14202C) : const Color(0xFFF8F8F8);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.grey;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 170,
                decoration: BoxDecoration(
                  color: imageBg,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                ),
                child: Center(child: Icon(product.icon, size: 72, color: isDark ? Colors.white24 : Colors.grey.shade300)),
              ),
              if (product.badge != null)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(6)),
                    child: Text(product.badge!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => setState(() => product.isFavorite = !product.isFavorite),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: cardBg, shape: BoxShape.circle),
                    child: Icon(product.isFavorite ? Icons.favorite : Icons.favorite_border, size: 18, color: product.isFavorite ? Colors.red : subColor),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.brand, style: TextStyle(fontSize: 11, color: subColor, letterSpacing: 0.4, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(product.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor, height: 1.3)),
                const SizedBox(height: 8),
                Text(product.formattedPrice, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _addToCart(cart, product),
                    icon: const Icon(Icons.shopping_cart_outlined, size: 17, color: Colors.white),
                    label: Text(t('add_cart'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMore(String Function(String) t, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white38 : Colors.grey.shade500;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.keyboard_arrow_down, size: 18, color: textColor),
            label: Text(t('load_more'), style: TextStyle(color: textColor)),
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor,
              side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 6),
          Text('${t('showing')} ${_filtered.length} ${t('of')} 240 ${t('products')}', style: TextStyle(fontSize: 12, color: subColor)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────
  void _goToTracking(BuildContext context) {
    final order = ongoingOrder;
    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pas de livraison en cours'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => LiveTrackingScreen(order: order)));
  }

  void _addToCart(CartState cart, ProductModel product) {
    cart.add(product);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${product.name} ajouté'),
      backgroundColor: AppColors.navy,
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _openNotifications() {
    context.read<NotificationState>().markAllAsRead();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
  }

  void _openCart(CartState cart) {
    final t = context.read<AppState>().t;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ChangeNotifierProvider.value(value: cart, child: _CartSheet(t: t)),
    );
  }

  void _confirmLogout(BuildContext context, AppState state) {
    final t = state.t;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('logout_title')),
        content: Text(t('logout_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t('cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t('yes_logout'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet panier ────────────────────────────────────────────
class _CartSheet extends StatelessWidget {
  final String Function(String) t;
  const _CartSheet({required this.t});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          if (cart.isEmpty) ...[
            Icon(Icons.shopping_cart_outlined, size: 48, color: isDark ? Colors.white24 : Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(t('cart_empty'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
          ] else ...[
            ...cart.items.map((item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(item.product.icon, color: AppColors.gold),
              title: Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
              subtitle: Text('Qté: ${item.quantity}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
              trailing: Text(item.product.formattedPrice, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
            )),
            Divider(color: isDark ? Colors.white10 : null),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(t('view_cart'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Bottom sheet notifications ──────────────────────────────────────
class _NotifSheet extends StatelessWidget {
  const _NotifSheet();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final notif = context.watch<NotificationState>();
    final t = state.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.grey.shade500;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(t('notifications_title'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          if (notif.notifications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Aucune notification', style: TextStyle(color: subColor))),
            )
          else
            ...notif.notifications.map((n) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: !n.isRead ? AppColors.gold.withOpacity(0.15) : (isDark ? Colors.white10 : Colors.grey.shade100), shape: BoxShape.circle),
                child: Icon(n.icon, color: !n.isRead ? AppColors.gold : subColor, size: 22),
              ),
              title: Text(n.title, style: TextStyle(fontSize: 13, fontWeight: !n.isRead ? FontWeight.bold : FontWeight.normal, color: textColor)),
              subtitle: Text(n.body, style: TextStyle(fontSize: 12, color: subColor)),
              trailing: Text(n.timeAgo, style: TextStyle(fontSize: 11, color: subColor)),
            )),
        ],
      ),
    );
  }
}