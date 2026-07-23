import 'package:url_launcher/url_launcher.dart';

enum DeliveryStatus { pending, assigned, validated, inProgress, suspended, delivered, cancelled }

// Convertit une valeur num OU String (cas des Decimal Prisma) en double
double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class DeliveryModel {
  final String id;
  final String? deliveryPersonId;
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
  String? commercantNom;
  String? commercantTelephone;
  String? commercantAdresse;

  DeliveryModel({
    required this.id,
    this.deliveryPersonId,
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
    this.commercantNom,
    this.commercantTelephone,
    this.commercantAdresse,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    String? otp;
    final confs = json['confirmations'] as List?;
    if (confs != null && confs.isNotEmpty) {
      otp = confs[0]['otp_code']?.toString();
    }

    final clientNom = json['client_nom']?.toString().trim().isNotEmpty == true
        ? json['client_nom'].toString().trim()
        : json['clientNom']?.toString().trim().isNotEmpty == true
            ? json['clientNom'].toString().trim()
            : 'Client';

    final clientTel = json['client_telephone']?.toString() ??
        json['clientTelephone']?.toString() ?? '';

    final adresse = json['delivery_address']?.toString() ??
        json['adresseLivraison']?.toString() ?? '';

    // Montant et frais — utilisent maintenant _toDouble() pour gérer
    // les Decimal Prisma retournés en String (ex: "20") sans planter.
    final montant = _toDouble(json['amount_to_collect'] ?? json['montant']);
    final frais   = _toDouble(json['frais_livraison'] ?? json['fraisLivraison']);

    final dateCreation = DateTime.tryParse(
          json['creation_date']?.toString() ??
          json['dateCreation']?.toString() ?? '') ??
        DateTime.now();

    final dateLivraison = json['delivery_date'] != null
        ? DateTime.tryParse(json['delivery_date'].toString())
        : json['dateLivraison'] != null
            ? DateTime.tryParse(json['dateLivraison'].toString())
            : null;

    return DeliveryModel(
      id                 : json['_id']?.toString() ?? json['id']?.toString() ?? '',
      deliveryPersonId   : json['delivery_person_id']?.toString(),
      clientNom          : clientNom,
      clientTelephone    : clientTel,
      adresseLivraison   : adresse,
      latitude           : _toDouble(json['latitude']),
      longitude          : _toDouble(json['longitude']),
      montant            : montant,
      fraisLivraison     : frais,
      status             : _statusFromString(json['status']),
      dateCreation       : dateCreation,
      dateLivraison      : dateLivraison,
      isSuspended        : json['status'] == 'Suspendu' || json['status'] == 'suspended',
      signaturePath      : json['signatureUrl']?.toString() ?? json['signature_url']?.toString(),
      otpCode            : otp,
      zoneBloc           : json['zone_bloc']?.toString() ?? json['zoneBloc']?.toString(),
      instructions       : json['delivery_instructions']?.toString() ?? json['instructions']?.toString(),
      commercantNom      : json['commercant_nom']?.toString(),
      commercantTelephone: json['commercant_telephone']?.toString(),
      commercantAdresse  : json['commercant_adresse']?.toString(),
    );
  }

  static DeliveryStatus _statusFromString(String? s) {
    switch (s) {
      case 'En_cours':
      case 'in_progress':
        return DeliveryStatus.inProgress;
      case 'Assign_':
      case 'assigned':
        return DeliveryStatus.assigned;
      case 'Valide_':
      case 'validated':
        return DeliveryStatus.validated;
      case 'Suspendu':
      case 'suspended':
        return DeliveryStatus.suspended;
      case 'Livr_':
      case 'delivered':
        return DeliveryStatus.delivered;
      case 'Annul_':
      case 'cancelled':
        return DeliveryStatus.cancelled;
      default:
        return DeliveryStatus.pending;
    }
  }
}