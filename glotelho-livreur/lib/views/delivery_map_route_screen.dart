import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/constants.dart';
import '../models/delivery_model.dart';

class DeliveryMapRouteScreen extends StatefulWidget {
  final DeliveryModel delivery;
  const DeliveryMapRouteScreen({super.key, required this.delivery});

  @override
  State<DeliveryMapRouteScreen> createState() => _DeliveryMapRouteScreenState();
}

class _DeliveryMapRouteScreenState extends State<DeliveryMapRouteScreen> {
  GoogleMapController? _controller;

  // Position par défaut du livreur (ex: Akwa, Douala)
  static const LatLng _livreurPos = LatLng(4.0511, 9.7679);

  // Position par défaut si les coordonnées client sont nulles/égales à 0
  static const LatLng _doualaDefault = LatLng(4.0611, 9.7550);

  LatLng _getClientCoordinates() {
    final double lat = widget.delivery.latitude;
    final double lng = widget.delivery.longitude;

    // Si les coordonnées valent 0.0 (Null Island), on évite le point dans l'océan
    if (lat == 0.0 || lng == 0.0) {
      return _doualaDefault;
    }
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    final LatLng clientPos = _getClientCoordinates();

    final markers = {
      Marker(
        markerId: const MarkerId('livreur'),
        position: _livreurPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Vous (Livreur)'),
      ),
      Marker(
        markerId: const MarkerId('client'),
        position: clientPos,
        infoWindow: InfoWindow(
          title: widget.delivery.clientNom,
          snippet: widget.delivery.adresseLivraison,
        ),
      ),
    };

    final polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_livreurPos, clientPos],
        color: AppColors.gold,
        width: 5,
      ),
    };

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Itinéraire · ${widget.delivery.clientNom}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Stack(
        children: [
          // 1. La Carte Google Maps
          GoogleMap(
            initialCameraPosition: CameraPosition(target: clientPos, zoom: 13),
            markers: markers,
            polylines: polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) {
              _controller = c;
              Future.delayed(const Duration(milliseconds: 300), () {
                if (_livreurPos.latitude == clientPos.latitude &&
                    _livreurPos.longitude == clientPos.longitude) {
                  return;
                }

                final sw = LatLng(
                  clientPos.latitude < _livreurPos.latitude
                      ? clientPos.latitude
                      : _livreurPos.latitude,
                  clientPos.longitude < _livreurPos.longitude
                      ? clientPos.longitude
                      : _livreurPos.longitude,
                );
                final ne = LatLng(
                  clientPos.latitude > _livreurPos.latitude
                      ? clientPos.latitude
                      : _livreurPos.latitude,
                  clientPos.longitude > _livreurPos.longitude
                      ? clientPos.longitude
                      : _livreurPos.longitude,
                );

                _controller?.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    LatLngBounds(southwest: sw, northeast: ne),
                    80,
                  ),
                );
              });
            },
          ),

          // 2. Bannière d'information client en bas
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Livraison #${widget.delivery.id}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'En cours',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        widget.delivery.clientNom,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.delivery.adresseLivraison,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}