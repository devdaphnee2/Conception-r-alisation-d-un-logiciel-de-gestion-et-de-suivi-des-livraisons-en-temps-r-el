import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery_model.dart';
import '../services/tracking_service.dart';
import '../services/directions_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
  import 'package:firebase_database/firebase_database.dart';

class DeliveryMapScreen extends StatefulWidget {
  final DeliveryModel? activeLivraison;
  const DeliveryMapScreen({super.key, this.activeLivraison});

  @override
  State<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen> {
  GoogleMapController? _mapController;
  List<DeliveryModel> _deliveries = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _loadingRoutes = true;
  DeliveryModel? _selected;

  // Position GPS réelle du livreur
  LatLng? _myPosition;
  bool _positionSharing = false;
  Timer? _gpsTimer;

  static const CameraPosition _douala = CameraPosition(
    target: LatLng(4.0611, 9.7550), zoom: 12);

  Color _statusColor(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.delivered:  return AppColors.statusDelivered;
      case DeliveryStatus.cancelled:  return AppColors.statusCancelled;
      case DeliveryStatus.inProgress: return AppColors.statusInProgress;
      case DeliveryStatus.suspended:  return AppColors.amber;
      case DeliveryStatus.assigned:   return AppColors.blue;
      case DeliveryStatus.validated:  return AppColors.green;
      case DeliveryStatus.pending:    return AppColors.statusPending;
    }
  }

