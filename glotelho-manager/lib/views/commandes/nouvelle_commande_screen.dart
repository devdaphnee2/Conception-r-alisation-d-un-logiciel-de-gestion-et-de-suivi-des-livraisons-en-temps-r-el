import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/app_state.dart';
import '../../services/api_service.dart';
import '../../widgets/adresse_input.dart';
import '../../config/app_config.dart';

// --- FORMATTEURS DE TEXTE PERSONNALISÉS ---

/// Formatteur pour espacer les numéros de téléphone (ex: 655 112 233)
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && (i == 3 || i == 6 || i == 9)) {
        buffer.write(' ');
      }
      buffer.write(digitsOnly[i]);
    }
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

/// Formatteur pour les milliers dans les prix (ex: 15 000)
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return newValue.copyWith(text: '');

    final number = int.tryParse(digitsOnly);
    if (number == null) return newValue;

    // Formatage manuel avec espaces pour les milliers
    final str = number.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      count++;
      buffer.write(str[i]);
      if (count % 3 == 0 && i != 0) {
        buffer.write(' ');
      }
    }
    final formatted = buffer.toString().split('').reversed.join('');
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// --- ÉCRAN PRINCIPAL ---

class NouvelleCommandeScreen extends StatefulWidget {
  const NouvelleCommandeScreen({super.key});
  @override
  State<NouvelleCommandeScreen> createState() => _NouvelleCommandeScreenState();
}

class _ArticleRow {
  final nom          = TextEditingController();
  final quantite     = TextEditingController(text: '1');
  final prixUnitaire = TextEditingController();
  void dispose() { nom.dispose(); quantite.dispose(); prixUnitaire.dispose(); }

  double get sousTotal {
    final q = int.tryParse(quantite.text.replaceAll(RegExp(r'\D'), '')) ?? 1;
    final p = double.tryParse(prixUnitaire.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    return q * p;
  }
}

class _NouvelleCommandeScreenState extends State<NouvelleCommandeScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _nom           = TextEditingController();
  final _telephone     = TextEditingController();
  final _whatsapp      = TextEditingController();
  final _adresseDepart = TextEditingController();
  final _adresse       = TextEditingController();
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
  String _formatColis = 'Petit';
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

  /// Détermine si l'utilisateur a saisi des données dans le formulaire
  bool get _isFormDirty {
    return _nom.text.isNotEmpty ||
        _telephone.text.isNotEmpty ||
        _adresseDepart.text.isNotEmpty ||
        _adresse.text.isNotEmpty ||
        _articles.any((a) => a.nom.text.isNotEmpty || a.prixUnitaire.text.isNotEmpty);
  }

