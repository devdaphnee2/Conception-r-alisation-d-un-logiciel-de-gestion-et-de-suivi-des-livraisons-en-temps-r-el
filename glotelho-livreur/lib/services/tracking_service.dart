import '../models/delivery_model.dart';

/// Service de suivi des livraisons du jour — MOCK en attendant le backend.
class TrackingService {
  static const bool _useMock = true;

  /// Vérifie le code de clôture envoyé par le manager au client.
  /// MOCK : accepte "1234" en attendant le backend.
  static Future<bool> verifierCodeCloture(String deliveryId, String code) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (_useMock) {
      return code.trim() == '1234';
    }
    // TODO : POST /drivers/me/deliveries/$deliveryId/close  { code }
    throw UnimplementedError();
  }

  static Future<List<DeliveryModel>> getTodayDeliveries() async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return [
        DeliveryModel(
          id: '1',
          clientNom: 'Sophie Martin',
          clientTelephone: '652332745',
          adresseLivraison: 'Rue des Palmiers, Bonapriso',
          latitude: 4.0384,
          longitude: 9.7043,
          montant: 25000,
          fraisLivraison: 2000,
          status: DeliveryStatus.delivered,
          dateCreation: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        DeliveryModel(
          id: '2',
          clientNom: 'Le Petit Gourmet',
          clientTelephone: '693598665',
          adresseLivraison: 'Avenue de Gaulle, Akwa',
          latitude: 4.0511,
          longitude: 9.7679,
          montant: 12000,
          fraisLivraison: 1500,
          status: DeliveryStatus.cancelled,
          dateCreation: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        DeliveryModel(
          id: '3',
          clientNom: 'Jean Bosco',
          clientTelephone: '620119173',
          adresseLivraison: 'Carrefour Ndogpassi',
          latitude: 4.0250,
          longitude: 9.7420,
          montant: 8000,
          fraisLivraison: 1000,
          status: DeliveryStatus.inProgress,
          dateCreation: DateTime.now().subtract(const Duration(minutes: 20)),
        ),
      ];
    }
    // TODO : appel réel GET /drivers/me/deliveries?date=today
    throw UnimplementedError();
  }
}