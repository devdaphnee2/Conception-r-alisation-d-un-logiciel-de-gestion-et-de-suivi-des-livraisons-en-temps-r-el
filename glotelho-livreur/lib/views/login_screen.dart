import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../utils/constants.dart';
import '../utils/driver_state.dart';
import '../services/api_service.dart';
import '../services/polling_service.dart';
import '../models/driver_model.dart';
import 'main_navigation_screen.dart';
import 'pending_verification_screen.dart';
import 'signup/signup_screen.dart';
import '../services/google_auth_service.dart';
import 'auth/forgot_password_screen.dart';
import '../services/biometric_service.dart';

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

  void _goAfterLogin(DriverState driverState) {
    if (driverState.driver?.status == DriverStatus.approved) {
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()), (r) => false);
    } else {
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => const PendingVerificationScreen()), (r) => false);
    }
  }

  Future<void> _maybeOfferBiometrics(String token) async {
    if (await BiometricService.isAvailable() && !await BiometricService.isEnabled()) {
      if (!mounted) return;
      final activer = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardNavy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Connexion rapide', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: const Text(
            'Voulez-vous activer la connexion par empreinte digitale pour les prochaines fois ?',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Plus tard', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
              child: const Text('Activer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (activer == true) await BiometricService.enable(token);
    }
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
      final data  = response.data;
      final token = data['token'] ?? data['data']?['token'];
      if (token == null) { _showError('Réponse serveur invalide'); return; }

      final driverState = context.read<DriverState>();
      await driverState.saveSession(token);
      ApiService.setToken(token);
      await driverState.refreshProfile();

      // Démarrer le polling après connexion
      if (driverState.driver?.status == DriverStatus.approved) {
        await PollingService.start();
      }

      if (!mounted) return;
      await _maybeOfferBiometrics(token);
      if (!mounted) return;
      _goAfterLogin(driverState);
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Identifiants incorrects')
          : 'Erreur réseau, vérifiez votre connexion';
      _showError(msg.toString());
    } catch (_) {
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
    if (driverState.driver?.status == DriverStatus.approved) {
      await PollingService.start();
    }
    setState(() => _isLoading = false);
    if (!mounted) return;
    await _maybeOfferBiometrics(token);
    if (!mounted) return;
    _goAfterLogin(driverState);
  }

  Future<void> _loginWithBiometrics() async {
    final ok = await BiometricService.authenticate(reason: 'Déverrouillez pour accéder à votre compte');
    if (!ok) return;
    final token = await BiometricService.getSavedToken();
    if (token == null) { _showError('Aucune session enregistrée. Connectez-vous manuellement.'); return; }
    final driverState = context.read<DriverState>();
    await driverState.saveSession(token);
    ApiService.setToken(token);
    await driverState.refreshProfile();
    if (driverState.driver?.status == DriverStatus.approved) {
      await PollingService.start();
    }
    if (!mounted) return;
    _goAfterLogin(driverState);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF102A43), AppColors.navy],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        Center(
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/glotelho_delivery_logo_high_contrast.png',
                              width: 110, height: 110, fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text('Bienvenue 👋',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Connectez-vous pour commencer vos livraisons',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 14)),
                        const SizedBox(height: 40),
                        _label('Téléphone ou e-mail'),
                        const SizedBox(height: 8),
                        _buildField(_phoneCtrl, 'Ex : 6XX XXX XXX', Icons.person_outline),
                        const SizedBox(height: 20),
                        _label('Mot de passe'),
                        const SizedBox(height: 8),
                        _buildField(_passwordCtrl, '••••••••', Icons.lock_outline, isPassword: true),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 4)),
                            child: const Text('Mot de passe oublié ?',
                                style: TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              disabledBackgroundColor: AppColors.gold.withOpacity(0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 22, width: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Text('Se connecter',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<bool>(
                          future: BiometricService.isEnabled(),
                          builder: (context, snap) {
                            if (snap.data != true) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _loginWithBiometrics,
                                icon: const Icon(Icons.fingerprint, color: AppColors.gold, size: 24),
                                label: const Text('Se connecter avec empreinte',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 54),
                                  side: const BorderSide(color: AppColors.gold),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(children: const [
                          Expanded(child: Divider(color: Colors.white24)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text('ou', style: TextStyle(color: Colors.white38, fontSize: 13)),
                          ),
                          Expanded(child: Divider(color: Colors.white24)),
                        ]),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 54,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _loginWithGoogle,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _googleG(),
                                const SizedBox(width: 12),
                                const Text('Continuer avec Google',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.push(
                                context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                            child: const Text.rich(TextSpan(
                              text: 'Pas encore livreur ? ',
                              style: TextStyle(color: Colors.white54, fontSize: 14),
                              children: [
                                TextSpan(text: 'Inscrivez-vous',
                                    style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                              ],
                            )),
                          ),
                        ),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const MainNavigationScreen())),
                            child: const Text('Accès test (sans backend)',
                                style: TextStyle(color: Colors.white24, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500));

  Widget _googleG() => Container(
    width: 22, height: 22,
    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
    alignment: Alignment.center,
    child: const Text('G', style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.bold, fontSize: 15, height: 1)),
  );

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword ? _obscure : false,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.white54, size: 20),
          onPressed: () => setState(() => _obscure = !_obscure),
        )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.gold, width: 1.5)),
      ),
    );
  }
}