  /// Dialogue de confirmation lors de l'annulation/retour
  Future<bool> _confirmCancel() async {
    if (!_isFormDirty) return true; // Rien de rempli, on ferme directement
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandonner la commande ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('Toutes les informations déjà saisies seront perdues.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuer la saisie'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFBA1A1A)),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  double get _totalArticles => _articles.fold(0, (s, a) => s + a.sousTotal);
  double get _frais         => double.tryParse(_fraisLivraison.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  void _addArticle() => setState(() => _articles.add(_ArticleRow()));
  void _removeArticle(int i) {
    if (_articles.length == 1) return;
    setState(() { _articles[i].dispose(); _articles.removeAt(i); });
  }

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

      // Nettoyage des chaînes pour extraire uniquement les valeurs numériques pures
      final telPropre = _telephone.text.replaceAll(RegExp(r'\D'), '');
      final whatsappPropre = _whatsapp.text.trim().isNotEmpty
          ? _whatsapp.text.replaceAll(RegExp(r'\D'), '')
          : telPropre;

      await api.createLivraison({
        'client_nom'           : _nom.text.trim(),
        'client_telephone'     : telPropre,
        'client_whatsapp'      : whatsappPropre,
        'pickup_address'       : _adresseDepart.text.trim(),
        'delivery_address'     : _adresse.text.trim(),
        'zone_bloc'            : _zoneBloc.text.trim(),
        'delivery_instructions': _instructions.text.trim(),
        'montant_livraison'    : _frais,
        'articles'             : valides.map((a) => {
          'nom'          : a.nom.text.trim(),
          'quantite'     : int.tryParse(a.quantite.text.replaceAll(RegExp(r'\D'), '')) ?? 1,
          'prix_unitaire': double.tryParse(a.prixUnitaire.text.replaceAll(RegExp(r'\D'), '')) ?? 0,
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
    final isDark = Theme.of(context).brightness == Brightness.dark || true;

    final bgColor    = isDark ? const Color(0xFF0D1B2A) : Colors.white;
    final bgField    = isDark ? const Color(0xFF1B2A4A) : Colors.white;
    final txtColor   = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final hintColor  = isDark ? Colors.white54 : Colors.grey;
    final borderColor= isDark ? Colors.white24 : const Color(0xFFE0E0E0);

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
        {bool required = false, int maxLines = 1, TextInputType? type, List<TextInputFormatter>? formatters}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller  : ctrl,
            maxLines    : maxLines,
            keyboardType: type,
            inputFormatters: formatters,
            style       : TextStyle(color: txtColor, fontSize: 13),
            decoration  : deco(label, hint, icon),
            validator   : required ? (v) => (v == null || v.trim().isEmpty) ? 'Ce champ est requis' : null : null,
          ),
        );

    // Encapsulation dans PopScope pour la confirmation d'annulation lors du retour arrière
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmCancel();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text('Nouvelle commande'),
          backgroundColor: isDark ? const Color(0xFF0D1B2A) : null,
          elevation: 0,
        ),
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
              field(_nom, 'Nom complet du client *', 'Ex : Marie Ngono', Icons.person_outline, required: true),

              // Champs Téléphones formatés
              field(_telephone, 'Téléphone *', 'Ex : 655 112 233', Icons.phone_outlined,
                  required: true, type: TextInputType.phone, formatters: [PhoneInputFormatter()]),
              field(_whatsapp, 'WhatsApp (si différent)', 'Laisser vide si identique', Icons.chat_outlined,
                  type: TextInputType.phone, formatters: [PhoneInputFormatter()]),

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
              field(_zoneBloc,     'Repère du lieu',     'Ex : Après le Shell, portail rouge',   Icons.place_outlined),
              field(_instructions, 'Instructions',       'Ex : Colis fragile, appeler avant...', Icons.notes_outlined, maxLines: 2),

              // ARTICLES
              _section('🛍️ Articles', isDark),
              ...List.generate(_articles.length, (i) {
                final a = _articles[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgField,
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
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(color: txtColor, fontSize: 13),
                          decoration: deco('Qté', 'Ex : 2', Icons.numbers),
                        )),
                        const SizedBox(width: 8),

                        // Champ Prix unitaire formaté en milliers
                        Expanded(child: TextFormField(
                          controller: a.prixUnitaire,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandsSeparatorInputFormatter()],
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
                            child: Text('Sous-total : ${_formatMontant(a.sousTotal)} XAF',
                                style: const TextStyle(fontSize: 11, color: Color(0xFFC9952E), fontWeight: FontWeight.w600)),
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
                  color: bgField,
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
                  color: bgField,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2411) : const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFE082).withOpacity(0.4)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline, color: Color(0xFFC9952E), size: 16),
                      SizedBox(width: 8),
                      Expanded(child: Text('Le client paie la marchandise en ligne. Les frais de livraison sont remis en cash au livreur.',
                          style: TextStyle(fontSize: 11, color: Color(0xFFC9952E)))),
                    ]),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Sous-total articles', style: TextStyle(fontSize: 12, color: hintColor)),
                    Text('${_formatMontant(_totalArticles)} XAF',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: txtColor)),
                  ]),
                  const SizedBox(height: 14),

                  if (_calculLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Color(0xFFC9952E), strokeWidth: 2)),
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
                        ? '${_formatMontant(_frais)} XAF'
                        : 'Non calculés',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                            color: _frais > 0 ? const Color(0xFFC9952E) : hintColor)),
                  ]),

                  Divider(height: 24, color: borderColor),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Marchandise (à payer en ligne)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: txtColor)),
                    Text('${_formatMontant(_totalArticles)} XAF',
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
                    color: bgField,
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

              // BOUTON PRINCIPAL (JAUNE/OR + TEXTE NOIR)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Icon(Icons.add_shopping_cart, color: Colors.black),
                  label: Text(
                    _loading ? 'Enregistrement...' : 'Enregistrer la commande',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC9952E),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // BOUTON ANNULER
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () async {
                    final shouldPop = await _confirmCancel();
                    if (shouldPop && context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// Formate un nombre double/int avec séparateur de milliers pour l'affichage textuel
  String _formatMontant(double montant) {
    final str = montant.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      count++;
      buffer.write(str[i]);
      if (count % 3 == 0 && i != 0) {
        buffer.write(' ');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  Widget _detailRow(String label, dynamic montant, Color color) {
    final numVal = montant is num ? montant.toDouble() : double.tryParse(montant.toString()) ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 11, color: color)),
        Text('${_formatMontant(numVal)} XAF', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }

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