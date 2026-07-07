import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../widgets/theme_toggle_switch.dart';

class ParametresScreen extends StatelessWidget {
  const ParametresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Thème'),
            subtitle: Text(isDark ? 'Navy (par défaut)' : 'Clair'),
            trailing: ThemeToggleSwitch(
              isDark: isDark,
              onChanged: (_) => context.read<AppState>().toggleTheme(),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Langue'),
            subtitle: Text(appState.locale == 'fr' ? 'Français' : 'English'),
            trailing: TextButton(
              onPressed: () => context.read<AppState>().toggleLocale(),
              child: const Text('Changer'),
            ),
          ),
        ],
      ),
    );
  }
}