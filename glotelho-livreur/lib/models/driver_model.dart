import 'package:glotelho_livreur/models/vehicle_model.dart';

/// Statut de validation du compte livreur par le manager.
enum DriverStatus { pending, approved, rejected }

/// Disponibilité hebdomadaire du livreur.
class Availability {
  final String jour;
  final String heureDebut;
  final String heureFin;

  Availability({required this.jour, required this.heureDebut, required this.heureFin});

  Map<String, dynamic> toJson() => {'jour': jour, 'heureDebut': heureDebut, 'heureFin': heureFin};

  factory Availability.fromJson(Map<String, dynamic> json) => Availability(
    jour: json['jour'] ?? '',
    heureDebut: json['heureDebut'] ?? '',
    heureFin: json['heureFin'] ?? '',
  );
}

class DriverModel {
  final String id;
  final String nom;
  final String prenom;
  final DateTime dateNaissance;
  final String telephone;
  final String email;
  String? photoPath;
  final String adresseResidence;

  // Identité
  final String cniNumero;
  String? cniRectoPath;
  String? cniVersoPath;
  String? permisPath;

  // Véhicule
  final VehicleModel vehicule;

  // Disponibilités
  final List<Availability> disponibilites;

  // Mobile Money
  final String mobileMoneyNumero;
  final String mobileMoneyTitulaire;

  // Statut & finances
  final DriverStatus status;
  final double soldeCommission;
  final double emprunt;
  final double note;

  // Caution
  final bool cautionPayee;
  final double cautionMontant;
  final DateTime? dateActivation;
  final int? joursRestantsAvantSuspension;

  bool get isVerified => status == DriverStatus.approved;

  DriverModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.dateNaissance,
    required this.telephone,
    required this.email,
    this.photoPath,
    required this.adresseResidence,
    required this.cniNumero,
    this.cniRectoPath,
    this.cniVersoPath,
    this.permisPath,
    required this.vehicule,
    required this.disponibilites,
    required this.mobileMoneyNumero,
    required this.mobileMoneyTitulaire,
    this.status = DriverStatus.pending,
    this.soldeCommission = 0,
    this.emprunt = 0,
    this.note = 0,
    this.cautionPayee = false,
    this.cautionMontant = 50000,
    this.dateActivation,
    this.joursRestantsAvantSuspension,
  });

  String get nomComplet => '$prenom $nom';

  factory DriverModel.fromJson(Map<String, dynamic> json) => DriverModel(
    id: json['_id'] ?? json['id'] ?? '',
    nom: json['nom'] ?? '',
    prenom: json['prenom'] ?? '',
    dateNaissance: DateTime.tryParse(json['dateNaissance'] ?? '') ?? DateTime.now(),
    telephone: json['telephone'] ?? '',
    email: json['email'] ?? '',
    photoPath: json['photoUrl'],
    adresseResidence: json['adresseResidence'] ?? '',
    cniNumero: json['cniNumero'] ?? '',
    cniRectoPath: json['cniRectoUrl'],
    cniVersoPath: json['cniVersoUrl'],
    permisPath: json['permisUrl'],
    vehicule: VehicleModel.fromJson(json['vehicule'] ?? {}),
    disponibilites: (json['disponibilites'] as List<dynamic>? ?? [])
        .map((d) => Availability.fromJson(d))
        .toList(),
    mobileMoneyNumero: json['mobileMoneyNumero'] ?? '',
    mobileMoneyTitulaire: json['mobileMoneyTitulaire'] ?? '',
    status: _statusFromString(json['status']),
    soldeCommission: (json['soldeCommission'] ?? 0).toDouble(),
    emprunt: (json['emprunt'] ?? 0).toDouble(),
    note: (json['note'] ?? 0).toDouble(),
    // Caution — nouveaux champs du backend Glotelho
    cautionPayee: json['cautionPayee'] == true || json['cautionPayee'] == 1,
    cautionMontant: (json['cautionMontant'] ?? 50000).toDouble(),
    dateActivation: json['dateActivation'] != null
        ? DateTime.tryParse(json['dateActivation'].toString())
        : null,
    joursRestantsAvantSuspension: json['joursRestantsAvantSuspension'] as int?,
  );

  static DriverStatus _statusFromString(String? s) {
    switch (s) {
      case 'approved':
        return DriverStatus.approved;
      case 'rejected':
        return DriverStatus.rejected;
      default:
        return DriverStatus.pending;
    }
  }
}