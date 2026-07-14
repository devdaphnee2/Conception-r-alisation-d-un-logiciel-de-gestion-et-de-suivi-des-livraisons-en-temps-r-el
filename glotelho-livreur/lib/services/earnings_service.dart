import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/activity_model.dart';

class EarningsSummary {
  final double soldeCommission;
  final double emprunt;
  final double totalGains;
  final double totalVentes;

  EarningsSummary({
    required this.soldeCommission,
    required this.emprunt,
    required this.totalGains,
    required this.totalVentes,
  });
}

class EarningsService {

  static Future<EarningsSummary> getSummary() async {
    try {
      final response = await ApiService.dio.get('/drivers/me');
      final data = response.data['data'] ?? response.data;
      return EarningsSummary(
        soldeCommission: (data['soldeCommission'] ?? 0).toDouble(),
        emprunt        : (data['emprunt'] ?? 0).toDouble(),
        totalGains     : (data['soldeCommission'] ?? 0).toDouble(),
        totalVentes    : 0,
      );
    } catch (_) {
      return EarningsSummary(
        soldeCommission: 0,
        emprunt        : 0,
        totalGains     : 0,
        totalVentes    : 0,
      );
    }
  }

  static Future<List<ActivityModel>> getActivities({int limit = 0}) async {
    // Les activites seront chargees depuis l'historique des courses
    try {
      final response = await ApiService.dio.get('/drivers/historique');
      final List data = response.data ?? [];
      final activities = data.map((json) => ActivityModel(
        id            : json['id']?.toString() ?? '',
        type          : ActivityType.livraison,
        amount        : (json['amount_to_collect'] ?? 0).toDouble(),
        date          : DateTime.tryParse(json['creation_date'] ?? '') ?? DateTime.now(),
        clientName    : json['client_nom'] ?? '',
        clientPhone   : json['client_telephone'] ?? '',
        clientAddress : json['delivery_address'] ?? '',
        fraisLivraison: 0,
      )).toList();
      return limit > 0 ? activities.take(limit).toList() : activities;
    } catch (_) {
      return [];
    }
  }

  static Future<bool> repayDebt() async {
    // A implementer quand le module recouvrement sera connecte
    return false;
  }
}
