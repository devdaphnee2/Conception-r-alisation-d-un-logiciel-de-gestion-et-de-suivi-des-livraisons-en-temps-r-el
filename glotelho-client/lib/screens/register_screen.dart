import 'package:flutter/material.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color navy = Color(0xFF0D1B2A);
  static const Color gold = Color(0xFFC8960C);

  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  bool _emailValide(String email) =>
      RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  bool _telephoneValide(String tel) =>
      RegExp(r'^\+?[0-9]{8,15}$').hasMatch(tel);

  Future<void> _sInscrire() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte créé avec succès !'),
          backgroundColor: Color(0xFF3B6D11),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Widget _champTexte({
    required String label,
    required TextEditingController controller,
    required IconData icone,
    required String? Function(String?) validateur,
    TextInputType clavier = TextInputType.text,
    bool motDePasse = false,
    bool? obscure,
    VoidCallback? toggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: navy,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: clavier,
          obscureText: obscure ?? false,
          validator: validateur,
          decoration: InputDecoration(
            prefixIcon: Icon(icone, color: navy),
            suffixIcon: motDePasse
                ? IconButton(
              icon: Icon(
                (obscure ?? false)
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey,
              ),
              onPressed: toggleObscure,
            )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: gold, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // En-tête
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'G',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Glotelho',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'EXPRESS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        color: gold,
                      ),
                    ),
                  ],
                ),
              ),

              // Formulaire
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Créer un compte',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Rejoignez Glotelho Express dès maintenant',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      _champTexte(
                        label: 'Nom complet',
                        controller: _nomController,
                        icone: Icons.person_outline,
                        validateur: (val) {
                          if (val == null || val.isEmpty)
                            return 'Le nom est obligatoire';
                          if (val.length < 3) return 'Au moins 3 caractères';
                          return null;
                        },
                      ),

                      _champTexte(
                        label: 'Adresse email',
                        controller: _emailController,
                        icone: Icons.email_outlined,
                        clavier: TextInputType.emailAddress,
                        validateur: (val) {
                          if (val == null || val.isEmpty)
                            return 'L\'email est obligatoire';
                          if (!_emailValide(val)) return 'Email invalide';
                          return null;
                        },
                      ),

                      _champTexte(
                        label: 'Téléphone',
                        controller: _telephoneController,
                        icone: Icons.phone_outlined,
                        clavier: TextInputType.phone,
                        validateur: (val) {
                          if (val == null || val.isEmpty)
                            return 'Le téléphone est obligatoire';
                          if (!_telephoneValide(val))
                            return 'Numéro invalide';
                          return null;
                        },
                      ),

                      _champTexte(
                        label: 'Mot de passe',
                        controller: _passwordController,
                        icone: Icons.lock_outline,
                        motDePasse: true,
                        obscure: _obscurePassword,
                        toggleObscure: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                        validateur: (val) {
                          if (val == null || val.isEmpty)
                            return 'Le mot de passe est obligatoire';
                          if (val.length < 6)
                            return 'Au moins 6 caractères';
                          return null;
                        },
                      ),

                      _champTexte(
                        label: 'Confirmer le mot de passe',
                        controller: _confirmPasswordController,
                        icone: Icons.lock_outline,
                        motDePasse: true,
                        obscure: _obscureConfirm,
                        toggleObscure: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        validateur: (val) {
                          if (val == null || val.isEmpty)
                            return 'Confirmez votre mot de passe';
                          if (val != _passwordController.text)
                            return 'Les mots de passe ne correspondent pas';
                          return null;
                        },
                      ),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sInscrire,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navy,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                              : const Text(
                            'Créer mon compte',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Déjà un compte ? Se connecter',
                            style: TextStyle(
                              color: gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}