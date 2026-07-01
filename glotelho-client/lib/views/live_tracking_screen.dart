import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';
import '../utils/constants.dart';
import '../utils/notification_state.dart';
import '../services/notification_service.dart';

/// Écran de suivi en temps réel du livreur sur une vraie carte (OpenStreetMap).
/// La position du livreur est interpolée entre l'entrepôt (origine) et
/// l'adresse du client (destination) en fonction de `_progress`.
/// Dès que l'API backend exposera la position GPS réelle du livreur
/// (websocket / polling), il suffira de remplacer la simulation par
/// la position reçue.
class LiveTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const LiveTrackingScreen({super.key, required this.order});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final Distance _distanceCalc = const Distance();

  // Progression simulée du livreur entre l'origine et la destination (0.0 → 1.0)
  double _progress = 0.15;
  bool _arrivalNotified = false;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  late final LatLng _origin;
  late final LatLng _destination;

  LatLng get _courierPosition => LatLng(
    _origin.latitude + (_destination.latitude - _origin.latitude) * _progress,
    _origin.longitude + (_destination.longitude - _origin.longitude) * _progress,
  );

  String get _eta {
    final remaining = (1.0 - _progress);
    final minutes = (remaining * 20).round();
    if (minutes <= 0) return '< 1 min';
    return '$minutes min';
  }

  double get _distanceKm => _distanceCalc.as(LengthUnit.Kilometer, _courierPosition, _destination);

  @override
  void initState() {
    super.initState();

    // Coordonnées par défaut : entrepôt et centre de Yaoundé si non fournies par la commande.
    _origin = LatLng(
      (widget.order['originLat'] as num?)?.toDouble() ?? 3.8667,
      (widget.order['originLng'] as num?)?.toDouble() ?? 11.5167,
    );
    _destination = LatLng(
      (widget.order['destLat'] as num?)?.toDouble() ?? 3.8480,
      (widget.order['destLng'] as num?)?.toDouble() ?? 11.5021,
    );

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Simule le déplacement du livreur toutes les 2 secondes.
    // À remplacer par un flux temps réel (websocket/polling) une fois l'API prête.
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      if (_progress < 1.0) {
        setState(() => _progress = (_progress + 0.04).clamp(0.0, 1.0));
        _mapController.move(_courierPosition, _mapController.camera.zoom);
        if (_progress >= 1.0 && !_arrivalNotified) {
          _arrivalNotified = true;
          _notifyArrival();
        }
      }
    });
  }

  /// Notifie le client en temps réel que le livreur est arrivé à destination.
  /// Alimente le badge/la liste de notifications de HomeScreen (NotificationState)
  /// et affiche un message immédiat sur l'écran de suivi lui-même.
  void _notifyArrival() {
    final livreur = widget.order['livreur'] as String? ?? 'Votre livreur';
    final title = '$livreur est arrivé !';
    final body = 'Votre livreur est arrivé à destination avec la commande #${widget.order['id']}.';

    // 1) Notification in-app (badge cloche + liste, visible dans l'app)
    context.read<NotificationState>().add(icon: Icons.location_on, title: title, body: body);

    // 2) Vraie notification système (visible même app en arrière-plan)
    NotificationService.showDeliveryArrived(title: title, body: body);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$livreur est arrivé à destination 🎉'),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
    }
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
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEn ? 'Live Tracking' : 'Suivi en direct',
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
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(isEn ? 'LIVE' : 'EN DIRECT', style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
      body: Column(children: [
        // ── CARTE RÉELLE (OpenStreetMap via flutter_map) ─────
        SizedBox(
          height: screenH * 0.58,
          child: Stack(children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _courierPosition,
                initialZoom: 14.5,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'cm.glotelho.client',
                ),
                PolylineLayer(polylines: [
                  Polyline(points: [_origin, _destination], strokeWidth: 4, color: AppColors.gold),
                ]),
                MarkerLayer(markers: [
                  // Pin destination (fixe)
                  Marker(
                    point: _destination,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
                      ),
                      child: const Icon(Icons.location_on, color: Colors.white, size: 22),
                    ),
                  ),
                  // Pin livreur (animé)
                  Marker(
                    point: _courierPosition,
                    width: 50,
                    height: 50,
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Transform.scale(
                        scale: _pulseAnim.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.gold, width: 2.5),
                            boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)],
                          ),
                          child: const Icon(Icons.delivery_dining, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                ]),
                // Attribution obligatoire OpenStreetMap
                const RichAttributionWidget(
                  attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
                ),
              ],
            ),

            // Badge ETA sur la carte
            Positioned(
              top: 16,
              left: 16,
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
                  Text(isEn ? 'ETA: $_eta' : 'Arrivée: $_eta', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                ]),
              ),
            ),

            // Badge distance sur la carte
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(24)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.straighten, size: 14, color: Colors.white),
                  const SizedBox(width: 5),
                  Text('${_distanceKm.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),

            // Barre de progression en bas de la carte
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.5), Colors.transparent]),
                ),
                child: Column(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: _progress, backgroundColor: Colors.white24, color: AppColors.gold, minHeight: 5),
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
                    Text('#${widget.order['id']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text(widget.order['nom'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                    CircleAvatar(radius: 22, backgroundColor: Colors.grey.shade200, child: const Icon(Icons.person, color: Colors.grey, size: 26)),
                    Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                  ]),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(widget.order['livreur'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                        Row(children: [
                          Icon(Icons.star, size: 12, color: AppColors.gold),
                          const SizedBox(width: 3),
                          Text('${widget.order['livreurNote']}  ·  ${widget.order['livreurTel']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ]),
                      ])),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gold.withOpacity(0.3))),
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
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(isEn ? 'Delivery address' : 'Adresse de livraison', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(widget.order['adresse'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
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