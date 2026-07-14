enum DeliveryStatus { pending, inProgress, suspended, delivered, cancelled }

class DeliveryModel {
  final String id;
  final String clientNom;
  final String clientTelephone;
  String adresseLivraison;
  final double latitude;
  final double longitude;
  final double montant;
  final double fraisLivraison;
  DeliveryStatus status;
  final DateTime dateCreation;
  DateTime? dateLivraison;
  String? modifiedAddressNote;
  bool isSuspended;
  String? signaturePath;
  String? otpCode;
  String? zoneBloc;
  String? instructions;

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
    this.otpCode,
    this.zoneBloc,
    this.instructions,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    // Recuperer OTP depuis confirmations
    String? otp;
    final confs = json['confirmations'] as List?;
    if (confs != null && confs.isNotEmpty) {
      otp = confs[0]['otp_code']?.toString();
    }

    return DeliveryModel(
      id              : json['_id']?.toString() ?? json['id']?.toString() ?? '',
      clientNom       : json['client_nom'] ?? json['clientNom'] ?? '',
      clientTelephone : json['client_telephone'] ?? json['clientTelephone'] ?? '',
      adresseLivraison: json['delivery_address'] ?? json['adresseLivraison'] ?? '',
      latitude        : (json['latitude'] ?? 0).toDouble(),
      longitude       : (json['longitude'] ?? 0).toDouble(),
      montant         : (json['amount_to_collect'] ?? json['montant'] ?? 0).toDouble(),
      fraisLivraison  : (json['fraisLivraison'] ?? 0).toDouble(),
      status          : _statusFromString(json['status']),
      dateCreation    : DateTime.tryParse(json['creation_date'] ?? json['dateCreation'] ?? '') ?? DateTime.now(),
      dateLivraison   : json['delivery_date'] != null ? DateTime.tryParse(json['delivery_date'].toString()) : null,
      isSuspended     : json['status'] == 'Suspendu',
      signaturePath   : json['signatureUrl'],
      otpCode         : otp,
      zoneBloc        : json['zone_bloc'],
      instructions    : json['delivery_instructions'],
    );
  }

  static DeliveryStatus _statusFromString(String? s) {
    switch (s) {
      case 'En_cours' :
      case 'in_progress': return DeliveryStatus.inProgress;
      case 'Suspendu' :
      case 'suspended'  : return DeliveryStatus.suspended;
      case 'Livr_'    :
      case 'delivered'  : return DeliveryStatus.delivered;
      case 'Annul_'   :
      case 'cancelled'  : return DeliveryStatus.cancelled;
      default           : return DeliveryStatus.pending;
    }
  }
}
