import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../tracking/tracking_screen.dart';

/// Détail d'une commande — vue E-COMMERÇANT (lecture seule) :
/// timeline de progression, infos commande/client, livreur (avec
/// matricule et contact), dates de début/clôture, durée totale,
/// preuve de livraison, litige éventuel lié, et accès au suivi GPS
/// en direct si la livraison est en cours.
///
/// ⚠️ Contrairement à la version manager, il n'y a plus d'actions
/// d'assignation/réassignation/annulation ici : ces opérations
/// relèvent de l'administration Glotelho, pas de l'e-commerçant.
class CommandeDetailScreen extends StatefulWidget {
  final int livraisonId;
  const CommandeDetailScreen({super.key, required this.livraisonId});

  @override
  State<CommandeDetailScreen> createState() => _CommandeDetailScreenState();
}

class _CommandeDetailScreenState extends State<CommandeDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? livraison;
  String? _error;

  static const _statusConfig = {
    'En_attente': (Color(0xFFFFDEA9), Color(0xFF483100), 'Course en attente', 1),
    'Assigné': (Color(0xFFB5CCFF), Color(0xFF3E5682), 'Assigné', 2),
    'En_cours': (Color(0xFF6AA1E3), Color(0xFF003762), 'En cours', 3),
    'Livré': (Color(0xFFC8E6C9), Color(0xFF1B5E20), 'Livré', 4),
    'Suspendu': (Color(0xFFFFDAD6), Color(0xFFBA1A1A), 'Suspendu', 2),
    'Annulé': (Color(0xFFE8E8E8), Color(0xFF4F4536), 'Annulé', 0),
  };

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final api = ApiService(context.read<AppState>());
      final res = await api.getLivraison(widget.livraisonId);
      setState(() => livraison = Map<String, dynamic>.from(res.data));
    } catch (_) {
      setState(() => _error = 'Commande introuvable.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  String _formatDateTime(DateTime? d) {
    if (d == null) return '—';
    final jj = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$jj/$mm/${d.year} à $hh:$min';
  }

  String _formatDuree(DateTime? debut, DateTime? fin) {
    if (debut == null) return '—';
    final f = fin ?? DateTime.now();
    final d = f.difference(debut);
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null && livraison == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Commande')),
        body: Center(child: Text(_error!)),
      );
    }

    final l = livraison!;
    final status = l['status'];
    final conf = _statusConfig[status] ??
        (Colors.grey.shade200, Colors.grey.shade700, '$status', 0);
    final commandeId = l['id'].toString().padLeft(5, '0');

    final dateDebut = _parseDate(l['started_at'] ?? l['start_delivery_date']);
    final dateCloture = _parseDate(l['closed_at'] ?? l['closure_date']);
    final livreur = l['delivery_persons'];
    final litige = l['litige'] ?? (l['litiges'] is List && l['litiges'].isNotEmpty
        ? l['litiges'][0]
        : null);

    final steps = [
      ('Créée', true),
      ('Assignée', ['Assigné', 'En_cours', 'Livré'].contains(status)),
      ('En cours', ['En_cours', 'Livré'].contains(status)),
      ('Livrée', status == 'Livré'),
    ];

    return Scaffold(
        appBar: AppBar(
          title: Text('Commande #$commandeId'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: conf.$1,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(conf.$3,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: conf.$2)),
                ),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
            onRefresh: _charger,
            child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                if (status != 'Annulé') _card(child: _timeline(steps)),

    if (status == 'Suspendu')
    _banner(
    color: const Color(0xFFFFDAD6),
    icon: Icons.warning_amber_rounded,
    iconColor: const Color(0xFFBA1A1A),
    title: 'Commande suspendue',
    subtitle:
    'Contactez l\'administration Glotelho pour plus de détails.',
    ),

    // Litige lié (consultation uniquement)
    if (litige != null)
    _banner(
    color: const Color(0xFFFFDEA9),
    icon: Icons.report_gmailerrorred_outlined,
    iconColor: const Color(0xFF7D5700),
    title: 'Litige associé — ${litige['status'] ?? 'en cours'}',
    subtitle: 'Géré par l\'administration Glotelho.',
    ),

    // Bouton suivi en direct
    if (status == 'En_cours')
    Container(
    margin: const EdgeInsets.only(bottom: 14),
    width: double.infinity,
    child: ElevatedButton.icon(
    onPressed: () => Navigator.push(context,
    MaterialPageRoute(builder: (_) => const TrackingScreen())),
    style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.navy,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape:
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    icon: const Icon(Icons.map_outlined, size: 18),
    label: const Text('Suivre le livreur en direct'),
    ),
    ),

    // Détails commande
    _card(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Text('Détails de la commande',
    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
    const SizedBox(height: 12),
    _field('Adresse de livraison', l['delivery_address']),
    if (l['zone_bloc'] != null) _field('Repère', l['zone_bloc']),
    _field('Montant', l['amount_to_collect'] != null
    ? '${l['amount_to_collect']} FCFA'
        : '—',
    valueColor: AppTheme.navy, bold: true),
    _field('Date création', '${l['creation_date'] ?? '—'}'.split('T').first),
    ],
    ),
    ),

    // Client
    _card(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Text('Client',
    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    const SizedBox(height: 10),
    _personRow(
    nom: l['client_nom'] ??
    '${l['customers']?['users']?['first_name'] ?? ''} ${l['customers']?['users']?['last_name'] ?? ''}',
    sous: l['client_telephone'] ?? l['customers']?['users']?['phone'] ?? '',
    color: AppTheme.navy,
    ),
    ],
    ),
    ),

    // Livreur (matricule, contact)
    _card(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Text('Livreur',
    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    const SizedBox(height: 10),
    if (livreur != null) ...[
    _personRow(
    nom:
    '${livreur['users']?['first_name'] ?? ''} ${livreur['users']?['last_name'] ?? ''}',
    sous: livreur['users']?['phone'] ?? '',
    color: AppTheme.navyLight,
    ),
    const SizedBox(height: 10),
    Row(
    children: [
    Expanded(
    child: _field('Matricule',
    livreur['matricule'] ?? livreur['registration_number'] ?? '—')),
    Expanded(
    child: _field(
    'Véhicule',
    livreur['vehicules'] != null
    ? '${livreur['vehicules']['type'] ?? ''}'
        : '—')),
    ],
    ),
    ] else
    Text('Pas encore assigné',
    style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
    ],
    ),
    ),

    // Dates début / clôture / durée
    if (dateDebut != null || dateCloture != null)
    _card(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Text('Suivi temporel',
    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    const SizedBox(height: 10),
    Row(
    children: [
    Expanded(
    child: _field('Début livraison', _formatDateTime(dateDebut))),
    Expanded(
    child: _field('Clôture', _formatDateTime(dateCloture))),
    ],