import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service de calcul d'itinéraire routier GRATUIT via OSRM (OpenStreetMap).
class DirectionsService {
  static const String _base = 'https://router.project-osrm.org';

  /// Renvoie la liste des points du tracé routier.
  static Future<List<LatLng>> getRoute(LatLng origin, LatLng destination) async {
    // Si l'origine ou la destination sont invalides (Null Island), on ignore
    if (origin.latitude == 0.0 || origin.longitude == 0.0 ||
        destination.latitude == 0.0 || destination.longitude == 0.0) {
      return [];
    }

    try {
      // OSRM attend l'ordre : longitude, latitude
      final url = Uri.parse(
        '$_base/route/v1/driving/'
            '${origin.longitude},${origin.latitude};'
            '${destination.longitude},${destination.latitude}'
            '?overview=full&geometries=geojson',
      );

      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);
      if (data['routes'] == null || (data['routes'] as List).isEmpty) return [];

      final coords = data['routes'][0]['geometry']['coordinates'] as List;

      // GeoJSON renvoie [lng, lat] -> conversion en LatLng(lat, lng)
      return coords
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
    } catch (_) {
      // En cas de panne de connexion, retourne une liste vide sans faire crasher l'application
      return [];
    }
  }
}