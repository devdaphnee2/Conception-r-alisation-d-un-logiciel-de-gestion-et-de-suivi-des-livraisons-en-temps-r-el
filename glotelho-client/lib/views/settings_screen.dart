/*import 'package:flutter/material.dart';
SKIPPED_COMMENT_BLOCK*/

import 'dart:io';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final isDark = state.isDarkMode;
    final bg       = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF5F5F5);
    final cardBg   = isDark ? const Color(0xFF1E2A38) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor  = isDark ? Colors.white54 : Colors.grey;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0D1B2A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t('settings'),
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t('settings'),
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 4),
                      Text(t('subtitle'), style: TextStyle(fontSize: 13, color: subColor)),
                    ],
                  ),
                ),
                _DayNightToggle(isDark: isDark, onToggle: () {
                  context.read<AppState>().setDarkMode(!isDark);
                }),
              ],
            ),
            const SizedBox(height: 28),

            _SectionLabel(t('section_account'), subColor),
            const SizedBox(height: 10),
            _SettingsCard(isDark: isDark, children: [
              _SettingsItem(
                icon: Icons.person_outline, label: t('profile'),
                textColor: textColor, isDark: isDark,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen())),
              ),
              _Divider(isDark),
              _SettingsItem(
                icon: Icons.lock_outline, label: t('privacy'),
                textColor: textColor, isDark: isDark,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PrivacyScreen())),
              ),
            ]),
            const SizedBox(height: 22),

            _SectionLabel(t('section_general'), subColor),
            const SizedBox(height: 10),
            _SettingsCard(isDark: isDark, children: [
              _SettingsItem(
                icon: Icons.notifications_outlined, label: t('notifications'),
                textColor: textColor, isDark: isDark,
                onTap: () => _showNotificationSettings(context, state),
              ),
              _Divider(isDark),
              _SettingsItem(
                icon: Icons.language_outlined, label: t('language'),
                textColor: textColor, isDark: isDark,
                trailing: Text(
                  state.language == 'Français' ? '🇫🇷 FR' : '🇬🇧 EN',
                  style: TextStyle(color: subColor, fontSize: 13),
                ),
                onTap: () => _showLanguagePicker(context, state),
              ),
              _Divider(isDark),
              _SettingsItem(
                icon: Icons.info_outline, label: t('about'),
                textColor: textColor, isDark: isDark,
                onTap: () => _showAbout(context, state),
              ),
              _Divider(isDark),
              _SettingsItem(
                icon: Icons.help_outline, label: t('help'),
                textColor: textColor, isDark: isDark,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HelpScreen())),
              ),
            ]),
            const SizedBox(height: 22),

            _SectionLabel(t('section_security'), subColor),
            const SizedBox(height: 10),
            _SettingsCard(isDark: isDark, children: [
              _SettingsItem(
                icon: Icons.fingerprint, label: t('biometric'),
                textColor: textColor, isDark: isDark,
                trailing: Switch(
                  value: state.biometricEnabled,
                  activeColor: AppColors.gold,
                  onChanged: (val) => _toggleBiometric(context, state, val),
                ),
              ),
              _Divider(isDark),
              _SettingsItem(
                icon: Icons.password_outlined, label: t('change_password'),
                textColor: textColor, isDark: isDark,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
              ),
            ]),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity, height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context, state),
                icon: const Icon(Icons.logout, color: Colors.red, size: 20),
                label: Text(t('logout'),
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(child: Text('Glotelho Express v1.0.0', style: TextStyle(fontSize: 12, color: subColor))),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _toggleBiometric(BuildContext context, AppState state, bool val) async {
    final auth = LocalAuthentication();

    // Vérifier si la biométrie est disponible sur l'appareil
    final bool canCheck = await auth.canCheckBiometrics;
    final bool isAvailable = await auth.isDeviceSupported();

    if (!canCheck || !isAvailable) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Aucune biométrie disponible sur cet appareil.'),
          backgroundColor: Colors.orange,
        ));
      }
      return;
    }

    if (val) {
      // Activer : demande d'authentification biométrique pour confirmer
      try {
        final bool authenticated = await auth.authenticate(
          localizedReason: 'Scannez votre empreinte pour activer la biométrie',
          options: const AuthenticationOptions(
            biometricOnly: false, // permet aussi le PIN en fallback
            stickyAuth: true,
          ),
        );
        if (authenticated && context.mounted) {
          state.setBiometric(true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Authentification biométrique activée ✓'),
            backgroundColor: Colors.green,
          ));
        }
      } on PlatformException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur biométrie : ${e.message}'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } else {
      // Désactiver : confirmation simple
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(state.t('biometric_disable')),
            content: Text(state.t('biometric_confirm')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(state.t('cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  state.setBiometric(false);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                child: Text(state.t('confirm'),
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    }
  }

  void _confirmLogout(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(state.t('logout_title')),
        content: Text(state.t('logout_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(state.t('cancel'))),
          ElevatedButton(
            onPressed: () {
              state.setLoggedIn(false);
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(state.t('yes_logout'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _sheetHandle(),
          const SizedBox(height: 16),
          Text(state.t('choose_language'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          for (final lang in ['Français', 'English'])
            ListTile(
              leading: Text(lang == 'Français' ? '🇫🇷' : '🇬🇧', style: const TextStyle(fontSize: 24)),
              title: Text(lang, style: TextStyle(fontWeight: state.language == lang ? FontWeight.bold : FontWeight.normal)),
              trailing: state.language == lang ? Icon(Icons.check_circle, color: AppColors.gold) : null,
              onTap: () { state.setLanguage(lang); Navigator.pop(context); },
            ),
        ]),
      ),
    );
  }

  void _showNotificationSettings(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ChangeNotifierProvider.value(
          value: state, child: const _NotificationSettingsSheet()),
    );
  }

  void _showAbout(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Glotelho Express', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(state.t('about_text'), style: const TextStyle(fontSize: 13)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: AppColors.gold)))],
      ),
    );
  }

  Widget _sheetHandle() => Center(child: Container(
    width: 40, height: 4,
    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
  ));
}

// ── Toggle jour/nuit ─────────────────────────────────────────────
class _DayNightToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;
  const _DayNightToggle({required this.isDark, required this.onToggle});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onToggle,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 72, height: 36,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFFFD54F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(children: [
        Positioned(left: 6, top: 0, bottom: 0,
            child: Center(child: Text('☀️', style: TextStyle(fontSize: 15, color: isDark ? Colors.white24 : Colors.white)))),
        Positioned(right: 6, top: 0, bottom: 0,
            child: Center(child: Text('🌙', style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.white24)))),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          left: isDark ? 36 : 2, top: 2,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)]),
            child: Center(child: Text(isDark ? '🌙' : '☀️', style: const TextStyle(fontSize: 16))),
          ),
        ),
      ]),
    ),
  );
}

