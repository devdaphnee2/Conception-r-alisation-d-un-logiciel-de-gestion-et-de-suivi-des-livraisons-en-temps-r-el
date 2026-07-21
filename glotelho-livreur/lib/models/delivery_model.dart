import 'package:url_launcher/url_launcher.dart';

enum DeliveryStatus { pending, assigned, validated, inProgress, suspended, delivered, cancelled }

class DeliveryModel {
  final String id;
  final String? deliveryPersonId; // ID du livreur dans delivery_persons
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
    // OTP depuis confirmations
    String? otp;
    final confs = json['confirmations'] as List?;
    if (confs != null && confs.isNotEmpty) {
      otp = confs[0]['otp_code']?.toString();
    }

    // Nom client
    final clientNom = json['client_nom']?.toString().trim().isNotEmpty == true
        ? json['client_nom'].toString().trim()
        : json['clientNom']?.toString().trim().isNotEmpty == true
            ? json['clientNom'].toString().trim()
            : 'Client';

    // Téléphone client
    final clientTel = json['client_telephone']?.toString() ??
        json['clientTelephone']?.toString() ?? '';

    // Adresse
    final adresse = json['delivery_address']?.toString() ??
        json['adresseLivraison']?.toString() ?? '';

    // Montant
    final montant = (json['amount_to_collect'] ?? json['montant'] ?? 0).toDouble();

    // Frais livraison
    final frais = (json['frais_livraison'] ?? json['fraisLivraison'] ?? 0).toDouble();

    // Dates
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
      latitude           : (json['latitude']  ?? 0).toDouble(),
      longitude          : (json['longitude'] ?? 0).toDouble(),
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