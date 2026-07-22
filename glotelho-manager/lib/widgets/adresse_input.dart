import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

const String _MAPBOX_TOKEN = 'pk.eyJ1IjoiYW1hbmRpbmVraWx5IiwiYSI6ImNtcjRyZzd2NzBjc3UzMHIwdHkxZmdnZWIifQ.CrM5ELxBNEXlP4rQzxsxow';

// Centre approximatif de Douala pour limiter les résultats
const double _DOUALA_LAT = 4.0483;
const double _DOUALA_LNG = 9.7043;

// Quartiers de secours avec coordonnées pré-enregistrées
const Map<String, List<double>> QUARTIERS_DOUALA = {
  'Akwa'          : [4.0500, 9.6980],
  'Bonanjo'       : [4.0470, 9.6930],
  'Bonapriso'     : [4.0330, 9.7030],
  'Bonamoussadi'  : [4.0850, 9.7460],
  'Deido'         : [4.0620, 9.6980],
  'Bali'          : [4.0500, 9.6850],
  'Ndokoti'       : [4.0680, 9.7350],
  'Makepe'        : [4.0800, 9.7280],
  'Logpom'        : [4.0950, 9.7550],
  'Kotto'         : [4.0620, 9.7550],
  'PK8'           : [4.0350, 9.6600],
  'PK14'          : [4.0100, 9.6300],
  'Village'       : [4.0400, 9.7100],
  'New Bell'      : [4.0500, 9.7100],
  'Bepanda'       : [4.0700, 9.7200],
};

class AdresseResult {
  final String texte;
  final double? latitude;
  final double? longitude;
  AdresseResult({required this.texte, this.latitude, this.longitude});
}

class AdresseInput extends StatefulWidget {
  final String label;
  final IconData icon;
  final ValueChanged<AdresseResult> onChanged;
  final bool showGeoloc;

  const AdresseInput({
    super.key,
    required this.label,
    required this.icon,
    required this.onChanged,
    this.showGeoloc = true,
  });

  @override
  State<AdresseInput> createState() => _AdresseInputState();
}