// ── Widgets helpers ──────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label; final Color color;
  const _SectionLabel(this.label, this.color);
  @override
  Widget build(BuildContext context) => Text(label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 1));
}

class _SettingsCard extends StatelessWidget {
  final bool isDark; final List<Widget> children;
  const _SettingsCard({required this.isDark, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E2A38) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 8)],
    ),
    child: Column(children: children),
  );
}

class _SettingsItem extends StatelessWidget {
  final IconData icon; final String label; final Color textColor;
  final bool isDark; final Widget? trailing; final VoidCallback? onTap;
  const _SettingsItem({required this.icon, required this.label,
    required this.textColor, required this.isDark, this.trailing, this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black87, size: 22),
    title: Text(label, style: TextStyle(fontSize: 14, color: textColor)),
    trailing: trailing ?? Icon(Icons.chevron_right, color: isDark ? Colors.white38 : Colors.grey.shade400, size: 20),
    onTap: onTap, dense: true,
  );
}

class _Divider extends StatelessWidget {
  final bool isDark; const _Divider(this.isDark);
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100);
}

// ── Notifications bottom sheet ───────────────────────────────────
class _NotificationSettingsSheet extends StatefulWidget {
  const _NotificationSettingsSheet();
  @override
  State<_NotificationSettingsSheet> createState() => _NotifSheetState();
}
class _NotifSheetState extends State<_NotificationSettingsSheet> {
  bool _proximity = true, _orders = true, _promos = false;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text(t('notifications_title'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SwitchListTile(
          value: _proximity, activeColor: AppColors.gold,
          onChanged: (v) => setState(() => _proximity = v),
          secondary: Icon(Icons.delivery_dining, color: AppColors.gold),
          title: Text(t('driver_nearby'), style: const TextStyle(fontSize: 14)),
          subtitle: Text(t('driver_nearby_sub'), style: const TextStyle(fontSize: 12)),
        ),
        SwitchListTile(
          value: _orders, activeColor: AppColors.gold,
          onChanged: (v) => setState(() => _orders = v),
          secondary: Icon(Icons.receipt_outlined, color: AppColors.gold),
          title: Text(t('order_updates'), style: const TextStyle(fontSize: 14)),
        ),
        SwitchListTile(
          value: _promos, activeColor: AppColors.gold,
          onChanged: (v) => setState(() => _promos = v),
          secondary: Icon(Icons.local_offer_outlined, color: AppColors.gold),
          title: Text(t('promotions'), style: const TextStyle(fontSize: 14)),
        ),
      ]),
    );
  }
}

