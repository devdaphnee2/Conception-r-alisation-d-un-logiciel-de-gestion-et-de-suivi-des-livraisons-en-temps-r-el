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

/// Service des gains/commissions — MOCK en attendant les endpoints backend.
class EarningsService {
  static const bool _useMock = true;

  static Future<EarningsSummary> getSummary() async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return EarningsSummary(
        soldeCommission: 4782.0,
        emprunt: 2000.0, // ← non nul pour tester l'affichage de la carte Emprunt
        totalGains: 35100,
        totalVentes: 237000,
      );
    }
    // TODO : appel réel GET /drivers/me/earnings
    throw UnimplementedError();
  }

  static Future<List<ActivityModel>> getActivities({int limit = 4}) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      final all = [
        ActivityModel(id: '1', type: ActivityType.commission, label: 'Commission', subLabel: 'GLOTELHO', amount: 9.0, date: DateTime(2026, 7, 2, 17, 48)),
        ActivityModel(id: '2', type: ActivityType.retrait, label: 'Orange', subLabel: '693 598 665', amount: -250.0, date: DateTime(2026, 7, 2, 17, 48), provider: 'orange'),
        ActivityModel(id: '3', type: ActivityType.commission, label: 'Commission', subLabel: 'GLOTELHO', amount: 9.5, date: DateTime(2026, 7, 1, 21, 55)),
        ActivityModel(id: '4', type: ActivityType.retrait, label: 'Blue', subLabel: '620 119 173', amount: -100.0, date: DateTime(2026, 7, 1, 21, 54), provider: 'mtn'),
        ActivityModel(id: '5', type: ActivityType.commission, label: 'Commission', subLabel: 'GLOTELHO', amount: 3000.0, date: DateTime(2026, 6, 17, 12, 0)),
        ActivityModel(id: '6', type: ActivityType.retrait, label: 'Orange', subLabel: '693 598 665', amount: -1000.0, date: DateTime(2026, 6, 17, 11, 0), provider: 'orange'),
      ];
      return limit > 0 ? all.take(limit).toList() : all;
    }
    // TODO : appel réel GET /drivers/me/activities
    throw UnimplementedError();
  }

  /// Rembourse l'emprunt en utilisant le solde commission disponible.
  static Future<bool> repayDebt() async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    }
    // TODO : appel réel POST /drivers/me/repay-debt
    throw UnimplementedError();
  }
}