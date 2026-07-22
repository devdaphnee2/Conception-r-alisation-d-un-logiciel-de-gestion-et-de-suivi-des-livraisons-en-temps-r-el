import { useState, useRef, useEffect } from 'react';

const MAPBOX_TOKEN = 'pk.eyJ1IjoiYW1hbmRpbmVraWx5IiwiYSI6ImNtcjRyZzd2NzBjc3UzMHIwdHkxZmdnZWIifQ.CrM5ELxBNEXlP4rQzxsxow';

// Quartiers de secours — relais local si Mapbox échoue
const QUARTIERS_DOUALA = {
    'Akwa'          : [9.6980, 4.0500],
    'Bonanjo'       : [9.6930, 4.0470],
    'Bonapriso'     : [9.7030, 4.0330],
    'Bonamoussadi'  : [9.7460, 4.0850],
    'Deido'         : [9.6980, 4.0620],
    'Bali'          : [9.6850, 4.0500],
    'Ndokoti'       : [9.7350, 4.0680],
    'Makepe'        : [9.7280, 4.0800],
    'Logpom'        : [9.7550, 4.0950],
    'Kotto'         : [9.7550, 4.0620],
    'Village'       : [9.7100, 4.0400],
    'New Bell'      : [9.7100, 4.0500],
    'Bepanda'       : [9.7200, 4.0700],
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
                        longitude + ',' + latitude + '.json?access_token=' + MAPBOX_TOKEN + '&limit=1';
                    const res = await fetch(url);
                    const data = await res.json();
                    const nom = data.features && data.features[0] ? data.features[0].place_name : 'Ma position actuelle';
                    setTexte(nom);
                    setSelected(true);
                    onChange({ texte: nom, latitude, longitude });
                } catch {
                    onChange({ texte: 'Ma position actuelle', latitude, longitude });
                    setTexte('Ma position actuelle');
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