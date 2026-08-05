import { useState, useRef, useEffect } from 'react';

const MAPBOX_TOKEN = 'pk.eyJ1IjoiYW1hbmRpbmVraWx5IiwiYSI6ImNtcjRyZzd2NzBjc3UzMHIwdHkxZmdnZWIifQ.CrM5ELxBNEXlP4rQzxsxow';

// Quartiers de Douala — données OpenStreetMap (92 quartiers réels, format [lng, lat])
const QUARTIERS_DOUALA = {
    'Bonaberi': [9.6649718, 4.0822098],
    'Akwa': [9.6963304, 4.052544],
    'Ndogbati': [9.7236832, 4.0495046],
    'Ndobo': [9.6360158, 4.1018152],
    'Ngangue': [9.7068203, 4.0207674],
    'Ndogmbe': [9.7529055, 4.0349769],
    'Ndokoti': [9.7436776, 4.0434344],
    'Bonendale 1': [9.6375552, 4.1122222],
    'Nkomba': [9.6733797, 4.0715713],
    'Beedi': [9.7662924, 4.0611714],
    'Bonaminkano': [9.675549, 4.0820341],
    'Vallee Bessengue': [9.7052693, 4.0526728],
    'Bonambape': [9.6755731, 4.0762703],
    'Bonantone': [9.7075205, 4.0618085],
    'Bonadouma II': [9.7011987, 4.0190947],
    'Sodiko': [9.6623609, 4.097744],
    'Nkolminta': [9.7260913, 4.0372098],
    'Bonamatoumbe': [9.6711081, 4.0952147],
    'Bonamouang': [9.721624, 4.0829325],
    'Bassa': [9.7289916, 4.0458695],
    'Bonamoudourou': [9.71758, 4.06185],
    'Songbikako': [9.7681459, 4.0456961],
    'Koto': [9.7555747, 4.1003794],
    'Bepanda': [9.7227206, 4.0565417],
    'Bonadiwoto': [9.7217454, 4.0161627],
    'Ndoghem': [9.7904885, 4.0675197],
    'Bonanloka': [9.7327861, 4.0139573],
    'Bonamouti': [9.7144253, 4.0717537],
    'Cite Des Palmiers': [9.7640556, 4.0542657],
    'Logpom': [9.7711838, 4.0769067],
    'Bonendale 2': [9.6544209, 4.1164184],
    'New Bell': [9.7057582, 4.0314849],
    'Logbaba': [9.7603178, 4.0328521],
    'Ndogsimbi': [9.7311528, 4.0404139],
    'Bali': [9.6930482, 4.0399946],
    'Bonanjo': [9.6864962, 4.043024],
    'Makepe II Yonyong': [9.7308224, 4.0671936],
    'Bonatene': [9.7076223, 4.0657787],
    'Youpwe': [9.699614, 4.0105092],
    'Koumassi': [9.6932786, 4.0357924],
    'Pindo': [9.7839646, 4.0596128],
    'Besseke': [9.6804632, 4.0726387],
    'Bomkoul': [9.8026592, 4.0949123],
    'Makepe II Bonamoussadi': [9.75451, 4.0826348],
    'Bayis': [9.8152313, 4.1116212],
    'Nkolmbong': [9.7955265, 4.0182989],
    'Brazzaville': [9.7292726, 4.0233735],
    'Bonadoumbe': [9.6988735, 4.0230872],
    'Bonamoussongo': [9.7254947, 4.0717211],
    'Bonangang': [9.744505, 4.1056467],
    'Malangue': [9.7613769, 4.0684699],
    'Bonajinje': [9.7130541, 4.0654728],
    'Bangue': [9.7528416, 4.1056394],
    'Camp Yabassi': [9.7092426, 4.0431861],
    'Zusa Bassa': [9.8091756, 4.1050886],
    'Kambo': [9.7941289, 4.0236763],
    'Nkololoun': [9.7195305, 4.0334598],
    'Logbessou I': [9.7842289, 4.0844731],
    'Nylon': [9.7307532, 4.0282399],
    'Bois des Singes': [9.7079395, 4.0080364],
    'Bonamoussadi': [9.7393663, 4.094354],
    'Ndogbong': [9.7521285, 4.0644714],
    'Yassa': [9.8103803, 3.9913253],
    'Madagascar': [9.7360237, 4.033651],
    'Congo': [9.7053201, 4.0373892],
    'Bonewonda': [9.7190991, 4.0755225],
    'Nyalla Bassa': [9.7744243, 4.0334103],
    'Logbessou II': [9.7970314, 4.0810919],
    'Domaine Universitaire': [9.7401261, 4.0596227],
    'New Deido': [9.7146748, 4.0594866],
    'Bonapriso': [9.6930153, 4.0256151],
    'KM 6': [9.7206786, 4.0379991],
    'Bonadouma': [9.6998938, 4.028734],
    'Oyak': [9.7397861, 4.0266304],
    'Nouvel Aeroport': [9.7211998, 4.0110463],
    'Babylone': [9.7085218, 4.0261148],
    'Ancien Aeroport': [9.70769, 4.0147686],
    'Didom II': [9.7430749, 4.0141502],
    'Denver': [9.7323226, 4.0915045],
    'Ndogpassi III': [9.7566698, 4.0100854],
    'Cite SIC': [9.7307181, 4.0539142],
    'Village': [9.7294207, 4.011774],
    'Mbanga Bakoko': [9.7992035, 4.0070341],
    'Bepele': [9.6223042, 4.1058985],
    'Bojongo': [9.6190381, 4.0866081],
    'Ngwele': [9.6505071, 4.0911188],
    'Bonateki': [9.7175548, 4.0703304],
    'Bessengue': [9.7111669, 4.0566106],
    'Washington': [9.6534023, 4.0842012],
    'Ange Raphael': [9.7017512, 4.0225624],
    'Mabanda': [9.6573311, 4.0706087],
    'Lobe': [9.6554455, 4.0990957],

    // Carrefours et ronds-points (repères courants a Douala)
    'Pointe Olga': [9.6242702, 3.9707303],
    'Carrefour Tunnel Logbaba': [9.7519975, 4.0357113],
    'Carrefour Ngann Yonn': [9.7694872, 4.086336],
    'Carrefour Casmando': [9.7293801, 4.0698297],
    'Carrefour Bonabassem': [9.7187862, 4.0710983],
    'Carrefour Tonnerre': [9.7268416, 4.0721007],
    'Grand Hangar': [9.6626969, 4.0802347],
    'Carrefour Block 7': [9.6596847, 4.0775048],
    'Carrefour Lycee de Makepe': [9.7570327, 4.0826317],
    'Carrefour Express': [9.7655549, 4.0827223],
    'Carrefour 3 Baham': [9.7267781, 4.0698676],
    'Carrefour Ndokoti': [9.7431494, 4.0437742],
    'Carrefour Casino': [9.7190464, 4.0335372],
    'Rond Point Colonel Ndi': [9.7725904, 4.0532046],
    'Nyalla Etrangers': [9.7887296, 4.0328835],
    'Rhone Poulenc Makepe': [9.7552894, 4.0846865],
    'Carrefour La Manne': [9.6903877, 4.0488517],
    'Place Armee de lAir': [9.7067233, 4.0167536],
    'Place du Defile': [9.6868822, 4.0274647],
    'Place du President Ahidjo': [9.7029159, 4.0429435],
    'Rond Point 4': [9.7032085, 4.060587],
    'Rond-Point de Deido': [9.7067837, 4.0640884],
    'Club Nautique Marina 2000': [9.7016367, 4.0065209],
    'Rondpoint Dakar': [9.735171, 4.0253489],
    'Pointe Docteur': [9.6579378, 4.015608],
    'Carrefour Nelson Mandela': [9.7322941, 4.0118142],
    'Carrefour KM': [9.7410248, 4.0995735],
    'Quatre etages': [9.6584668, 4.0932069],
    'Carrefour Safari': [9.7306438, 4.0769011],
    'Rondpoint Ecole Publique': [9.7146459, 4.0646447],
    'Rondpoint Bepanda An 2000': [9.7235112, 4.0658704],
    'Rondpoint Le Pauvre': [9.7242414, 4.0667726],
    'Rondpoint Americaine': [9.7249885, 4.0673906],
    'Rondpoint Bepanda Ambiance': [9.7298948, 4.0623683],
    'Carrefour Fraternite': [9.7293484, 4.0647772],
    'Rondpoint Boulangerie de la Paix': [9.7292587, 4.0666653],
    'Rondpoint Sans Kalicon': [9.7279551, 4.0666983],
    'Rondpoint OK Pressing': [9.7259241, 4.0667738],
    'Rondpoint 1 to 1': [9.7281481, 4.0718178],
    'Rondpoint Double Bar': [9.7248084, 4.0727484],
    'Rondpoint Lycee Bepanda': [9.724381, 4.0703526],
    'Carrefour Garden Logbaba': [9.764468, 4.0341274],
    'Chefferie Nyalla': [9.7735053, 4.0343532],
    'Rond Point Palais Justice Ndokoti': [9.7445738, 4.0461176],
    'Chefferie Ndoghem': [9.7385348, 4.0511556],
    'Rondpoint Omnisport': [9.7184212, 4.0495733],
    'Rond Point BP Cite': [9.728418, 4.047342],
    'Carrefour Chico': [9.6532568, 4.0704557],
    'Carrefour Alhadji': [9.656389, 4.0687563],
    'Carrefour de Garage': [9.6747529, 4.0718958],
    'Carrefour Alphonse': [9.7644208, 4.0004064],
    'Rondpoint Bon Fils': [9.7251192, 4.0598634],
    'Carrefour Grand Towoh': [9.631248, 4.1139168],
    'Carrefour Yassa': [9.8053236, 4.0006054],
    'Carrefour Amacam': [9.6953681, 4.0525611],
    'Carrefour Andem': [9.7654453, 4.0869015],
    'Carrefour Etoo': [9.7438087, 4.087056],
    'Carrefour Menoserie': [9.7684108, 4.0854609],
    'Carrefour Patrick Boma': [9.7454278, 4.0785777],
    'Carrefour Santa Barbara': [9.7410897, 4.0843131],
    'Carrefour Yoro Joss': [9.7410348, 4.0968511],
    'Carrefour CCC': [9.7402439, 4.0335557],
    'Pont Noir': [9.7353613, 4.0147817],
    'Carrefour Dernier Poteau': [9.7204324, 4.0379173],
    'Feu Rouge Bessengue': [9.7112817, 4.0591545],
    'Carrefour Soudanaise': [9.6942565, 4.0480479],
    'Ancien Dalip': [9.6986773, 4.0460192],
    'Carrefour Tiff': [9.6975318, 4.0445701],
    'Carrefour Deux Eglises': [9.7062184, 4.042904],
    'Carrefour Basson': [9.7716482, 4.0807626],
    'Douala Bar': [9.699767, 4.0473669],
    'PK8': [9.7578107, 4.0470063],
    'Carrefour de lAir': [9.7011758, 4.0198627],
    'Carrefour des ruelles': [9.7209836, 4.0652754],
    'Garde-fou': [9.7233562, 4.0301577],
    'Shell Village': [9.7410425, 4.0091257],
    'Carrefour Saint Nicolas': [9.7614781, 4.0203234],

    // Stations-service et marchés (repères fréquents à Douala)
    'Tradex': [9.7521566, 4.0925705],
    'Oilibya Bonamoussadi': [9.733334, 4.0851023],
    'TOTAL Bonamoussadi 1': [9.7345574, 4.0864022],
    'Oilibya Bonanjo': [9.7049499, 4.0534268],
    'Oilibya Akwa': [9.6877812, 4.0269939],
    'Petrolex': [9.698604, 4.0360903],
    'MRS Ndogbong': [9.7221723, 4.0191113],
    'Texaco Akwa': [9.6890475, 4.0277255],
    'Texaco Bonanjo': [9.6873557, 4.0414052],
    'Texaco New Bell': [9.7077224, 4.0427586],
    'Texaco Deido': [9.7056735, 4.0439574],
    'Texaco Bonapriso': [9.6954752, 4.05609],
    'MRS Bonapriso': [9.7010305, 4.0581088],
    'Total Aeroport': [9.7265943, 4.0156066],
    'TOTAL Manga Bell': [9.7013101, 4.03661],
    'Total Bonanjo': [9.6870033, 4.040596],
    'TOTAL Jomat': [9.7065176, 4.0427373],
    'TOTAL Bonalembe': [9.7107351, 4.0434796],
    'TOTAL Laquintinie': [9.7042089, 4.0494728],
    'TOTAL Carrefour Z': [9.7493386, 4.0547778],
    'Total Bonapriso 2': [9.6991532, 4.056584],
    'TOTAL Bessengue': [9.7088375, 4.0568302],
    'Bocom Bonaberi': [9.8127009, 4.0026266],
    'Blessing Station': [9.8275824, 3.9968505],
    'Station Neptune Bonamoussadi': [9.7534095, 4.0969057],
    'MRS Makepe': [9.7491829, 4.0968193],
    'TOTAL Wouri 2': [9.7064056, 4.0634722],
    'TOTAL Besseke': [9.6899852, 4.047752],
    'Total Deido': [9.7068598, 4.0637534],
    'Oilibya New Bell': [9.6904713, 4.0365269],
    'TOTAL Makepe': [9.7510823, 4.077006],
    'TOTAL Bonateki 2': [9.7141088, 4.0705969],
    'TOTAL Bonamoussadi 2': [9.7325975, 4.0842621],
    'MRS Bonatene': [9.7142478, 4.0643043],
    'Tradex Ndokoti': [9.743154, 4.0441155],
    'Alpha Oil': [9.7847, 4.060799],
    'MRS Village': [9.7412931, 4.008832],
    'MRS PK': [9.7529709, 4.0068611],
    'Tradex Yassa': [9.8049658, 4.0008474],
    'TOTAL Cite des Palmiers': [9.761597, 4.0480436],
    'TOTAL Logbaba': [9.7608426, 4.0372883],
    'Gulfin': [9.7661641, 4.0327345],
    'Total Ndokoti': [9.7455508, 4.0412483],
    'Bocom Logbaba': [9.7527411, 4.0356146],
    'Neptune Logbaba': [9.7786334, 4.0347886],
    'Socamit': [9.7903108, 4.0295123],
    'Afrigaz': [9.6660779, 4.0860991],
    'Bocom Missoke': [9.7424371, 4.064874],
    'First Oil': [9.7181834, 4.0717991],
    'TOTAL Mbanga Bakoko': [9.7962153, 4.0175835],
    'TOTAL Ndogpassi': [9.7489035, 4.0101406],
    'TOTAL Aeroport Douala': [9.7267159, 4.0155083],
    'TOTAL Grand Mall': [9.7203478, 4.0249662],
    'TOTAL Independence': [9.7064831, 4.0276968],
    'TOTAL Neuilly 2': [9.6886937, 4.0279807],
    'TOTAL Njo Njo': [9.6947405, 4.0359295],
    'TOTAL Ngodi': [9.709905, 4.0430855],
    'TOTAL President': [9.6987054, 4.0456781],
    'TOTAL Kassalafam': [9.7114226, 4.0364567],
    'TOTAL Reunification': [9.7150694, 4.0543558],
    'TOTAL Wouri 1': [9.706861, 4.063743],
    'TOTAL Bonamoudourou': [9.7114202, 4.0595749],
    'TOTAL Bepanda Yoyong': [9.7317752, 4.06591],
    'TOTAL Gare Bassa': [9.7445008, 4.0421846],
    'TOTAL MAGZI': [9.7415026, 4.0389107],
    'TOTAL Cite SIC': [9.728221, 4.0475914],
    'TOTAL Beedi': [9.765368, 4.0611157],
    'TOTAL Logpom': [9.7703447, 4.0833768],
    'TOTAL PK 12': [9.7875065, 4.0646222],
    'TOTAL Bonaberi': [9.6647655, 4.0808926],
    'TOTAL Bojongo': [9.6363047, 4.0994153],
    'Vision Energy': [9.79529, 4.0862899],
    'Petit Marche Akwa Nord': [9.718884, 4.0825175],
    'Marche PK12': [9.7862998, 4.0627582],
    'Petit Marche Nyalla': [9.7888874, 4.0321646],
    'Petit Marche Logbaba': [9.7588885, 4.0372655],
    'Marche Ndogpassi': [9.7562424, 4.0040965],
};

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    surface: '#ffffff', onSurface: '#1a1c1c',
    outline: '#817564', outlineVariant: '#d3c4b0',
    surfaceContainerLow: '#f3f3f3',
};

