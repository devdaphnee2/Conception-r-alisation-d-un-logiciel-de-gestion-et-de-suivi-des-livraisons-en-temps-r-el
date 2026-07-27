import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/app_state.dart';
import '../../services/api_service.dart';
import '../../widgets/adresse_input.dart';
import '../../config/app_config.dart';

class NouvelleLivraisonScreen extends StatefulWidget {
  const NouvelleLivraisonScreen({super.key});
  @override
  State<NouvelleLivraisonScreen> createState() => _NouvelleLivraisonScreenState();
}

class _ArticleRow {
  final nom          = TextEditingController();
  final quantite     = TextEditingController(text: '1');
  final prixUnitaire = TextEditingController();
  void dispose() { nom.dispose(); quantite.dispose(); prixUnitaire.dispose(); }
  double get sousTotal {
    final q = int.tryParse(quantite.text) ?? 1;
    final p = double.tryParse(prixUnitaire.text) ?? 0;
    return q * p;
  }
}

class _NouvelleLivraisonScreenState extends State<NouvelleLivraisonScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _nom           = TextEditingController();
  final _telephone     = TextEditingController();
  final _whatsapp      = TextEditingController();
  final _adresseDepart = TextEditingController(); // ← adresse du commerçant (récupération)
  final _adresse       = TextEditingController(); // adresse du client (livraison)
  final _zoneBloc      = TextEditingController();
  final _instructions  = TextEditingController();
  final _fraisLivraison= TextEditingController(text: '0');
  final List<_ArticleRow> _articles = [_ArticleRow()];
  DateTime? _dateSouhaitee;
  bool   _loading = false;
  bool   _calculLoading = false;
  String? _error;
  double? _distanceKm;
  Timer? _debounce;
  String _formatColis = 'Petit'; // Petit | Moyen | Gros
  bool   _livraisonExpress = false;
  Map<String, dynamic>? _surchargesDetails;
  double? _latDepart, _lngDepart;
  double? _latLivraison, _lngLivraison;

  static String get _baseUrl => AppConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _adresseDepart.addListener(_onAdresseChanged);
    _adresse.addListener(_onAdresseChanged);
  }

  void _onAdresseChanged() {
    _debounce?.cancel();
    if (_adresseDepart.text.trim().length < 4 || _adresse.text.trim().length < 4) return;
    _debounce = Timer(const Duration(milliseconds: 1500), () {
      _calculerFrais();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _adresseDepart.removeListener(_onAdresseChanged);
    _adresse.removeListener(_onAdresseChanged);
    _nom.dispose(); _telephone.dispose(); _whatsapp.dispose();
    _adresseDepart.dispose(); _adresse.dispose(); _zoneBloc.dispose(); _instructions.dispose();
    _fraisLivraison.dispose();
    for (final a in _articles) a.dispose();
    super.dispose();
  }

  double get _totalArticles => _articles.fold(0, (s, a) => s + a.sousTotal);
  double get _frais         => double.tryParse(_fraisLivraison.text) ?? 0;

  void _addArticle() => setState(() => _articles.add(_ArticleRow()));
  void _removeArticle(int i) {
    if (_articles.length == 1) return;
    setState(() { _articles[i].dispose(); _articles.removeAt(i); });
  }

  // ── Calcul automatique des frais selon la distance ──────────────────
  Future<void> _calculerFrais() async {
    if (_adresseDepart.text.trim().isEmpty || _adresse.text.trim().isEmpty) {
      setState(() => _error = 'Renseignez l\'adresse de récupération ET l\'adresse de livraison.');
      return;
    }
    setState(() { _calculLoading = true; _error = null; });
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/distance/calculer-frais'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adresse_depart' : _adresseDepart.text.trim(),
          'adresse_arrivee': _adresse.text.trim(),
          'format_colis'   : _formatColis,
          'express'        : _livraisonExpress,
          if (_latDepart != null) 'lat_depart': _latDepart,
          if (_lngDepart != null) 'lng_depart': _lngDepart,
          if (_latLivraison != null) 'lat_arrivee': _latLivraison,
          if (_lngLivraison != null) 'lng_arrivee': _lngLivraison,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode != 200) {
        setState(() => _error = data['message'] ?? 'Erreur de calcul.');
        return;
      }
      setState(() {
        _distanceKm = (data['distance_km'] as num).toDouble();
        _fraisLivraison.text = (data['frais_livraison'] as num).toStringAsFixed(0);
        _surchargesDetails = data;
      });
    } catch (e) {
      debugPrint('[FRAIS] ERREUR: $e');
      setState(() => _error = 'Impossible de calculer les frais. Vérifiez votre connexion.');
    } finally {
      if (mounted) setState(() => _calculLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context, initialDate: DateTime.now(),
      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(() => _dateSouhaitee =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final valides = _articles.where((a) => a.nom.text.trim().isNotEmpty).toList();
    if (valides.isEmpty) { setState(() => _error = 'Ajoutez au moins un article.'); return; }
    if (_fraisLivraison.text.trim().isEmpty || _frais <= 0) {
      setState(() => _error = 'Calculez les frais de livraison avant de continuer.');
      return;
    }
    setState(() { _error = null; _loading = true; });
    try {
      final api = ApiService(context.read<AppState>());
      await api.createLivraison({
        'client_nom'           : _nom.text.trim(),
        'client_telephone'     : _telephone.text.trim(),
        'client_whatsapp'      : _whatsapp.text.trim().isNotEmpty ? _whatsapp.text.trim() : _telephone.text.trim(),
        'pickup_address'       : _adresseDepart.text.trim(),
        'delivery_address'     : _adresse.text.trim(),
        'zone_bloc'            : _zoneBloc.text.trim(),
        'delivery_instructions': _instructions.text.trim(),
        // amount_to_collect est recalculé côté backend = total articles uniquement
        'montant_livraison'    : _frais, // frais payés cash au livreur
        'articles'             : valides.map((a) => {
          'nom'          : a.nom.text.trim(),
          'quantite'     : int.tryParse(a.quantite.text) ?? 1,
          'prix_unitaire': double.tryParse(a.prixUnitaire.text) ?? 0,
        }).toList(),
        'delivery_date': _dateSouhaitee?.toIso8601String(),
        'source'       : 'commercant',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Commande créée ! Retrouvez-la dans l\'onglet Commandes.'),
          backgroundColor: Color(0xFF1B5E20),
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = 'Erreur lors de la création. Vérifiez votre connexion.\n$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgField  = isDark ? const Color(0xFF1C3D56) : Colors.white;
    final txtColor = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final hintColor= isDark ? Colors.white54 : Colors.grey;
    final borderColor = isDark ? Colors.white24 : const Color(0xFFE0E0E0);

    InputDecoration deco(String label, String hint, IconData icon) => InputDecoration(
      labelText     : label,
      labelStyle    : TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey),
      hintText      : hint,
      hintStyle     : TextStyle(fontSize: 12, color: hintColor),
      prefixIcon    : Icon(icon, size: 18, color: hintColor),
      filled        : true,
      fillColor     : bgField,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border        : OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder : OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
      focusedBorder : OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFC9952E), width: 1.5)),
    );

    Widget field(TextEditingController ctrl, String label, String hint, IconData icon,
        {bool required = false, int maxLines = 1, TextInputType? type}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller  : ctrl,
            maxLines    : maxLines,
            keyboardType: type,
            style       : TextStyle(color: txtColor, fontSize: 13),
            decoration  : deco(label, hint, icon),
            validator   : required ? (v) => (v == null || v.trim().isEmpty) ? 'Ce champ est requis' : null : null,
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle commande')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: const Color(0xFFFFDAD6), borderRadius: BorderRadius.circular(8)),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 12)),
              ),
            ],

            // CLIENT
            _section('👤 Informations du client', isDark),
            field(_nom,       'Nom complet du client *', 'Ex : Marie Ngono',   Icons.person_outline,   required: true),
            field(_telephone, 'Téléphone *',             'Ex : 655 112 233',   Icons.phone_outlined,   required: true, type: TextInputType.phone),
            field(_whatsapp,  'WhatsApp (si différent)', 'Laisser vide si identique', Icons.chat_outlined, type: TextInputType.phone),

            // ADRESSES
            _section('📍 Adresses', isDark),
            AdresseInput(
              key: const ValueKey('adresse_depart'),
              controller: _adresseDepart,
              label: 'Votre adresse (récupération) *',
              icon : Icons.store_outlined,
              onChanged: (result) {
                _latDepart = result.latitude;
                _lngDepart = result.longitude;
                _onAdresseChanged();
              },
            ),
            const SizedBox(height: 14),
            AdresseInput(
              key: const ValueKey('adresse_livraison'),
              controller: _adresse,
              label: 'Adresse du client (livraison) *',
              icon : Icons.location_on_outlined,
              showGeoloc: false,
              onChanged: (result) {
                _latLivraison = result.latitude;
                _lngLivraison = result.longitude;
                _onAdresseChanged();
              },
            ),
            const SizedBox(height: 14),
            field(_zoneBloc,      'Repère du lieu',     'Ex : Après le Shell, portail rouge',   Icons.place_outlined),
            field(_instructions,  'Instructions',       'Ex : Colis fragile, appeler avant...', Icons.notes_outlined, maxLines: 2),

            // ARTICLES
            _section('🛍️ Articles', isDark),
            ...List.generate(_articles.length, (i) {
              final a = _articles[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C3D56) : Colors.white,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('Article ${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: txtColor)),
                      const Spacer(),
                      if (_articles.length > 1)
                        GestureDetector(onTap: () => _removeArticle(i),
                            child: const Icon(Icons.close, color: Color(0xFFBA1A1A), size: 18)),
                    ]),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: a.nom,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: txtColor, fontSize: 13),
                      decoration: deco('Désignation *', 'Ex : Crème Balea 125ml, Riz 5kg...', Icons.inventory_2_outlined),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextFormField(
                        controller: a.quantite,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: txtColor, fontSize: 13),
                        decoration: deco('Qté', 'Ex : 2', Icons.numbers),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(
                        controller: a.prixUnitaire,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: txtColor, fontSize: 13),
                        decoration: deco('Prix unitaire (XAF)', 'Ex : 5 000', Icons.monetization_on_outlined),
                      )),
                    ]),
                    if (a.nom.text.isNotEmpty && a.prixUnitaire.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('Sous-total : ${a.sousTotal.toStringAsFixed(0)} XAF',
                              style: TextStyle(fontSize: 11, color: const Color(0xFFC9952E), fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              );
            }),

            OutlinedButton.icon(
              onPressed: _addArticle,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter un article'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC9952E),
                side: const BorderSide(color: Color(0xFFC9952E)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            // FORMAT COLIS & DÉLAI
            _section('📦 Détails du colis', isDark),
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C3D56) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(children: [
                DropdownButtonFormField<String>(
                  value: _formatColis,
                  decoration: deco('Format du colis', '', Icons.inventory_2_outlined),
                  dropdownColor: bgField,
                  style: TextStyle(color: txtColor, fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: 'Petit', child: Text('Petit')),
                    DropdownMenuItem(value: 'Moyen', child: Text('Moyen')),
                    DropdownMenuItem(value: 'Gros',  child: Text('Gros (+700 XAF)')),
                  ],
                  onChanged: (v) {
                    setState(() => _formatColis = v ?? 'Petit');
                    _onAdresseChanged();
                  },
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _livraisonExpress,
                  onChanged: (v) {
                    setState(() => _livraisonExpress = v ?? false);
                    _onAdresseChanged();
                  },
                  activeColor: const Color(0xFFC9952E),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('Livraison Express (+700 XAF)', style: TextStyle(fontSize: 13, color: txtColor)),
                  subtitle: Text('Non coché = Livraison Standard', style: TextStyle(fontSize: 11, color: hintColor)),
                ),
              ]),
            ),

            // FRAIS AUTO
            _section('💰 Montant & Frais de livraison', isDark),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C3D56) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline, color: Color(0xFFF57F17), size: 15),
                    SizedBox(width: 8),
                    Expanded(child: Text('Le client paie la marchandise en ligne. Les frais de livraison sont remis en cash au livreur.',
                        style: TextStyle(fontSize: 11, color: Color(0xFFF57F17)))),
                  ]),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Sous-total articles', style: TextStyle(fontSize: 12, color: hintColor)),
                  Text('${_totalArticles.toStringAsFixed(0)} XAF',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: txtColor)),
                ]),
                const SizedBox(height: 14),

                // Calcul automatique — indicateur
                if (_calculLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 10),
                        Text('Calcul automatique des frais...', style: TextStyle(fontSize: 12, color: hintColor)),
                      ],
                    ),
                  )
                else if (_frais == 0)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline, size: 14, color: hintColor),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Renseignez les deux adresses — les frais se calculent automatiquement.',
                          style: TextStyle(fontSize: 11, color: hintColor))),
                    ]),
                  ),
                const SizedBox(height: 12),

                if (_distanceKm != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('Distance estimée : ${_distanceKm!.toStringAsFixed(1)} km',
                        style: TextStyle(fontSize: 11, color: hintColor)),
                  ),

                if (_surchargesDetails != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(children: [
                      _detailRow('Frais de base', _surchargesDetails!['frais_base'], hintColor),
                      _detailRow('Distance (${_distanceKm?.toStringAsFixed(1)} km)', _surchargesDetails!['cout_distance'], hintColor),
                      if ((_surchargesDetails!['surcharges_details'] as List).isNotEmpty)
                        ...(_surchargesDetails!['surcharges_details'] as List).map(
                          (s) => _detailRow(s['label'], s['montant'], hintColor),
                        ),
                    ]),
                  ),
                ],

                Row(children: [
                  Expanded(child: Text('Frais de livraison (calculés)',
                      style: TextStyle(fontSize: 12, color: txtColor, fontWeight: FontWeight.w600))),
                  Text(_fraisLivraison.text.isNotEmpty && _fraisLivraison.text != '0'
                      ? '${_frais.toStringAsFixed(0)} XAF'
                      : 'Non calculés',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                          color: _frais > 0 ? const Color(0xFFC9952E) : hintColor)),
                ]),

                const Divider(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Marchandise (à payer en ligne)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: txtColor)),
                  Text('${_totalArticles.toStringAsFixed(0)} XAF',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFC9952E))),
                ]),
              ]),
            ),
            const SizedBox(height: 20),

            // DATE
            _section('📅 Date souhaitée (optionnel)', isDark),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C3D56) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today_outlined, color: hintColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      _dateSouhaitee != null
                          ? '${_dateSouhaitee!.day}/${_dateSouhaitee!.month}/${_dateSouhaitee!.year} à ${_dateSouhaitee!.hour.toString().padLeft(2,'0')}:${_dateSouhaitee!.minute.toString().padLeft(2,'0')}'
                          : 'Choisir une date de livraison',
                      style: TextStyle(fontSize: 13,
                          color: _dateSouhaitee != null ? txtColor : hintColor,
                          fontWeight: _dateSouhaitee != null ? FontWeight.w600 : FontWeight.normal),
                    ),
                    const SizedBox(height: 2),
                    Text('Vous pouvez commander la course plus tard', style: TextStyle(fontSize: 10, color: hintColor)),
                  ])),
                  if (_dateSouhaitee != null)
                    GestureDetector(onTap: () => setState(() => _dateSouhaitee = null),
                        child: Icon(Icons.close, size: 16, color: hintColor))
                  else Icon(Icons.chevron_right, color: hintColor),
                ]),
              ),
            ),
            const SizedBox(height: 28),

            // BOUTONS
            ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.add_shopping_cart),
              label: Text(_loading ? 'Enregistrement...' : 'Enregistrer la commande'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D1B2A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: const BorderSide(color: Colors.grey),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Annuler'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, dynamic montant, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 11, color: color)),
      Text('${montant is num ? montant.toStringAsFixed(0) : montant} XAF', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _section(String text, bool isDark) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 12),
    child: Row(children: [
      Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF0D1B2A))),
      const SizedBox(width: 10),
      Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey.shade300)),
    ]),
  );
}