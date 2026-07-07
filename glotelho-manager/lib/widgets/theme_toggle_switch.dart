import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Switch pilule Navy / Blanc pour basculer entre thème Navy (sombre,
/// icône lune) et thème Clair (blanc, icône soleil). Pas de doré.
class ThemeToggleSwitch extends StatelessWidget {
  final bool isDark; // true = Navy, false = Clair
  final ValueChanged<bool> onChanged;

  const ThemeToggleSwitch({
    super.key,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isDark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        height: 32,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.navy : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppTheme.navyLight : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: isDark ? Alignment.centerLeft : Alignment.centerRight,
          curve: Curves.easeInOut,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isDark ? Colors.white : AppTheme.navy,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
              size: 14,
              color: isDark ? AppTheme.navy : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}