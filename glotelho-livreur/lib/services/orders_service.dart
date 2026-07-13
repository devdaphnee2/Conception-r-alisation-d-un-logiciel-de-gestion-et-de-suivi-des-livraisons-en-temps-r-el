import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/order_model.dart';

class OrdersService {

  /// Courses en attente d'acceptation pour ce livreur
  static Future<List<OrderModel>> getOrders() async {
    try {
      final response = await ApiService.dio.get('/drivers/courses');
      final List data = response.data ?? [];
      return data.map((json) => OrderModel(
        id         : json['id']?.toString() ?? '',
        clientName : json['client_nom'] ?? '',
        address    : json['delivery_address'] ?? '',
        lat        : 4.0580,
        lng        : 9.7400,
        paymentType: 'Especes',
        total      : (json['amount_to_collect'] ?? 0).toDouble(),
        products   : (json['delivery_items'] as List? ?? [])
            .map((i) => '${i['product_name']} x${i['quantity'] ?? 1}')
            .join(' · '),
        date       : DateTime.tryParse(json['creation_date'] ?? '') ?? DateTime.now(),
        status     : _mapStatus(json['status']),
      )).toList();
    } catch (_) {
      return [];
    }
  }

  /// Accepter une course
  static Future<bool> accepterCourse(String courseId) async {
    try {
      final response = await ApiService.dio.post('/drivers/courses/$courseId/accepter');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Refuser une course
  static Future<bool> refuserCourse(String courseId) async {
    try {
      final response = await ApiService.dio.post('/drivers/courses/$courseId/refuser');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static OrderStatus _mapStatus(String? s) {
    switch (s) {
      case 'Livr_'   : return OrderStatus.livree;
      case 'Annul_'  : return OrderStatus.annulee;
      case 'En_cours': return OrderStatus.enCours;
      default        : return OrderStatus.nouvelle;
    }
  }

  static Color statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.livree  : return const Color(0xFF2ECC71);
      case OrderStatus.annulee : return const Color(0xFFE74C3C);
      case OrderStatus.enCours : return const Color(0xFF3498DB);
      case OrderStatus.nouvelle: return const Color(0xFFE0A400);
    }
  }

  static String statusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.livree  : return 'Livrée';
      case OrderStatus.annulee : return 'Annulée';
      case OrderStatus.enCours : return 'En cours';
      case OrderStatus.nouvelle: return 'Nouvelle';
    }
  }
}
