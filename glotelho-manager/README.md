# Squelette glotelho-manager (mobile)

## Comment intégrer ça dans ton projet

1. Crée le projet Flutter comme pour glotelho-livreur :
   ```
   flutter create glotelho_manager
   ```
2. Copie le contenu de `lib/` de ce squelette dans le `lib/` de ton
   nouveau projet (en fusionnant, pas en écrasant `main.dart` généré
   par défaut).
3. Ajoute les dépendances dans `pubspec.yaml` :
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     provider: ^6.1.2
     dio: ^5.7.0
   ```
4. `flutter pub get`

## Ce qui est fourni (squelette)
- `config/app_colors.dart` : palette identique au web (variable `P`)
- `config/app_state.dart` : Provider global (langue, thème, session)
- `services/api_service.dart` : dio + intercepteur Bearer, mêmes
  endpoints que `services/api.js` côté web
- `widgets/app_drawer.dart` : menu latéral avec les 7 sections
- `widgets/base_scaffold.dart` : layout commun (AppBar + Drawer)
- `views/dashboard/dashboard_screen.dart` : écran d'accueil placeholder
- `main.dart` : routes + thème clair/sombre

## Prochaines étapes suggérées
1. Écran Login (`views/auth/login_screen.dart`) branché sur `ApiService`
2. Dashboard réel avec les KPIs (cartes cliquables comme sur le web)
3. Livraisons (liste + détail avec le workflow de statut)
4. Livreurs (liste + validation des profils en attente)
5. Litiges, Recouvrements, Tracking, Paramètres

⚠️ Pense à remplacer `10.0.2.2` dans `api_service.dart` par l'adresse
réelle du backend de ton frère une fois qu'il tourne (10.0.2.2 est
l'alias localhost pour l'émulateur Android uniquement).