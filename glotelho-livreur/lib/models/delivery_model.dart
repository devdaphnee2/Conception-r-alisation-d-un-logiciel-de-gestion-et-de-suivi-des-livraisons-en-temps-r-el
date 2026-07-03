/// Statut d'une livraison (point 9 : livrée, en_cours, annulée).
enum DeliveryStatus { pending, inProgress, suspended, delivered, cancelled }

class DeliveryModel {
  final String id;
  final String clientNom;
  final String clientTelephone;
  String adresseLivraison; // modifiable par le livreur (point 7)
  final double latitude;
  final double longitude;
  final double montant;
  final double fraisLivraison;
  DeliveryStatus status;
  final DateTime dateCreation;
  DateTime? dateLivraison;
  String? modifiedAddressNote; // note obligatoire si adresse modifiée (point 7)
  bool isSuspended; // point 4
  String? signaturePath; // point 6

  DeliveryModel({
    required this.id,
    required this.clientNom,
    required this.clientTelephone,
    required this.adresseLivraison,
    required this.latitude,
    required this.longitude,
    required this.montant,
    required this.fraisLivraison,
    this.status = DeliveryStatus.pending,
    required this.dateCreation,
    this.dateLivraison,
    this.modifiedAddressNote,
    this.isSuspended = false,
    this.signaturePath,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) => DeliveryModel(
    id: json['_id'] ?? json['id'] ?? '',
    clientNom: json['clientNom'] ?? '',
    clientTelephone: json['clientTelephone'] ?? '',
    adresseLivraison: json['adresseLivraison'] ?? '',
    latitude: (json['latitude'] ?? 0).toDouble(),
    longitude: (json['longitude'] ?? 0).toDouble(),
    montant: (json['montant'] ?? 0).toDouble(),
    fraisLivraison: (json['fraisLivraison'] ?? 0).toDouble(),
    status: _statusFromString(json['status']),
    dateCreation: DateTime.tryParse(json['dateCreation'] ?? '') ?? DateTime.now(),
    dateLivraison: json['dateLivraison'] != null ? DateTime.tryParse(json['dateLivraison']) : null,
    modifiedAddressNote: json['modifiedAddressNote'],
    isSuspended: json['isSuspended'] ?? false,
    signaturePath: json['signatureUrl'],
  );

  static DeliveryStatus _statusFromString(String? s) {
    switch (s) {
      case 'in_progress':
        return DeliveryStatus.inProgress;
      case 'suspended':
        return DeliveryStatus.suspended;
      case 'delivered':
        return DeliveryStatus.delivered;
      case 'cancelled':
        return DeliveryStatus.cancelled;
      default:
        return DeliveryStatus.pending;
    }
  }
}