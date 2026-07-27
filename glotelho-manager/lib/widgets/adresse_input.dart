import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

const String _MAPBOX_TOKEN = 'pk.eyJ1IjoiYW1hbmRpbmVraWx5IiwiYSI6ImNtcjRyZzd2NzBjc3UzMHIwdHkxZmdnZWIifQ.CrM5ELxBNEXlP4rQzxsxow';

// Centre approximatif de Douala pour limiter les résultats
const double _DOUALA_LAT = 4.0483;
const double _DOUALA_LNG = 9.7043;

// Quartiers de Douala — données OpenStreetMap (92 quartiers réels avec coordonnées)
const Map<String, List<double>> QUARTIERS_DOUALA = {
  'Bonaberi': [4.0822098, 9.6649718],
  'Akwa': [4.052544, 9.6963304],
  'Ndogbati': [4.0495046, 9.7236832],
  'Ndobo': [4.1018152, 9.6360158],
  'Ngangue': [4.0207674, 9.7068203],
  'Ndogmbe': [4.0349769, 9.7529055],
  'Ndokoti': [4.0434344, 9.7436776],
  'Bonendale 1': [4.1122222, 9.6375552],
  'Nkomba': [4.0715713, 9.6733797],
  'Beedi': [4.0611714, 9.7662924],
  'Bonaminkano': [4.0820341, 9.675549],
  'Vallee Bessengue': [4.0526728, 9.7052693],
  'Bonambape': [4.0762703, 9.6755731],
  'Bonantone': [4.0618085, 9.7075205],
  'Bonadouma II': [4.0190947, 9.7011987],
  'Sodiko': [4.097744, 9.6623609],
  'Nkolminta': [4.0372098, 9.7260913],
  'Bonamatoumbe': [4.0952147, 9.6711081],
  'Bonamouang': [4.0829325, 9.721624],
  'Bassa': [4.0458695, 9.7289916],
  'Bonamoudourou': [4.06185, 9.71758],
  'Songbikako': [4.0456961, 9.7681459],
  'Koto': [4.1003794, 9.7555747],
  'Bepanda': [4.0565417, 9.7227206],
  'Bonadiwoto': [4.0161627, 9.7217454],
  'Ndoghem': [4.0675197, 9.7904885],
  'Bonanloka': [4.0139573, 9.7327861],
  'Bonamouti': [4.0717537, 9.7144253],
  'Cite Des Palmiers': [4.0542657, 9.7640556],
  'Logpom': [4.0769067, 9.7711838],
  'Bonendale 2': [4.1164184, 9.6544209],
  'New Bell': [4.0314849, 9.7057582],
  'Logbaba': [4.0328521, 9.7603178],
  'Ndogsimbi': [4.0404139, 9.7311528],
  'Bali': [4.0399946, 9.6930482],
  'Bonanjo': [4.043024, 9.6864962],
  'Makepe II Yonyong': [4.0671936, 9.7308224],
  'Bonatene': [4.0657787, 9.7076223],
  'Youpwe': [4.0105092, 9.699614],
  'Koumassi': [4.0357924, 9.6932786],
  'Pindo': [4.0596128, 9.7839646],
  'Besseke': [4.0726387, 9.6804632],
  'Bomkoul': [4.0949123, 9.8026592],
  'Makepe II Bonamoussadi': [4.0826348, 9.75451],
  'Bayis': [4.1116212, 9.8152313],
  'Nkolmbong': [4.0182989, 9.7955265],
  'Brazzaville': [4.0233735, 9.7292726],
  'Bonadoumbe': [4.0230872, 9.6988735],
  'Bonamoussongo': [4.0717211, 9.7254947],
  'Bonangang': [4.1056467, 9.744505],
  'Malangue': [4.0684699, 9.7613769],
  'Bonajinje': [4.0654728, 9.7130541],
  'Bangue': [4.1056394, 9.7528416],
  'Camp Yabassi': [4.0431861, 9.7092426],
  'Zusa Bassa': [4.1050886, 9.8091756],
  'Kambo': [4.0236763, 9.7941289],
  'Nkololoun': [4.0334598, 9.7195305],
  'Logbessou I': [4.0844731, 9.7842289],
  'Nylon': [4.0282399, 9.7307532],
  'Bois des Singes': [4.0080364, 9.7079395],
  'Bonamoussadi': [4.094354, 9.7393663],
  'Ndogbong': [4.0644714, 9.7521285],
  'Yassa': [3.9913253, 9.8103803],
  'Madagascar': [4.033651, 9.7360237],
  'Congo': [4.0373892, 9.7053201],
  'Bonewonda': [4.0755225, 9.7190991],
  'Nyalla Bassa': [4.0334103, 9.7744243],
  'Logbessou II': [4.0810919, 9.7970314],
  'Domaine Universitaire': [4.0596227, 9.7401261],
  'New Deido': [4.0594866, 9.7146748],
  'Bonapriso': [4.0256151, 9.6930153],
  'KM 6': [4.0379991, 9.7206786],
  'Bonadouma': [4.028734, 9.6998938],
  'Oyak': [4.0266304, 9.7397861],
  'Nouvel Aeroport': [4.0110463, 9.7211998],
  'Babylone': [4.0261148, 9.7085218],
  'Ancien Aeroport': [4.0147686, 9.70769],
  'Didom II': [4.0141502, 9.7430749],
  'Denver': [4.0915045, 9.7323226],
  'Ndogpassi III': [4.0100854, 9.7566698],
  'Cite SIC': [4.0539142, 9.7307181],
  'Village': [4.011774, 9.7294207],
  'Mbanga Bakoko': [4.0070341, 9.7992035],
  'Bepele': [4.1058985, 9.6223042],
  'Bojongo': [4.0866081, 9.6190381],
  'Ngwele': [4.0911188, 9.6505071],
  'Bonateki': [4.0703304, 9.7175548],
  'Bessengue': [4.0566106, 9.7111669],
  'Washington': [4.0842012, 9.6534023],
  'Ange Raphael': [4.0225624, 9.7017512],
  'Mabanda': [4.0706087, 9.6573311],
  'Lobe': [4.0990957, 9.6554455],
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
  final TextEditingController? controller; // ← contrôleur externe optionnel (source de vérité)

  const AdresseInput({
    super.key,
    required this.label,
    required this.icon,
    required this.onChanged,
    this.showGeoloc = true,
    this.controller,
  });

  @override
  State<AdresseInput> createState() => _AdresseInputState();
}

