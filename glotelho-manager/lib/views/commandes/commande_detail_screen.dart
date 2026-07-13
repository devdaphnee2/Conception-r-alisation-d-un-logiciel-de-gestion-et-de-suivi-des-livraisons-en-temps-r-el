import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';

/// Détail d'une livraison — reprend LivraisonShow.jsx : timeline de
/// progression, infos, client, livreur, OTP, articles, rapport,
/// actions (assigner/réassigner/annuler/notifier WhatsApp).
///
/// ⚠️ Pour le bouton WhatsApp, ajoute `url_launcher` dans pubspec.yaml
/// et décommente l'appel `launchUrl` dans `_openWhatsApp()`.
class LivraisonDetailScreen extends StatefulWidget {
  final int livraisonId;
  const LivraisonDetailScreen({super.key, required this.livraisonId});

  @override
  State<LivraisonDetailScreen> createState() => _LivraisonDetailScreenState();
}

class _LivraisonDetailScreenState extends State<LivraisonDetailScreen> {
  bool _loading = true;
  bool _actionLoading = false;
  Map<String, dynamic>? livraison;
  List livreursDisponibles = [];
  String? _error;
  String? _successMsg;
  bool _showAssignerForm = false;
  bool _showReassignerForm = false;
  int? _selectedLivreurId;

