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