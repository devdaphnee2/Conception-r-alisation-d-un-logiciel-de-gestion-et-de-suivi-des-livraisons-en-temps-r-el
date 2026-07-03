import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: const Text('Inscription', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(child: Text('Formulaire d\'inscription à construire')),
    );
  }
}