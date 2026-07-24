import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/delivery_model.dart';

class TrackingService {

  /// Verifie le code OTP de cloture de course
  static Future<bool> verifierCodeCloture(String deliveryId, String code) async {
    try {
      final response = await ApiService.dio.post(
        '/drivers/courses/$deliveryId/cloturer',
        data: { 'otp_code': code },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Liste les livraisons du jour du livreur connecte
  static Future<List<DeliveryModel>> getTodayDeliveries() async {
    try {
      final response = await ApiService.dio.get('/drivers/courses');
      final List data = response.data ?? [];
      debugPrint('[TRACKING] ${data.length} livraisons reçues');
      return data.map((json) => DeliveryModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[TRACKING] ERREUR getTodayDeliveries: $e');
      return [];
    }
  }

  static Future<bool> accepterCourse(String deliveryId) async {
    try {
      final response = await ApiService.dio.post('/drivers/courses/$deliveryId/accepter');
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<bool> refuserCourse(String deliveryId) async {
    try {
      final response = await ApiService.dio.post('/drivers/courses/$deliveryId/refuser');
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// Historique des livraisons terminees
  static Future<List<DeliveryModel>> getHistorique() async {
    try {
      final response = await ApiService.dio.get('/drivers/historique');
      final List data = response.data ?? [];
      return data.map((json) => DeliveryModel.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Demarrer une course
  static Future<Map<String, dynamic>?> demarrerCourse(String deliveryId) async {
    try {
      final response = await ApiService.dio.post('/drivers/courses/$deliveryId/demarrer');
      return response.data;
    } catch (_) {
      return null;
    }
  }

  /// Mettre a jour la position GPS
  static Future<void> updatePosition({
    required String deliveryId,
    required double latitude,
    required double longitude,
    double speed = 0,
  }) async {
    try {
      await ApiService.dio.post('/drivers/courses/$deliveryId/position', data: {
        'latitude' : latitude,
        'longitude': longitude,
        'speed'    : speed,
      });
    } catch (_) {}
  }

  /// Signaler un incident
  static Future<bool> signalerIncident({
    required String deliveryId,
    required String typeIncident,
    String? description,
  }) async {
    try {
      final response = await ApiService.dio.post(
        '/drivers/courses/$deliveryId/incident',
        data: { 'type_incident': typeIncident, 'description': description ?? '' },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}