import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';

/// Écran "Mot de passe oublié" — le commerçant saisit son email,
/// on envoie la demande au backend puis on affiche une confirmation.
/// NB : suppose l'endpoint /auth/forgot-password côté backend
/// (voir TODO dans ApiService.forgotPassword) — à valider avec le
/// développeur backend avant mise en prod.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final appState = context.read<AppState>();
      final api = ApiService(appState);
      await api.forgotPassword(_emailController.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      setState(() {
        _error = "Impossible d'envoyer le lien pour le moment. Réessayez.";
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.navy,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _sent ? _buildConfirmation() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.navy.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.lock_reset_outlined,
                color: AppTheme.navy, size: 28),
          ),
          const SizedBox(height: 24),
          const Text(
            'Mot de passe oublié',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Entrez l\'email associé à votre compte commerçant, '
                'nous vous enverrons un lien pour réinitialiser votre mot de passe.',
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 28),

          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                    color: Color(0xFFBA1A1A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Text('EMAIL',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.7,
                  color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'commerçant@glotelho.com',
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
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
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Champ requis';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.2, color: Colors.white),
              )
                  : const Text('Envoyer le lien'),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Retour à la connexion',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFDCF5E3),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              color: Color(0xFF1E7A3B), size: 32),
        ),
        const SizedBox(height: 24),
        const Text(
          'Email envoyé',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Si un compte existe pour ${_emailController.text.trim()}, '
              'un lien de réinitialisation vient de lui être envoyé. '
              'Pensez à vérifier vos spams.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.navy,
              side: BorderSide(color: AppTheme.navy),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Retour à la connexion'),
          ),
        ),
      ],
    );
  }
}