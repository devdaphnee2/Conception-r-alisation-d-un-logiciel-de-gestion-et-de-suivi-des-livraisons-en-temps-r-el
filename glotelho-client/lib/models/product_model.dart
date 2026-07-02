import 'package:flutter/material.dart';

/// Modèle produit affiché dans le catalogue (page d'accueil, recherche...).
/// `icon` et `imageUrl` sont optionnels : tant que l'API catalogue n'est
/// pas branchée, on affiche une icône de remplacement (placeholder).
class ProductModel {
  final int id;
  final String brand;
  final String name;
  final int price; // en FCFA
  final IconData icon;
  final String? imageUrl;
  final String? badge;
  final String? category;
  bool isFavorite;

  ProductModel({
    required this.id,
    required this.brand,
    required this.name,
    required this.price,
    required this.icon,
    this.imageUrl,
    this.badge,
    this.category,
    this.isFavorite = false,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      brand: json['brand'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      icon: Icons.inventory_2_outlined,
      imageUrl: json['image_url'],
      badge: json['badge'],
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'name': name,
      'price': price,
      'image_url': imageUrl,
      'badge': badge,
      'is_favorite': isFavorite,
    };
  }

  /// Prix formaté, ex: "849 000 FCFA"
  String get formattedPrice =>
      '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
}