import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../models/driver_model.dart';
import '../../models/vehicle_model.dart';
import '../../services/driver_service.dart';
import '../../utils/driver_state.dart';
import '../pending_verification_screen.dart';
import 'signup_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController _pageController = PageController();
  int _step = 0;
  static const int _totalSteps = 4;

  // ── Étape 1 : Infos personnelles ──
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _dateNaissanceCtrl = TextEditingController();
  File? _photoProfil;

  // ── Étape 2 : Identité ──
  final _cniNumeroCtrl = TextEditingController();
  File? _cniRecto;
  File? _cniVerso;
  File? _permis;

  // ── Étape 3 : Véhicule ──
  String _typeVehicule = 'Scooter';
  final _marqueCtrl = TextEditingController();
  final _modeleCtrl = TextEditingController();
  final _immatriculationCtrl = TextEditingController();
  File? _photoVehicule;
  final _assuranceNumeroCtrl = TextEditingController();
  final _assuranceExpirationCtrl = TextEditingController();

  // ── Étape 4 : Disponibilités + Mobile Money ──
  final List<String> _joursDisponibles = [];
  TimeOfDay? _heureDebut;
  TimeOfDay? _heureFin;
  final _mobileMoneyNumeroCtrl = TextEditingController();
  final _mobileMoneyTitulaireCtrl = TextEditingController();

  bool _isSubmitting = false;

  static const List<String> _typesVehicule = ['Scooter', 'Moto', 'Tricycle', 'Voiture'];
  static const List<String> _jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in [
      _nomCtrl, _prenomCtrl, _telCtrl, _emailCtrl, _adresseCtrl, _passwordCtrl,
      _dateNaissanceCtrl, _cniNumeroCtrl, _marqueCtrl, _modeleCtrl, _immatriculationCtrl,
      _assuranceNumeroCtrl, _assuranceExpirationCtrl, _mobileMoneyNumeroCtrl, _mobileMoneyTitulaireCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
    ));
  }

  bool _validateStep() {
    switch (_step) {
      case 0:
        if (_nomCtrl.text.trim().isEmpty || _prenomCtrl.text.trim().isEmpty || _telCtrl.text.trim().isEmpty ||
            _emailCtrl.text.trim().isEmpty || _adresseCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
          _showError('Veuillez remplir tous les champs');
          return false;
        }
        if (parseDateInput(_dateNaissanceCtrl.text) == null) {
          _showError('Veuillez indiquer une date de naissance valide (jj/MM/aaaa)');
          return false;
        }
        if (_photoProfil == null) {
          _showError('Veuillez ajouter une photo de profil');
          return false;
        }
        return true;
      case 1:
        if (_cniNumeroCtrl.text.trim().isEmpty) {
          _showError('Veuillez indiquer le numéro de CNI');
          return false;
        }
        if (_cniRecto == null || _cniVerso == null) {
          _showError('Veuillez ajouter les photos recto et verso de la CNI');
          return false;
        }
        if (_permis == null) {
          _showError('Veuillez ajouter la photo du permis de conduire');
          return false;
        }
        return true;
      case 2:
        if (_marqueCtrl.text.trim().isEmpty || _modeleCtrl.text.trim().isEmpty || _immatriculationCtrl.text.trim().isEmpty ||
            _assuranceNumeroCtrl.text.trim().isEmpty) {
          _showError('Veuillez remplir tous les champs du véhicule');
          return false;
        }
        if (_photoVehicule == null) {
          _showError('Veuillez ajouter une photo du véhicule');
          return false;
        }
        if (parseDateInput(_assuranceExpirationCtrl.text) == null) {
          _showError('Veuillez indiquer une date d\'expiration valide (jj/MM/aaaa)');
          return false;
        }
        return true;
      case 3:
        if (_joursDisponibles.isEmpty) {
          _showError('Veuillez sélectionner au moins un jour de disponibilité');
          return false;
        }
        if (_heureDebut == null || _heureFin == null) {
          _showError('Veuillez indiquer vos horaires');
          return false;
        }
        if (_mobileMoneyNumeroCtrl.text.trim().isEmpty || _mobileMoneyTitulaireCtrl.text.trim().isEmpty) {
          _showError('Veuillez renseigner vos informations Mobile Money');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _next() {
    if (!_validateStep()) return;
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Navigator.pop(context);
    }
  }

  String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final availabilities = _joursDisponibles
        .map((jour) => Availability(jour: jour, heureDebut: _fmtTime(_heureDebut!), heureFin: _fmtTime(_heureFin!)))
        .toList();

    final vehicle = VehicleModel(
      type: _typeVehicule,
      marque: _marqueCtrl.text.trim(),
      modele: _modeleCtrl.text.trim(),
      immatriculation: _immatriculationCtrl.text.trim(),
      assuranceNumero: _assuranceNumeroCtrl.text.trim(),
      assuranceExpiration: parseDateInput(_assuranceExpirationCtrl.text)!,
    );

    final result = await DriverService.register(
      nom: _nomCtrl.text.trim(),
      prenom: _prenomCtrl.text.trim(),
      dateNaissance: parseDateInput(_dateNaissanceCtrl.text)!,
      telephone: _telCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
      adresseResidence: _adresseCtrl.text.trim(),
      cniNumero: _cniNumeroCtrl.text.trim(),
      vehicle: vehicle,
      disponibilites: availabilities,
      mobileMoneyNumero: _mobileMoneyNumeroCtrl.text.trim(),
      mobileMoneyTitulaire: _mobileMoneyTitulaireCtrl.text.trim(),
      photoProfil: _photoProfil!,
      cniRecto: _cniRecto!,
      cniVerso: _cniVerso!,
      permis: _permis!,
      photoVehicule: _photoVehicule!,
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (result.success) {
      if (result.token != null) {
        await context.read<DriverState>().saveSession(result.token!);
      }
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => const PendingVerificationScreen()), (r) => false);
    } else {
      _showError(result.errorMessage ?? 'Erreur lors de l\'inscription');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: _back),
        title: const Text('Inscription livreur', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: List.generate(_totalSteps, (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i == _totalSteps - 1 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: i <= _step ? AppColors.gold : Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
                _buildStep4(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_step == _totalSteps - 1 ? 'Soumettre mon dossier' : 'Continuer',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
  );

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Informations personnelles'),
          ImagePickerField(label: 'Photo de profil', file: _photoProfil, onPicked: (f) => setState(() => _photoProfil = f)),
          const SizedBox(height: 16),
          buildTextField(_nomCtrl, 'Nom', Icons.person_outline),
          const SizedBox(height: 12),
          buildTextField(_prenomCtrl, 'Prénom', Icons.person_outline),
          const SizedBox(height: 12),
          buildDateTextField(_dateNaissanceCtrl, 'Date de naissance'),
          const SizedBox(height: 12),
          buildTextField(_telCtrl, 'Numéro de téléphone', Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          buildTextField(_emailCtrl, 'Adresse e-mail', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          buildTextField(_adresseCtrl, 'Adresse de résidence', Icons.location_on_outlined),
          const SizedBox(height: 12),
          buildTextField(_passwordCtrl, 'Mot de passe', Icons.lock_outline, obscure: true),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Pièces d\'identité'),
          buildTextField(_cniNumeroCtrl, 'Numéro de CNI', Icons.badge_outlined),
          const SizedBox(height: 16),
          ImagePickerField(label: 'Photo recto de la CNI', file: _cniRecto, onPicked: (f) => setState(() => _cniRecto = f)),
          const SizedBox(height: 16),
          ImagePickerField(label: 'Photo verso de la CNI', file: _cniVerso, onPicked: (f) => setState(() => _cniVerso = f)),
          const SizedBox(height: 16),
          ImagePickerField(label: 'Photo du permis de conduire', file: _permis, onPicked: (f) => setState(() => _permis = f)),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Véhicule'),
          const Text('Type de véhicule', style: TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _typesVehicule.map((t) {
              final selected = _typeVehicule == t;
              return ChoiceChip(
                label: Text(t),
                selected: selected,
                onSelected: (_) => setState(() => _typeVehicule = t),
                selectedColor: AppColors.gold,
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 12),
                backgroundColor: AppColors.cardNavy,
                side: BorderSide(color: selected ? AppColors.gold : Colors.white24),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          buildTextField(_marqueCtrl, 'Marque', Icons.two_wheeler_outlined),
          const SizedBox(height: 12),
          buildTextField(_modeleCtrl, 'Modèle', Icons.two_wheeler_outlined),
          const SizedBox(height: 12),
          buildTextField(_immatriculationCtrl, 'Immatriculation', Icons.confirmation_number_outlined),
          const SizedBox(height: 16),
          ImagePickerField(label: 'Photo du véhicule', file: _photoVehicule, onPicked: (f) => setState(() => _photoVehicule = f)),
          const SizedBox(height: 16),
          buildTextField(_assuranceNumeroCtrl, 'Numéro d\'assurance', Icons.shield_outlined),
          const SizedBox(height: 12),
          buildDateTextField(_assuranceExpirationCtrl, 'Date d\'expiration de l\'assurance'),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Indiquez vos coordonnées pour vos transactions'),
          //const Text('Jours disponibles', style: TextStyle(fontSize: 13, color: Colors.white70)),
          //const SizedBox(height: 1),
          /*Wrap(
            spacing: 8, runSpacing: 8,
            children: _jours.map((j) {
              final selected = _joursDisponibles.contains(j);
              return FilterChip(
                label: Text(j, style: const TextStyle(fontSize: 12)),
                selected: selected,
                onSelected: (v) => setState(() => v ? _joursDisponibles.add(j) : _joursDisponibles.remove(j)),
                selectedColor: AppColors.gold,
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
                backgroundColor: AppColors.cardNavy,
                side: BorderSide(color: selected ? AppColors.gold : Colors.white24),
              );
            }).toList(),
          ),*/
          const SizedBox(height: 1),
          /*Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: _heureDebut ?? const TimeOfDay(hour: 8, minute: 0));
                    if (t != null) setState(() => _heureDebut = t);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Heure de début',
                      labelStyle: const TextStyle(fontSize: 12, color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    child: Text(_heureDebut == null ? '--:--' : _fmtTime(_heureDebut!),
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: _heureFin ?? const TimeOfDay(hour: 18, minute: 0));
                    if (t != null) setState(() => _heureFin = t);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Heure de fin',
                      labelStyle: const TextStyle(fontSize: 12),
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_heureFin == null ? '--:--' : _fmtTime(_heureFin!)),
                  ),
                ),
              ),
            ],
          ),*/
          const SizedBox(height: 8),
          _sectionTitle('Mobile Money / Orange money'),
          buildTextField(_mobileMoneyNumeroCtrl, 'Numéro Mobile Money', Icons.phone_android, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          buildTextField(_mobileMoneyTitulaireCtrl, 'Nom du titulaire du compte', Icons.person_outline),
        ],
      ),
    );
  }
}