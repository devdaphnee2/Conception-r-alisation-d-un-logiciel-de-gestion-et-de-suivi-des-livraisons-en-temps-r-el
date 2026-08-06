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

  // Carrefours et ronds-points (repères courants a Douala)
  'Pointe Olga': [3.9707303, 9.6242702],
  'Carrefour Tunnel Logbaba': [4.0357113, 9.7519975],
  'Carrefour Ngann Yonn': [4.086336, 9.7694872],
  'Carrefour Casmando': [4.0698297, 9.7293801],
  'Carrefour Bonabassem': [4.0710983, 9.7187862],
  'Carrefour Tonnerre': [4.0721007, 9.7268416],
  'Grand Hangar': [4.0802347, 9.6626969],
  'Carrefour Block 7': [4.0775048, 9.6596847],
  'Carrefour Lycee de Makepe': [4.0826317, 9.7570327],
  'Carrefour Express': [4.0827223, 9.7655549],
  'Carrefour 3 Baham': [4.0698676, 9.7267781],
  'Carrefour Ndokoti': [4.0437742, 9.7431494],
  'Carrefour Casino': [4.0335372, 9.7190464],
  'Rond Point Colonel Ndi': [4.0532046, 9.7725904],
  'Nyalla Etrangers': [4.0328835, 9.7887296],
  'Rhone Poulenc Makepe': [4.0846865, 9.7552894],
  'Carrefour La Manne': [4.0488517, 9.6903877],
  'Place Armee de lAir': [4.0167536, 9.7067233],
  'Place du Defile': [4.0274647, 9.6868822],
  'Place du President Ahidjo': [4.0429435, 9.7029159],
  'Rond Point 4': [4.060587, 9.7032085],
  'Rond-Point de Deido': [4.0640884, 9.7067837],
  'Club Nautique Marina 2000': [4.0065209, 9.7016367],
  'Rondpoint Dakar': [4.0253489, 9.735171],
  'Pointe Docteur': [4.015608, 9.6579378],
  'Carrefour Nelson Mandela': [4.0118142, 9.7322941],
  'Carrefour KM': [4.0995735, 9.7410248],
  'Quatre etages': [4.0932069, 9.6584668],
  'Carrefour Safari': [4.0769011, 9.7306438],
  'Rondpoint Ecole Publique': [4.0646447, 9.7146459],
  'Rondpoint Bepanda An 2000': [4.0658704, 9.7235112],
  'Rondpoint Le Pauvre': [4.0667726, 9.7242414],
  'Rondpoint Americaine': [4.0673906, 9.7249885],
  'Rondpoint Bepanda Ambiance': [4.0623683, 9.7298948],
  'Carrefour Fraternite': [4.0647772, 9.7293484],
  'Rondpoint Boulangerie de la Paix': [4.0666653, 9.7292587],
  'Rondpoint Sans Kalicon': [4.0666983, 9.7279551],
  'Rondpoint OK Pressing': [4.0667738, 9.7259241],
  'Rondpoint 1 to 1': [4.0718178, 9.7281481],
  'Rondpoint Double Bar': [4.0727484, 9.7248084],
  'Rondpoint Lycee Bepanda': [4.0703526, 9.724381],
  'Carrefour Garden Logbaba': [4.0341274, 9.764468],
  'Chefferie Nyalla': [4.0343532, 9.7735053],
  'Rond Point Palais Justice Ndokoti': [4.0461176, 9.7445738],
  'Chefferie Ndoghem': [4.0511556, 9.7385348],
  'Rondpoint Omnisport': [4.0495733, 9.7184212],
  'Rond Point BP Cite': [4.047342, 9.728418],
  'Carrefour Chico': [4.0704557, 9.6532568],
  'Carrefour Alhadji': [4.0687563, 9.656389],
  'Carrefour de Garage': [4.0718958, 9.6747529],
  'Carrefour Alphonse': [4.0004064, 9.7644208],
  'Rondpoint Bon Fils': [4.0598634, 9.7251192],
  'Carrefour Grand Towoh': [4.1139168, 9.631248],
  'Carrefour Yassa': [4.0006054, 9.8053236],
  'Carrefour Amacam': [4.0525611, 9.6953681],
  'Carrefour Andem': [4.0869015, 9.7654453],
  'Carrefour Etoo': [4.087056, 9.7438087],
  'Carrefour Menoserie': [4.0854609, 9.7684108],
  'Carrefour Patrick Boma': [4.0785777, 9.7454278],
  'Carrefour Santa Barbara': [4.0843131, 9.7410897],
  'Carrefour Yoro Joss': [4.0968511, 9.7410348],
  'Carrefour CCC': [4.0335557, 9.7402439],
  'Pont Noir': [4.0147817, 9.7353613],
  'Carrefour Dernier Poteau': [4.0379173, 9.7204324],
  'Feu Rouge Bessengue': [4.0591545, 9.7112817],
  'Carrefour Soudanaise': [4.0480479, 9.6942565],
  'Ancien Dalip': [4.0460192, 9.6986773],
  'Carrefour Tiff': [4.0445701, 9.6975318],
  'Carrefour Deux Eglises': [4.042904, 9.7062184],
  'Carrefour Basson': [4.0807626, 9.7716482],
  'Douala Bar': [4.0473669, 9.699767],
  'PK8': [4.0470063, 9.7578107],
  'Carrefour de lAir': [4.0198627, 9.7011758],
  'Carrefour des ruelles': [4.0652754, 9.7209836],
  'Garde-fou': [4.0301577, 9.7233562],
  'Shell Village': [4.0091257, 9.7410425],
  'Carrefour Saint Nicolas': [4.0203234, 9.7614781],

  // Stations-service et marchés (repères fréquents à Douala)
  'Tradex': [4.0925705, 9.7521566],
  'Oilibya Bonamoussadi': [4.0851023, 9.733334],
  'TOTAL Bonamoussadi 1': [4.0864022, 9.7345574],
  'Oilibya Bonanjo': [4.0534268, 9.7049499],
  'Oilibya Akwa': [4.0269939, 9.6877812],
  'Petrolex': [4.0360903, 9.698604],
  'MRS Ndogbong': [4.0191113, 9.7221723],
  'Texaco Akwa': [4.0277255, 9.6890475],
  'Texaco Bonanjo': [4.0414052, 9.6873557],
  'Texaco New Bell': [4.0427586, 9.7077224],
  'Texaco Deido': [4.0439574, 9.7056735],
  'Texaco Bonapriso': [4.05609, 9.6954752],
  'MRS Bonapriso': [4.0581088, 9.7010305],
  'Total Aeroport': [4.0156066, 9.7265943],
  'TOTAL Manga Bell': [4.03661, 9.7013101],
  'Total Bonanjo': [4.040596, 9.6870033],
  'TOTAL Jomat': [4.0427373, 9.7065176],
  'TOTAL Bonalembe': [4.0434796, 9.7107351],
  'TOTAL Laquintinie': [4.0494728, 9.7042089],
  'TOTAL Carrefour Z': [4.0547778, 9.7493386],
  'Total Bonapriso 2': [4.056584, 9.6991532],
  'TOTAL Bessengue': [4.0568302, 9.7088375],
  'Bocom Bonaberi': [4.0026266, 9.8127009],
  'Blessing Station': [3.9968505, 9.8275824],
  'Station Neptune Bonamoussadi': [4.0969057, 9.7534095],
  'MRS Makepe': [4.0968193, 9.7491829],
  'TOTAL Wouri 2': [4.0634722, 9.7064056],
  'TOTAL Besseke': [4.047752, 9.6899852],
  'Total Deido': [4.0637534, 9.7068598],
  'Oilibya New Bell': [4.0365269, 9.6904713],
  'TOTAL Makepe': [4.077006, 9.7510823],
  'TOTAL Bonateki 2': [4.0705969, 9.7141088],
  'TOTAL Bonamoussadi 2': [4.0842621, 9.7325975],
  'MRS Bonatene': [4.0643043, 9.7142478],
  'Tradex Ndokoti': [4.0441155, 9.743154],
  'Alpha Oil': [4.060799, 9.7847],
  'MRS Village': [4.008832, 9.7412931],
  'MRS PK': [4.0068611, 9.7529709],
  'Tradex Yassa': [4.0008474, 9.8049658],
  'TOTAL Cite des Palmiers': [4.0480436, 9.761597],
  'TOTAL Logbaba': [4.0372883, 9.7608426],
  'Gulfin': [4.0327345, 9.7661641],
  'Total Ndokoti': [4.0412483, 9.7455508],
  'Bocom Logbaba': [4.0356146, 9.7527411],
  'Neptune Logbaba': [4.0347886, 9.7786334],
  'Socamit': [4.0295123, 9.7903108],
  'Afrigaz': [4.0860991, 9.6660779],
  'Bocom Missoke': [4.064874, 9.7424371],
  'First Oil': [4.0717991, 9.7181834],
  'TOTAL Mbanga Bakoko': [4.0175835, 9.7962153],
  'TOTAL Ndogpassi': [4.0101406, 9.7489035],
  'TOTAL Aeroport Douala': [4.0155083, 9.7267159],
  'TOTAL Grand Mall': [4.0249662, 9.7203478],
  'TOTAL Independence': [4.0276968, 9.7064831],
  'TOTAL Neuilly 2': [4.0279807, 9.6886937],
  'TOTAL Njo Njo': [4.0359295, 9.6947405],
  'TOTAL Ngodi': [4.0430855, 9.709905],
  'TOTAL President': [4.0456781, 9.6987054],
  'TOTAL Kassalafam': [4.0364567, 9.7114226],
  'TOTAL Reunification': [4.0543558, 9.7150694],
  'TOTAL Wouri 1': [4.063743, 9.706861],
  'TOTAL Bonamoudourou': [4.0595749, 9.7114202],
  'TOTAL Bepanda Yoyong': [4.06591, 9.7317752],
  'TOTAL Gare Bassa': [4.0421846, 9.7445008],
  'TOTAL MAGZI': [4.0389107, 9.7415026],
  'TOTAL Cite SIC': [4.0475914, 9.728221],
  'TOTAL Beedi': [4.0611157, 9.765368],
  'TOTAL Logpom': [4.0833768, 9.7703447],
  'TOTAL PK 12': [4.0646222, 9.7875065],
  'TOTAL Bonaberi': [4.0808926, 9.6647655],
  'TOTAL Bojongo': [4.0994153, 9.6363047],
  'Vision Energy': [4.0862899, 9.79529],
  'Petit Marche Akwa Nord': [4.0825175, 9.718884],
  'Marche PK12': [4.0627582, 9.7862998],
  'Petit Marche Nyalla': [4.0321646, 9.7888874],
  'Petit Marche Logbaba': [4.0372655, 9.7588885],
  'Marche Ndogpassi': [4.0040965, 9.7562424],
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