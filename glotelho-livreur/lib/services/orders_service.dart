import 'package:flutter/material.dart';
import '../models/order_model.dart';

class OrdersService {
  static Future<List<OrderModel>> getOrders() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      OrderModel(
        id: '1234',
        clientName: 'Le Petit Gourmet',
        address: 'Avenue de Gaulle, Akwa',
        lat: 4.0489, lng: 9.7010,
        paymentType: 'Carte',
        total: 277.0,
        products: 'Lait bouteille x1 · Déodorant Nivea x2 · Nestlé Pure Life 1.5L x1',
        date: DateTime(2026, 6, 24, 12, 30),
        status: OrderStatus.annulee,
      ),
      OrderModel(
        id: '1235',
        clientName: 'Jean Bosco',
        address: 'Carrefour Ndogpassi',
        lat: 4.0290, lng: 9.7850,
        paymentType: 'Espèces',
        total: 5000.0,
        products: 'Riz 5kg · Huile 5L · Sardines x1',
        date: DateTime(2026, 6, 24, 11, 0),
        status: OrderStatus.enCours,
      ),
      OrderModel(
        id: '1236',
        clientName: 'Aïcha Ngono',
        address: 'Bonapriso, Rue Njo-Njo',
        lat: 4.0350, lng: 9.6980,
        paymentType: 'Mobile Money',
        total: 15000.0,
        products: 'Riz parfumé 5kg · Huile végétale 5L',
        date: DateTime(2026, 6, 24, 9, 15),
        status: OrderStatus.nouvelle,
      ),
      OrderModel(
        id: '1237',
        clientName: 'Fatou Diallo',
        address: 'Bonamoussadi, Carrefour Kotto',
        lat: 4.0900, lng: 9.7400,
        paymentType: 'Carte',
        total: 32000.0,
        products: 'Machine à laver 6kg · Kit installation',
        date: DateTime(2026, 6, 23, 16, 0),
        status: OrderStatus.livree,
      ),
    ];
  }

  static Color statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.livree:
        return const Color(0xFF2ECC71);
      case OrderStatus.annulee:
        return const Color(0xFFE74C3C);
      case OrderStatus.enCours:
        return const Color(0xFF3498DB);
      case OrderStatus.nouvelle:
        return const Color(0xFFE0A400);
    }
  }

  static String statusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.livree:
        return 'Livrée';
      case OrderStatus.annulee:
        return 'Annulée';
      case OrderStatus.enCours:
        return 'En cours';
      case OrderStatus.nouvelle:
        return 'Nouvelle';
    }
  }
}