class _AdresseInputState extends State<AdresseInput> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _suggestions = [];
  bool _loadingSuggestions = false;
  bool _loadingPosition = false;
  bool _showFallback = false;
  double? _lat, _lng;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ── Auto-complétion : recherche locale instantanée + Mapbox ────
  void _onTextChanged(String value) {
    _debounce?.cancel();
    setState(() => _showFallback = false);
    if (value.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    // Recherche LOCALE instantanée dans les quartiers connus
    final saisieLower = value.trim().toLowerCase();
    final quartiersTrouves = QUARTIERS_DOUALA.entries
        .where((e) => e.key.toLowerCase().contains(saisieLower))
        .map((e) => {
              'text': '${e.key}, Douala',
              'lat' : e.value[0],
              'lng' : e.value[1],
            })
        .toList();

    // Afficher immédiatement les résultats locaux pendant qu'on interroge Mapbox
    setState(() => _suggestions = quartiersTrouves);

    if (value.trim().length < 3) return;

    // Recherche Mapbox (debounce 300ms) pour rues/POI précis
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _loadingSuggestions = true);
      try {
        final requeteComplete = '$value, Douala, Cameroun';
        final url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/'
            '${Uri.encodeComponent(requeteComplete)}.json'
            '?access_token=$_MAPBOX_TOKEN'
            '&country=cm'
            '&proximity=$_DOUALA_LNG,$_DOUALA_LAT'
            '&types=neighborhood,locality,address,poi,place'
            '&limit=5';
        final res = await http.get(Uri.parse(url));
        final data = jsonDecode(res.body);
        final features = (data['features'] as List?) ?? [];

        final resultatsMapbox = features.where((f) {
          final nom = (f['place_name'] as String).toLowerCase();
          return nom.contains('douala') || nom.contains('littoral');
        }).map<Map<String, dynamic>>((f) => {
              'text': f['place_name'],
              'lat' : f['center'][1],
              'lng' : f['center'][0],
            }).toList();

        setState(() {
          final tousLesResultats = <Map<String, dynamic>>[...quartiersTrouves];
          for (final r in resultatsMapbox) {
            final dejaPresent = tousLesResultats.any((q) =>
                (q['text'] as String).toLowerCase().contains(
                    (r['text'] as String).split(',')[0].toLowerCase()));
            if (!dejaPresent) tousLesResultats.add(r);
          }
          _suggestions = tousLesResultats.take(6).toList();
          _showFallback = _suggestions.isEmpty;
        });
      } catch (_) {
        if (quartiersTrouves.isEmpty) setState(() => _showFallback = true);
      } finally {
        if (mounted) setState(() => _loadingSuggestions = false);
      }
    });
  }

  void _selectSuggestion(Map<String, dynamic> s) {
    setState(() {
      _controller.text = s['text'];
      _lat = s['lat'];
      _lng = s['lng'];
      _suggestions = [];
      _showFallback = false;
    });
    widget.onChanged(AdresseResult(texte: s['text'], latitude: _lat, longitude: _lng));
  }

  // ── Géolocalisation — position actuelle ────────────────────────
  Future<void> _utiliserMaPosition() async {
    setState(() => _loadingPosition = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() => _showFallback = true);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _lat = pos.latitude;
      _lng = pos.longitude;

      // Reverse geocoding pour affichage — mais on garde les coordonnées
      // même si cette requête échoue (le calcul de frais n'en a pas besoin)
      String texte = 'Ma position actuelle';
      try {
        final url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/'
            '${pos.longitude},${pos.latitude}.json?access_token=$_MAPBOX_TOKEN&limit=1';
        final res = await http.get(Uri.parse(url));
        final data = jsonDecode(res.body);
        final features = (data['features'] as List?) ?? [];
        if (features.isNotEmpty) texte = features[0]['place_name'];
      } catch (_) {
        // Reverse geocoding a échoué — on garde quand même les coordonnées GPS
      }

      setState(() {
        _controller.text = texte;
        _suggestions = [];
        _showFallback = false;
      });
      widget.onChanged(AdresseResult(texte: texte, latitude: _lat, longitude: _lng));
    } catch (e) {
      // Échec de la géolocalisation elle-même (permission/GPS désactivé)
      setState(() => _showFallback = true);
    } finally {
      if (mounted) setState(() => _loadingPosition = false);
    }
  }

  // ── Relais local — quartier de secours ──────────────────────────
  void _selectQuartier(String nom, List<double> coords) {
    setState(() {
      _controller.text = nom + ' (quartier)';
      _lat = coords[0];
      _lng = coords[1];
      _showFallback = false;
      _suggestions = [];
    });
    widget.onChanged(AdresseResult(texte: nom, latitude: _lat, longitude: _lng));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgField  = isDark ? const Color(0xFF1C3D56) : Colors.white;
    final txtColor = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final hintColor= isDark ? Colors.white54 : Colors.grey;
    final borderColor = isDark ? Colors.white24 : const Color(0xFFE0E0E0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Barre de recherche intelligente
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: _onTextChanged,
                style: TextStyle(color: txtColor, fontSize: 13),
                decoration: InputDecoration(
                  labelText: widget.label,
                  labelStyle: TextStyle(fontSize: 12, color: hintColor),
                  hintText: 'Tapez un lieu à Douala...',
                  hintStyle: TextStyle(fontSize: 12, color: hintColor),
                  prefixIcon: Icon(widget.icon, size: 18, color: hintColor),
                  suffixIcon: _loadingSuggestions
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)))
                      : (_lat != null ? const Icon(Icons.check_circle, color: Colors.green, size: 18) : null),
                  filled: true,
                  fillColor: bgField,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFC9952E), width: 1.5)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Raccourci géolocalisation — masqué si showGeoloc=false
            if (widget.showGeoloc)
              Material(
                color: const Color(0xFFC9952E),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _loadingPosition ? null : _utiliserMaPosition,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    child: _loadingPosition
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.my_location, color: Colors.white, size: 20),
                  ),
                ),
              ),
          ],
        ),

        // Suggestions Mapbox + quartiers locaux
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: bgField,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
            ),
            child: Scrollbar(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: _suggestions.map((s) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined, size: 16, color: Color(0xFFC9952E)),
                  title: Text(s['text'], style: TextStyle(fontSize: 12, color: txtColor)),
                  onTap: () => _selectSuggestion(s),
                )).toList(),
              ),
            ),
          ),

        // Relais local — quartiers de secours
        if (_showFallback) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.info_outline, size: 14, color: Color(0xFFF57F17)),
                  SizedBox(width: 6),
                  Text('Adresse introuvable — choisissez le quartier le plus proche :',
                      style: TextStyle(fontSize: 11, color: Color(0xFFF57F17))),
                ]),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: QUARTIERS_DOUALA.entries.map((e) => GestureDetector(
                    onTap: () => _selectQuartier(e.key, e.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFC9952E)),
                      ),
                      child: Text(e.key, style: const TextStyle(fontSize: 11, color: Color(0xFF7d5700))),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}