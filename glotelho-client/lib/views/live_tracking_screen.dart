
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';
import '../utils/constants.dart';

/// Écran de suivi en temps réel du livreur
/// La carte occupe la majorité de l'écran.
/// Un point animé simule le déplacement du livreur.
/// Ce même écran est accessible depuis le menu "Suivi".
class LiveTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const LiveTrackingScreen({super.key, required this.order});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with TickerProviderStateMixin {
  // Simule la progression du livreur (0.0 → 1.0)
  double _progress = 0.15;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  String get _eta {
    final remaining = (1.0 - _progress);
    final minutes = (remaining * 20).round();
    if (minutes <= 0) return '< 1 min';
    return '$minutes min';
  }

  double get _distanceKm => ((1.0 - _progress) * 4.0);

  @override
  void initState() {
    super.initState();
    // Animation pulsation du pin livreur
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Simule le déplacement toutes les 2 secondes
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted && _progress < 0.98) {
        setState(() => _progress += 0.04 + Random().nextDouble() * 0.02);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isEn = state.language == 'English';
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEn ? 'Live Tracking' : 'Suivi en temps réel',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade400, width: 1),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(isEn ? 'LIVE' : 'EN DIRECT',
                  style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
      body: Column(children: [
        // ── CARTE (grande, occupe ~60% de l'écran) ──────────
        SizedBox(
          height: screenH * 0.58,
          child: Stack(children: [
            // Fond carte
            Positioned.fill(child: CustomPaint(painter: _MapPainter(progress: _progress))),

            // Route du livreur (trait animé)
            Positioned.fill(child: CustomPaint(painter: _RoutePainter(progress: _progress))),

            // Pin destination (fixe)
            Positioned(
              bottom: screenH * 0.12,
              right: 60,
              child: Column(children: [
                Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)]),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 20)),
                Container(width: 2, height: 8, color: AppColors.gold),
              ]),
            ),

            // Pin livreur animé
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) {
                // Interpolation position livreur
                final x = 40.0 + _progress * (MediaQuery.of(context).size.width - 100);
                final y = screenH * 0.58 * 0.45 + sin(_progress * pi * 2) * 30;
                return Positioned(
                  left: x - 20,
                  top: y - 20,
                  child: Transform.scale(
                    scale: _pulseAnim.value,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold, width: 2.5),
                        boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)],
                      ),
                      child: const Icon(Icons.delivery_dining, color: Colors.white, size: 22),
                    ),
                  ),
                );
              },
            ),

            // Badge ETA sur la carte
            Positioned(
              top: 16, left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8)],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.access_time, size: 16, color: AppColors.gold),
                  const SizedBox(width: 6),
                  Text(isEn ? 'ETA: $_eta' : 'Arrivée: $_eta',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                ]),
              ),
            ),

            // Badge distance sur la carte
            Positioned(
              top: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.straighten, size: 14, color: Colors.white),
                  const SizedBox(width: 5),
                  Text('${_distanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),

            // Barre de progression en bas de la carte
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.5), Colors.transparent]),
                ),
                child: Column(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white24,
                      color: AppColors.gold,
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 8),
                ]),
              ),
            ),
          ]),
        ),

        // ── INFO PANEL (bas de l'écran) ──────────────────────
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Commande
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('#${widget.order['id']}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text(widget.order['nom'] as String,
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(20)),
                    child: Text(isEn ? 'On the way' : 'En route',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  ),
                ]),

                const SizedBox(height: 14),
                Divider(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 14),

                // Livreur
                Row(children: [
                  Stack(children: [
                    CircleAvatar(radius: 22, backgroundColor: Colors.grey.shade200,
                        child: const Icon(Icons.person, color: Colors.grey, size: 26)),
                    Positioned(bottom: 0, right: 0,
                        child: Container(width: 12, height: 12,
                            decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2)))),
                  ]),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.order['livreur'] as String,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                    Row(children: [
                      Icon(Icons.star, size: 12, color: AppColors.gold),
                      const SizedBox(width: 3),
                      Text('${widget.order['livreurNote']}  ·  ${widget.order['livreurTel']}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ]),
                  ])),
                  // Appel rapide
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gold.withOpacity(0.3))),
                      child: Icon(Icons.phone_outlined, color: AppColors.gold, size: 20),
                    ),
                  ),
                ]),

                const SizedBox(height: 14),
                Divider(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 14),

                // Destination
                Row(children: [
                  Icon(Icons.location_on_outlined, color: AppColors.gold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isEn ? 'Delivery address' : 'Adresse de livraison',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(widget.order['adresse'] as String,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ])),
                ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────────
class _MapPainter extends CustomPainter {
  final double progress;
  _MapPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Fond carte
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFFD4E8D0));

    // Blocs bâtiments
    final bp = Paint()..color = const Color(0xFFBDD8B8);
    for (final r in [
      Rect.fromLTWH(10, 10, 70, 40), Rect.fromLTWH(90, 10, 90, 35),
      Rect.fromLTWH(10, 70, 60, 50), Rect.fromLTWH(200, 20, 80, 30),
      Rect.fromLTWH(size.width - 90, 70, 70, 50),
      Rect.fromLTWH(size.width * 0.4, 100, 90, 40),
    ]) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), bp);
    }

    // Routes
    final rp = Paint()..color = Colors.white.withOpacity(0.85)..strokeWidth = 10..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), rp);
    canvas.drawLine(Offset(size.width * 0.4, 0), Offset(size.width * 0.4, size.height), rp);
    final rp2 = Paint()..color = Colors.white.withOpacity(0.5)..strokeWidth = 5;
    canvas.drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), rp2);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.7, size.height), rp2);
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.progress != progress;
}

class _RoutePainter extends CustomPainter {
  final double progress;
  _RoutePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(30, size.height * 0.4)
      ..cubicTo(size.width * 0.25, size.height * 0.6,
          size.width * 0.6, size.height * 0.3,
          size.width - 60, size.height * 0.55);

    // Trait grisé (route complète)
    canvas.drawPath(path, Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // Trait doré (partie parcourue)
    final metrics = path.computeMetrics().first;
    final traveled = metrics.extractPath(0, metrics.length * progress);
    canvas.drawPath(traveled, Paint()
      ..color = const Color(0xFFC8960C)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) => old.progress != progress;
}