class _AdresseInputState extends State<AdresseInput> {
  late final TextEditingController _controller;
  bool _controllerEstExterne = false;
  Timer? _debounce;
  List<Map<String, dynamic>> _suggestions = [];
  bool _loadingSuggestions = false;
  bool _loadingPosition = false;
  bool _showFallback = false;
  double? _lat, _lng;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _controllerEstExterne = true;
    } else {
      _controller = TextEditingController();
      _controllerEstExterne = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    // Ne jamais disposer un contrôleur fourni par le parent — il lui appartient
    if (!_controllerEstExterne) _controller.dispose();
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

      // Reverse geocoding précis — privilégie l'adresse de rue / POI / quartier
      String texte = 'Ma position actuelle';
      try {
        final url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/'
            '${pos.longitude},${pos.latitude}.json'
            '?access_token=$_MAPBOX_TOKEN'
            '&types=address,poi,neighborhood'
            '&limit=1';
        final res = await http.get(Uri.parse(url));
        final data = jsonDecode(res.body);
        final features = (data['features'] as List?) ?? [];
        if (features.isNotEmpty) {
          texte = features[0]['place_name'];
        } else {
          // Rien de précis chez Mapbox — trouver le quartier connu le plus proche
          // localement (calcul de distance), sans jamais retomber sur "Douala, ville"
          String? quartierProche;
          double distanceMin = double.infinity;
          QUARTIERS_DOUALA.forEach((nom, coords) {
            final dLat = coords[0] - pos.latitude;
            final dLng = coords[1] - pos.longitude;
            final dist = dLat * dLat + dLng * dLng; // distance au carré, suffisant pour comparer
            if (dist < distanceMin) {
              distanceMin = dist;
              quartierProche = nom;
            }
          });
          texte = quartierProche != null ? 'Près de $quartierProche' : 'Ma position actuelle';
        }
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
