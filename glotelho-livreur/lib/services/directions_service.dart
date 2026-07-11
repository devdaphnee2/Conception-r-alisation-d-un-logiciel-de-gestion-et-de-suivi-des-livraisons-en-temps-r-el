import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Calcul d'itinéraire routier GRATUIT via OSRM (OpenStreetMap).
/// Aucune clé API, aucun coût.
class DirectionsService {
  // Serveur de démo public OSRM. Gratuit, sans clé.
  // Pour un usage intensif/production, on pourra héberger notre propre OSRM.
  static const String _base = 'https://router.project-osrm.org';

  /// Renvoie les points du tracé routier entre origine et destination.
  /// Retourne une liste vide en cas d'erreur (l'app continue de fonctionner).
  static Future<List<LatLng>> getRoute(LatLng origin, LatLng destination) async {
    try {
      // OSRM attend l'ordre longitude,latitude
      final url = Uri.parse(
        '$_base/route/v1/driving/'
            '${origin.longitude},${origin.latitude};'
            '${destination.longitude},${destination.latitude}'
            '?overview=full&geometries=geojson',
      );

      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);
      if (data['routes'] == null || (data['routes'] as List).isEmpty) return [];

      final coords = data['routes'][0]['geometry']['coordinates'] as List;
      // GeoJSON renvoie [lng, lat] → on inverse pour LatLng(lat, lng)
      return coords
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
    } catch (_) {
      return [];
    }
  }
}