// ── Écran Profil ─────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameCtrl, _emailCtrl, _phoneCtrl;
  bool _isSaving = false, _hasChanges = false;
  File? _pickedImage;
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  bool _emailValide(String v) => RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v);

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _nameCtrl  = TextEditingController(text: state.userName);
    _emailCtrl = TextEditingController(text: state.userEmail);
    _phoneCtrl = TextEditingController(text: state.userPhone);
    if (state.userAvatarPath != null) {
      final f = File(state.userAvatarPath!);
      if (f.existsSync()) _pickedImage = f;
    }
    for (final c in [_nameCtrl, _emailCtrl, _phoneCtrl]) {
      c.addListener(() => setState(() => _hasChanges = true));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Copie la photo dans le dossier permanent de l'app ────────
  Future<File> _savePermanently(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destPath = '${appDir.path}/$fileName';
    return File(sourcePath).copy(destPath);
  }

  // ── Choix de la photo ────────────────────────────────────────
  void _pickImage() {
    final profileCtx = context; // capture avant l'async
    showModalBottomSheet(
      context: profileCtx,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Theme.of(profileCtx).cardColor,
      builder: (sheetCtx) {
        final isDark = Theme.of(profileCtx).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black87;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Choisir une photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(width: 42, height: 42,
                    decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.12), shape: BoxShape.circle),
                    child: Icon(Icons.camera_alt_outlined, color: AppColors.gold)),
                title: Text('Prendre une photo',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                onTap: () async {
                  Navigator.pop(sheetCtx); // ferme le sheet avec son propre contexte
                  await Future.delayed(const Duration(milliseconds: 400));
                  if (!mounted) return;
                  try {
                    final xFile = await _picker.pickImage(
                        source: ImageSource.camera, imageQuality: 80);
                    if (xFile != null && mounted) {
                      final permanent = await _savePermanently(xFile.path);
                      setState(() { _pickedImage = permanent; _hasChanges = true; });
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur caméra : $e'), backgroundColor: Colors.red));
                  }
                },
              ),
              ListTile(
                leading: Container(width: 42, height: 42,
                    decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.12), shape: BoxShape.circle),
                    child: Icon(Icons.photo_library_outlined, color: AppColors.gold)),
                title: Text('Choisir dans la galerie',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                onTap: () async {
                  Navigator.pop(sheetCtx); // ferme le sheet avec son propre contexte
                  await Future.delayed(const Duration(milliseconds: 400));
                  if (!mounted) return;
                  try {
                    final xFile = await _picker.pickImage(
                        source: ImageSource.gallery, imageQuality: 80);
                    if (xFile != null && mounted) {
                      final permanent = await _savePermanently(xFile.path);
                      setState(() { _pickedImage = permanent; _hasChanges = true; });
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur galerie : $e'), backgroundColor: Colors.red));
                  }
                },
              ),
            ]),
          ),
        );
      },
    );
  }

  // ── Sauvegarde ───────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      String? avatarUrl;

      // ── 1) Upload de la photo si une nouvelle a été choisie ────
      if (_pickedImage != null) {
        try {
          final formData = FormData.fromMap({
            'avatar': await MultipartFile.fromFile(
              _pickedImage!.path,
              filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
              contentType: DioMediaType('image', 'jpeg'),
            ),
          });
          final uploadResponse = await ApiService.dio.patch(
            '/auth/me/avatar',
            data: formData,
          );
          avatarUrl = uploadResponse.data['avatar_url'] as String?;
        } catch (e) {
          debugPrint('Upload avatar échoué : $e');
        }
      }

      // ── 2) Mise à jour du profil (nom, email, téléphone) ───────
      final updateResponse = await ApiService.dio.patch(
        '/users/me',
        data: {
          'full_name': _nameCtrl.text.trim(),
          'email':     _emailCtrl.text.trim(),
          'phone':     _phoneCtrl.text.trim(),
        },
      );

      if (!mounted) return;

      // ── 3) Stocker le nouveau token JWT (si email changé) ──────
      final newToken = updateResponse.data['token'] as String?;
      if (newToken != null && newToken.isNotEmpty) {
        ApiService.setToken(newToken);
      }

      // ── 4) Mettre à jour AppState localement ───────────────────
      context.read<AppState>().updateProfile(
        name:       _nameCtrl.text.trim(),
        email:      _emailCtrl.text.trim(),
        phone:      _phoneCtrl.text.trim(),
        avatarPath: avatarUrl ?? _pickedImage?.path,
      );

      setState(() { _isSaving = false; _hasChanges = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour !'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);

    } on DioException catch (e) {
      setState(() => _isSaving = false);
      final msg = e.response?.data['message'] ?? 'Erreur lors de la mise à jour.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0B0F17) : const Color(0xFFF5F5F5);
    final appBarBg   = isDark ? const Color(0xFF161D29) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.white60 : Colors.grey;
    final fieldBg    = isDark ? const Color(0xFF1E2733) : Colors.white;
    final fieldText  = isDark ? Colors.white : Colors.black87;
    final iconColor  = isDark ? Colors.white54 : AppColors.navy;

    return Scaffold(
      resizeToAvoidBottomInset: false, // ← empêche le RenderFlex overflow au retour de la caméra
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: titleColor), onPressed: () => Navigator.pop(context)),
        title: Text(t('profile_title'), style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)),
        actions: [
          if (_hasChanges && !_isSaving)
            TextButton(
              onPressed: _save,
              child: Text('Enregistrer', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            const SizedBox(height: 16),
            // Avatar
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(clipBehavior: Clip.none, children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.gold,
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!)
                        : (state.userAvatarPath != null && state.userAvatarPath!.startsWith('http'))
                        ? NetworkImage(state.userAvatarPath!) as ImageProvider
                        : null,
                    child: (_pickedImage == null && (state.userAvatarPath == null || !state.userAvatarPath!.startsWith('http')))
                        ? Text(state.userName.isNotEmpty ? state.userName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white))
                        : null,
                  ),
                  Positioned(
                    bottom: 2, right: 2,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                          color: AppColors.navy, shape: BoxShape.circle,
                          border: Border.all(color: isDark ? const Color(0xFF0B0F17) : Colors.white, width: 2)),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Center(child: Text('Appuyez pour changer la photo',
                style: TextStyle(fontSize: 12, color: labelColor))),
            const SizedBox(height: 28),
            _field(t('full_name'), _nameCtrl, Icons.person_outline,
                isDark: isDark, fieldBg: fieldBg, fieldText: fieldText, iconColor: iconColor, labelColor: labelColor,
                validator: (v) => (v == null || v.trim().length < 2) ? 'Nom trop court' : null),
            const SizedBox(height: 16),
            _field(t('email'), _emailCtrl, Icons.email_outlined,
                type: TextInputType.emailAddress,
                isDark: isDark, fieldBg: fieldBg, fieldText: fieldText, iconColor: iconColor, labelColor: labelColor,
                validator: (v) => (v == null || !_emailValide(v)) ? 'Email invalide' : null),
            const SizedBox(height: 16),
            _field(t('phone'), _phoneCtrl, Icons.phone_outlined,
                type: TextInputType.phone,
                isDark: isDark, fieldBg: fieldBg, fieldText: fieldText, iconColor: iconColor, labelColor: labelColor,
                validator: (v) => (v == null || v.trim().length < 8) ? 'Numéro invalide' : null),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    disabledBackgroundColor: AppColors.gold.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(t('save'),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {
    TextInputType type = TextInputType.text,
    required bool isDark, required Color fieldBg, required Color fieldText,
    required Color iconColor, required Color labelColor,
    String? Function(String?)? validator,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: labelColor)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl, keyboardType: type, validator: validator,
        style: TextStyle(fontSize: 14, color: fieldText),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: iconColor, size: 20),
          filled: true, fillColor: fieldBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.gold, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.2)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        ),
      ),
    ]);
  }
}

