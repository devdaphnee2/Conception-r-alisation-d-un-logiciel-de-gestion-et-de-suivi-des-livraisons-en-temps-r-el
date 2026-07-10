import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../config/app_strings.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';

/// Écran de changement de mot de passe — fond navy fixe (identité
/// visuelle forte pour un écran sécurité), repris de la maquette fournie.
/// Le bouton était doré sur la maquette ; remplacé par blanc/gris pour
/// rester sur la palette navy + blanc/noir uniquement.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _newPwd = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  bool get _canSubmit =>
      _current.text.isNotEmpty &&
          _newPwd.text.length >= 8 &&
          _newPwd.text == _confirm.text;

  @override
  void dispose() {
    _current.dispose();
    _newPwd.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _loading = true);
    try {
      final api = ApiService(context.read<AppState>());
      await api.changePassword(_current.text, _newPwd.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF2ECC9B)),
                const SizedBox(width: 10),
                Text(AppStrings.t(context, 'password_update_success')),
              ],
            ),
            backgroundColor: AppTheme.navyLight,
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 8),
                  Text(AppStrings.t(context, 'change_password_subtitle'),
                      style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  Text(AppStrings.t(context, 'change_password_title'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 30),
                  _field(AppStrings.t(context, 'current_password'), _current),
                  const SizedBox(height: 24),
                  _field(AppStrings.t(context, 'new_password'), _newPwd),
                  const SizedBox(height: 24),
                  _field(AppStrings.t(context, 'confirm_password'), _confirm),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_canSubmit && !_loading) ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSubmit ? Colors.white : Colors.white24,
                    foregroundColor: _canSubmit ? AppTheme.navy : Colors.white54,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(AppStrings.t(context, 'update'),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}