  static const _statusConfig = {
    'En_attente': (Color(0xFFFFDEA9), Color(0xFF483100), 'En attente', 1),
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
    final api = ApiService(context.read<AppState>());
    try {
      final res = await api.getLivraison(widget.livraisonId);
      final livreursRes = await api.getLivreurs(all: true);
      setState(() {
        livraison = Map<String, dynamic>.from(res.data);
        livreursDisponibles = (livreursRes.data as List? ?? [])
            .where((l) => l['status'] == 'Disponible')
            .toList();
      });
    } catch (_) {
      setState(() => _error = 'Livraison introuvable.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _assigner({bool reassign = false}) async {
    if (_selectedLivreurId == null) return;
    setState(() => _actionLoading = true);
    try {
      final api = ApiService(context.read<AppState>());
      await api.assignerLivreur(widget.livraisonId, _selectedLivreurId!);
      setState(() {
        _successMsg = reassign ? 'Livraison réassignée.' : 'Livraison assignée.';
        _showAssignerForm = false;
        _showReassignerForm = false;
        _selectedLivreurId = null;
      });
      _charger();
    } catch (_) {
      setState(() => _error = 'Erreur lors de l\'assignation.');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _annuler() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler cette livraison ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A)),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _actionLoading = true);
    try {
      final api = ApiService(context.read<AppState>());
      await api.annulerLivraison(widget.livraisonId);
      setState(() => _successMsg = 'Livraison annulée.');
      _charger();
    } catch (_) {
      setState(() => _error = 'Erreur lors de l\'annulation.');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  String? _buildWaLink() {
    if (livraison == null) return null;
    var tel = (livraison!['client_whatsapp'] ?? livraison!['client_telephone'] ?? '')
        .toString()
        .replaceAll(' ', '')
        .replaceAll('+', '');
    if (tel.isEmpty) return null;
    if (!tel.startsWith('237')) tel = '237$tel';
    final confirmations = livraison!['confirmations'] as List?;
    final otp = (confirmations != null && confirmations.isNotEmpty)
        ? (confirmations[0]['otp_code'] ?? '')
        : '';
    final clientNom = livraison!['client_nom'] ??
        '${livraison!['customers']?['users']?['first_name'] ?? ''} ${livraison!['customers']?['users']?['last_name'] ?? ''}';
    final id = livraison!['id'].toString().padLeft(5, '0');
    final trackingUrl = livraison!['tracking_url'] ?? 'https://glotelho.com/tracking/${livraison!['id']}';
    final msg = 'Bonjour $clientNom !\n\n'
        'Votre commande Glotelho est en cours de livraison.\n'
        'Numéro : $id\n\n'
        'Suivez votre livreur :\n$trackingUrl\n\n'
        'Code à donner au livreur :\n*$otp*\n\nNe partagez pas ce code.';
    return 'https://wa.me/$tel?text=${Uri.encodeComponent(msg)}';
  }

  Future<void> _openWhatsApp() async {
    final link = _buildWaLink();
    if (link == null) return;
    // TODO: ajouter url_launcher dans pubspec.yaml, puis :
    // await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lien WhatsApp prêt (url_launcher à intégrer) : $link')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null && livraison == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Livraison')),
        body: Center(child: Text(_error!)),
      );
    }

    final l = livraison!;
    final status = l['status'];
    final conf = _statusConfig[status] ?? (Colors.grey.shade200, Colors.grey.shade700, '$status', 0);
    final livraisonId = l['id'].toString().padLeft(5, '0');
    final waLink = _buildWaLink();

    final steps = [
      ('Créée', true),
      ('Assignée', ['Assigné', 'En_cours', 'Livré'].contains(status)),
      ('En cours', ['En_cours', 'Livré'].contains(status)),
      ('Livrée', status == 'Livré'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Livraison #$livraisonId'),
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
            // Timeline
            if (status != 'Annulé') _card(child: _timeline(steps)),

            // Alerte suspendu
            if (status == 'Suspendu')
              _banner(
                color: const Color(0xFFFFDAD6),
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFBA1A1A),
                title: 'Livraison suspendue',
                subtitle: 'Motif : ${l['suspension_reason'] ?? 'Non précisé'}',
              ),

            if (_successMsg != null)
              _banner(
                color: const Color(0xFFC8E6C9),
                icon: Icons.check_circle_outline,
                iconColor: const Color(0xFF1B5E20),
                title: _successMsg!,
              ),
            if (_error != null)
              _banner(
                color: const Color(0xFFFFDAD6),
                icon: Icons.error_outline,
                iconColor: const Color(0xFFBA1A1A),
                title: _error!,
              ),

            // Notification client WhatsApp
            if (['Assigné', 'En_cours'].contains(status) && waLink != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Notification client',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1B5E20))),
                          const SizedBox(height: 3),
                          Text('Envoyer le lien de suivi et le code au client.',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.green.shade700)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openWhatsApp,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white),
                      icon: const Icon(Icons.chat, size: 16),
                      label: const Text('WhatsApp', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Détails livraison
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Détails livraison',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _field('Adresse', l['delivery_address']),
                  if (l['zone_bloc'] != null) _field('Description lieu', l['zone_bloc']),
                  if (l['delivery_instructions'] != null)
                    _field('Instructions', l['delivery_instructions']),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                            'À collecter',
                            l['amount_to_collect'] != null
                                ? '${l['amount_to_collect']} FCFA'
                                : '—',
                            valueColor: AppTheme.navy,
                            bold: true),
                      ),
                      Expanded(
                        child: _field(
                            'Collecté',
                            l['collected_amount'] != null
                                ? '${l['collected_amount']} FCFA'
                                : '0 FCFA',
                            valueColor: const Color(0xFF1B5E20)),
                      ),
                    ],
                  ),
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

            // Livreur
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Livreur assigné',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  if (l['delivery_persons'] != null)
                    _personRow(
                      nom:
                      '${l['delivery_persons']['users']?['first_name'] ?? ''} ${l['delivery_persons']['users']?['last_name'] ?? ''}',
                      sous: l['delivery_persons']['vehicules'] != null
                          ? '${l['delivery_persons']['vehicules']['brand'] ?? ''} ${l['delivery_persons']['vehicules']['type'] ?? ''}'
                          : '',
                      color: AppTheme.navyLight,
                    )
                  else
                    Text('Non assigné',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),

            // OTP
            if ((l['confirmations'] as List?)?.isNotEmpty == true &&
                l['confirmations'][0]['otp_code'] != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.navy,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CODE OTP',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.4),
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('${l['confirmations'][0]['otp_code']}',
                            style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 4)),
                      ],
                    ),
                    Flexible(
                      child: Text(
                          'Demandé par le livreur au client pour confirmer la remise.',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 10, color: Colors.white.withOpacity(0.4))),
                    ),
                  ],
                ),
              ),

            // Articles
            if ((l['delivery_items'] as List?)?.isNotEmpty == true)
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Articles (${l['delivery_items'].length})',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    ...List.generate(l['delivery_items'].length, (i) {
                      final item = l['delivery_items'][i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                  '${item['product_name']}${item['quantity'] != null ? ' x${item['quantity']}' : ''}',
                                  style: const TextStyle(fontSize: 12)),
                            ),
                            if (item['unit_price'] != null)
                              Text('${item['unit_price']} FCFA',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.navy)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            // Actions
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Actions',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (status == 'En_attente')
                        FilledButton(
                          onPressed: () =>
                              setState(() => _showAssignerForm = !_showAssignerForm),
                          style: FilledButton.styleFrom(backgroundColor: AppTheme.navy),
                          child: const Text('Assigner un livreur'),
                        ),
                      if (status == 'Suspendu')
                        FilledButton(
                          onPressed: () =>
                              setState(() => _showReassignerForm = !_showReassignerForm),
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFBA1A1A)),
                          child: const Text('Réassigner'),
                        ),
                      if (!['Livré', 'Annulé'].contains(status))
                        OutlinedButton(
                          onPressed: () {
                            // TODO: écran de modification (LivraisonEdit.jsx)
                          },
                          child: const Text('Modifier'),
                        ),
                      if (['En_attente', 'Suspendu'].contains(status))
                        OutlinedButton(
                          onPressed: _actionLoading ? null : _annuler,
                          style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFBA1A1A),
                              side: const BorderSide(color: Color(0xFFBA1A1A))),
                          child: const Text('Annuler'),
                        ),
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: génération/téléchargement du bordereau PDF
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                        label: const Text('Bordereau PDF'),
                      ),
                    ],
                  ),

                  if (_showAssignerForm) ...[
                    const SizedBox(height: 14),
                    _assignationForm(reassign: false),
                  ],
                  if (_showReassignerForm) ...[
                    const SizedBox(height: 14),
                    _assignationForm(reassign: true),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assignationForm({required bool reassign}) {
    final currentId = livraison!['delivery_person_id'];
    final options = livreursDisponibles
        .where((l) => !reassign || l['id'] != currentId)
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: reassign ? const Color(0xFFFFDAD6) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reassign ? 'Réassigner à un nouveau livreur' : 'Assigner un livreur',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: _selectedLivreurId,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            hint: const Text('-- Sélectionner --', style: TextStyle(fontSize: 12)),
            items: options
                .map<DropdownMenuItem<int>>((l) => DropdownMenuItem(
              value: l['id'],
              child: Text(
                  '${l['users']?['first_name'] ?? ''} ${l['users']?['last_name'] ?? ''} — ${l['zone_affectee'] ?? ''}',
                  style: const TextStyle(fontSize: 12)),
            ))
                .toList(),
            onChanged: (v) => setState(() => _selectedLivreurId = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton(
                onPressed: (_actionLoading || _selectedLivreurId == null)
                    ? null
                    : () => _assigner(reassign: reassign),
                style: FilledButton.styleFrom(
                    backgroundColor: reassign ? const Color(0xFFBA1A1A) : AppTheme.navy),
                child: Text(_actionLoading ? '...' : 'Confirmer'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() {
                  _showAssignerForm = false;
                  _showReassignerForm = false;
                }),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade200),
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );

  Widget _banner({
    required Color color,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: iconColor)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: TextStyle(fontSize: 12, color: iconColor.withOpacity(0.8))),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _timeline(List<(String, bool)> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PROGRESSION',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.6)),
        const SizedBox(height: 14),
        Row(
          children: List.generate(steps.length, (i) {
            final (label, done) = steps[i];
            return Expanded(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: done ? AppTheme.navy : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: done
                            ? const Icon(Icons.check, size: 13, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(label,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: done ? FontWeight.w700 : FontWeight.w400,
                              color: done ? Colors.black87 : Colors.grey.shade500)),
                    ],
                  ),
                  if (i < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        color: done ? AppTheme.navy : Colors.grey.shade200,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _field(String label, dynamic value, {Color? valueColor, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text('${value ?? '—'}',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _personRow({required String nom, required String sous, required Color color}) {
    return Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: color,
          child: Text(nom.isNotEmpty ? nom[0] : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nom, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(sous, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }
}