// ── Écran Confidentialité ────────────────────────────────────────
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});
  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}
class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _shareLocation = true, _dataAnalytics = false;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0B0F17) : const Color(0xFFF5F5F5);
    final appBarBg   = isDark ? const Color(0xFF161D29) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final cardBg     = isDark ? const Color(0xFF161D29) : Colors.white;
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: titleColor), onPressed: () => Navigator.pop(context)),
        title: Text(t('privacy_title'), style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            SwitchListTile(
              value: _shareLocation, activeColor: AppColors.gold,
              onChanged: (v) => setState(() => _shareLocation = v),
              secondary: Icon(Icons.location_on_outlined, color: AppColors.gold),
              title: Text(t('share_location'), style: TextStyle(fontSize: 14, color: titleColor)),
              subtitle: Text(t('share_location_sub'), style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),
            SwitchListTile(
              value: _dataAnalytics, activeColor: AppColors.gold,
              onChanged: (v) => setState(() => _dataAnalytics = v),
              secondary: Icon(Icons.analytics_outlined, color: AppColors.gold),
              title: Text(t('data_analytics'), style: TextStyle(fontSize: 14, color: titleColor)),
              subtitle: Text(t('data_analytics_sub'), style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Écran Changer mot de passe ───────────────────────────────────
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePwdState();
}
class _ChangePwdState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController(), _newCtrl = TextEditingController(), _confirmCtrl = TextEditingController();
  bool _oldHidden = true, _newHidden = true, _confirmHidden = true, _isSaving = false;
  @override
  void dispose() { _oldCtrl.dispose(); _newCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0B0F17) : const Color(0xFFF5F5F5);
    final appBarBg   = isDark ? const Color(0xFF161D29) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: titleColor), onPressed: () => Navigator.pop(context)),
        title: Text(t('change_password'), style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(children: [
            const SizedBox(height: 10),
            _pwdField(t('old_password'), _oldCtrl, _oldHidden, () => setState(() => _oldHidden = !_oldHidden),
                    (v) => (v == null || v.isEmpty) ? 'Obligatoire' : null, isDark),
            const SizedBox(height: 16),
            _pwdField(t('new_password'), _newCtrl, _newHidden, () => setState(() => _newHidden = !_newHidden),
                    (v) => (v == null || v.length < 6) ? 'Au moins 6 caractères' : null, isDark),
            const SizedBox(height: 16),
            _pwdField(t('confirm_password'), _confirmCtrl, _confirmHidden, () => setState(() => _confirmHidden = !_confirmHidden),
                    (v) => v != _newCtrl.text ? 'Les mots de passe ne correspondent pas' : null, isDark),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _isSaving = true);

                  final result = await AuthController.changePassword(
                    oldPassword: _oldCtrl.text,
                    newPassword: _newCtrl.text,
                  );

                  setState(() => _isSaving = false);
                  if (!mounted) return;

                  if (result['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t('password_changed')), backgroundColor: Colors.green),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? 'Erreur lors du changement de mot de passe.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(t('save'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _pwdField(String label, TextEditingController ctrl, bool hidden,
      VoidCallback toggle, String? Function(String?) validator, bool isDark) {
    final fieldBg   = isDark ? const Color(0xFF1E2733) : Colors.white;
    final fieldText = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.white60 : Colors.grey;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: labelColor)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl, obscureText: hidden, validator: validator,
        style: TextStyle(color: fieldText),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock_outline, color: isDark ? Colors.white54 : AppColors.navy, size: 20),
          suffixIcon: IconButton(
              icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: Colors.grey),
              onPressed: toggle),
          filled: true, fillColor: fieldBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.gold, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1)),
        ),
      ),
    ]);
  }
}

