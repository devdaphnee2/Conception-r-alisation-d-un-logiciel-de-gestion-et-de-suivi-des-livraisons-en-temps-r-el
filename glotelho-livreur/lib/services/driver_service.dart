import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/driver_model.dart';

class DriverService {
  /// Récupère le profil complet du livreur connecté (avec son statut).
  static Future<DriverModel?> fetchProfile() async {
    try {
      final response = await ApiService.dio.get('/drivers/me');
      if (response.statusCode == 200) {
        return DriverModel.fromJson(response.data['data'] ?? response.data);
      }
      return null;
    } on DioException {
      return null;
    }
  }
}