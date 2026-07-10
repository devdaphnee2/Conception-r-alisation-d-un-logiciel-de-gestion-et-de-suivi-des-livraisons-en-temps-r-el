import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';

/// Formulaire de création — reprend LivraisonCreate.jsx : infos client,
/// adresse, articles dynamiques, récapitulatif de montant, assignation
/// livreur optionnelle, date souhaitée.
class NouvelleLivraisonScreen extends StatefulWidget {
  const NouvelleLivraisonScreen({super.key});

  @override
  State<NouvelleLivraisonScreen> createState() => _NouvelleLivraisonScreenState();
}

class _ArticleRow {
  final nom = TextEditingController();
  final quantite = TextEditingController(text: '1');
  final prixUnitaire = TextEditingController();

  void dispose() {
    nom.dispose();
    quantite.dispose();
    prixUnitaire.dispose();
  }

  double get sousTotal {
    final q = int.tryParse(quantite.text) ?? 1;
    final p = double.tryParse(prixUnitaire.text) ?? 0;
    return q * p;
  }
}

class _NouvelleLivraisonScreenState extends State<NouvelleLivraisonScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nom = TextEditingController();
  final _telephone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _adresse = TextEditingController();
  final _zoneBloc = TextEditingController();
  final _instructions = TextEditingController();
  final _montantLivraison = TextEditingController(text: '500');

  final List<_ArticleRow> _articles = [_ArticleRow()];
  List livreurs = [];
  int? _livreurId;
  DateTime? _dateSouhaitee;
  bool _loading = false;
  bool _loadingLivreurs = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLivreurs();
  }

  @override
  void dispose() {
    _nom.dispose();
    _telephone.dispose();
    _whatsapp.dispose();
    _adresse.dispose();
    _zoneBloc.dispose();
    _instructions.dispose();
    _montantLivraison.dispose();
    for (final a in _articles) {
      a.dispose();
    }
    super.dispose();
  }

  Future<void> _loadLivreurs() async {
    try {
      final api = ApiService(context.read<AppState>());
      final res = await api.getLivreurs();
      setState(() => livreurs = res.data ?? []);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingLivreurs = false);
    }
  }

  double get _totalArticles => _articles.fold(0, (sum, a) => sum + a.sousTotal);
  double get _fraisLivraison => double.tryParse(_montantLivraison.text) ?? 0;
  double get _totalGeneral => _totalArticles + _fraisLivraison;

  void _addArticle() => setState(() => _articles.add(_ArticleRow()));

  void _removeArticle(int i) {
    if (_articles.length == 1) return;
    setState(() {
      _articles[i].dispose();
      _articles.removeAt(i);
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(() => _dateSouhaitee =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final articlesValides = _articles.where((a) => a.nom.text.trim().isNotEmpty).toList();
    if (articlesValides.isEmpty) {
      setState(() => _error = 'Ajoutez au moins un article.');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final api = ApiService(context.read<AppState>());
      await api.createLivraison({
        'client_nom': _nom.text.trim(),
        'client_telephone': _telephone.text.trim(),
        'client_whatsapp': _whatsapp.text.trim().isNotEmpty
            ? _whatsapp.text.trim()
            : _telephone.text.trim(),
        'delivery_address': _adresse.text.trim(),
        'zone_bloc': _zoneBloc.text.trim(),
        'delivery_instructions': _instructions.text.trim(),
        'amount_to_collect': _totalGeneral,
        'collected_amount': 0,
        'montant_livraison': _fraisLivraison,
        'articles': articlesValides
            .map((a) => {
          'nom': a.nom.text.trim(),
          'quantite': int.tryParse(a.quantite.text) ?? 1,
          'prix_unitaire': double.tryParse(a.prixUnitaire.text) ?? 0,
        })
            .toList(),
        'delivery_person_id': _livreurId,
        'delivery_date': _dateSouhaitee?.toIso8601String(),
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _error = 'Erreur lors de la création.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle livraison')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],

            _sectionTitle('Informations client'),
            _textField(_nom, 'Nom complet du client *', required: true),
            _textField(_telephone, 'Téléphone *',
                required: true, keyboardType: TextInputType.phone),
            _textField(_whatsapp, 'Numéro WhatsApp (si différent)',
                keyboardType: TextInputType.phone),

            _sectionTitle('Adresse de livraison'),
            _textField(_adresse, 'Adresse complète *', required: true),
            _textField(_zoneBloc, 'Description du lieu / Repère'),
            _textField(_instructions, 'Instructions spéciales', maxLines: 2),

            _sectionTitle('Articles de la commande'),
            ...List.generate(_articles.length, (i) => _articleCard(i)),
            OutlinedButton(
              onPressed: _addArticle,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.grey.shade400, style: BorderStyle.solid),
              ),
              child: Text('+ Ajouter un article',
                  style: TextStyle(color: AppTheme.navy, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 20),

            // Récapitulatif
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sous-total articles',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      Text('${_totalArticles.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Frais de livraison',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      SizedBox(
                        width: 110,
                        child: TextFormField(
                          controller: _montantLivraison,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total à collecter',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('${_totalGeneral.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.navy)),
                    ],
                  ),
                ],
              ),
            ),

            _sectionTitle('Assignation livreur'),
            _loadingLivreurs
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: LinearProgressIndicator(),
            )
                : DropdownButtonFormField<int>(
              value: _livreurId,
              decoration: _inputDecoration('Livreur (optionnel)'),
              hint: const Text('-- Assigner plus tard --', style: TextStyle(fontSize: 12)),
              items: livreurs
                  .map<DropdownMenuItem<int>>((l) => DropdownMenuItem(
                value: l['id'],
                child: Text(
                    '${l['users']?['first_name'] ?? ''} ${l['users']?['last_name'] ?? ''} — ${l['zone_affectee'] ?? 'Sans zone'}',
                    style: const TextStyle(fontSize: 12)),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _livreurId = v),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: _inputDecoration('Date souhaitée'),
                child: Text(
                  _dateSouhaitee != null
                      ? '${_dateSouhaitee!.day}/${_dateSouhaitee!.month}/${_dateSouhaitee!.year} à ${_dateSouhaitee!.hour}:${_dateSouhaitee!.minute.toString().padLeft(2, '0')}'
                      : 'Choisir une date',
                  style: TextStyle(
                      fontSize: 13,
                      color: _dateSouhaitee != null ? Colors.black87 : Colors.grey.shade500),
                ),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(_loading ? 'Création en cours...' : 'Créer la livraison'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 10),
    child: Row(
      children: [
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    ),
  );

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 12),
    filled: true,
    fillColor: Colors.grey.shade100,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  );

  Widget _textField(
      TextEditingController controller,
      String label, {
        bool required = false,
        int maxLines = 1,
        TextInputType? keyboardType,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: _inputDecoration(label),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
            : null,
      ),
    );
  }

  Widget _articleCard(int i) {
    final a = _articles[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: a.nom,
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration('Désignation *'),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: a.quantite,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: _inputDecoration('Quantité'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: a.prixUnitaire,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: _inputDecoration('Prix unitaire'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _articles.length == 1 ? null : () => _removeArticle(i),
                icon: const Icon(Icons.close),
                color: const Color(0xFFBA1A1A),
              ),
            ],
          ),
          if (a.nom.text.isNotEmpty && a.prixUnitaire.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('Sous-total : ${a.sousTotal.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.navy, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}