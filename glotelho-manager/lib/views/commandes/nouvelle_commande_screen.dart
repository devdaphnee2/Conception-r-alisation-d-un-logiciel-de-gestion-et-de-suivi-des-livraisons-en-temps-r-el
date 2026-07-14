import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../services/api_service.dart';

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
  final _adresse       = TextEditingController();
  final _zoneBloc      = TextEditingController();
  final _instructions  = TextEditingController();
  final _fraisLivraison= TextEditingController(text: '500');
  final List<_ArticleRow> _articles = [_ArticleRow()];
  DateTime? _dateSouhaitee;
  bool   _loading = false;
  String? _error;

  @override
  void dispose() {
    _nom.dispose(); _telephone.dispose(); _whatsapp.dispose();
    _adresse.dispose(); _zoneBloc.dispose(); _instructions.dispose();
    _fraisLivraison.dispose();
    for (final a in _articles) a.dispose();
    super.dispose();
  }

  double get _totalArticles => _articles.fold(0, (s, a) => s + a.sousTotal);
  double get _frais         => double.tryParse(_fraisLivraison.text) ?? 0;
  double get _totalGeneral  => _totalArticles + _frais;

  void _addArticle() => setState(() => _articles.add(_ArticleRow()));
  void _removeArticle(int i) {
    if (_articles.length == 1) return;
    setState(() { _articles[i].dispose(); _articles.removeAt(i); });
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
    setState(() { _error = null; _loading = true; });
    try {
      final api = ApiService(context.read<AppState>());
      await api.createLivraison({
        'client_nom'           : _nom.text.trim(),
        'client_telephone'     : _telephone.text.trim(),
        'client_whatsapp'      : _whatsapp.text.trim().isNotEmpty ? _whatsapp.text.trim() : _telephone.text.trim(),
        'delivery_address'     : _adresse.text.trim(),
        'zone_bloc'            : _zoneBloc.text.trim(),
        'delivery_instructions': _instructions.text.trim(),
        'amount_to_collect'    : _totalGeneral,
        'montant_livraison'    : _frais,
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

            // Intro
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C3D56) : const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white24 : const Color(0xFF90CAF9)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: isDark ? Colors.white70 : const Color(0xFF1565C0), size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Comment ça marche ?',
                          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1565C0),
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        '1. Renseignez les infos du client et ses articles.\n'
                            '2. Fixez les frais de livraison pour le livreur.\n'
                            '3. La commande est enregistrée — livrez quand vous êtes prêt.\n'
                            '4. Cliquez "Commander une course" pour notifier l\'admin.',
                        style: TextStyle(fontSize: 11, height: 1.5,
                            color: isDark ? Colors.white70 : const Color(0xFF1565C0)),
                      ),
                    ],
                  )),
                ],
              ),
            ),

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

            // ADRESSE
            _section('📍 Adresse de livraison', isDark),
            field(_adresse,      'Adresse complète *', 'Ex : Bonamoussadi, Rue des Manguiers', Icons.location_on_outlined, required: true),
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

            // FRAIS + RECAP
            _section('💰 Montant & Frais de livraison', isDark),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C3D56) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(children: [
                // Note frais
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
                    Expanded(child: Text('Les frais de livraison sont reversés intégralement au livreur.',
                        style: TextStyle(fontSize: 11, color: Color(0xFFF57F17)))),
                  ]),
                ),
                // Sous-total
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Sous-total articles', style: TextStyle(fontSize: 12, color: hintColor)),
                  Text('${_totalArticles.toStringAsFixed(0)} XAF',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: txtColor)),
                ]),
                const SizedBox(height: 12),
                // Frais
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Frais de livraison', style: TextStyle(fontSize: 12, color: txtColor, fontWeight: FontWeight.w600)),
                    Text('Montant reversé au livreur', style: TextStyle(fontSize: 10, color: hintColor)),
                  ])),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    child: TextFormField(
                      controller: _fraisLivraison,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: txtColor, fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: bgField,
                        suffixText: 'XAF',
                        suffixStyle: TextStyle(color: hintColor, fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFC9952E))),
                      ),
                    ),
                  ),
                ]),
                const Divider(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Total à collecter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: txtColor)),
                  Text('${_totalGeneral.toStringAsFixed(0)} XAF',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFC9952E))),
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