  double _hueForStatus(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.delivered:  return BitmapDescriptor.hueGreen;
      case DeliveryStatus.cancelled:  return BitmapDescriptor.hueRed;
      case DeliveryStatus.inProgress: return BitmapDescriptor.hueAzure;
      case DeliveryStatus.suspended:  return BitmapDescriptor.hueOrange;
      case DeliveryStatus.assigned:   return BitmapDescriptor.hueBlue;
      case DeliveryStatus.validated:  return BitmapDescriptor.hueCyan;
      case DeliveryStatus.pending:    return BitmapDescriptor.hueYellow;
    }
  }

  String _statusLabel(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.delivered:  return 'Livrée';
      case DeliveryStatus.cancelled:  return 'Annulée';
      case DeliveryStatus.inProgress: return 'En cours';
      case DeliveryStatus.suspended:  return 'Suspendue';
      case DeliveryStatus.assigned:   return 'Assignée';
      case DeliveryStatus.validated:  return 'Validée';
      case DeliveryStatus.pending:    return 'En attente';
    }
  }

  @override
  void initState() {
    super.initState();
    _selected = widget.activeLivraison;
    _load();
    _initPosition();
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Initialiser la position GPS ──────────────────────────────
  Future<void> _initPosition() async {
    final ok = await _demanderPermission();
    if (!ok) return;
    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    if (!mounted) return;
    setState(() => _myPosition = LatLng(pos.latitude, pos.longitude));
    _updateMarkerLivreur();
  }

  Future<bool> _demanderPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.whileInUse ||
           perm == LocationPermission.always;
  }

  // ── Bouton : Partager / Arrêter la position ───────────────────
  Future<void> _togglePartagerPosition() async {
    if (_positionSharing) {
      _gpsTimer?.cancel();
      setState(() => _positionSharing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Partage de position arrêté.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final ok = await _demanderPermission();
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Permission GPS refusée. Activez la localisation.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _positionSharing = true);

    // Envoyer immédiatement
    await _envoyerPosition();

    // Puis toutes les 5 secondes
    _gpsTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _envoyerPosition();
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('📍 Position partagée en temps réel (toutes les 5s)'),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }



Future<void> _envoyerPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final latLng = LatLng(pos.latitude, pos.longitude);

      // Écrire directement sur Firebase
      final dbRef = FirebaseDatabase.instance.ref('positions/22');
      await dbRef.set({
        'latitude' : pos.latitude,
        'longitude': pos.longitude,
        'speed'    : pos.speed,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      if (!mounted) return;
      setState(() => _myPosition = latLng);
      _updateMarkerLivreur();
    } catch (e) {
      debugPrint('[GPS] Erreur: $e');
    }
  }

  // ── Bouton : Me centrer ───────────────────────────────────────
  Future<void> _centrerSurMoi() async {
    final ok = await _demanderPermission();
    if (!ok) return;

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final latLng = LatLng(pos.latitude, pos.longitude);

    if (!mounted) return;
    setState(() => _myPosition = latLng);
    _updateMarkerLivreur();

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: 16),
      ),
    );
  }

  void _updateMarkerLivreur() {
    if (_myPosition == null) return;
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'livreur');
      _markers.add(Marker(
        markerId: const MarkerId('livreur'),
        position: _myPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: const InfoWindow(title: 'Vous 📍'),
      ));
    });
  }

  Future<void> _load() async {
    final data = await TrackingService.getTodayDeliveries();
    if (!mounted) return;

    final markers = <Marker>{};

    // Marqueur livreur (position réelle si disponible)
    final livreurPos = _myPosition ?? const LatLng(4.0611, 9.7550);
    markers.add(Marker(
      markerId: const MarkerId('livreur'),
      position: livreurPos,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      infoWindow: const InfoWindow(title: 'Vous 📍'),
    ));

    for (final d in data) {
      markers.add(Marker(
        markerId: MarkerId(d.id),
        position: LatLng(d.latitude, d.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(_hueForStatus(d.status)),
        infoWindow: InfoWindow(title: d.clientNom, snippet: d.adresseLivraison),
        onTap: () => setState(() => _selected = d),
      ));
    }

    setState(() {
      _deliveries = data;
      _markers = markers;
      if (_selected == null && data.isNotEmpty) {
        _selected = data.firstWhere(
          (d) => d.status == DeliveryStatus.inProgress ||
                 d.status == DeliveryStatus.assigned,
          orElse: () => data.first,
        );
      }
    });

    final polylines = <Polyline>{};
    for (final d in data) {
      final from = _myPosition ?? const LatLng(4.0611, 9.7550);
      final points = await DirectionsService.getRoute(
          from, LatLng(d.latitude, d.longitude));
      if (points.isNotEmpty) {
        polylines.add(Polyline(
          polylineId: PolylineId('route_${d.id}'),
          points: points,
          color: _statusColor(d.status),
          width: 4,
        ));
      }
    }

    if (!mounted) return;
    setState(() { _polylines = polylines; _loadingRoutes = false; });
  }

  Future<void> _appelerClient(String tel) async {
    final uri = Uri(scheme: 'tel', path: tel);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appel vers $tel'),
            backgroundColor: AppColors.navy),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _myPosition != null
                ? CameraPosition(target: _myPosition!, zoom: 14)
                : _douala,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) {
              _mapController = c;
              if (_myPosition != null) {
                c.animateCamera(CameraUpdate.newLatLngZoom(_myPosition!, 14));
              }
            },
          ),

          // ── Légende ──────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.12), blurRadius: 8)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _legend(AppColors.statusDelivered, 'Livrée'),
                    _legend(AppColors.statusCancelled, 'Annulée'),
                    _legend(AppColors.statusInProgress, 'En cours'),
                    _legend(AppColors.blue, 'Assignée'),
                  ],
                ),
              ),
            ),
          ),

          // ── Boutons GPS (droite) ──────────────────────────────
          Positioned(
            right: 12,
            bottom: _selected != null ? 220 : 30,
            child: Column(
              children: [
                // Bouton Me centrer
                FloatingActionButton.small(
                  heroTag: 'centrer',
                  onPressed: _centrerSurMoi,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                // Bouton Partager position
                FloatingActionButton(
                  heroTag: 'partager',
                  onPressed: _togglePartagerPosition,
                  backgroundColor: _positionSharing
                      ? Colors.green
                      : AppColors.gold,
                  child: Icon(
                    _positionSharing
                        ? Icons.location_on
                        : Icons.location_off,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // ── Indicateur partage actif ──────────────────────────
          if (_positionSharing)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.2), blurRadius: 8)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Position partagée en direct',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),

          // ── Carte livraison sélectionnée ──────────────────────
          if (_selected != null)
            Positioned(
              bottom: 30, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.25), blurRadius: 12)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Livraison #${_selected!.id}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(_selected!.status)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_statusLabel(_selected!.status),
                              style: TextStyle(
                                  color: _statusColor(_selected!.status),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.person_outline,
                          color: Colors.white54, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_selected!.clientNom,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13))),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          color: Colors.white54, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_selected!.adresseLivraison,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12))),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _appelerClient(_selected!.clientTelephone),
                        icon: const Icon(Icons.phone, size: 16),
                        label: Text('Appeler ${_selected!.clientTelephone}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Chargement itinéraires ────────────────────────────
          if (_loadingRoutes)
            Positioned(
              top: 80, left: 0, right: 0,
              child: Center(
                child: Card(
                  color: Colors.white,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Calcul des itinéraires…',
                            style: TextStyle(color: Colors.black87)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: Colors.black87,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}