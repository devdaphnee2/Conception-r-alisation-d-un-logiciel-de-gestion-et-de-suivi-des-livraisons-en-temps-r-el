import 'package:flutter/material.dart';
enum OrderStatus { nouvelle, enCours, livree, annulee }

class OrderModel {
  final String id;
  final String clientName;
  final String address;
  final double lat;
  final double lng;
  final String paymentType;
  final double total;
  final String products;
  final DateTime date;
  final OrderStatus status;

  OrderModel({
    required this.id,
    required this.clientName,
    required this.address,
    required this.lat,
    required this.lng,
    required this.paymentType,
    required this.total,
    required this.products,
    required this.date,
    required this.status,
  });
}