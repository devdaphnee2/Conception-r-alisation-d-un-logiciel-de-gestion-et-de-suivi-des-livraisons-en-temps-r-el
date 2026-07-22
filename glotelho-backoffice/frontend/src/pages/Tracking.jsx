import { useState, useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';
import { database, ref, onValue, off } from '../config/firebase';
import api from '../services/api';

mapboxgl.accessToken = "import.meta.env.VITE_MAPBOX_TOKEN";
//pk.eyJ1IjoiYW1hbmRpbmVraWx5IiwiYSI6ImNtcjRyZzd2NzBjc3UzMHIwdHkxZmdnZWIifQ.CrM5ELxBNEXlP4rQzxsxow

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    surface: '#ffffff', background: '#f5f5f5',
    surfaceContainerLow: '#f3f3f3', surfaceContainerHigh: '#e8e8e8',
    inverseS: '#2f3131', inverseSOn: '#f1f1f1',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
};

const COLORS = ['#c9952e', '#3B82F6', '#22C55E', '#EF4444', '#8B5CF6', '#EC4899'];

export default function Tracking() {
    const mapContainer = useRef(null);
    const map = useRef(null);
    const markersRef = useRef({});

    const [livreurs, setLivreurs] = useState([]);
    const [selected, setSelected] = useState(null);
    const [positions, setPositions] = useState({});
    const [mapLoaded, setMapLoaded] = useState(false);
    const [loading, setLoading] = useState(true);

    // Charger livreurs en cours
    useEffect(() => {
        api.get('/livraisons?status=En_cours')
            .then(res => {
                const data = res.data || [];
                const livreurMap = {};
                data.forEach(l => {
                    if (l.delivery_persons && !livreurMap[l.delivery_person_id]) {
                        livreurMap[l.delivery_person_id] = {
                            id: l.delivery_person_id,
                            nom: (l.delivery_persons.users?.first_name || '') + ' ' + (l.delivery_persons.users?.last_name || ''),
                            vehicule: l.delivery_persons.vehicules?.type || 'moto',
                            zone: l.delivery_persons.zone_affectee || '',
                            livraison_id: l.id,
                            livraison_ref: 'LIV-' + String(l.id).padStart(5, '0'),
                            client: (l.customers?.users?.first_name || '') + ' ' + (l.customers?.users?.last_name || ''),
                            client_phone: l.customers?.users?.phone || '',
                            adresse: l.delivery_address || '',
                            montant: l.amount_to_collect || 0,
                        };
                    }
                });
                const list = Object.values(livreurMap);
                setLivreurs(list);
                if (list.length > 0) setSelected(list[0].id);
            })
            .catch(() => {})
            .finally(() => setLoading(false));
    }, []);

    // Écouter Firebase positions
    useEffect(() => {
        const posRef = ref(database, 'positions');
        onValue(posRef, snapshot => {
            const data = snapshot.val();
            if (data) setPositions(data);
        });
        return () => off(posRef);
    }, []);

    // Init Mapbox
    useEffect(() => {
        if (map.current) return;

        map.current = new mapboxgl.Map({
            container: mapContainer.current,
            style: 'mapbox://styles/mapbox/streets-v12',
            center: [9.7400, 4.0580],
            zoom: 13,
        });

        // Tous les contrôles DANS le callback load
        map.current.on('load', () => {
            // Zoom +
            map.current.addControl(
                new mapboxgl.NavigationControl({ showCompass: false }),
                'bottom-right'
            );

            // Bouton géolocalisation — me montrer sur la carte
            map.current.addControl(
                new mapboxgl.GeolocateControl({
                    positionOptions: { enableHighAccuracy: true },
                    trackUserLocation: true,
                    showUserHeading: true,
                    showAccuracyCircle: true,
                }),
                'bottom-right'
            );

            setMapLoaded(true);
        });

        return () => {
            if (map.current) { map.current.remove(); map.current = null; }
        };
    }, []);

    // Mettre à jour marqueurs quand positions Firebase changent
    useEffect(() => {
        if (!mapLoaded || !map.current) return;

        Object.entries(positions).forEach(([livreurId, pos]) => {
            const id = parseInt(livreurId);
            const livreurIdx = livreurs.findIndex(l => l.id === id);
            const color = COLORS[livreurIdx >= 0 ? livreurIdx % COLORS.length : 0];
            const isSelected = selected === id;
            const livreur = livreurs.find(l => l.id === id);
            const coords = [pos.longitude, pos.latitude];

            if (markersRef.current[id]) {
                markersRef.current[id].marker.setLngLat(coords);
                updateMarkerEl(markersRef.current[id].el, pos, color, isSelected, livreur);
            } else {
                const el = document.createElement('div');
                el.style.cursor = 'pointer';
                updateMarkerEl(el, pos, color, isSelected, livreur);
                el.addEventListener('click', () => {
                    setSelected(prev => prev === id ? null : id);
                    map.current.flyTo({ center: coords, zoom: 15, duration: 600 });
                });
                const marker = new mapboxgl.Marker({ element: el, anchor: 'bottom' })
                    .setLngLat(coords)
                    .addTo(map.current);
                markersRef.current[id] = { marker, el, color };
            }

            if (isSelected && livreur) {
                fetchAndDrawRoute(livreur, coords, color);
            }
        });

        Object.keys(markersRef.current).forEach(id => {
            if (!positions[id]) {
                markersRef.current[id].marker.remove();
                delete markersRef.current[id];
            }
        });
    }, [positions, mapLoaded, selected, livreurs]);

    async function fetchAndDrawRoute(livreur, currentCoords, color) {
        if (!map.current || !livreur.adresse) return;
        try {
            const geocodeUrl = 'https://api.mapbox.com/geocoding/v5/mapbox.places/' +
                encodeURIComponent(livreur.adresse + ', Douala, Cameroun') +
                '.json?access_token=' + mapboxgl.accessToken + '&limit=1';
            const geoRes = await fetch(geocodeUrl);
            const geoData = await geoRes.json();
            if (!geoData.features || geoData.features.length === 0) return;

            const dest = geoData.features[0].center;
            const dirUrl = 'https://api.mapbox.com/directions/v5/mapbox/driving/' +
                currentCoords[0] + ',' + currentCoords[1] + ';' + dest[0] + ',' + dest[1] +
                '?geometries=geojson&access_token=' + mapboxgl.accessToken;
            const dirRes = await fetch(dirUrl);
            const dirData = await dirRes.json();
            if (!dirData.routes || dirData.routes.length === 0) return;

            const routeCoords = dirData.routes[0].geometry;
            const sourceId = 'route-' + livreur.id;
            const layerId = 'route-layer-' + livreur.id;

            if (map.current.getSource(sourceId)) {
                map.current.getSource(sourceId).setData({ type: 'Feature', geometry: routeCoords });
            } else {
                map.current.addSource(sourceId, { type: 'geojson', data: { type: 'Feature', geometry: routeCoords } });
                map.current.addLayer({
                    id: layerId + '-bg', type: 'line', source: sourceId,
                    layout: { 'line-join': 'round', 'line-cap': 'round' },
                    paint: { 'line-color': '#e0e0e0', 'line-width': 6, 'line-dasharray': [2, 3] }
                });
                map.current.addLayer({
                    id: layerId, type: 'line', source: sourceId,
                    layout: { 'line-join': 'round', 'line-cap': 'round' },
                    paint: { 'line-color': color, 'line-width': 5, 'line-opacity': 0.9 }
                });

                const destEl = document.createElement('div');
                destEl.innerHTML = `<div style="background:${color};color:white;font-size:10px;font-weight:700;padding:4px 10px;border-radius:10px;font-family:Poppins,sans-serif;white-space:nowrap;box-shadow:0 2px 8px rgba(0,0,0,0.2);">📍 Arrivee</div>`;
                new mapboxgl.Marker({ element: destEl, anchor: 'bottom' }).setLngLat(dest).addTo(map.current);
            }
        } catch (err) {
            console.warn('Route non calculee:', err.message);
        }
    }

    function updateMarkerEl(el, pos, color, isSelected, livreur) {
        const speed = pos.speed || 0;
        const vehicule = pos.vehicule || (livreur ? livreur.vehicule : 'moto');
        const isMoto = vehicule === 'moto' || vehicule === 'Moto';
        el.innerHTML = `
            <div style="text-align:center;pointer-events:none;">
                <div style="background:${color};color:white;font-size:9px;font-weight:700;padding:3px 8px;border-radius:10px;white-space:nowrap;font-family:Poppins,sans-serif;box-shadow:0 2px 8px rgba(0,0,0,0.2);margin-bottom:4px;">${Math.round(speed)} km/h</div>
                <div style="width:34px;height:34px;border-radius:50%;background:${color};border:3px solid white;display:flex;align-items:center;justify-content:center;box-shadow:0 3px 12px rgba(0,0,0,0.3);margin:0 auto;${isSelected ? 'outline:3px solid ' + color + ';outline-offset:3px;' : ''}">
                    <svg width="18" height="13" viewBox="0 0 20 14" fill="none">
                        ${isMoto
                            ? '<circle cx="3" cy="11" r="2.5" stroke="white" stroke-width="1.5"/><circle cx="17" cy="11" r="2.5" stroke="white" stroke-width="1.5"/><path d="M5.5 11 L7 7 L13 7 L15.5 9 L14 11" stroke="white" stroke-width="1.5" fill="none" stroke-linecap="round"/>'
                            : '<rect x="1" y="5" width="18" height="7" rx="1.5" fill="white" fill-opacity="0.9"/><path d="M3 5 L5 1.5 L15 1.5 L17 5" fill="white" fill-opacity="0.9"/><circle cx="5" cy="12" r="2" fill="' + color + '" stroke="white" stroke-width="1"/><circle cx="15" cy="12" r="2" fill="' + color + '" stroke="white" stroke-width="1"/>'
                        }
                    </svg>
                </div>
            </div>
        `;
    }

    const selectedLivreur = livreurs.find(l => l.id === selected);
    const selectedColor = selectedLivreur ? COLORS[livreurs.findIndex(l => l.id === selected) % COLORS.length] : P.primaryContainer;
    const selectedPos = selected ? positions[selected] : null;

    const cardStyle = { backgroundColor: P.surface, borderRadius: '12px', border: '1px solid ' + P.outlineVariant, padding: '14px 16px', marginBottom: '10px' };
    const labelStyle = { margin: '0 0 2px 0', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.07em' };

    return (
        <div style={{ fontFamily: 'Poppins, sans-serif', display: 'flex', height: 'calc(100vh - 56px)', backgroundColor: P.background, overflow: 'hidden' }}>

            <style>{`
                .mapboxgl-ctrl-attrib, .mapboxgl-ctrl-logo { display: none !important; }
                .mapboxgl-ctrl-group { border: 1px solid ${P.outlineVariant} !important; border-radius: 10px !important; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1) !important; }
                .mapboxgl-ctrl-geolocate { background-color: ${P.primary} !important; }
                .mapboxgl-ctrl-geolocate .mapboxgl-ctrl-icon { filter: brightness(0) invert(1); }
            `}</style>

            {/* ── PANNEAU GAUCHE ─────────────────────────────── */}
            <div style={{ width: '320px', flexShrink: 0, overflowY: 'auto', padding: '16px', borderRight: '1px solid ' + P.outlineVariant, backgroundColor: P.surface }}>

                <div style={{ marginBottom: '14px' }}>
                    <p style={{ margin: '0 0 4px 0', fontSize: '11px', color: P.outline }}>
                        <Link to="/livraisons" style={{ color: P.outline, textDecoration: 'none' }}>Livraisons</Link>
                        <span style={{ margin: '0 4px' }}>→</span>
                        <span style={{ color: P.onSurface, fontWeight: 600 }}>Tracking GPS</span>
                    </p>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#22C55E', boxShadow: '0 0 6px #22C55E' }}></div>
                        <span style={{ fontSize: '11px', fontWeight: 600, color: '#22C55E' }}>EN DIRECT — Firebase</span>
                    </div>
                </div>

                <div style={{ marginBottom: '14px' }}>
                    <p style={{ ...labelStyle, marginBottom: '8px' }}>Livreurs actifs ({Object.keys(positions).length})</p>

                    {loading && <p style={{ color: P.outline, fontSize: '12px' }}>Chargement...</p>}

                    {!loading && livreurs.length === 0 && (
                        <div style={{ padding: '20px', textAlign: 'center', backgroundColor: P.surfaceContainerLow, borderRadius: '10px' }}>
                            <p style={{ margin: 0, fontSize: '12px', color: P.outline }}>Aucune livraison en cours.</p>
                        </div>
                    )}

                    {livreurs.map((l, i) => {
                        const color = COLORS[i % COLORS.length];
                        const isSelected = selected === l.id;
                        const hasPos = !!positions[l.id];
                        return (
                            <div key={l.id} onClick={() => {
                                setSelected(l.id);
                                if (positions[l.id] && map.current) {
                                    map.current.flyTo({ center: [positions[l.id].longitude, positions[l.id].latitude], zoom: 15, duration: 600 });
                                }
                            }}
                                style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '9px 12px', borderRadius: '10px', cursor: 'pointer', marginBottom: '5px', backgroundColor: isSelected ? color + '12' : 'transparent', border: isSelected ? '1.5px solid ' + color + '40' : '1.5px solid transparent', transition: 'all 0.15s' }}>
                                <div style={{ position: 'relative' }}>
                                    <div style={{ width: '32px', height: '32px', borderRadius: '50%', backgroundColor: color, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '13px', fontWeight: 800, color: '#fff', flexShrink: 0 }}>{l.nom[0]}</div>
                                    <div style={{ position: 'absolute', bottom: 0, right: 0, width: '9px', height: '9px', borderRadius: '50%', backgroundColor: hasPos ? '#22C55E' : P.outline, border: '2px solid white' }}></div>
                                </div>
                                <div style={{ flex: 1, minWidth: 0 }}>
                                    <p style={{ margin: 0, fontSize: '12px', fontWeight: isSelected ? 700 : 500, color: P.onSurface }}>{l.nom}</p>
                                    <p style={{ margin: 0, fontSize: '10px', color: P.outline }}>{hasPos ? Math.round(positions[l.id].speed || 0) + ' km/h' : 'Position inconnue'}</p>
                                </div>
                                {hasPos && <div style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: '#22C55E', flexShrink: 0 }}></div>}
                            </div>
                        );
                    })}
                </div>

                {selectedLivreur && (
                    <>
                        <div style={cardStyle}>
                            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '10px' }}>
                                <p style={{ margin: 0, fontSize: '15px', fontWeight: 800, color: P.onSurface }}>{selectedLivreur.livraison_ref}</p>
                                <Link to={'/livraisons/' + selectedLivreur.livraison_id}
                                    style={{ padding: '5px 12px', borderRadius: '8px', backgroundColor: selectedColor, color: '#fff', fontSize: '11px', fontWeight: 600, textDecoration: 'none' }}>
                                    Voir
                                </Link>
                            </div>
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '8px', marginBottom: '12px' }}>
                                {[
                                    { label: 'Vitesse', value: selectedPos ? Math.round(selectedPos.speed || 0) + ' km/h' : '— km/h', color: '#22C55E' },
                                    { label: 'GPS', value: selectedPos ? 'Actif' : 'Inactif', color: selectedPos ? '#22C55E' : P.outline },
                                    { label: 'Montant', value: parseInt(selectedLivreur.montant).toLocaleString('fr-FR') + ' F', color: selectedColor },
                                ].map((s, i) => (
                                    <div key={i} style={{ textAlign: 'center', backgroundColor: P.surfaceContainerLow, borderRadius: '8px', padding: '8px 4px' }}>
                                        <p style={{ margin: '0 0 2px 0', fontSize: '12px', fontWeight: 700, color: s.color }}>{s.value}</p>
                                        <p style={{ margin: 0, fontSize: '8px', color: P.outline, textTransform: 'uppercase', letterSpacing: '0.05em' }}>{s.label}</p>
                                    </div>
                                ))}
                            </div>
                            <div>
                                <p style={labelStyle}>Adresse de livraison</p>
                                <p style={{ margin: 0, fontSize: '12px', color: P.onSurface }}>{selectedLivreur.adresse}</p>
                            </div>
                        </div>

                        <div style={{ ...cardStyle, display: 'flex', alignItems: 'center', gap: '10px' }}>
                            <div style={{ width: '34px', height: '34px', borderRadius: '50%', backgroundColor: P.inverseS, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '13px', fontWeight: 800, color: '#fff', flexShrink: 0 }}>{selectedLivreur.client[0]}</div>
                            <div style={{ flex: 1 }}>
                                <p style={{ margin: 0, fontSize: '12px', fontWeight: 700, color: P.onSurface }}>{selectedLivreur.client}</p>
                                <p style={{ margin: 0, fontSize: '10px', color: P.outline }}>{selectedLivreur.client_phone}</p>
                            </div>
                        </div>

                        {selectedPos && (
                            <div style={{ ...cardStyle, backgroundColor: P.surfaceContainerLow }}>
                                <p style={labelStyle}>Position GPS actuelle</p>
                                <p style={{ margin: '4px 0 0', fontSize: '11px', color: P.onSurface, fontFamily: 'monospace' }}>
                                    {selectedPos.latitude.toFixed(6)}, {selectedPos.longitude.toFixed(6)}
                                </p>
                                <p style={{ margin: '4px 0 0', fontSize: '10px', color: P.outline }}>
                                    Derniere MAJ : {selectedPos.timestamp ? new Date(selectedPos.timestamp).toLocaleTimeString('fr-FR') : '—'}
                                </p>
                            </div>
                        )}
                    </>
                )}
            </div>

            {/* ── CARTE ─────────────────────────────────────── */}
            <div style={{ flex: 1, position: 'relative' }}>
                <div ref={mapContainer} style={{ width: '100%', height: '100%' }} />

                {Object.keys(positions).length === 0 && !loading && (
                    <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%,-50%)', backgroundColor: 'rgba(255,255,255,0.95)', borderRadius: '14px', padding: '20px 28px', textAlign: 'center', boxShadow: '0 4px 20px rgba(0,0,0,0.1)', border: '1px solid ' + P.outlineVariant }}>
                        <p style={{ margin: '0 0 6px', fontSize: '14px', fontWeight: 700, color: P.onSurface }}>Aucun livreur en mouvement</p>
                        <p style={{ margin: 0, fontSize: '12px', color: P.outline }}>Les positions GPS apparaitront ici en temps reel des que les livreurs seront en cours de livraison.</p>
                    </div>
                )}
            </div>
        </div>
    );
}