export default function AdresseInput({ label, placeholder, onChange }) {
    const [texte, setTexte]             = useState('');
    const [suggestions, setSuggestions] = useState([]);
    const [loading, setLoading]         = useState(false);
    const [loadingGps, setLoadingGps]   = useState(false);
    const [showFallback, setShowFallback] = useState(false);
    const [selected, setSelected]       = useState(false);
    const debounceRef = useRef(null);

    // ── Étape 1-4 : recherche locale instantanée + Debounce 300ms + Mapbox ──
    function handleInputChange(e) {
        const value = e.target.value;
        setTexte(value);
        setSelected(false);
        setShowFallback(false);

        if (debounceRef.current) clearTimeout(debounceRef.current);

        if (value.trim().length < 2) {
            setSuggestions([]);
            return;
        }

        // Recherche LOCALE instantanée dans les quartiers connus
        const saisieLower = value.trim().toLowerCase();
        const quartiersTrouves = Object.entries(QUARTIERS_DOUALA)
            .filter(([nom]) => nom.toLowerCase().includes(saisieLower))
            .map(([nom, coords]) => ({ texte: nom + ', Douala', lng: coords[0], lat: coords[1] }));

        // Afficher immédiatement les résultats locaux
        setSuggestions(quartiersTrouves);

        if (value.trim().length < 3) return;

        // Étape 2 — attend 300ms d'inactivité avant d'interroger Mapbox
        debounceRef.current = setTimeout(async () => {
            setLoading(true);
            try {
                const requeteComplete = value + ', Douala, Cameroun';
                const url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/' +
                    encodeURIComponent(requeteComplete) + '.json' +
                    '?access_token=' + MAPBOX_TOKEN +
                    '&country=cm' +
                    '&proximity=9.7043,4.0483' +
                    '&types=neighborhood,locality,address,poi,place' +
                    '&limit=5';

                const res = await fetch(url);
                const data = await res.json();
                const features = data.features || [];

                const resultatsMapbox = features
                    .filter(f => {
                        const nom = f.place_name.toLowerCase();
                        return nom.includes('douala') || nom.includes('littoral');
                    })
                    .map(f => ({ texte: f.place_name, lng: f.center[0], lat: f.center[1] }));

                // Fusionner : résultats locaux d'abord, puis Mapbox (sans doublons)
                const tousLesResultats = [...quartiersTrouves];
                resultatsMapbox.forEach(r => {
                    const dejaPresent = tousLesResultats.some(q =>
                        q.texte.toLowerCase().includes(r.texte.split(',')[0].toLowerCase()));
                    if (!dejaPresent) tousLesResultats.push(r);
                });

                setSuggestions(tousLesResultats.slice(0, 6));
                setShowFallback(tousLesResultats.length === 0);
            } catch {
                if (quartiersTrouves.length === 0) setShowFallback(true);
            } finally {
                setLoading(false);
            }
        }, 300);
    }

    // ── Étape 5 : sélection — extraction lat/lng ──
    function selectSuggestion(s) {
        setTexte(s.texte);
        setSuggestions([]);
        setSelected(true);
        setShowFallback(false);
        onChange({ texte: s.texte, latitude: s.lat, longitude: s.lng });
    }

    // ── Raccourci géolocalisation ──
    function quartierLePlusProche(lat, lng) {
        let plusProche = null;
        let distanceMin = Infinity;
        Object.entries(QUARTIERS_DOUALA).forEach(([nom, coords]) => {
            const dLng = coords[0] - lng;
            const dLat = coords[1] - lat;
            const dist = dLat * dLat + dLng * dLng;
            if (dist < distanceMin) { distanceMin = dist; plusProche = nom; }
        });
        return plusProche;
    }

    function utiliserMaPosition() {
        if (!navigator.geolocation) {
            setShowFallback(true);
            return;
        }
        setLoadingGps(true);
        navigator.geolocation.getCurrentPosition(
            async (pos) => {
                const { latitude, longitude } = pos.coords;
                try {
                    const url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/' +
                        longitude + ',' + latitude + '.json?access_token=' + MAPBOX_TOKEN +
                        '&types=address,poi,neighborhood&limit=1';
                    const res = await fetch(url);
                    const data = await res.json();
                    let nom;
                    if (data.features && data.features.length > 0) {
                        nom = data.features[0].place_name;
                    } else {
                        // Rien de précis chez Mapbox — quartier connu le plus proche
                        const proche = quartierLePlusProche(latitude, longitude);
                        nom = proche ? 'Près de ' + proche : 'Ma position actuelle';
                    }
                    setTexte(nom);
                    setSelected(true);
                    onChange({ texte: nom, latitude, longitude });
                } catch {
                    const proche = quartierLePlusProche(latitude, longitude);
                    const nom = proche ? 'Près de ' + proche : 'Ma position actuelle';
                    onChange({ texte: nom, latitude, longitude });
                    setTexte(nom);
                    setSelected(true);
                } finally {
                    setLoadingGps(false);
                }
            },
            () => { setLoadingGps(false); setShowFallback(true); },
            { enableHighAccuracy: true }
        );
    }

    // ── Relais local — quartier pré-enregistré ──
    function selectQuartier(nom, coords) {
        setTexte(nom + ' (quartier)');
        setSelected(true);
        setShowFallback(false);
        onChange({ texte: nom, latitude: coords[1], longitude: coords[0] });
    }

    return (
        <div style={{ marginBottom: '14px' }}>
            <p style={{ margin: '0 0 6px', fontSize: '12px', fontWeight: 600, color: P.outline }}>{label}</p>
            <div style={{ display: 'flex', gap: '8px' }}>
                <div style={{ position: 'relative', flex: 1 }}>
                    <input
                        type="text"
                        value={texte}
                        onChange={handleInputChange}
                        placeholder={placeholder || 'Tapez un lieu à Douala...'}
                        style={{
                            width: '100%', padding: '12px 14px', borderRadius: '10px',
                            border: '1.5px solid ' + P.outlineVariant, fontSize: '13px',
                            fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none',
                            boxSizing: 'border-box',
                        }}
                    />
                    {loading && (
                        <span style={{ position: 'absolute', right: '12px', top: '50%', transform: 'translateY(-50%)', fontSize: '12px' }}>⏳</span>
                    )}
                    {selected && !loading && (
                        <span style={{ position: 'absolute', right: '12px', top: '50%', transform: 'translateY(-50%)', color: '#22C55E' }}>✓</span>
                    )}

                    {/* Étape 4 — liste déroulante des suggestions */}
                    {suggestions.length > 0 && (
                        <div style={{
                            position: 'absolute', top: '100%', left: 0, right: 0, zIndex: 20,
                            backgroundColor: P.surface, border: '1px solid ' + P.outlineVariant,
                            borderRadius: '10px', marginTop: '4px', boxShadow: '0 4px 16px rgba(0,0,0,0.1)',
                            maxHeight: '220px', overflowY: 'auto',
                        }}>
                            {suggestions.map((s, i) => (
                                <div key={i} onClick={() => selectSuggestion(s)}
                                    style={{
                                        padding: '10px 14px', fontSize: '12px', cursor: 'pointer',
                                        borderBottom: i < suggestions.length - 1 ? '1px solid ' + P.surfaceContainerLow : 'none',
                                        display: 'flex', alignItems: 'center', gap: '8px',
                                    }}
                                    onMouseEnter={e => e.currentTarget.style.backgroundColor = P.surfaceContainerLow}
                                    onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}>
                                    <span>📍</span>
                                    <span style={{ color: P.onSurface }}>{s.texte}</span>
                                </div>
                            ))}
                        </div>
                    )}
                </div>

                {/* Bouton géolocalisation */}
                <button type="button" onClick={utiliserMaPosition} disabled={loadingGps}
                    style={{
                        padding: '12px 14px', borderRadius: '10px', border: 'none',
                        backgroundColor: P.primaryContainer, color: '#fff', cursor: 'pointer',
                        fontSize: '16px', flexShrink: 0,
                    }}
                    title="Utiliser ma position">
                    {loadingGps ? '⏳' : '📍'}
                </button>
            </div>

            {/* Relais local — quartiers de secours */}
            {showFallback && (
                <div style={{ marginTop: '8px', padding: '10px', backgroundColor: '#fff8e1', borderRadius: '8px', border: '1px solid #ffe082' }}>
                    <p style={{ margin: '0 0 8px', fontSize: '11px', color: '#f57f17' }}>
                        ℹ️ Adresse introuvable — choisissez le quartier le plus proche :
                    </p>
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
                        {Object.entries(QUARTIERS_DOUALA).map(([nom, coords]) => (
                            <span key={nom} onClick={() => selectQuartier(nom, coords)}
                                style={{
                                    padding: '5px 12px', borderRadius: '20px', border: '1px solid ' + P.primaryContainer,
                                    color: P.primary, fontSize: '11px', cursor: 'pointer', backgroundColor: '#fff',
                                }}>
                                {nom}
                            </span>
                        ))}
                    </div>
                </div>
            )}
        </div>
    );
}