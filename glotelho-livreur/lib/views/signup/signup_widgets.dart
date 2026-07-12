import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/constants.dart';

/// Label au-dessus d'un champ (style sombre cohérent avec le login).
Widget fieldLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(text,
        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
  );
}

Widget buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
      TextInputType? keyboardType,
      bool obscure = false,
      String? Function(String?)? validator,
    }) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      fieldLabel(label),
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        obscureText: obscure,
        validator: validator ?? (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
        style: const TextStyle(fontSize: 15, color: Colors.white),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(fontSize: 14, color: Colors.white30),
          prefixIcon: Icon(icon, size: 20, color: Colors.white54),
          filled: true,
          fillColor: Colors.white.withOpacity(0.06),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.gold, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
          errorStyle: const TextStyle(color: Colors.redAccent),
        ),
      ),
    ],
  );
}

/// Formatte automatiquement la saisie en jj/MM/aaaa.
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '');
    if (text.length > 8) text = text.substring(0, 8);

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 || i == 3) buffer.write('/');
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

Widget buildDateTextField(
    TextEditingController ctrl,
    String label, {
      String? Function(String?)? validator,
    }) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      fieldLabel(label),
      TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [DateInputFormatter()],
        validator: validator ??
                (v) {
              if (v == null || v.trim().isEmpty) return 'Champ requis';
              if (v.length != 10) return 'Format jj/MM/aaaa';
              return null;
            },
        style: const TextStyle(fontSize: 15, color: Colors.white),
        decoration: InputDecoration(
          hintText: 'jj/MM/aaaa',
          hintStyle: const TextStyle(fontSize: 14, color: Colors.white30),
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.white54),
          filled: true,
          fillColor: Colors.white.withOpacity(0.06),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.gold, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent)),
          errorStyle: const TextStyle(color: Colors.redAccent),
        ),
      ),
    ],
  );
}

/// Convertit "jj/MM/aaaa" en DateTime, ou null si invalide.
DateTime? parseDateInput(String text) {
  final parts = text.split('/');
  if (parts.length != 3) return null;
  final jour = int.tryParse(parts[0]);
  final mois = int.tryParse(parts[1]);
  final annee = int.tryParse(parts[2]);
  if (jour == null || mois == null || annee == null) return null;
  try {
    return DateTime(annee, mois, jour);
  } catch (_) {
    return null;
  }
}

/// Sélecteur de photo avec aperçu (photo profil, CNI, permis, véhicule).
class ImagePickerField extends StatelessWidget {
  final String label;
  final File? file;
  final ValueChanged<File> onPicked;
  final double height;

  const ImagePickerField({
    super.key,
    required this.label,
    required this.file,
    required this.onPicked,
    this.height = 140,
  });

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) onPicked(File(picked.path));
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardNavy,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.gold),
              title: const Text('Prendre une photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.gold),
              title: const Text('Choisir depuis la galerie', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel(label),
        GestureDetector(
          onTap: () => _showSourceSheet(context),
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: file == null ? Colors.white24 : AppColors.gold,
                  width: file == null ? 1 : 1.5),
            ),
            child: file == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined, color: Colors.white38, size: 32),
                const SizedBox(height: 6),
                const Text('Ajouter une photo', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            )
                : Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.file(file!, fit: BoxFit.contain),
                ),
                Positioned(
                  top: 6, right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}