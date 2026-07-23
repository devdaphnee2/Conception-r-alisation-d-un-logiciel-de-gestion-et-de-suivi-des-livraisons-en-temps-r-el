import { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';
import { database, ref, onValue, off } from '../config/firebase';

mapboxgl.accessToken = 'import.meta.env.VITE_MAPBOX_TOKEN';
//import.meta.env.VITE_MAPBOX_TOKEN
//pk.eyJ1IjoiYW1hbmRpbmVraWx5IiwiYSI6ImNtcjRyZzd2NzBjc3UzMHIwdHkxZmdnZWIifQ.CrM5ELxBNEXlP4rQzxsxow
const STATUS_INFO = {
    'En_attente': { label: 'En attente de livreur', color: '#c9952e', bg: '#ffdea9', icon: '⏳' },
    'Assign_':    { label: 'Livreur assigné',        color: '#475e8b', bg: '#b5ccff', icon: '🛵' },
    'En_cours':   { label: 'En cours de livraison',  color: '#1b5e20', bg: '#c8e6c9', icon: '📍' },
    'Livr_':      { label: 'Livraison effectuée',    color: '#1b5e20', bg: '#c8e6c9', icon: '✅' },
    'Annul_':     { label: 'Livraison annulée',      color: '#ba1a1a', bg: '#ffdad6', icon: '❌' },
    'Suspendu':   { label: 'Livraison suspendue',    color: '#ba1a1a', bg: '#ffdad6', icon: '⚠️' },
};

export default function TrackingCommercant() {
    const { id } = useParams();
    const navigate = useNavigate();
    const mapContainer = useRef(null);
    const map = useRef(null);
    const markerRef = useRef(null);

    const [livraison, setLivraison] = useState(null);
    const [position, setPosition]   = useState(null);
    const [loading, setLoading]     = useState(true);
    const [error, setError]         = useState('');
    const [mapReady, setMapReady]   = useState(false);
    const [panelOpen, setPanelOpen] = useState(false);

    // Charger la livraison
    useEffect(function() {
        var apiUrl = (import.meta.env.VITE_API_URL || 'http://192.168.1.145:5000/api') + '/livraisons/public/' + id;
        fetch(apiUrl)
            .then(function(r) { return r.json(); })
            .then(function(data) {
                if (data.message && !data.id) setError(data.message);
                else setLivraison(data);
            })
            .catch(function() { setError('Impossible de charger les informations.'); })
            .finally(function() { setLoading(false); });
    }, [id]);

    // Écouter Firebase
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
        if (loading || error) return;
        if (map.current) return;
        var timer = setTimeout(function() {
            if (!mapContainer.current) return;
            map.current = new mapboxgl.Map({
                container: mapContainer.current,
                style: 'mapbox://styles/mapbox/streets-v12',
                center: [9.7400, 4.0580],
                zoom: 13,
            });
            map.current.addControl(new mapboxgl.NavigationControl({ showCompass: false }), 'bottom-right');
            map.current.on('load', function() { setMapReady(true); });
        }, 150);
        return function() {
            clearTimeout(timer);
            if (map.current) { map.current.remove(); map.current = null; }
        };
    }, [loading, error]);

    // Mettre à jour marqueur
    useEffect(function() {
        if (!mapReady || !map.current || !position) return;
        var coords = [position.longitude, position.latitude];
        if (markerRef.current) {
            markerRef.current.setLngLat(coords);
        } else {
            var el = document.createElement('div');
            el.innerHTML = '<div style="text-align:center;">' +
                '<div style="background:#c9952e;color:white;font-size:9px;font-weight:700;padding:3px 8px;border-radius:10px;margin-bottom:4px;white-space:nowrap;box-shadow:0 2px 8px rgba(0,0,0,0.25);">' +
                Math.round(position.speed || 0) + ' km/h</div>' +
                '<div style="width:40px;height:40px;border-radius:50%;background:linear-gradient(135deg,#c9952e,#7d5700);border:3px solid white;display:flex;align-items:center;justify-content:center;box-shadow:0 4px 14px rgba(0,0,0,0.3);margin:0 auto;font-size:20px;">🛵</div>' +
                '</div>';
            markerRef.current = new mapboxgl.Marker({ element: el, anchor: 'bottom' }).setLngLat(coords).addTo(map.current);
        }
        map.current.flyTo({ center: coords, zoom: 15, duration: 800 });
    }, [position, mapReady]);

    var statusInfo = livraison ? (STATUS_INFO[livraison.status] || STATUS_INFO['En_attente']) : null;
    var numFormate = String(id).padStart(5, '0');
    var livreurNom = livraison?.delivery_persons?.users
        ? livraison.delivery_persons.users.first_name + ' ' + livraison.delivery_persons.users.last_name
        : '—';
    var vehiculeInfo = livraison?.delivery_persons?.vehicules
        ? livraison.delivery_persons.vehicules.brand + ' ' + livraison.delivery_persons.vehicules.type + ' • ' + livraison.delivery_persons.vehicules.plate_number
        : '';

    if (loading) return (
        <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'linear-gradient(135deg, #2f3131, #1a1c1c)', fontFamily: 'Poppins, sans-serif' }}>
            <div style={{ textAlign: 'center' }}>
                <p style={{ fontSize: '48px', margin: '0 0 16px' }}>⏳</p>
                <p style={{ color: 'rgba(255,255,255,0.5)', fontSize: '14px', margin: 0 }}>Chargement...</p>
            </div>
        </div>
    );

    if (error) return (
        <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Poppins, sans-serif', backgroundColor: '#f5f5f5' }}>
            <div style={{ textAlign: 'center', backgroundColor: '#fff', borderRadius: '20px', padding: '40px 32px', boxShadow: '0 8px 32px rgba(0,0,0,0.1)', maxWidth: '400px' }}>
                <p style={{ fontSize: '52px', margin: '0 0 16px' }}>🔍</p>
                <p style={{ fontSize: '20px', fontWeight: 800, color: '#1a1c1c', margin: '0 0 10px' }}>Livraison introuvable</p>
                <p style={{ fontSize: '14px', color: '#817564', margin: '0 0 28px' }}>Le numéro #{numFormate} ne correspond à aucune livraison.</p>
                <button onClick={() => navigate(-1)} style={{ width: '100%', padding: '16px', borderRadius: '12px', border: 'none', background: 'linear-gradient(135deg, #7d5700, #c9952e)', color: '#fff', fontSize: '15px', fontWeight: 700, cursor: 'pointer' }}>
                    Retour
                </button>
            </div>
        </div>
    );

    return (
        <div style={{ width: '100vw', height: '100vh', fontFamily: 'Poppins, sans-serif', position: 'relative', overflow: 'hidden' }}>
            <style>{`.mapboxgl-ctrl-attrib,.mapboxgl-ctrl-logo{display:none!important} * { box-sizing:border-box; } body { margin:0; }`}</style>

            {/* Carte plein écran */}
            <div ref={mapContainer} style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }} />

            {/* Header */}
            <div style={{ position: 'absolute', top: 0, left: 0, right: 0, zIndex: 10, background: 'linear-gradient(180deg, rgba(47,49,49,0.95) 0%, rgba(47,49,49,0.0) 100%)', padding: '14px 16px 40px' }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <button onClick={() => navigate(-1)} style={{ background: 'rgba(255,255,255,0.15)', backdropFilter: 'blur(8px)', border: 'none', color: '#fff', cursor: 'pointer', fontSize: '16px', padding: '8px 12px', borderRadius: '10px' }}>←</button>
                        <div>
                            <p style={{ margin: 0, fontSize: '9px', color: 'rgba(255,255,255,0.5)', textTransform: 'uppercase', letterSpacing: '0.12em' }}>Livraison</p>
                            <p style={{ margin: 0, fontSize: '20px', fontWeight: 900, color: '#c9952e', letterSpacing: '0.08em', fontFamily: 'monospace' }}>#{numFormate}</p>
                        </div>
                    </div>
                    {statusInfo && (
                        <span style={{ backgroundColor: statusInfo.bg, color: statusInfo.color, padding: '7px 14px', borderRadius: '20px', fontSize: '11px', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '5px' }}>
                            {statusInfo.icon} {statusInfo.label}
                        </span>
                    )}
                </div>
            </div>

            {/* Badge GPS */}
            {!position && livraison && ['En_cours', 'Assign_'].includes(livraison.status) && (
                <div style={{ position: 'absolute', top: '80px', left: '50%', transform: 'translateX(-50%)', zIndex: 10, backgroundColor: 'rgba(255,255,255,0.95)', borderRadius: '20px', padding: '8px 18px', display: 'flex', alignItems: 'center', gap: '8px', whiteSpace: 'nowrap' }}>
                    <span>📡</span>
                    <p style={{ margin: 0, fontSize: '12px', color: '#817564', fontWeight: 600 }}>En attente de la position GPS...</p>
                </div>
            )}

            {position && (
                <div style={{ position: 'absolute', top: '80px', left: '50%', transform: 'translateX(-50%)', zIndex: 10, backgroundColor: 'rgba(47,49,49,0.9)', borderRadius: '20px', padding: '7px 16px', display: 'flex', alignItems: 'center', gap: '10px', whiteSpace: 'nowrap' }}>
                    <div style={{ width: '7px', height: '7px', borderRadius: '50%', backgroundColor: '#22C55E', boxShadow: '0 0 6px #22C55E' }}></div>
                    <p style={{ margin: 0, fontSize: '12px', color: '#fff', fontWeight: 600 }}>
                        En direct • {Math.round(position.speed || 0)} km/h • {new Date(position.timestamp).toLocaleTimeString('fr-FR')}
                    </p>
                </div>
            )}

            {/* Panneau bas */}
            <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, zIndex: 10 }}>
                <div onClick={() => setPanelOpen(!panelOpen)} style={{ display: 'flex', justifyContent: 'center', padding: '10px', cursor: 'pointer' }}>
                    <div style={{ width: '40px', height: '4px', borderRadius: '2px', backgroundColor: 'rgba(255,255,255,0.4)' }}></div>
                </div>

                <div style={{ backgroundColor: 'rgba(255,255,255,0.97)', backdropFilter: 'blur(20px)', borderRadius: '24px 24px 0 0', padding: '0 16px 24px', boxShadow: '0 -8px 40px rgba(0,0,0,0.2)', maxHeight: panelOpen ? '70vh' : '180px', overflow: 'hidden', transition: 'max-height 0.35s ease' }}>

                    {/* Livreur */}
                    {livraison && livraison.delivery_persons && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: '14px', padding: '16px 0 12px', borderBottom: panelOpen ? '1px solid #f3f3f3' : 'none' }}>
                            <div style={{ width: '50px', height: '50px', borderRadius: '50%', background: 'linear-gradient(135deg, #c9952e, #7d5700)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '22px', flexShrink: 0 }}>🛵</div>
                            <div style={{ flex: 1 }}>
                                <p style={{ margin: '0 0 2px', fontSize: '10px', fontWeight: 700, color: '#c9952e', textTransform: 'uppercase' }}>Votre livreur</p>
                                <p style={{ margin: '0 0 2px', fontSize: '16px', fontWeight: 800, color: '#1a1c1c' }}>{livreurNom}</p>
                                <p style={{ margin: 0, fontSize: '11px', color: '#817564' }}>{vehiculeInfo}</p>
                            </div>
                            <p style={{ margin: 0, fontSize: '11px', color: '#817564' }}>{panelOpen ? '▲ Réduire' : '▼ Voir plus'}</p>
                        </div>
                    )}

                    {/* Contenu étendu */}
                    {panelOpen && (
                        <div style={{ paddingTop: '12px' }}>
                            {/* Infos client */}
                            <div style={{ display: 'flex', alignItems: 'flex-start', gap: '12px', padding: '12px 0', borderBottom: '1px solid #f3f3f3' }}>
                                <div style={{ width: '36px', height: '36px', borderRadius: '10px', backgroundColor: '#ffdea9', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '18px', flexShrink: 0 }}>👤</div>
                                <div>
                                    <p style={{ margin: '0 0 3px', fontSize: '10px', fontWeight: 700, color: '#817564', textTransform: 'uppercase' }}>Client</p>
                                    <p style={{ margin: '0 0 2px', fontSize: '14px', fontWeight: 700, color: '#1a1c1c' }}>{livraison?.client_nom || '—'}</p>
                                    <p style={{ margin: 0, fontSize: '12px', color: '#817564' }}>{livraison?.client_telephone || ''}</p>
                                </div>
                            </div>

                            {/* Adresse */}
                            <div style={{ display: 'flex', alignItems: 'flex-start', gap: '12px', padding: '12px 0' }}>
                                <div style={{ width: '36px', height: '36px', borderRadius: '10px', backgroundColor: '#ffdea9', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '18px', flexShrink: 0 }}>📍</div>
                                <div>
                                    <p style={{ margin: '0 0 3px', fontSize: '10px', fontWeight: 700, color: '#817564', textTransform: 'uppercase' }}>Adresse de livraison</p>
                                    <p style={{ margin: '0 0 2px', fontSize: '14px', fontWeight: 700, color: '#1a1c1c' }}>{livraison?.delivery_address || '—'}</p>
                                    {livraison?.zone_bloc && <p style={{ margin: 0, fontSize: '12px', color: '#817564' }}>{livraison.zone_bloc}</p>}
                                </div>
                            </div>

                            {/* Livraison terminée */}
                            {livraison?.status === 'Livr_' && (
                                <div style={{ backgroundColor: '#f0fdf4', borderRadius: '16px', padding: '24px', textAlign: 'center', border: '2px solid #a5d6a7', margin: '14px 0' }}>
                                    <p style={{ margin: '0 0 8px', fontSize: '44px' }}>✅</p>
                                    <p style={{ margin: '0 0 4px', fontSize: '18px', fontWeight: 900, color: '#1b5e20' }}>Livraison confirmée !</p>
                                    <p style={{ margin: 0, fontSize: '13px', color: '#4caf50' }}>Le colis a bien été remis au client.</p>
                                </div>
                            )}

                            <p style={{ textAlign: 'center', fontSize: '11px', color: '#d3c4b0', marginTop: '12px' }}>Glotelho E-commerce — Douala, Cameroun</p>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}