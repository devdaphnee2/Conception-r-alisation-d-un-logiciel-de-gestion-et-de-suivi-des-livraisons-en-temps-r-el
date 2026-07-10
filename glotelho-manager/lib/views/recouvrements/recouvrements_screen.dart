import 'package:flutter/material.dart';

class RecouvrementsScreen extends StatelessWidget {
  const RecouvrementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recouvrements')),
      body: const Center(child: Text('Liste des recouvrements à venir')),
    );
  }
}