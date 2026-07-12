/// Une demande de course envoyée par le manager au livreur.
/// (Aujourd'hui simulée localement, demain reçue via Firebase — même structure.)
class DeliveryRequestModel {
  final String id;
  final String clientNom;
  final String clientTelephone;
  final String adresseLivraison;
  final String articles;
  final double montant;
  final double fraisLivraison;
  final String managerNom;
  final double distanceKm;

  DeliveryRequestModel({
    required this.id,
    required this.clientNom,
    required this.clientTelephone,
    required this.adresseLivraison,
    required this.articles,
    required this.montant,
    required this.fraisLivraison,
    required this.managerNom,
    required this.distanceKm,
  });

  factory DeliveryRequestModel.fromJson(Map<String, dynamic> json) => DeliveryRequestModel(
    id: json['id']?.toString() ?? '',
    clientNom: json['clientNom'] ?? '',
    clientTelephone: json['clientTelephone'] ?? '',
    adresseLivraison: json['adresseLivraison'] ?? '',
    articles: json['articles'] ?? '',
    montant: (json['montant'] ?? 0).toDouble(),
    fraisLivraison: (json['fraisLivraison'] ?? 0).toDouble(),
    managerNom: json['managerNom'] ?? '',
    distanceKm: (json['distanceKm'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientNom': clientNom,
    'clientTelephone': clientTelephone,
    'adresseLivraison': adresseLivraison,
    'articles': articles,
    'montant': montant,
    'fraisLivraison': fraisLivraison,
    'managerNom': managerNom,
    'distanceKm': distanceKm,
  };
}