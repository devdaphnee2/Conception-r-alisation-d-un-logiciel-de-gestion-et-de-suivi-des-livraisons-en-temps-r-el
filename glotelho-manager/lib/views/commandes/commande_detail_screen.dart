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
  bool _loading = true;
  Map? _cmd;
  bool _actionLoading = false;
  String? _error;
  String? _success;

  static const _statusColors = <String, Color>{
    'Commande': Color(0xFF9E9E9E), 'En_attente': Color(0xFFC9952E), 'Assign_': Color(0xFF3E5682),
    'En_cours': Color(0xFF20619E), 'Livr_': Color(0xFF1B5E20),
    'Suspendu': Color(0xFFBA1A1A), 'Annul_': Color(0xFF817564),
  };
  static const _statusLabels = <String, String>{
    'Commande': 'Brouillon', 'En_attente': 'En attente', 'Assign_': 'Assigné',
    'En_cours': 'En cours', 'Livr_': 'Livré',
    'Suspendu': 'Suspendu', 'Annul_': 'Annulé',
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiService(context.read<AppState>());
      final res = await api.getCommande(widget.id);
      setState(() => _cmd = res.data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _commanderCourse() async {
    setState(() { _actionLoading = true; _error = null; });
    try {
      final api = ApiService(context.read<AppState>());
      await api.commanderCourse(widget.id);
      setState(() => _success = 'Course commandée ! L\'admin va assigner un livreur.');
      await _load();
    } catch (_) {
      setState(() => _error = 'Erreur lors de la commande.');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _annuler() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Annuler la commande ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Oui, annuler')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final api = ApiService(context.read<AppState>());
      await api.annulerCommande(widget.id);
      setState(() => _success = 'Commande annulée.');
      await _load();
    } catch (_) { setState(() => _error = 'Erreur lors de l\'annulation.'); }
  }

  Future<void> _declarerLitige() async {
    final motifCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Déclarer un litige'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: motifCtrl,
                decoration: const InputDecoration(labelText: 'Motif', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: descCtrl, maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1B2A), foregroundColor: Colors.white),
              child: const Text('Soumettre')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final api = ApiService(context.read<AppState>());
      await api.declarerLitige(widget.id, motifCtrl.text, descCtrl.text);
      setState(() => _success = 'Litige déclaré. L\'admin va traiter votre demande.');
    } catch (_) { setState(() => _error = 'Erreur lors de la déclaration.'); }
  }

  Future<void> _ouvrirSuivi() async {
    final url = Uri.parse('http://192.168.1.145:5173/suivi/${widget.id}');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final l          = _cmd ?? {};
    final status     = l['status'] as String? ?? '';
    final color      = _statusColors[status] ?? Colors.grey;
    final label      = _statusLabels[status] ?? status;
    final articles   = (l['delivery_items'] as List?) ?? [];
    final livreurInfo = l['delivery_persons'];
    final livreurNom = livreurInfo?['users'] != null
        ? '${livreurInfo['users']['first_name'] ?? ''} ${livreurInfo['users']['last_name'] ?? ''}'.trim()
        : null;
    final otp = (l['confirmations'] as List?)?.isNotEmpty == true
        ? l['confirmations'][0]['otp_code']?.toString() : null;
    final id = '#${widget.id.toString().padLeft(5,'0')}';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        title: Text('Commande $id'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          if (_success != null) _banner(_success!, const Color(0xFFC8E6C9), const Color(0xFF1B5E20)),
          if (_error   != null) _banner(_error!,   const Color(0xFFFFDAD6), const Color(0xFFBA1A1A)),

          // Bouton suivi en direct
          if (['Assign_','En_cours'].contains(status)) ...[
            ElevatedButton.icon(
              onPressed: _ouvrirSuivi,
              icon: const Icon(Icons.location_on),
              label: const Text('📍 Suivre la livraison en direct'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF20619E), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Client
          _card('Informations client', [
            _row('Nom', l['client_nom']),
            _row('Téléphone', l['client_telephone']),
            if (l['client_whatsapp'] != null && l['client_whatsapp'] != l['client_telephone'])
              _row('WhatsApp', l['client_whatsapp']),
            _row('Adresse', l['delivery_address']),
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
                  Text('${((double.tryParse(a["unit_price"]?.toString() ?? "0") ?? 0) * (int.tryParse(a["quantity"]?.toString() ?? "1") ?? 1)).toStringAsFixed(0)} FCFA',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A), fontSize: 12)),
                ],
              ),
            )).toList(),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total à collecter', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${double.tryParse(l['amount_to_collect']?.toString() ?? '0')?.toStringAsFixed(0) ?? '0'} FCFA',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0D1B2A))),
              ],
            ),
          ]),

          // Livreur
          if (livreurNom != null) ...[
            const SizedBox(height: 12),
            _card('Livreur assigné', [
              _row('Nom', livreurNom),
              if (livreurInfo?['users']?['phone'] != null)
                _row('Téléphone', livreurInfo['users']['phone']),
              if (livreurInfo?['vehicules'] != null)
                _row('Véhicule', '${livreurInfo['vehicules']['type'] ?? ''} — ${livreurInfo['vehicules']['plate_number'] ?? ''}'),
            ]),
          ],

          // OTP masque cote commercant

          // Actions
          const SizedBox(height: 16),

          // Commander une course
          if (status == 'En_attente') ...[
            ElevatedButton.icon(
              onPressed: _actionLoading ? null : _commanderCourse,
              icon: const Icon(Icons.send),
              label: Text(_actionLoading ? 'Envoi en cours...' : 'Commander une course'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D1B2A), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Declarer litige
          if (['Assign_','En_cours','Suspendu'].contains(status)) ...[
            OutlinedButton.icon(
              onPressed: _declarerLitige,
              icon: const Icon(Icons.gavel_outlined),
              label: const Text('Déclarer un litige'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC9952E),
                side: const BorderSide(color: Color(0xFFC9952E)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Annuler
          if (['En_attente','Assign_'].contains(status)) ...[
            OutlinedButton.icon(
              onPressed: _annuler,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Annuler la commande'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],

          const SizedBox(height: 30),
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
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      const Divider(height: 16),
      ...children,
    ]),
  );

  Widget _row(String label, String? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label,
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600))),
      Expanded(child: Text(value ?? '—', style: const TextStyle(fontSize: 13))),
    ]),
  );
}