import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../views/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color navy    = Color(0xFF0D1B2A);
  static const Color gold    = Color(0xFFC8960C);
  static const Color goldBtn = Color(0xFFE5A800);

  final _formKey                   = GlobalKey<FormState>();
  final _nomController             = TextEditingController();
  final _emailController           = TextEditingController();
  final _telephoneController       = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword    = true;
  bool _obscureConfirm     = true;
  bool _acceptConditions   = false;
  bool _isLoading          = false;

  bool _emailValide(String email) =>
      RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  bool _telephoneValide(String tel) =>
      RegExp(r'^\+?[0-9]{8,15}$').hasMatch(tel);

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sInscrire() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptConditions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez accepter les conditions d\'utilisation'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthController.register(
      nom:       _nomController.text.trim(),
      email:     _emailController.text.trim(),
      telephone: _telephoneController.text.trim(),
      password:  _passwordController.text,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['success'] == true) {
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Erreur lors de l\'inscription.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Champ texte générique ────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A202C)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFADB5C7), fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFFADB5C7), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.12),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          BorderSide(color: Colors.white.withOpacity(0.20), width: 1.2),
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

  // ── Label doré au-dessus de chaque champ ────────────────────
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: gold,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: navy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Logo centré ────────────────────────────────
                Center(child: _GlotelhLogo()),

                const SizedBox(height: 28),

                // ── Titre + sous-titre ─────────────────────────
                const Center(
                  child: Text(
                    'Créer un compte',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Rejoignez la révolution de la livraison rapide.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Nom complet ────────────────────────────────
                _label('Nom complet'),
                _buildField(
                  controller: _nomController,
                  hint: 'John Doe',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Le nom est obligatoire';
                    if (val.length < 3) return 'Au moins 3 caractères';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ── Email ──────────────────────────────────────
                _label('Email'),
                _buildField(
                  controller: _emailController,
                  hint: 'entrezvotreemail@gmail.com',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'L\'email est obligatoire';
                    if (!_emailValide(val)) return 'Email invalide';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ── Numéro de téléphone (+237 | champ) ────────
                _label('Numéro de téléphone'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bouton indicatif +237
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: navy,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.20),
                          width: 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '+237',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Champ numéro
                    Expanded(
                      child: TextFormField(
                        controller: _telephoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF1A202C)),
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return 'Le téléphone est obligatoire';
                          if (!_telephoneValide(val)) return 'Numéro invalide';
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: '6XX XXX XXX',
                          hintStyle: const TextStyle(
                              color: Color(0xFFADB5C7), fontSize: 14),
                          prefixIcon: const Icon(Icons.phone_outlined,
                              color: Color(0xFFADB5C7), size: 20),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.12),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.20),
                                width: 1.2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            const BorderSide(color: gold, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Colors.red, width: 1.2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Colors.red, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Mot de passe ───────────────────────────────
                _label('Mot de passe'),
                _buildField(
                  controller: _passwordController,
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFFADB5C7),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty)
                      return 'Le mot de passe est obligatoire';
                    if (val.length < 6) return 'Au moins 6 caractères';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ── Confirmer le mot de passe ──────────────────
                _label('Confirmer le mot de passe'),
                _buildField(
                  controller: _confirmPasswordController,
                  hint: '••••••••',
                  prefixIcon: Icons.lock_reset_rounded,
                  obscureText: _obscureConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFFADB5C7),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty)
                      return 'Confirmez votre mot de passe';
                    if (val != _passwordController.text)
                      return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Checkbox conditions ────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _acceptConditions,
                        onChanged: (v) =>
                            setState(() => _acceptConditions = v ?? false),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.40),
                          width: 1.5,
                        ),
                        checkColor: navy,
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) return gold;
                          return Colors.transparent;
                        }),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.80),
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(text: "J'accepte les "),
                            TextSpan(
                              text: "Conditions d'Utilisation",
                              style: const TextStyle(
                                color: gold,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: gold,
                              ),
                            ),
                            const TextSpan(text: " et la "),
                            TextSpan(
                              text: "Politique de Confidentialité",
                              style: const TextStyle(
                                color: gold,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: gold,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Bouton S'INSCRIRE ──────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sInscrire,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldBtn,
                      disabledBackgroundColor: goldBtn.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "S'INSCRIRE",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // ── OU S'INSCRIRE AVEC ─────────────────────────
                Row(
                  children: [
                    Expanded(
                        child: Divider(
                            color: Colors.white.withOpacity(0.18),
                            thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OU S\'INSCRIRE AVEC',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.40),
                          fontSize: 11,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                        child: Divider(
                            color: Colors.white.withOpacity(0.18),
                            thickness: 1)),
                  ],
                ),

                const SizedBox(height: 18),

                // ── Google + Facebook (fond navy) ──────────────
                Row(
                  children: [
                    Expanded(child: _oauthButton('Google', _googleIcon())),
                    const SizedBox(width: 14),
                    Expanded(child: _oauthButton('Facebook', _facebookIcon())),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Lien Se connecter ──────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                        children: [
                          TextSpan(text: 'Vous avez déjà un compte ?  '),
                          TextSpan(
                            text: 'Se connecter',
                            style: TextStyle(
                              color: gold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Bouton OAuth (fond navy avec bordure) ────────────────────
  Widget _oauthButton(String label, Widget icon) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: navy,
          side: BorderSide(color: Colors.white.withOpacity(0.20), width: 1.2),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _googleIcon() => SizedBox(
    width: 20,
    height: 20,
    child: CustomPaint(painter: _GoogleLogoPainter()),
  );

  Widget _facebookIcon() => Container(
    width: 20,
    height: 20,
    decoration: BoxDecoration(
      color: const Color(0xFF1877F2),
      borderRadius: BorderRadius.circular(4),
    ),
    alignment: Alignment.center,
    child: const Text(
      'f',
      style: TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// Logo Glotelho
// ─────────────────────────────────────────────────────────────────
class _GlotelhLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CustomPaint(painter: _GlotelhLogoPainter()),
        ),
        const SizedBox(height: 10),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                  text: 'Glotelho ',
                  style: TextStyle(color: Colors.white)),
              TextSpan(
                  text: 'Express',
                  style: TextStyle(color: Color(0xFFC8960C))),
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

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -0.4, 5.1, false, arcPaint,
    );

    canvas.drawLine(
      Offset(cx + 1, cy),
      Offset(cx + r + sw / 2, cy),
      arcPaint,
    );

    final arrowPaint = Paint()
      ..color = const Color(0xFFC8960C)
      ..style = PaintingStyle.fill;

    final aw = size.width * 0.26;
    final ah = size.height * 0.14;
    final ax = cx - aw * 0.45;
    final ay = cy + size.height * 0.06;

    final path = Path()
      ..moveTo(ax, ay)
      ..lineTo(ax + aw * 0.60, ay)
      ..lineTo(ax + aw * 0.60, ay - ah * 0.55)
      ..lineTo(ax + aw, ay + ah * 0.15)
      ..lineTo(ax + aw * 0.60, ay + ah * 0.85)
      ..lineTo(ax + aw * 0.60, ay + ah * 0.40)
      ..lineTo(ax, ay + ah * 0.40)
      ..close();
    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────
// Google logo
// ─────────────────────────────────────────────────────────────────
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const pi = 3.14159265;
    final c  = Offset(size.width / 2, size.height / 2);
    final r  = size.width * 0.42;
    final sw = size.width * 0.22;

    void arc(Color color, double start, double sweep) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start, sweep, false,
        Paint()
          ..color       = color
          ..style       = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap   = StrokeCap.butt,
      );
    }

    arc(const Color(0xFF4285F4), -pi / 2,           pi * 0.50);
    arc(const Color(0xFF34A853), -pi / 2 + pi*0.50, pi * 0.50);
    arc(const Color(0xFFFBBC05), -pi / 2 + pi*1.00, pi * 0.25);
    arc(const Color(0xFFEA4335), -pi / 2 + pi*1.25, pi * 0.75);

    canvas.drawLine(
      Offset(c.dx, c.dy),
      Offset(c.dx + r + sw / 2, c.dy),
      Paint()
        ..color       = const Color(0xFF4285F4)
        ..strokeWidth = sw
        ..strokeCap   = StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}