import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const List<Map<String, String>> _slides = [
    {
      'title': 'Livrez vite,\nlivrez bien',
      'body': 'Rejoignez les livreurs Glotelho et gagnez de l\'argent en toute liberté, à votre rythme.',
      'icon': 'delivery',
    },
    {
      'title': 'Suivez vos\ncourses en direct',
      'body': 'Une carte claire, un itinéraire optimisé, et toutes vos livraisons du jour en un coup d\'œil.',
      'icon': 'map',
    },
    {
      'title': 'Vos gains,\nen toute transparence',
      'body': 'Suivez vos commissions, vos statistiques et retirez vos gains facilement via Mobile Money.',
      'icon': 'earnings',
    },
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'map':
        return Icons.map_outlined;
      case 'earnings':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.two_wheeler_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _goToLogin,
                child: const Text('Passer', style: TextStyle(color: Colors.white70)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_iconFor(slide['icon']!), size: 72, color: AppColors.gold),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          slide['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide['body']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _page == i ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _page == i ? AppColors.gold : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _page == _slides.length - 1 ? 'Commencer' : 'Suivant',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}