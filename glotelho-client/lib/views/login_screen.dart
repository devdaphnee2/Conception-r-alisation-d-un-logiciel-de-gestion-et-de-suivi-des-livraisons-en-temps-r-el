import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../views/forgot_password_screen.dart';
import '../views/register_screen.dart';
import '../utils/app_state.dart';
import '../utils/constants.dart';
import '../controllers/auth_controller.dart';
import '../services/api_service.dart';
import '../views/home_screen.dart';
import '../services/fcm_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color navy    = Color(0xFF0D1B2A);
  static const Color gold    = Color(0xFFC8960C);
  static const Color goldBtn = Color(0xFFE5A800);

  final _formKey             = GlobalKey<FormState>();
  final _emailController     = TextEditingController();
  final _passwordController  = TextEditingController();
  bool  _obscurePassword     = true;
  bool  _isLoading           = false;
  bool  _isGoogleLoading     = false;

  bool _emailValide(String email) =>
      RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Connexion email/password ────────────────────────────────────
  Future<void> _seConnecter() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await AuthController.login(
      email:    _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['success'] == true) {
      final data  = result['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user  = data['user']  as Map<String, dynamic>;

      ApiService.setToken(token);

      context.read<AppState>().setUser(
        token:     token,
        firstName: user['full_name'] as String? ?? '',
        lastName:  '',
        email:     user['email']    as String? ?? '',
        phone:     user['phone']    as String? ?? '',
        avatarUrl: user['avatar_url'] as String?,
      );

      FcmService.registerTokenWithBackend();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connexion réussie !'), backgroundColor: Color(0xFF3B6D11)),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Identifiants incorrects.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Connexion Google ────────────────────────────────────────────
  Future<void> _seConnecterGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        setState(() => _isGoogleLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de récupérer le token Google.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final result = await AuthController.googleLogin(idToken: idToken);

      setState(() => _isGoogleLoading = false);
      if (!mounted) return;

      if (result['success'] == true) {
        final data  = result['data'] as Map<String, dynamic>;
        final token = data['token'] as String;
        final user  = data['user']  as Map<String, dynamic>;

        ApiService.setToken(token);

        context.read<AppState>().setUser(
          token:     token,
          firstName: user['full_name'] as String? ?? '',
          lastName:  '',
          email:     user['email']    as String? ?? '',
          phone:     user['phone']    as String? ?? '',
          avatarUrl: user['avatar_url'] as String?,
        );

        FcmService.registerTokenWithBackend();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connexion Google réussie !'), backgroundColor: Color(0xFF3B6D11)),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur connexion Google.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGoogleLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur Google Sign-In : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Champ de saisie unifié ──────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    bool isDark = false,
  }) {
    final fieldBg    = isDark ? const Color(0xFF1E2733) : Colors.white;
    final textColor  = isDark ? Colors.white : const Color(0xFF1A202C);
    final hintColor  = isDark ? Colors.white38 : const Color(0xFFADB5C7);
    final borderColor = isDark ? const Color(0xFF2E3A4D) : const Color(0xFFE2E8F0);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor, fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: hintColor, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark          = Theme.of(context).brightness == Brightness.dark;
    final cardBg          = isDark ? const Color(0xFF161D29) : const Color(0xFFF5F7FA);
    final labelColor      = isDark ? Colors.white : const Color(0xFF2D3748);
    final dividerColor    = isDark ? const Color(0xFF2E3A4D) : Colors.grey.shade300;
    final dividerTextColor = isDark ? Colors.white38 : Colors.grey.shade400;
    final footerColor     = isDark ? Colors.white60 : const Color(0xFF718096);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: navy,
      body: Column(
        children: [
          // ── Zone navy : logo + titre ──────────────────────────
          Expanded(
            flex: 38,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _GlotelhLogo(),
                      const SizedBox(height: 16),
                      const Text('Welcome Back',
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text(
                        'Reliable. Precise. Velocity. The logistics\nplatform for everyday heroes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF8A9BB0), fontSize: 13, height: 1.55),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Carte blanche arrondie ────────────────────────────
          Expanded(
            flex: 55,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.only(
                  topLeft:  Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Email ───────────────────────────────
                      Text('Email or Phone Number',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor)),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _emailController,
                        hint: 'yourname@email.com',
                        prefixIcon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        isDark: isDark,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'L\'email est obligatoire';
                          if (!_emailValide(val)) return 'Email invalide';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // ── Password ────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Password',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor)),
                          GestureDetector(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                            child: const Text('Forgot password?',
                              style: TextStyle(color: gold, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _passwordController,
                        hint: '••••••••',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        isDark: isDark,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: isDark ? Colors.white38 : const Color(0xFFADB5C7),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Le mot de passe est obligatoire';
                          if (val.length < 6) return 'Au moins 6 caractères';
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // ── Bouton LOG IN ───────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _seConnecter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldBtn,
                            disabledBackgroundColor: goldBtn.withOpacity(0.6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 10),
                                    Text('LOG IN',
                                      style: TextStyle(color: Colors.white, fontSize: 15,
                                        fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── OR CONTINUE WITH ────────────────────
                      Row(
                        children: [
                          Expanded(child: Divider(color: dividerColor, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('OR CONTINUE WITH',
                              style: TextStyle(color: dividerTextColor, fontSize: 11,
                                letterSpacing: 0.8, fontWeight: FontWeight.w500)),
                          ),
                          Expanded(child: Divider(color: dividerColor, thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ── Google + Facebook ───────────────────
                      Row(
                        children: [
                          Expanded(child: _oauthButton('Google', _googleIcon(), isDark,
                            onPressed: _isGoogleLoading ? null : _seConnecterGoogle,
                            isLoading: _isGoogleLoading)),
                          const SizedBox(width: 14),
                          Expanded(child: _oauthButton('Facebook', _facebookIcon(), isDark,
                            onPressed: null)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Create an account ───────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 14, color: footerColor),
                              children: const [
                                TextSpan(text: "Don't have an account? "),
                                TextSpan(text: 'Create an account',
                                  style: TextStyle(color: gold, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _oauthButton(String label, Widget icon, bool isDark, {
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF1E2733) : Colors.white,
          side: BorderSide(
            color: isDark ? const Color(0xFF2E3A4D) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC8960C)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 8),
                  Text(label,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF2D3748),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    )),
                ],
              ),
      ),
    );
  }

  Widget _googleIcon() => SizedBox(
    width: 20, height: 20,
    child: CustomPaint(painter: _GoogleLogoPainter()),
  );

  Widget _facebookIcon() => Container(
    width: 20, height: 20,
    decoration: BoxDecoration(color: const Color(0xFF1877F2), borderRadius: BorderRadius.circular(4)),
    alignment: Alignment.center,
    child: const Text('f',
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
  );
}

// ── Logo Glotelho ──────────────────────────────────────────────────
class _GlotelhLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(width: 90, height: 90, child: CustomPaint(painter: _GlotelhLogoPainter())),
        const SizedBox(height: 10),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: 'Glotelho ', style: TextStyle(color: Colors.white)),
              TextSpan(text: 'Express', style: TextStyle(color: Color(0xFFC8960C))),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlotelhLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.40;
    final sw = size.width * 0.10;

    final arcPaint = Paint()
      ..color       = const Color(0xFFC8960C)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap   = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), -0.4, 5.1, false, arcPaint);
    canvas.drawLine(Offset(cx + 1, cy), Offset(cx + r + sw / 2, cy), arcPaint);

    final arrowPaint = Paint()..color = const Color(0xFFC8960C)..style = PaintingStyle.fill;
    final aw = size.width * 0.26;
    final ah = size.height * 0.14;
    final ax = cx - aw * 0.45;
    final ay = cy + size.height * 0.06;

    final path = Path()
      ..moveTo(ax, ay)
      ..lineTo(ax + aw * 0.60, ay)
      ..lineTo(ax + aw * 0.60, ay - ah * 0.55)
      ..lineTo(ax + aw,        ay + ah * 0.15)
      ..lineTo(ax + aw * 0.60, ay + ah * 0.85)
      ..lineTo(ax + aw * 0.60, ay + ah * 0.40)
      ..lineTo(ax,             ay + ah * 0.40)
      ..close();
    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const pi = 3.14159265;
    final c  = Offset(size.width / 2, size.height / 2);
    final r  = size.width * 0.42;
    final sw = size.width * 0.22;

    void arc(Color color, double start, double sweep) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r), start, sweep, false,
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.butt,
      );
    }

    arc(const Color(0xFF4285F4), -pi / 2,            pi * 0.5);
    arc(const Color(0xFF34A853), -pi / 2 + pi * 0.5, pi * 0.5);
    arc(const Color(0xFFFBBC05), -pi / 2 + pi * 1.0, pi * 0.25);
    arc(const Color(0xFFEA4335), -pi / 2 + pi * 1.25, pi * 0.75);

    canvas.drawLine(Offset(c.dx, c.dy), Offset(c.dx + r + sw / 2, c.dy),
      Paint()..color = const Color(0xFF4285F4)..strokeWidth = sw..strokeCap = StrokeCap.butt);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
