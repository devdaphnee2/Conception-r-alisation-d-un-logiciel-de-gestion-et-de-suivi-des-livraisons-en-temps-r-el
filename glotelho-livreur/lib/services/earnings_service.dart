import '../models/activity_model.dart';

class EarningsSummary {
  final double soldeCommission;
  final double emprunt;
  final double totalGains;
  final double totalVentes;

  EarningsSummary({
    required this.soldeCommission,
    required this.emprunt,
    required this.totalGains,
    required this.totalVentes,
  });
}

class EarningsService {
  static const bool _useMock = true;

  static Future<EarningsSummary> getSummary() async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return EarningsSummary(
        soldeCommission: 4781.96,
        emprunt: 2000.0,      // non nul pour tester la carte Emprunt
        totalGains: 35100,
        totalVentes: 237000,
      );
    }
    throw UnimplementedError();
  }

  /// Chaque livraison est fournie avec sa commission liée (linkedId croisé).
  static Future<List<ActivityModel>> getActivities({int limit = 0}) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      final all = _buildMockActivities();
      return limit > 0 ? all.take(limit).toList() : all;
    }
    throw UnimplementedError();
  }

  static Future<bool> repayDebt() async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    }
    throw UnimplementedError();
  }

  static List<ActivityModel> _buildMockActivities() {
    final list = <ActivityModel>[];

    void addPair({
      required String delivId,
      required String commId,
      required DateTime date,
      required double montantProduits,
      required double commission,
      required String manager,
      required String client,
      required String phone,
      required String address,
      required String articles,
      required String quantite,
      required String payment,
      required String zone,
      required String prise,
      required String livre,
      required String note,
      required double soldeAvant,
      required double soldeApres,
    }) {
      // Commission (affichée au-dessus, comme sur les captures)
      list.add(ActivityModel(
        id: commId,
        type: ActivityType.commission,
        amount: commission,
        date: date,
        manager: manager,
        linkedId: delivId,
        soldeAvant: soldeAvant,
        soldeApres: soldeApres,
        // recopie des infos source pour la section TRANSACTION SOURCE
        clientName: client,
        clientPhone: phone,
        fraisLivraison: commission,
      ));
      // Livraison
      list.add(ActivityModel(
        id: delivId,
        type: ActivityType.livraison,
        amount: montantProduits,
        date: date.subtract(const Duration(minutes: 1)),
        manager: manager,
        linkedId: commId,
        clientName: client,
        clientPhone: phone,
        clientAddress: address,
        articles: articles,
        quantite: quantite,
        paymentMethod: payment,
        zone: zone,
        priseEnCharge: prise,
        heureLivraison: livre,
        note: note,
        fraisLivraison: commission,
      ));
    }

    addPair(
      delivId: '29fcfaee-0669-4845-b7db-5aee3944362c',
      commId: 'faf8e58b-9948-43f9-a29f-e3dd94984ae3',
      date: DateTime(2026, 7, 2, 17, 48),
      montantProduits: 15000,
      commission: 1500,
      manager: 'Jean Kamga',
      client: 'Aïcha Ngono',
      phone: '693 598 665',
      address: 'Bonapriso, Rue Njo-Njo, Douala',
      articles: 'Riz parfumé 5kg · Huile végétale 5L · Sardines (carton)',
      quantite: '1 · 2 · 1',
      payment: 'Espèces à la livraison',
      zone: 'Bonapriso · 4,2 km',
      prise: '17:05',
      livre: '17:48',
      note: 'Appeler avant d\'arriver au portail.',
      soldeAvant: 3281.96,
      soldeApres: 4781.96,
    );

    addPair(
      delivId: '7bd104c2-51aa-49e0-88fe-2f1a90cbe771',
      commId: 'a1c9d0e2-77b3-42aa-9c14-6d5e2f0ab933',
      date: DateTime(2026, 7, 1, 21, 55),
      montantProduits: 9500,
      commission: 950,
      manager: 'Jean Kamga',
      client: 'Blaise Etoa',
      phone: '620 119 173',
      address: 'Akwa, Boulevard de la Liberté, Douala',
      articles: 'Poulet braisé · Plantains mûrs · Jus de bissap 1L',
      quantite: '2 · 3 · 1',
      payment: 'Mobile Money',
      zone: 'Akwa · 2,8 km',
      prise: '21:20',
      livre: '21:55',
      note: 'Immeuble bleu, 3e étage, porte gauche.',
      soldeAvant: 2331.96,
      soldeApres: 3281.96,
    );

    addPair(
      delivId: '5e02fb47-90c1-4a72-b0d6-c4471e8ad210',
      commId: 'c3f7a812-6e44-4b90-a1d2-88b0e5c47f6a',
      date: DateTime(2026, 6, 17, 12, 0),
      montantProduits: 32000,
      commission: 3000,
      manager: 'Sandrine Mbarga',
      client: 'Fatou Diallo',
      phone: '697 445 012',
      address: 'Bonamoussadi, Carrefour Kotto, Douala',
      articles: 'Machine à laver 6kg · Kit installation',
      quantite: '1 · 1',
      payment: 'Payé en ligne',
      zone: 'Bonamoussadi · 7,6 km',
      prise: '10:45',
      livre: '12:00',
      note: 'Livraison à l\'étage, prévoir aide au portage.',
      soldeAvant: -669.04,
      soldeApres: 2331.96,
    );

    return list;
  }
}