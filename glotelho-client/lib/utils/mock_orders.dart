import 'package:flutter/material.dart';

/// Liste de commandes simulées, partagée entre `OrderHistoryScreen` et
/// `HomeScreen` (onglet "Suivi"), le temps que l'API backend (GET /orders)
/// soit disponible. Centraliser ces données ici évite toute incohérence
/// entre les écrans qui en ont besoin.
final List<Map<String, dynamic>> mockOrders = [
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
    // Coordonnées GPS réelles pour la carte de suivi (entrepôt → client)
    'originLat': 3.8667, 'originLng': 11.5167, // Entrepôt Glotelho, Yaoundé Centre-ville
    'destLat': 3.8895, 'destLng': 11.5174,     // Adresse client, Yaoundé Bastos
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

/// Retourne la commande "En cours" la plus récente, ou `null` s'il n'y en a aucune.
/// À remplacer par un appel API (GET /orders?statut=en_cours) plus tard.
Map<String, dynamic>? get ongoingOrder {
  for (final o in mockOrders) {
    if (o['statut'] == 'En cours') return o;
  }
  return null;
}