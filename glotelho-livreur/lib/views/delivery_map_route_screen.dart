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

  static const LatLng _livreurPos = LatLng(4.0611, 9.7550);

  @override
  Widget build(BuildContext context) {
    final client = LatLng(widget.delivery.latitude, widget.delivery.longitude);

    final markers = {
      Marker(
        markerId: const MarkerId('livreur'),
        position: _livreurPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Vous'),
      ),
      Marker(
        markerId: const MarkerId('client'),
        position: client,
        infoWindow: InfoWindow(
            title: widget.delivery.clientNom,
            snippet: widget.delivery.adresseLivraison),
      ),
    };

    final polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_livreurPos, client],
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
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: client, zoom: 13),
        markers: markers,
        polylines: polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        onMapCreated: (c) {
          _controller = c;
          Future.delayed(const Duration(milliseconds: 300), () {
            final sw = LatLng(
              client.latitude < _livreurPos.latitude ? client.latitude : _livreurPos.latitude,
              client.longitude < _livreurPos.longitude ? client.longitude : _livreurPos.longitude,
            );
            final ne = LatLng(
              client.latitude > _livreurPos.latitude ? client.latitude : _livreurPos.latitude,
              client.longitude > _livreurPos.longitude ? client.longitude : _livreurPos.longitude,
            );
            _controller?.animateCamera(
              CameraUpdate.newLatLngBounds(
                  LatLngBounds(southwest: sw, northeast: ne), 80),
            );
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}