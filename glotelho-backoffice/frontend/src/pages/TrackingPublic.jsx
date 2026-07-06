import { useState, useEffect, useRef } from 'react';
import { useParams } from 'react-router-dom';
import mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';
import { database, ref, onValue, off } from '../config/firebase';

mapboxgl.accessToken = 'import.meta.env.VITE_MAPBOX_TOKEN';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    primaryFixed: '#ffdea9', onPrimaryContainer: '#483100',
    error: '#ba1a1a', errorContainer: '#ffdad6',
    surface: '#ffffff', background: '#f5f5f5',
    surfaceContainerLow: '#f3f3f3',
    onSurface: '#1a1c1c',
    outline: '#817564', outlineVariant: '#d3c4b0',
};

const STATUS_LABELS = {
    'En_attente': { label: 'En attente de livreur', color: P.primaryContainer, bg: P.primaryFixed },
    'Assign_':    { label: 'Livreur assigne — depart imminent', color: '#475e8b', bg: '#b5ccff' },
    'En_cours':   { label: 'En cours de livraison', color: '#1b5e20', bg: '#c8e6c9' },
    'Livr_':      { label: 'Livraison effectuee', color: '#1b5e20', bg: '#c8e6c9' },
    'Annul_':     { label: 'Livraison annulee', color: P.error, bg: P.errorContainer },
};

