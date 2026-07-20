import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery_model.dart';
import '../services/tracking_service.dart';
import '../services/directions_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

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
      case DeliveryStatus.assigned:
        return AppColors.blue;
      case DeliveryStatus.pending:
        return AppColors.statusPending;
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
      case DeliveryStatus.delivered:
        return BitmapDescriptor.hueGreen;
      case DeliveryStatus.cancelled:
        return BitmapDescriptor.hueRed;
      case DeliveryStatus.inProgress:
        return BitmapDescriptor.hueAzure;
      case DeliveryStatus.suspended:
        return BitmapDescriptor.hueOrange;
      case DeliveryStatus.assigned:
        return BitmapDescriptor.hueBlue;
      case DeliveryStatus.pending:
        return BitmapDescriptor.hueYellow;
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
  }

  Future<void> _load() async {
    final data = await TrackingService.getTodayDeliveries();
    if (!mounted) return;

    final markers = <Marker>{
      const Marker(
        markerId: MarkerId('livreur'),
        position: _livreurPos,
        infoWindow: InfoWindow(title: 'Vous'),
      ),
    };
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
          (d) => d.status == DeliveryStatus.inProgress || d.status == DeliveryStatus.assigned,
          orElse: () => data.first,
        );
      }
    });

    final polylines = <Polyline>{};
    for (final d in data) {
      final points = await DirectionsService.getRoute(_livreurPos, LatLng(d.latitude, d.longitude));
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
        SnackBar(content: Text('Appel vers $tel'), backgroundColor: AppColors.navy),
      );
    }
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

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    _legend(AppColors.blue, 'Assignée'),
                  ],
                ),
              ),
            ),
          ),

          if (_selected != null)
            Positioned(
              bottom: 30, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Livraison #${_selected!.id}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(_selected!.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_statusLabel(_selected!.status),
                              style: TextStyle(color: _statusColor(_selected!.status), fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, color: Colors.white54, size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text(_selected!.clientNom,
                            style: const TextStyle(color: Colors.white, fontSize: 13))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Colors.white54, size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text(_selected!.adresseLivraison,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 12))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _appelerClient(_selected!.clientTelephone),
                        icon: const Icon(Icons.phone, size: 16),
                        label: Text('Appeler ${_selected!.clientTelephone}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_loadingRoutes)
            Positioned(
              top: 80, left: 0, right: 0,
              child: Center(
                child: Card(
                  color: Colors.white,
                  child: const Padding(
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

  Widget _legend(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}