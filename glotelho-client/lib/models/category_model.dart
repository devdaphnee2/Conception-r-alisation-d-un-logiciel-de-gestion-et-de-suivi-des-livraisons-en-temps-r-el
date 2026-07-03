import 'package:flutter/material.dart';

/// Modèle catégorie produit (section "Explorer les catégories").
class CategoryModel {
  final int id;
  final String labelFr;
  final String labelEn;
  final IconData icon;

  const CategoryModel({
    required this.id,
    required this.labelFr,
    required this.labelEn,
    required this.icon,
  });

  String label(String language) => language == 'Français' ? labelFr : labelEn;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      labelFr: json['label_fr'] ?? '',
      labelEn: json['label_en'] ?? json['label_fr'] ?? '',
      icon: Icons.category_outlined,
    );
  }
}

/// Catégories par défaut, utilisées tant que l'API /categories
/// n'est pas branchée sur ApiService.
const List<CategoryModel> defaultCategories = [
  CategoryModel(id: 1, labelFr: 'Électronique', labelEn: 'Electronics', icon: Icons.devices_outlined),
  CategoryModel(id: 2, labelFr: 'Mode', labelEn: 'Fashion', icon: Icons.checkroom_outlined),
  CategoryModel(id: 3, labelFr: 'Maison', labelEn: 'Home', icon: Icons.home_outlined),
  CategoryModel(id: 4, labelFr: 'Téléphones', labelEn: 'Phones', icon: Icons.phone_iphone_outlined),
  CategoryModel(id: 5, labelFr: 'Sports', labelEn: 'Sports', icon: Icons.sports_soccer_outlined),
  CategoryModel(id: 6, labelFr: 'Cuisine', labelEn: 'Kitchen', icon: Icons.kitchen_outlined),
];