export default function TrackingPublic() {
    const { id } = useParams();
    const mapContainer = useRef(null);
    const map = useRef(null);
    const markerRef = useRef(null);

    const [livraison, setLivraison] = useState(null);
    const [position, setPosition] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [mapLoaded, setMapLoaded] = useState(false);

    // Charger infos livraison depuis API publique
    useEffect(() => {
        fetch((import.meta.env.VITE_API_URL || 'http://localhost:5000/api') + '/livraisons/public/' + id)
            .then(r => r.json())
            .then(data => {
                if (data.message) setError(data.message);
                else setLivraison(data);
            })
            .catch(() => setError('Impossible de charger les informations de livraison.'))
            .finally(() => setLoading(false));
    }, [id]);

    // Écouter position Firebase du livreur
    useEffect(() => {
        if (!livraison?.delivery_person_id) return;
        const posRef = ref(database, 'positions/' + livraison.delivery_person_id);
        onValue(posRef, snapshot => {
            const data = snapshot.val();
            if (data) setPosition(data);
        });
        return () => off(posRef);
    }, [livraison?.delivery_person_id]);

    // Init carte
    useEffect(() => {
        if (map.current) return;
        map.current = new mapboxgl.Map({
            container: mapContainer.current,
            style: 'mapbox://styles/mapbox/streets-v12',
            center: [9.7400, 4.0580],
            zoom: 13,
        });
        map.current.addControl(new mapboxgl.NavigationControl({ showCompass: false }), 'bottom-right');
        map.current.on('load', () => setMapLoaded(true));
        return () => { if (map.current) { map.current.remove(); map.current = null; } };
    }, []);

    // Mettre a jour marqueur livreur
    useEffect(() => {
        if (!mapLoaded || !map.current || !position) return;
        const coords = [position.longitude, position.latitude];

        if (markerRef.current) {
            markerRef.current.setLngLat(coords);
        } else {
            const el = document.createElement('div');
            el.innerHTML = `
                <div style="text-align:center;">
                    <div style="background:#c9952e;color:white;font-size:9px;font-weight:700;padding:3px 8px;border-radius:10px;font-family:Poppins,sans-serif;margin-bottom:4px;box-shadow:0 2px 8px rgba(0,0,0,0.2);">
                        ${Math.round(position.speed || 0)} km/h
                    </div>
                    <div style="width:36px;height:36px;border-radius:50%;background:#c9952e;border:3px solid white;display:flex;align-items:center;justify-content:center;box-shadow:0 3px 12px rgba(0,0,0,0.3);margin:0 auto;">
                        <svg width="18" height="13" viewBox="0 0 20 14" fill="none">
                            <circle cx="3" cy="11" r="2.5" stroke="white" stroke-width="1.5"/>
                            <circle cx="17" cy="11" r="2.5" stroke="white" stroke-width="1.5"/>
                            <path d="M5.5 11 L7 7 L13 7 L15.5 9 L14 11" stroke="white" stroke-width="1.5" fill="none" stroke-linecap="round"/>
                        </svg>
                    </div>
                </div>
            `;
            markerRef.current = new mapboxgl.Marker({ element: el, anchor: 'bottom' })
                .setLngLat(coords)
                .addTo(map.current);
        }

        map.current.flyTo({ center: coords, zoom: 15, duration: 600 });
    }, [position, mapLoaded]);

    const statusInfo = livraison ? (STATUS_LABELS[livraison.status] || STATUS_LABELS['En_attente']) : null;

    if (loading) return (
        <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Poppins, sans-serif' }}>
            <p style={{ color: P.outline }}>Chargement...</p>
        </div>
    );

    if (error) return (
        <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Poppins, sans-serif', padding: '20px' }}>
            <div style={{ textAlign: 'center', maxWidth: '380px' }}>
                <p style={{ fontSize: '32px', marginBottom: '12px' }}>📦</p>
                <p style={{ fontSize: '16px', fontWeight: 700, color: P.onSurface, marginBottom: '8px' }}>Livraison introuvable</p>
                <p style={{ fontSize: '13px', color: P.outline }}>{error}</p>
            </div>
        </div>
    );

    return (
        <div style={{ minHeight: '100vh', fontFamily: 'Poppins, sans-serif', backgroundColor: P.background }}>

            {/* Header */}
            <div style={{ backgroundColor: P.surface, borderBottom: '1px solid ' + P.outlineVariant, padding: '14px 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                    <p style={{ margin: 0, fontSize: '10px', color: P.outline, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Glotelho</p>
                    <p style={{ margin: 0, fontSize: '16px', fontWeight: 800, color: P.onSurface }}>Suivi de livraison</p>
                </div>
                <div style={{ textAlign: 'right' }}>
                    <p style={{ margin: 0, fontSize: '10px', color: P.outline }}>N° livraison</p>
                    <p style={{ margin: 0, fontSize: '16px', fontWeight: 800, color: P.primary }}>
                        #{String(livraison.id).padStart(5, '0')}
                    </p>
                </div>
            </div>

            {/* Statut */}
            <div style={{ padding: '14px 20px' }}>
                <div style={{ backgroundColor: statusInfo.bg, borderRadius: '12px', padding: '14px 18px', display: 'flex', alignItems: 'center', gap: '12px', border: '1px solid ' + statusInfo.color + '30' }}>
                    <div style={{ width: '10px', height: '10px', borderRadius: '50%', backgroundColor: statusInfo.color, flexShrink: 0 }}></div>
                    <div>
                        <p style={{ margin: 0, fontSize: '14px', fontWeight: 700, color: statusInfo.color }}>{statusInfo.label}</p>
                        {position && (
                            <p style={{ margin: '2px 0 0', fontSize: '11px', color: P.outline }}>
                                Derniere position : {new Date(position.timestamp).toLocaleTimeString('fr-FR')}
                            </p>
                        )}
                    </div>
                </div>
            </div>

            {/* Carte */}
            <div style={{ height: '350px', margin: '0 16px', borderRadius: '14px', overflow: 'hidden', border: '1px solid ' + P.outlineVariant }}>
                <div ref={mapContainer} style={{ width: '100%', height: '100%' }} />
            </div>

            {/* Infos livraison */}
            <div style={{ padding: '16px 20px' }}>
                <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, padding: '16px', marginBottom: '12px' }}>
                    <p style={{ margin: '0 0 12px', fontSize: '11px', fontWeight: 700, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.07em' }}>Adresse de livraison</p>
                    <p style={{ margin: 0, fontSize: '14px', fontWeight: 600, color: P.onSurface }}>{livraison.delivery_address}</p>
                    {livraison.zone_bloc && <p style={{ margin: '4px 0 0', fontSize: '12px', color: P.outline }}>{livraison.zone_bloc}</p>}
                </div>

                {/* Livreur */}
                {livraison.delivery_persons && (
                    <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, padding: '16px', marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '12px' }}>
                        <div style={{ width: '42px', height: '42px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '16px', fontWeight: 800, color: '#fff', flexShrink: 0 }}>
                            {livraison.delivery_persons.users?.first_name?.[0]}
                        </div>
                        <div>
                            <p style={{ margin: '0 0 2px', fontSize: '14px', fontWeight: 700, color: P.onSurface }}>
                                {livraison.delivery_persons.users?.first_name} {livraison.delivery_persons.users?.last_name}
                            </p>
                            <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>
                                {livraison.delivery_persons.vehicules?.brand} {livraison.delivery_persons.vehicules?.type} — {livraison.delivery_persons.vehicules?.plate_number}
                            </p>
                        </div>
                        {position && (
                            <div style={{ marginLeft: 'auto', textAlign: 'right' }}>
                                <p style={{ margin: 0, fontSize: '16px', fontWeight: 800, color: P.primaryContainer }}>{Math.round(position.speed || 0)} km/h</p>
                                <p style={{ margin: 0, fontSize: '10px', color: P.outline }}>vitesse</p>
                            </div>
                        )}
                    </div>
                )}

                {/* Code OTP */}
                {livraison.status === 'En_cours' && (
                    <div style={{ backgroundColor: '#2f3131', borderRadius: '14px', padding: '20px', marginBottom: '12px', textAlign: 'center' }}>
                        <p style={{ margin: '0 0 6px', fontSize: '11px', color: 'rgba(241,241,241,0.5)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em' }}>
                            Code de confirmation a donner au livreur
                        </p>
                        <p style={{ margin: '0 0 6px', fontSize: '36px', fontWeight: 900, color: P.primaryContainer, letterSpacing: '0.15em', fontFamily: 'monospace' }}>
                            {livraison.confirmations?.[0]?.value || '------'}
                        </p>
                        <p style={{ margin: 0, fontSize: '11px', color: 'rgba(241,241,241,0.35)' }}>
                            Ne partagez ce code qu'au livreur en face de vous
                        </p>
                    </div>
                )}

                {/* Livraison completee */}
                {livraison.status === 'Livr_' && (
                    <div style={{ backgroundColor: '#f0fdf4', borderRadius: '14px', padding: '20px', textAlign: 'center', border: '1px solid #a5d6a7' }}>
                        <p style={{ margin: '0 0 6px', fontSize: '28px' }}>✅</p>
                        <p style={{ margin: 0, fontSize: '15px', fontWeight: 700, color: '#1b5e20' }}>Livraison confirmee !</p>
                        <p style={{ margin: '4px 0 0', fontSize: '12px', color: '#4caf50' }}>Votre colis a bien ete remis.</p>
                    </div>
                )}

                <p style={{ textAlign: 'center', marginTop: '16px', fontSize: '11px', color: P.outline }}>
                    Propulsé par Glotelho E-commerce
                </p>
            </div>

            <style>{`
                .mapboxgl-ctrl-attrib, .mapboxgl-ctrl-logo { display: none !important; }
            `}</style>
        </div>
    );
}