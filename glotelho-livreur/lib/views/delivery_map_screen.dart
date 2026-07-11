import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery_model.dart';
import '../services/tracking_service.dart';
import '../services/directions_service.dart';
import '../utils/constants.dart';
import 'orders_screen.dart';

class DeliveryMapScreen extends StatefulWidget {
  const DeliveryMapScreen({super.key});

  @override
  State<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen> {
  GoogleMapController? _mapController;
  List<DeliveryModel> _deliveries = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _loadingRoutes = true;

  // Position (mock) du livreur — point de départ des itinéraires.
  static const LatLng _livreurPos = LatLng(4.0611, 9.7550);

  static const CameraPosition _douala = CameraPosition(target: _livreurPos, zoom: 12);

  Color _statusColor(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.delivered:
        return AppColors.statusDelivered;
      case DeliveryStatus.cancelled:
        return AppColors.statusCancelled;
      case DeliveryStatus.inProgress:
        return AppColors.statusInProgress;
      case DeliveryStatus.suspended:
        return AppColors.amber;
      case DeliveryStatus.pending:
        return AppColors.statusPending;
    }
  }

  double _hueForStatus(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.delivered:
        return BitmapDescriptor.hueGreen;
      case DeliveryStatus.cancelled:
        return BitmapDescriptor.hueRed;
      case DeliveryStatus.inProgress:
        return BitmapDescriptor.hueAzure;
      case DeliveryStatus.suspended:
        return BitmapDescriptor.hueOrange;
      case DeliveryStatus.pending:
        return BitmapDescriptor.hueYellow;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await TrackingService.getTodayDeliveries();
    if (!mounted) return;

    // Marqueur du livreur
    final markers = <Marker>{
      const Marker(
        markerId: MarkerId('livreur'),
        position: _livreurPos,
        infoWindow: InfoWindow(title: 'Vous'),
      ),
    };
    // Marqueurs clients
    for (final d in data) {
      markers.add(Marker(
        markerId: MarkerId(d.id),
        position: LatLng(d.latitude, d.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(_hueForStatus(d.status)),
        infoWindow: InfoWindow(title: d.clientNom, snippet: d.adresseLivraison),
      ));
    }

    setState(() {
      _deliveries = data;
      _markers = markers;
    });

    // Trace un itinéraire routier par livraison (séquentiel)
    final polylines = <Polyline>{};
    for (final d in data) {
      final points = await DirectionsService.getRoute(
        _livreurPos,
        LatLng(d.latitude, d.longitude),
      );
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
    setState(() {
      _polylines = polylines;
      _loadingRoutes = false;
    });
  }

  void _openOrders() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _douala,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) => _mapController = c,
          ),

          // En-tête : hamburger + légende
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _iconButton(Icons.menu, _openOrders),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8)],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _legend(AppColors.statusDelivered, 'Livrée'),
                          _legend(AppColors.statusCancelled, 'Annulée'),
                          _legend(AppColors.statusInProgress, 'En cours'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Indicateur de chargement des itinéraires
          if (_loadingRoutes)
            const Positioned(
              bottom: 30, left: 0, right: 0,
              child: Center(
                child: Card(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Calcul des itinéraires…', style: TextStyle(color: Colors.black87)),
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

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8)],
        ),
        child: Icon(icon, color: Colors.black87),
      ),
    );
  }

  Widget _legend(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}