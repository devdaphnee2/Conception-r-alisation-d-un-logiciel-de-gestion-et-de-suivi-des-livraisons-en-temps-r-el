enum ActivityType { commission, livraison }

/// Une activité = soit une Livraison effectuée, soit la Commission associée.
/// Les deux partagent le même "groupe" via deliveryId <-> commissionId.
class ActivityModel {
  final String id;              // identifiant propre de l'activité
  final ActivityType type;
  final double amount;          // livraison: coût des produits (affiché tel quel)
  // commission: frais de livraison (positif)
  final DateTime date;

  // --- Champs LIVRAISON ---
  final String? clientName;     // nom du client
  final String? clientPhone;    // numéro du client
  final String? clientAddress;  // adresse de livraison
  final String? articles;       // produits à livrer
  final String? quantite;       // quantités correspondantes
  final String? paymentMethod;  // méthode de paiement
  final String? zone;           // zone / distance
  final String? priseEnCharge;  // heure de prise en charge
  final String? heureLivraison; // heure de livraison
  final String? note;           // instructions du client
  final double? fraisLivraison; // = montant de la commission liée

  // --- Champs COMMISSION ---
  final double? soldeAvant;     // solde commission avant incrément
  final double? soldeApres;     // solde commission après incrément

  // --- Liaison entre les deux ---
  final String manager;         // opérateur = manager qui a assigné
  final String? linkedId;       // livraison -> id de sa commission
  // commission -> id de sa livraison (source)

  ActivityModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.manager,
    this.linkedId,
    this.clientName,
    this.clientPhone,
    this.clientAddress,
    this.articles,
    this.quantite,
    this.paymentMethod,
    this.zone,
    this.priseEnCharge,
    this.heureLivraison,
    this.note,
    this.fraisLivraison,
    this.soldeAvant,
    this.soldeApres,
  });

  bool get isCommission => type == ActivityType.commission;
  bool get isLivraison => type == ActivityType.livraison;

  factory ActivityModel.fromJson(Map<String, dynamic> json) => ActivityModel(
    id: json['_id'] ?? json['id'] ?? '',
    type: json['type'] == 'commission'
        ? ActivityType.commission
        : ActivityType.livraison,
    amount: (json['amount'] ?? 0).toDouble(),
    date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    manager: json['manager'] ?? '',
    linkedId: json['linkedId'],
    clientName: json['clientName'],
    clientPhone: json['clientPhone'],
    clientAddress: json['clientAddress'],
    articles: json['articles'],
    quantite: json['quantite'],
    paymentMethod: json['paymentMethod'],
    zone: json['zone'],
    priseEnCharge: json['priseEnCharge'],
    heureLivraison: json['heureLivraison'],
    note: json['note'],
    fraisLivraison: (json['fraisLivraison'])?.toDouble(),
    soldeAvant: (json['soldeAvant'])?.toDouble(),
    soldeApres: (json['soldeApres'])?.toDouble(),
  );
}