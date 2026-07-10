import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/constants.dart';
import '../../models/delivery_model.dart';
import '../../services/tracking_service.dart';

class TrackingMapScreen extends StatefulWidget {
  const TrackingMapScreen({super.key});

  @override
  State<TrackingMapScreen> createState() => _TrackingMapScreenState();
}

class _TrackingMapScreenState extends State<TrackingMapScreen> {
  GoogleMapController? _mapController;
  List<DeliveryModel> _deliveries = [];
  bool _isLoading = true;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(4.0511, 9.7679), // Douala Akwa
    zoom: 13,
  );

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _load();
  }

  Future<void> _requestPermission() async {
    await Permission.location.request();
  }

  Future<void> _load() async {
    final deliveries = await TrackingService.getTodayDeliveries();
    if (!mounted) return;
    setState(() {
      _deliveries = deliveries;
      _isLoading = false;
    });
  }

  Color _statusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.delivered:
        return AppColors.green;
      case DeliveryStatus.cancelled:
        return AppColors.red;
      case DeliveryStatus.inProgress:
        return AppColors.blue;
      case DeliveryStatus.suspended:
        return AppColors.amber;
      case DeliveryStatus.pending:
        return Colors.grey;
    }
  }

  double _statusHue(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.delivered:
        return BitmapDescriptor.hueGreen;
      case DeliveryStatus.cancelled:
        return BitmapDescriptor.hueRed;
      case DeliveryStatus.inProgress:
        return BitmapDescriptor.hueAzure;
      case DeliveryStatus.suspended:
        return BitmapDescriptor.hueOrange;
      case DeliveryStatus.pending:
        return BitmapDescriptor.hueViolet;
    }
  }

  String _statusLabel(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.delivered:
        return 'Livrée';
      case DeliveryStatus.cancelled:
        return 'Annulée';
      case DeliveryStatus.inProgress:
        return 'En cours';
      case DeliveryStatus.suspended:
        return 'Suspendue';
      case DeliveryStatus.pending:
        return 'En attente';
    }
  }

  Set<Marker> get _markers => _deliveries.map((d) {
    return Marker(
      markerId: MarkerId(d.id),
      position: LatLng(d.latitude, d.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(_statusHue(d.status)),
      infoWindow: InfoWindow(
        title: d.clientNom,
        snippet: '${_statusLabel(d.status)} — ${d.adresseLivraison}',
      ),
    );
  }).toSet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (c) => _mapController = c,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
          ),
          Positioned(
            top: 16, left: 16, right: 16,
            child: _buildLegend(),
          ),
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: _buildDeliveriesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendDot(AppColors.green, 'Livrée'),
          _legendDot(AppColors.red, 'Annulée'),
          _legendDot(AppColors.blue, 'En cours'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }

  Widget _buildDeliveriesList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 160),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10)],
      ),
      child: ListView.separated(
        itemCount: _deliveries.length,
        separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
        itemBuilder: (_, i) {
          final d = _deliveries[i];
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            onTap: () {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(LatLng(d.latitude, d.longitude), 16),
              );
            },
            leading: Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: _statusColor(d.status), shape: BoxShape.circle),
            ),
            title: Text(d.clientNom, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(d.adresseLivraison, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            trailing: Text(_statusLabel(d.status),
                style: TextStyle(color: _statusColor(d.status), fontSize: 11, fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}