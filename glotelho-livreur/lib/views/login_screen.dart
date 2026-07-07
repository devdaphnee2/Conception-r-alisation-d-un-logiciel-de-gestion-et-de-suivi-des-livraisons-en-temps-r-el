import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../utils/constants.dart';
import '../utils/driver_state.dart';
import '../services/api_service.dart';
import 'main_navigation_screen.dart';
import 'pending_verification_screen.dart';
import 'signup/signup_screen.dart';
import '../services/google_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_phoneCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      _showError('Veuillez remplir tous les champs');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.dio.post('/drivers/login', data: {
        'telephone': _phoneCtrl.text.trim(),
        'password': _passwordCtrl.text.trim(),
      });

      final data = response.data;
      final token = data['token'] ?? data['data']?['token'];

      if (token == null) {
        _showError('Réponse serveur invalide');
        return;
      }

      final driverState = context.read<DriverState>();
      await driverState.saveSession(token);
      ApiService.setToken(token);
      await driverState.refreshProfile();

      if (!mounted) return;

      if (driverState.driver?.isVerified == true) {
        Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()), (r) => false);
      } else {
        Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (_) => const PendingVerificationScreen()), (r) => false);
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Identifiants incorrects')
          : 'Erreur réseau, vérifiez votre connexion';
      _showError(msg.toString());
    } catch (e) {
      _showError('Une erreur est survenue');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    final token = await GoogleAuthService.signInWithGoogle();
    if (!mounted) return;

    if (token == null) {
      setState(() => _isLoading = false);
      _showError('Connexion Google annulée ou échouée');
      return;
    }

    final driverState = context.read<DriverState>();
    await driverState.saveSession(token);
    ApiService.setToken(token);
    await driverState.refreshProfile();

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (driverState.driver?.isVerified == true) {
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()), (r) => false);
    } else {
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => const PendingVerificationScreen()), (r) => false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
                  },
                  child: const Text('🧪 Accès test (sans backend)', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ),
              ),

              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12)],
                  ),
                  child: Image.asset('assets/images/glotelho_delivery_logo_high_contrast.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Connexion',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Connectez-vous pour commencer vos livraisons',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 32),

              _buildField(_phoneCtrl, 'Téléphone ou e-mail', Icons.person_outline),
              const SizedBox(height: 16),
              _buildField(_passwordCtrl, 'Mot de passe', Icons.lock_outline, isPassword: true),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Mot de passe oublié ?', style: TextStyle(color: AppColors.gold, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Se connecter',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white24)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('ou', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: Colors.white24)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loginWithGoogle,
                  icon: Image.network(
                    'https://www.google.com/favicon.ico',
                    width: 18, height: 18,
                    errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, color: Colors.white),
                  ),
                  label: const Text('Continuer avec Google', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Pas encore livreur ? ',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                      children: [
                        TextSpan(text: 'Inscrivez-vous', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword ? _obscure : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20),
          onPressed: () => setState(() => _obscure = !_obscure),
        )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold, width: 1.5)),
      ),
    );
  }


}