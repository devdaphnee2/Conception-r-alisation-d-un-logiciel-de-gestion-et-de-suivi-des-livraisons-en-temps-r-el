import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';

/// Écran d'inscription — reprend Register.jsx côté web :
/// prénom, nom, email, téléphone, mot de passe, confirmation.
/// Validation identique : mots de passe identiques + 8 caractères min.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _loading = false;
  bool _obscurePwd = true;
  bool _obscureConfirm = true;
  bool _welcomeNew = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);

    if (_password.text != _confirmPassword.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }
    if (_password.text.length < 8) {
      setState(() => _error = 'Le mot de passe doit contenir au moins 8 caractères.');
      return;
    }

    setState(() => _loading = true);
    try {
      final appState = context.read<AppState>();
      final api = ApiService(appState);
      await api.register(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
        confirmPassword: _confirmPassword.text,
      );
      setState(() => _welcomeNew = true);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      }
    } catch (e) {
      setState(() => _error = 'Erreur lors de la création du compte.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_welcomeNew) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC8E6C9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Color(0xFF1B5E20), size: 28),
                ),
                const SizedBox(height: 20),
                const Text('Bienvenue chez Glotelho !',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Votre compte manager a été créé. Redirection en cours...',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte manager')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inscrivez-vous pour gérer livraisons, livreurs et litiges.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 20),

                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDAD6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(
                            color: Color(0xFFBA1A1A),
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 16),
                ],

                Row(
                  children: [
                    Expanded(
                      child: _field('Prénom', _firstName),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field('Nom', _lastName),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _field('Email', _email,
                    hint: 'manager@glotelho.com',
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _field('Numéro de téléphone', _phone,
                    hint: '655112233', keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _field('Mot de passe', _password,
                    obscure: _obscurePwd,
                    toggleObscure: () => setState(() => _obscurePwd = !_obscurePwd)),
                const SizedBox(height: 14),
                _field('Confirmer le mot de passe', _confirmPassword,
                    obscure: _obscureConfirm,
                    toggleObscure: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm)),
                const SizedBox(height: 6),
                Text('Minimum 8 caractères.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(_loading ? 'Création...' : 'Créer mon compte'),
                  ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text('Déjà un compte ? ',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text('Se connecter',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.navy,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
      String label,
      TextEditingController controller, {
        String? hint,
        TextInputType? keyboardType,
        bool obscure = false,
        VoidCallback? toggleObscure,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7,
                color: Colors.grey.shade700)),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.navy, width: 1.5),
            ),
            suffixIcon: toggleObscure == null
                ? null
                : IconButton(
              icon: Icon(obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: toggleObscure,
            ),
          ),
        ),
      ],
    );
  }
}