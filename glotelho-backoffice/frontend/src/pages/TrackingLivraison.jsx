import { useState, useEffect, useRef } from 'react';
import { useParams, Link } from 'react-router-dom';
import mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';
import { database, ref, onValue, off } from '../config/firebase';
import api from '../services/api';

mapboxgl.accessToken = "";
//pk.eyJ1IjoiYW1hbmRpbmVraWx5IiwiYSI6ImNtcjRyZzd2NzBjc3UzMHIwdHkxZmdnZWIifQ.CrM5ELxBNEXlP4rQzxsxow
const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    primaryFixed: '#ffdea9', onPrimaryContainer: '#483100',
    surface: '#ffffff', surfaceContainerLow: '#f3f3f3', surfaceContainerHigh: '#e8e8e8',
    inverseS: '#2f3131', inverseSOn: '#f1f1f1',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
    error: '#ba1a1a', errorContainer: '#ffdad6',
};

const STATUS_CONFIG = {
    'En_attente': { label: 'En attente', color: P.primaryContainer, bg: P.primaryFixed },
    'Assign_':    { label: 'Assigne',    color: '#475e8b',           bg: '#b5ccff' },
    'En_cours':   { label: 'En cours',   color: '#20619e',           bg: '#6aa1e3' },
    'Livr_':      { label: 'Livre',      color: '#1b5e20',           bg: '#c8e6c9' },
    'Suspendu':   { label: 'Suspendu',   color: P.error,             bg: P.errorContainer },
    'Annul_':     { label: 'Annule',     color: P.outline,           bg: P.surfaceContainerHigh },
};

