enum ActivityType { commission, retrait, depot }

class ActivityModel {
  final String id;
  final ActivityType type;
  final String label; // "Commission", "Orange", "Blue"...
  final String subLabel; // "GLOTELHO", numéro de téléphone...
  final double amount; // positif ou négatif
  final DateTime date;
  final String? provider; // "orange", "mtn", null pour commission

  ActivityModel({
    required this.id,
    required this.type,
    required this.label,
    required this.subLabel,
    required this.amount,
    required this.date,
    this.provider,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) => ActivityModel(
    id: json['_id'] ?? json['id'] ?? '',
    type: _typeFromString(json['type']),
    label: json['label'] ?? '',
    subLabel: json['subLabel'] ?? '',
    amount: (json['amount'] ?? 0).toDouble(),
    date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    provider: json['provider'],
  );

  static ActivityType _typeFromString(String? s) {
    switch (s) {
      case 'retrait':
        return ActivityType.retrait;
      case 'depot':
        return ActivityType.depot;
      default:
        return ActivityType.commission;
    }
  }
}