// ── Écran Aide & Support ─────────────────────────────────────────
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0B0F17) : const Color(0xFFF5F5F5);
    final appBarBg   = isDark ? const Color(0xFF161D29) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final cardBg     = isDark ? const Color(0xFF161D29) : Colors.white;
    final textColor  = isDark ? Colors.white : Colors.black87;
    final subColor   = isDark ? Colors.white60 : Colors.grey;
    final dividerColor = isDark ? Colors.white10 : Colors.grey.shade100;

    final faqs = state.language == 'Français'
        ? [
      {'q': 'Comment suivre ma livraison ?', 'a': 'Allez dans l\'onglet Suivi et entrez votre numéro de commande.'},
      {'q': 'Comment annuler une commande ?', 'a': 'Ouvrez votre commande dans l\'historique et appuyez sur Annuler.'},
      {'q': 'Comment contacter un livreur ?', 'a': 'Dans les détails de la commande, appuyez sur le bouton Contacter.'},
      {'q': 'Quels modes de paiement sont acceptés ?', 'a': 'Orange Money, MTN MoMo et espèces à la livraison.'},
    ] : [
      {'q': 'How to track my delivery?', 'a': 'Go to the Tracking tab and enter your order number.'},
      {'q': 'How to cancel an order?', 'a': 'Open your order in history and tap Cancel.'},
      {'q': 'How to contact a driver?', 'a': 'In order details, tap the Contact button.'},
      {'q': 'What payment methods are accepted?', 'a': 'Orange Money, MTN MoMo and cash on delivery.'},
    ];

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: titleColor), onPressed: () => Navigator.pop(context)),
        title: Text(t('help'), style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t('faq'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          ...faqs.map((faq) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              iconColor: AppColors.gold, collapsedIconColor: subColor,
              title: Text(faq['q']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
              children: [Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(faq['a']!, style: TextStyle(fontSize: 13, color: subColor)),
              )],
            ),
          )),
          const SizedBox(height: 20),
          Text(t('contact_us'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              ListTile(
                leading: Icon(Icons.email_outlined, color: AppColors.gold),
                title: Text('support@glotelho.cm', style: TextStyle(color: textColor)),
                dense: true,
              ),
              Divider(height: 1, color: dividerColor),
              ListTile(
                leading: Icon(Icons.phone_outlined, color: AppColors.gold),
                title: Text('+237 6XX XXX XXX', style: TextStyle(color: textColor)),
                dense: true,
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}