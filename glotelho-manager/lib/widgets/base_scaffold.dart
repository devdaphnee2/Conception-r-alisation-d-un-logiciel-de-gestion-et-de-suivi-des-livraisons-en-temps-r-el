import 'package:flutter/material.dart';
import 'app_drawer.dart';
import '../config/app_colors.dart';

/// Scaffold commun à tous les écrans protégés : AppBar avec le titre
/// de la section + Drawer. Équivalent mobile de DashboardLayout.jsx.
class BaseScaffold extends StatelessWidget {
  final String title;
  final String currentRoute;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const BaseScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        actions: actions,
      ),
      drawer: AppDrawer(currentRoute: currentRoute),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}