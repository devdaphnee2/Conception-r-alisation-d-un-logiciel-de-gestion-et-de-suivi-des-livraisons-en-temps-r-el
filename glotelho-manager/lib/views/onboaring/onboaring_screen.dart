import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Écran d'onboarding — 4 slides de présentation + un écran final
/// d'action (créer un compte / se connecter). Effet fondu + léger
/// glissement vertical entre les slides, piloté par la position du
/// PageController.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingItem {
  final String image;
  final String title;
  final String description;
  const _OnboardingItem(
      {required this.image, required this.title, required this.description});
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  double _page = 0;
  static const int _finalPageIndex = 4; // 4 slides (0-3) + écran final (4)

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      image: 'assets/onboarding/shopping.png',
      title: 'Bienvenue sur Glotelho Commerce',
      description:
      'Gérez votre boutique et vos commandes clients depuis votre téléphone, simplement.',
    ),
    _OnboardingItem(
      image: 'assets/onboarding/delivery.png',
      title: 'Livraison simplifiée',
      description:
      'Confiez vos courses à nos livreurs vérifiés dès qu\'une commande est prête.',
    ),
    _OnboardingItem(
      image: 'assets/onboarding/tracking.png',
      title: 'Suivi en temps réel',
      description:
      'Suivez chaque livraison en direct, de la prise en charge jusqu\'à la remise au client.',
    ),
    _OnboardingItem(
      image: 'assets/onboarding/support.png',
      title: 'Litiges gérés pour vous',
      description:
      'En cas de souci sur une course, consultez et suivez la résolution du litige facilement.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _page = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToFinal() {
    _controller.animateToPage(
      _finalPageIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _items.length + 1;
    final isLastContentPage = _page.round() == _items.length - 1;
    final isFinalPage = _page.round() == _finalPageIndex;

    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Column(
          children: [
            // Barre du haut : retour + skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 40,
                    child: _page.round() > 0 && !isFinalPage
                        ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white70, size: 18),
                      onPressed: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                    )
                        : null,
                  ),
                  if (!isFinalPage)
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text('Passer',
                          style: TextStyle(color: Colors.white54)),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: totalPages,
                itemBuilder: (context, index) {
                  final delta = (index - _page).clamp(-1.0, 1.0);
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final opacity = (1 - delta.abs()).clamp(0.0, 1.0);
                      return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, 40 * delta),
                          child: child,
                        ),
                      );
                    },
                    child: index < _items.length
                        ? _buildSlide(_items[index])
                        : _buildFinalPage(),
                  );
                },
              ),
            ),

            if (!isFinalPage) ...[
              // Indicateurs de page
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_items.length, (i) {
                  final active = i == _page.round();
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? AppTheme.gold : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: isLastContentPage
                    ? SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _goToFinal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: AppTheme.navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Commencer',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                )
                    : Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppTheme.gold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward,
                          color: AppTheme.navy),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 180,
            child: Image.asset(item.image, fit: BoxFit.contain),
          ),
          const SizedBox(height: 40),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 160,
            child: Image.asset('assets/onboarding/welcome.png',
                fit: BoxFit.contain),
          ),
          const SizedBox(height: 28),
          const Text(
            'Prêt à commencer ?',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre compte commerçant et démarrez la gestion de vos livraisons dès aujourd\'hui.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: AppTheme.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Créer un compte',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text('Déjà un compte ? Se connecter',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}