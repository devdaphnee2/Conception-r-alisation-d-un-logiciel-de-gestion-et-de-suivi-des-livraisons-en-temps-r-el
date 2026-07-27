import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/driver_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final driver = context.read<DriverState>().driver;
    _nomController = TextEditingController(text: driver != null ? '${driver.prenom} ${driver.nom}' : 'Audric Ndeugoue');
    _emailController = TextEditingController(text: 'audric.ndeugoue@glotelho.cm');
    _phoneController = TextEditingController(text: driver?.telephone ?? '+237 699 001 122');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : const Color(0xFFF5F6F8);
    final cardColor = isDark ? AppColors.cardNavy : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mon profil',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Avatar avec bouton appareil photo
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.gold,
                        child: const Text(
                          'M',
                          style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.cardNavy,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Appuyez pour changer la photo',
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 32),

                // Champs de saisie
                _buildFieldLabel('Nom complet', isDark),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _nomController,
                  icon: Icons.person_outline,
                  cardColor: cardColor,
                  textColor: textColor,
                ),
                const SizedBox(height: 20),

                _buildFieldLabel('Adresse email', isDark),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  cardColor: cardColor,
                  textColor: textColor,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                _buildFieldLabel('Numéro de téléphone', isDark),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _phoneController,
                  icon: Icons.phone_outlined,
                  cardColor: cardColor,
                  textColor: textColor,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 40),

                // Bouton Enregistrer
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Enregistrer',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.grey[700],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required Color cardColor,
    required Color textColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.gold),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}