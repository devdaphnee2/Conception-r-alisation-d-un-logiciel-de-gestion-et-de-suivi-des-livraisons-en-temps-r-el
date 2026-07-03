class VehicleModel {
  final String type; // ex: Scooter, Moto, Voiture, Tricycle
  final String marque;
  final String modele;
  final String immatriculation;
  String? photoPath;
  final String assuranceNumero;
  final DateTime assuranceExpiration;

  VehicleModel({
    required this.type,
    required this.marque,
    required this.modele,
    required this.immatriculation,
    this.photoPath,
    required this.assuranceNumero,
    required this.assuranceExpiration,
  });

  bool get assuranceExpiree => assuranceExpiration.isBefore(DateTime.now());

  Map<String, dynamic> toJson() => {
    'type': type,
    'marque': marque,
    'modele': modele,
    'immatriculation': immatriculation,
    'assuranceNumero': assuranceNumero,
    'assuranceExpiration': assuranceExpiration.toIso8601String(),
  };

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
    type: json['type'] ?? '',
    marque: json['marque'] ?? '',
    modele: json['modele'] ?? '',
    immatriculation: json['immatriculation'] ?? '',
    photoPath: json['photoUrl'],
    assuranceNumero: json['assuranceNumero'] ?? '',
    assuranceExpiration: DateTime.tryParse(json['assuranceExpiration'] ?? '') ?? DateTime.now(),
  );
}