function Field({ label, value }) {
    return (
        <div>
            <p style={{ margin: '0 0 2px', fontSize: '9px', fontWeight: 700, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em' }}>{label}</p>
            <p style={{ margin: 0, fontSize: '12px', color: P.onSurface, fontWeight: 500 }}>{value || <span style={{ color: P.outlineVariant, fontStyle: 'italic' }}>—</span>}</p>
        </div>
    );
}

export default function TrackingLivraison() {
    const { id } = useParams();
    const mapContainer = useRef(null);
    const map          = useRef(null);
    const markerRef    = useRef(null);
    const routeRef     = useRef(null);

    const [livraison, setLivraison] = useState(null);
    const [position,  setPosition]  = useState(null);
    const [loading,   setLoading]   = useState(true);
    const [error,     setError]     = useState('');
    const [mapLoaded, setMapLoaded] = useState(false);

    // Charger infos livraison
    useEffect(function() {
        api.get('/livraisons/' + id)
            .then(function(res) { setLivraison(res.data); })
            .catch(function() { setError('Livraison introuvable.'); })
            .finally(function() { setLoading(false); });
    }, [id]);

    // Firebase — ecouter position livreur
    useEffect(function() {
        if (!livraison || !livraison.delivery_person_id) return;
        var posRef = ref(database, 'positions/' + livraison.delivery_person_id);
        onValue(posRef, function(snapshot) {
            var data = snapshot.val();
            if (data) setPosition(data);
        });
        return function() { off(posRef); };
    }, [livraison]);

    // Init carte
    useEffect(function() {
        if (loading || error || map.current) return;
        var timer = setTimeout(function() {
            if (!mapContainer.current) return;
            map.current = new mapboxgl.Map({
                container: mapContainer.current,
                style    : 'mapbox://styles/mapbox/streets-v12',
                center   : [9.7400, 4.0580],
                zoom     : 13,
            });
            map.current.addControl(new mapboxgl.NavigationControl({ showCompass: false }), 'bottom-right');
            map.current.addControl(new mapboxgl.GeolocateControl({ positionOptions: { enableHighAccuracy: true }, trackUserLocation: false }), 'bottom-right');
            map.current.on('load', function() { setMapLoaded(true); });
        }, 150);
        return function() {
            clearTimeout(timer);
            if (map.current) { map.current.remove(); map.current = null; }
        };
    }, [loading, error]);

    // Mettre a jour marqueur livreur
    useEffect(function() {
        if (!mapLoaded || !map.current || !position) return;
        var coords = [position.longitude, position.latitude];

        if (markerRef.current) {
            markerRef.current.setLngLat(coords);
        } else {
            var el = document.createElement('div');
            el.innerHTML = '<div style="text-align:center;">' +
                '<div style="background:#c9952e;color:white;font-size:9px;font-weight:700;padding:3px 8px;border-radius:10px;margin-bottom:4px;white-space:nowrap;box-shadow:0 2px 8px rgba(0,0,0,0.3);">' +
                (livraison && livraison.delivery_persons && livraison.delivery_persons.users
                    ? livraison.delivery_persons.users.first_name
                    : 'Livreur') + ' • ' + Math.round(position.speed || 0) + ' km/h</div>' +
                '<div style="width:40px;height:40px;border-radius:50%;background:linear-gradient(135deg,#c9952e,#7d5700);border:3px solid white;display:flex;align-items:center;justify-content:center;box-shadow:0 4px 14px rgba(0,0,0,0.3);margin:0 auto;font-size:20px;">🛵</div>' +
                '</div>';
            markerRef.current = new mapboxgl.Marker({ element: el, anchor: 'bottom' })
                .setLngLat(coords)
                .addTo(map.current);
        }

        map.current.flyTo({ center: coords, zoom: 15, duration: 800 });

        // Tracer route vers destination si adresse dispo
        if (livraison && livraison.delivery_address && mapLoaded) {
            drawRoute(coords, livraison.delivery_address);
        }
    }, [position, mapLoaded]);

    async function drawRoute(origin, destinationText) {
        try {
            var geoRes = await fetch('https://api.mapbox.com/geocoding/v5/mapbox.places/' +
                encodeURIComponent(destinationText + ', Douala, Cameroun') +
                '.json?access_token=' + mapboxgl.accessToken + '&limit=1');
            var geoData = await geoRes.json();
            if (!geoData.features || geoData.features.length === 0) return;

            var dest = geoData.features[0].center;

            // Marqueur destination
            if (!routeRef.current) {
                routeRef.current = new mapboxgl.Marker({ color: '#ba1a1a' })
                    .setLngLat(dest)
                    .setPopup(new mapboxgl.Popup().setText(destinationText))
                    .addTo(map.current);
            }

            // Tracer route
            var routeRes = await fetch(
                'https://api.mapbox.com/directions/v5/mapbox/driving/' +
                origin[0] + ',' + origin[1] + ';' + dest[0] + ',' + dest[1] +
                '?geometries=geojson&access_token=' + mapboxgl.accessToken
            );
            var routeData = await routeRes.json();
            if (!routeData.routes || routeData.routes.length === 0) return;

            var geojson = { type: 'Feature', geometry: routeData.routes[0].geometry };

            if (map.current.getSource('route')) {
                map.current.getSource('route').setData(geojson);
            } else {
                map.current.addSource('route', { type: 'geojson', data: geojson });
                map.current.addLayer({
                    id: 'route', type: 'line', source: 'route',
                    layout: { 'line-join': 'round', 'line-cap': 'round' },
                    paint: { 'line-color': '#c9952e', 'line-width': 4, 'line-opacity': 0.8, 'line-dasharray': [2, 1] }
                });
            }
        } catch (e) {}
    }

    if (loading) return (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '60vh', fontFamily: 'Poppins, sans-serif' }}>
            <p style={{ color: P.outline }}>Chargement...</p>
        </div>
    );

    if (error) return (
        <div style={{ fontFamily: 'Poppins, sans-serif', textAlign: 'center', marginTop: '60px' }}>
            <p style={{ color: P.error }}>{error}</p>
            <Link to="/livraisons" style={{ color: P.primary }}>Retour aux livraisons</Link>
        </div>
    );

    var sc       = STATUS_CONFIG[livraison && livraison.status] || STATUS_CONFIG['En_attente'];
    var livreurNom = livraison && livraison.delivery_persons && livraison.delivery_persons.users
        ? livraison.delivery_persons.users.first_name + ' ' + livraison.delivery_persons.users.last_name
        : null;
    var vehicule = livraison && livraison.delivery_persons && livraison.delivery_persons.vehicules
        ? livraison.delivery_persons.vehicules.type + ' — ' + livraison.delivery_persons.vehicules.plate_number
        : null;
    var clientNom = livraison && (livraison.client_nom || ((livraison.customers && livraison.customers.users)
        ? livraison.customers.users.first_name + ' ' + livraison.customers.users.last_name : '—'));
    var otp = livraison && livraison.confirmations && livraison.confirmations.length > 0
        ? livraison.confirmations[0].otp_code : null;
    var numFormate = livraison ? '#' + String(livraison.id).padStart(5,'0') : '';

    return (
        <div style={{ fontFamily: 'Poppins, sans-serif', height: 'calc(100vh - 60px)', display: 'flex', flexDirection: 'column' }}>
            <style>{'.mapboxgl-ctrl-attrib,.mapboxgl-ctrl-logo{display:none!important}'}</style>

            {/* Header */}
            <div style={{ padding: '10px 0', marginBottom: '12px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexShrink: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <Link to={'/livraisons/' + id}
                        style={{ padding: '7px 12px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, textDecoration: 'none', fontSize: '12px', fontWeight: 500 }}>
                        ← Retour
                    </Link>
                    <div>
                        <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>Tracking GPS</p>
                        <p style={{ margin: 0, fontSize: '18px', fontWeight: 800, color: P.primary }}>Livraison {numFormate}</p>
                    </div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    {position && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '5px 12px', backgroundColor: '#f0fdf4', borderRadius: '20px', border: '1px solid #a5d6a7' }}>
                            <div style={{ width: '7px', height: '7px', borderRadius: '50%', backgroundColor: '#22C55E', boxShadow: '0 0 6px #22C55E' }}></div>
                            <span style={{ fontSize: '11px', color: '#1b5e20', fontWeight: 600 }}>GPS actif — {Math.round(position.speed || 0)} km/h</span>
                        </div>
                    )}
                    <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '5px 12px', borderRadius: '20px', fontSize: '11px', fontWeight: 700 }}>
                        {sc.label}
                    </span>
                </div>
            </div>

            {/* Body — carte + panneau */}
            <div style={{ flex: 1, display: 'flex', gap: '14px', overflow: 'hidden', minHeight: 0 }}>

                {/* PANNEAU GAUCHE */}
                <div style={{ width: '300px', flexShrink: 0, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '12px' }}>

                    {/* Livreur */}
                    <div style={{ backgroundColor: P.surface, borderRadius: '12px', border: '1px solid ' + P.outlineVariant, padding: '14px' }}>
                        <p style={{ margin: '0 0 10px', fontSize: '10px', fontWeight: 700, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Livreur</p>
                        {livreurNom ? (
                            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                {/* Photo livreur */}
                                <div style={{ width: '52px', height: '52px', borderRadius: '50%', overflow: 'hidden', flexShrink: 0, border: '2px solid ' + P.primaryContainer, backgroundColor: P.surfaceContainerLow }}>
                                    {livraison.delivery_persons && (livraison.delivery_persons.photo_profil || livraison.delivery_persons.photo_profil_url)
                                        ? <img src={livraison.delivery_persons.photo_profil || livraison.delivery_persons.photo_profil_url} alt="livreur" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                                        : <div style={{ width: '100%', height: '100%', background: 'linear-gradient(135deg,#c9952e,#7d5700)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '20px' }}>🛵</div>
                                    }
                                </div>
                                <div style={{ flex: 1, minWidth: 0 }}>
                                    <p style={{ margin: 0, fontSize: '13px', fontWeight: 700, color: P.onSurface }}>{livreurNom}</p>
                                    <p style={{ margin: '2px 0 0', fontSize: '11px', color: P.outline }}>{vehicule || '—'}</p>
                                    {livraison.delivery_persons && livraison.delivery_persons.users && livraison.delivery_persons.users.phone && (
                                        <p style={{ margin: '2px 0 0', fontSize: '11px', color: P.outline }}>📞 {livraison.delivery_persons.users.phone}</p>
                                    )}
                                    {position && <p style={{ margin: '3px 0 0', fontSize: '11px', color: P.primaryContainer, fontWeight: 600 }}>📍 {position.latitude?.toFixed(4)}, {position.longitude?.toFixed(4)}</p>}
                                </div>
                            </div>
                        ) : <p style={{ margin: 0, fontSize: '12px', color: P.outline, fontStyle: 'italic' }}>Aucun livreur assigné</p>}
                    </div>

                    {/* Client */}
                    <div style={{ backgroundColor: P.surface, borderRadius: '12px', border: '1px solid ' + P.outlineVariant, padding: '14px' }}>
                        <p style={{ margin: '0 0 10px', fontSize: '10px', fontWeight: 700, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Client</p>
                        <div style={{ display: 'grid', gap: '8px' }}>
                            <Field label="Nom" value={clientNom} />
                            <Field label="Téléphone" value={livraison && (livraison.client_telephone || (livraison.customers && livraison.customers.users && livraison.customers.users.phone))} />
                            <Field label="Adresse" value={livraison && livraison.delivery_address} />
                            {livraison && livraison.zone_bloc && <Field label="Repère" value={livraison.zone_bloc} />}
                        </div>
                    </div>

                    {/* OTP */}
                    {otp && (
                        <div style={{ backgroundColor: P.inverseS, borderRadius: '12px', padding: '14px', textAlign: 'center' }}>
                            <p style={{ margin: '0 0 6px', fontSize: '10px', fontWeight: 700, color: 'rgba(241,241,241,0.4)', textTransform: 'uppercase', letterSpacing: '0.1em' }}>Code OTP</p>
                            <p style={{ margin: '0 0 6px', fontSize: '32px', fontWeight: 900, color: P.primaryContainer, letterSpacing: '0.2em', fontFamily: 'monospace' }}>{otp}</p>
                            <p style={{ margin: 0, fontSize: '10px', color: 'rgba(241,241,241,0.3)' }}>A donner au client à la livraison</p>
                        </div>
                    )}

                    {/* Articles */}
                    {livraison && livraison.delivery_items && livraison.delivery_items.length > 0 && (
                        <div style={{ backgroundColor: P.surface, borderRadius: '12px', border: '1px solid ' + P.outlineVariant, padding: '14px' }}>
                            <p style={{ margin: '0 0 10px', fontSize: '10px', fontWeight: 700, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Articles ({livraison.delivery_items.length})</p>
                            <div style={{ display: 'grid', gap: '6px' }}>
                                {livraison.delivery_items.map(function(item, i) {
                                    return (
                                        <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '6px 10px', backgroundColor: P.surfaceContainerLow, borderRadius: '8px' }}>
                                            <span style={{ fontSize: '12px', color: P.onSurface }}>{item.product_name} x{item.quantity || 1}</span>
                                            <span style={{ fontSize: '11px', fontWeight: 600, color: P.primary }}>
                                                {item.unit_price ? (Number(item.unit_price) * (item.quantity || 1)).toLocaleString('fr-FR') + ' F' : ''}
                                            </span>
                                        </div>
                                    );
                                })}
                            </div>
                            <div style={{ marginTop: '10px', paddingTop: '10px', borderTop: '1px solid ' + P.outlineVariant, display: 'flex', justifyContent: 'space-between' }}>
                                <span style={{ fontSize: '12px', fontWeight: 700, color: P.onSurface }}>Total</span>
                                <span style={{ fontSize: '14px', fontWeight: 800, color: P.primary }}>
                                    {livraison.amount_to_collect ? Number(livraison.amount_to_collect).toLocaleString('fr-FR') + ' FCFA' : '—'}
                                </span>
                            </div>
                        </div>
                    )}

                    {/* Derniere position */}
                    {position && (
                        <div style={{ backgroundColor: P.surfaceContainerLow, borderRadius: '10px', padding: '10px 14px', textAlign: 'center' }}>
                            <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>
                                Dernière mise à jour : {new Date(position.timestamp).toLocaleTimeString('fr-FR')}
                            </p>
                        </div>
                    )}

                    {/* Pas de GPS */}
                    {!position && livraison && livraison.status === 'En_cours' && (
                        <div style={{ backgroundColor: P.primaryFixed, borderRadius: '10px', padding: '12px', textAlign: 'center' }}>
                            <p style={{ margin: 0, fontSize: '12px', color: P.onPrimaryContainer, fontWeight: 600 }}>📡 En attente de la position GPS...</p>
                        </div>
                    )}
                </div>

                {/* CARTE */}
                <div style={{ flex: 1, borderRadius: '14px', overflow: 'hidden', border: '1px solid ' + P.outlineVariant, position: 'relative' }}>
                    <div ref={mapContainer} style={{ width: '100%', height: '100%' }} />
                    {livraison && livraison.status !== 'En_cours' && (
                        <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%,-50%)', backgroundColor: 'rgba(255,255,255,0.95)', borderRadius: '14px', padding: '20px 28px', textAlign: 'center', boxShadow: '0 4px 20px rgba(0,0,0,0.1)' }}>
                            <p style={{ margin: '0 0 6px', fontSize: '24px' }}>
                                {livraison.status === 'Livr_' ? '✅' : livraison.status === 'Annul_' ? '❌' : '⏳'}
                            </p>
                            <p style={{ margin: 0, fontSize: '13px', fontWeight: 700, color: P.onSurface }}>
                                {livraison.status === 'Livr_' ? 'Livraison terminée' : livraison.status === 'Annul_' ? 'Livraison annulée' : 'GPS non actif — livraison ' + sc.label}
                            </p>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}