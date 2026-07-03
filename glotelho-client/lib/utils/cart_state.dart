import 'package:flutter/material.dart';
import '../models/product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  int get subtotal => product.price * quantity;
}

/// CartState — panier partagé dans toute l'application.
/// Évite de perdre le contenu du panier quand on navigue entre écrans.
class CartState extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  int get total => _items.fold(0, (sum, i) => sum + i.subtotal);

  bool get isEmpty => _items.isEmpty;

  void add(ProductModel product) {
    final index = _items.indexWhere((i) => i.product.id == product.id);
    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void remove(int productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}