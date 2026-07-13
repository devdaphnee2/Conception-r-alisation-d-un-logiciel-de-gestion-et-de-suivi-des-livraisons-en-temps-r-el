import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_state.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';

class CommandeDetailScreen extends StatefulWidget {
  final int id;
  const CommandeDetailScreen({super.key, required this.id});

  @override
  State<CommandeDetailScreen> createState() => _CommandeDetailScreenState();
}

class _CommandeDetailScreenState extends State<CommandeDetailScreen> {
  bool _loading  = true;
  Map? _livraison;
  List  _livreurs = [];
  int?  _livreurId;
  bool  _assigning = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiService(context.read<AppState>());
      final res = await api.getLivraison(widget.id);
      final liv = await api.getLivreurs(disponiblesOnly: true);
      setState(() {
        _livraison = res.data;
        _livreurs  = liv.data ?? [];
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _assigner() async {
    if (_livreurId == null) { setState(() => _error = 'Sélectionnez un livreur.'); return; }
    setState(() { _assigning = true; _error = null; });
    try {
      final api = ApiService(context.read<AppState>());
      final res = await api.assignerLivreur(widget.id, _livreurId!);
      final waLink = res.data['whatsapp_link'] as String?;
      if (waLink != null) {
        final uri = Uri.parse(waLink);
        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      setState(() => _success = 'Livreur assigné ! Client notifié via WhatsApp.');
      await _load();
    } catch (e) {
      setState(() => _error = 'Erreur lors de l\'assignation.');
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }

  Future<void> _annuler() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annuler la livraison ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Oui, annuler', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final api = ApiService(context.read<AppState>());
      await api.annulerLivraison(widget.id);
      setState(() => _success = 'Livraison annulée.');
      await _load();
    } catch (_) {
      setState(() => _error = 'Erreur lors de l\'annulation.');
    }
  }

  Future<void> _ouvrirTracking() async {
    final url = 'http://192.168.1.145:5173/suivi/${widget.id}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final l = _livraison ?? {};
    const statusLabels = {
      'En_attente': 'En attente', 'Assign_': 'Assigné',
      'En_cours': 'En cours', 'Livr_': 'Livré',
      'Suspendu': 'Suspendu', 'Annul_': 'Annulé',
    };
    const statusColors = {
      'En_attente': Color(0xFFC9952E), 'Assign_': Color(0xFF3E5682),
      'En_cours': Color(0xFF20619E), 'Livr_': Color(0xFF1B5E20),
      'Suspendu': Color(0xFFBA1A1A), 'Annul_': Color(0xFF817564),
    };
    final status      = l['status'] as String? ?? '';
    final statusLabel = statusLabels[status] ?? status;
    final statusColor = statusColors[status] ?? Colors.grey;
    final numFormate  = '#${widget.id.toString().padLeft(5, '0')}';
    final articles    = (l['delivery_items'] as List?) ?? [];
    final otp         = (l['confirmations'] as List?)?.isNotEmpty == true
        ? l['confirmations'][0]['otp_code'] : null;
    final livreurInfo = l['delivery_persons'];
    final livreurNom  = livreurInfo != null
        ? '${livreurInfo['users']?['first_name'] ?? ''} ${livreurInfo['users']?['last_name'] ?? ''}'
        : null;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
        title: Text('Livraison $numFormate'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Messages
          if (_success != null) _banner(_success!, Colors.green.shade50, Colors.green),
          if (_error   != null) _banner(_error!,   Colors.red.shade50,   Colors.red),

          // Bouton tracking
          if (['Assign_', 'En_cours'].contains(status))
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              child: ElevatedButton.icon(
                onPressed: _ouvrirTracking,
                icon: const Icon(Icons.location_on, size: 18),
                label: const Text('📍 Suivre la livraison en direct'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F3131),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

          // Client
          _card('Client', [
            _row('Nom', l['client_nom'] ?? '—'),
            _row('Téléphone', l['client_telephone'] ?? '—'),
            if (l['client_whatsapp'] != null && l['client_whatsapp'] != l['client_telephone'])
              _row('WhatsApp', l['client_whatsapp']),
            _row('Adresse', l['delivery_address'] ?? '—'),
            if (l['zone_bloc'] != null) _row('Repère', l['zone_bloc']),
            if (l['delivery_instructions'] != null) _row('Instructions', l['delivery_instructions']),
          ]),

          const SizedBox(height: 12),

          // Articles
          _card('Articles (${articles.length})', [
            ...articles.map((a) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${a["product_name"]} x${a["quantity"] ?? 1}',
                      style: const TextStyle(fontSize: 13))),
                  Text('${((a["unit_price"] ?? 0) as num * (a["quantity"] ?? 1)).toStringAsFixed(0)} FCFA',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy, fontSize: 12)),
                ],
              ),
            )).toList(),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total à collecter', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${l['amount_to_collect'] ?? 0} FCFA',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.navy)),
              ],
            ),
          ]),

          const SizedBox(height: 12),

          // Livreur assigné
          if (livreurNom != null)
            _card('Livreur assigné', [
              _row('Nom', livreurNom),
              if (livreurInfo?['users']?['phone'] != null)
                _row('Téléphone', livreurInfo['users']['phone']),
              if (livreurInfo?['vehicules'] != null)
                _row('Véhicule', '${livreurInfo['vehicules']['type']} — ${livreurInfo['vehicules']['plate_number']}'),
            ]),

          // OTP
          if (otp != null && status == 'En_cours') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2F3131),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Text('Code OTP — à donner au livreur',
                      style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Text(otp.toString(),
                      style: TextStyle(color: AppTheme.gold, fontSize: 40,
                          fontWeight: FontWeight.w900, letterSpacing: 8, fontFamily: 'monospace')),
                  const SizedBox(height: 8),
                  const Text('Communiquez ce code à votre client',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          ],

          // Assignation
          if (status == 'En_attente') ...[
            const SizedBox(height: 16),
            const Text('Assigner un livreur', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _livreurId,
              decoration: InputDecoration(
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              hint: const Text('-- Sélectionner un livreur --', style: TextStyle(fontSize: 12)),
              items: _livreurs.map<DropdownMenuItem<int>>((lv) => DropdownMenuItem(
                value: lv['id'] as int,
                child: Text('${lv['users']?['first_name'] ?? ''} ${lv['users']?['last_name'] ?? ''} — ${lv['zone_affectee'] ?? 'Sans zone'}',
                    style: const TextStyle(fontSize: 12)),
              )).toList(),
              onChanged: (v) => setState(() => _livreurId = v),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _assigning ? null : _assigner,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navy, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(_assigning ? 'Assignation...' : '🛵 Assigner et notifier le client'),
            ),
          ],

          // Annulation
          if (['En_attente', 'Assign_'].contains(status)) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _annuler,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Annuler la livraison'),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _banner(String msg, Color bg, Color color) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3))),
    child: Text(msg, style: TextStyle(color: color, fontSize: 13)),
  );

  Widget _card(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const Divider(height: 16),
        ...children,
      ],
    ),
  );

  Widget _row(String label, String? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value ?? '—', style: const TextStyle(fontSize: 13))),
      ],
    ),
  );
}