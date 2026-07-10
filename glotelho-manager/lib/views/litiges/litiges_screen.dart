import 'package:flutter/material.dart';

class LitigesScreen extends StatelessWidget {
  const LitigesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Litiges')),
      body: const Center(child: Text('Liste des litiges à venir')),
    );
  }
}