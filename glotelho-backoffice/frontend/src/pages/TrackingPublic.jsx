import { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';
import { database, ref, onValue, off } from '../config/firebase';

mapboxgl.accessToken = import.meta.env.VITE_MAPBOX_TOKEN;

//import.meta.env.VITE_MAPBOX_TOKEN
const STATUS_INFO = {
    'En_attente': { label: 'En attente de livreur', color: '#c9952e', bg: '#ffdea9', icon: '⏳' },
    'Assign_':    { label: 'Livreur assigne',        color: '#475e8b', bg: '#b5ccff', icon: '🛵' },
    'En_cours':   { label: 'En cours de livraison',  color: '#1b5e20', bg: '#c8e6c9', icon: '📍' },
    'Livr_':      { label: 'Livraison effectuee',    color: '#1b5e20', bg: '#c8e6c9', icon: '✅' },
    'Annul_':     { label: 'Livraison annulee',      color: '#ba1a1a', bg: '#ffdad6', icon: '❌' },
    'Suspendu':   { label: 'Livraison suspendue',    color: '#ba1a1a', bg: '#ffdad6', icon: '⚠️' },
};

// ── PAGE ACCUEIL ─────────────────────────────────────────────
function PageAccueil({ onSearch }) {
    const [numLivraison, setNumLivraison] = useState('');
    const [error, setError] = useState('');

    function handleSubmit(e) {
        e.preventDefault();
        var val = numLivraison.trim().replace(/^0+/, '');
        if (!val || isNaN(val)) { setError('Veuillez entrer un numero valide.'); return; }
        setError('');
        onSearch(val);
    }

    return (
        <div style={{ minHeight: '100vh', backgroundColor: '#f5f5f5', display: 'flex', flexDirection: 'column', fontFamily: 'Poppins, sans-serif' }}>
            <style>{`* { box-sizing: border-box; } body { margin: 0; }`}</style>

            <div style={{ background: 'linear-gradient(135deg, #2f3131 0%, #1a1c1c 100%)', padding: '32px 32px 100px', textAlign: 'center' }}>
                <div style={{ display: 'inline-flex', alignItems: 'center', gap: '10px', marginBottom: '32px' }}>
                    <div style={{ width: '40px', height: '40px', backgroundColor: '#c9952e', borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '20px' }}>📦</div>
                    <div style={{ textAlign: 'left' }}>
                        <p style={{ margin: 0, fontSize: '20px', fontWeight: 800, color: '#fff' }}>Glotelho</p>
                        <p style={{ margin: 0, fontSize: '9px', color: 'rgba(255,255,255,0.4)', textTransform: 'uppercase', letterSpacing: '0.1em' }}>Suivi de livraison</p>
                    </div>
                </div>
                <h1 style={{ margin: '0 0 12px', fontSize: 'clamp(24px, 4vw, 38px)', fontWeight: 900, color: '#fff', lineHeight: 1.2 }}>Ou est mon colis ? 🛵</h1>
                <p style={{ margin: '0 auto', fontSize: 'clamp(13px, 2vw, 16px)', color: 'rgba(255,255,255,0.5)', maxWidth: '400px', lineHeight: 1.6 }}>
                    Entrez votre numero de livraison pour suivre votre colis en temps reel.
                </p>
            </div>

            <div style={{ padding: '0 16px', marginTop: '-60px', maxWidth: '560px', margin: '-60px auto 0', width: '100%' }}>
                <div style={{ backgroundColor: '#fff', borderRadius: '24px', padding: 'clamp(24px, 4vw, 40px)', boxShadow: '0 12px 48px rgba(0,0,0,0.15)' }}>
                    <p style={{ margin: '0 0 6px', fontSize: '12px', fontWeight: 700, color: '#817564', textTransform: 'uppercase', letterSpacing: '0.1em', textAlign: 'center' }}>Numero de livraison</p>
                    <p style={{ margin: '0 0 20px', fontSize: '12px', color: '#817564', textAlign: 'center' }}>Recu par SMS ou WhatsApp</p>
                    <form onSubmit={handleSubmit}>
                        <input type="text" value={numLivraison}
                            onChange={function(e) { setNumLivraison(e.target.value); }}
                            placeholder="Ex: 00012"
                            style={{ width: '100%', padding: '18px 20px', borderRadius: '14px', border: '2px solid #d3c4b0', fontSize: 'clamp(20px, 3vw, 28px)', fontFamily: 'Poppins, sans-serif', color: '#1a1c1c', outline: 'none', textAlign: 'center', letterSpacing: '0.15em', fontWeight: 700, backgroundColor: '#f9f9f9', marginBottom: '14px' }}
                            onFocus={function(e) { e.target.style.borderColor = '#c9952e'; e.target.style.backgroundColor = '#fff'; }}
                            onBlur={function(e) { e.target.style.borderColor = '#d3c4b0'; e.target.style.backgroundColor = '#f9f9f9'; }}
                            autoFocus
                        />
                        {error && <p style={{ margin: '0 0 12px', fontSize: '13px', color: '#ba1a1a', textAlign: 'center' }}>{error}</p>}
                        <button type="submit"
                            style={{ width: '100%', padding: '18px', borderRadius: '14px', border: 'none', background: 'linear-gradient(135deg, #7d5700, #c9952e)', color: '#fff', fontSize: 'clamp(14px, 2vw, 17px)', fontWeight: 700, cursor: 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: '0 6px 20px rgba(125,87,0,0.35)' }}>
                            Suivre ma livraison →
                        </button>
                    </form>
                </div>
            </div>
            <p style={{ textAlign: 'center', padding: '40px 16px 20px', fontSize: '12px', color: '#d3c4b0' }}>Glotelho E-commerce — Douala, Cameroun</p>
        </div>
    );
}

// ── PAGE TRACKING ────────────────────────────────────────────
function PageTracking({ livraisonId, onBack }) {
    const mapContainer = useRef(null);
    const map = useRef(null);
    const markerRef = useRef(null);

    const [livraison, setLivraison] = useState(null);
    const [position, setPosition] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [mapReady, setMapReady] = useState(false);
    const [panelOpen, setPanelOpen] = useState(false);

    useEffect(function() {
        var apiUrl = (import.meta.env.VITE_API_URL || 'http://localhost:5000/api') + '/livraisons/public/' + livraisonId;
        fetch(apiUrl)
            .then(function(r) { return r.json(); })
            .then(function(data) {
                if (data.message && !data.id) setError(data.message);
                else setLivraison(data);
            })
            .catch(function() { setError('Impossible de charger les informations.'); })
            .finally(function() { setLoading(false); });
    }, [livraisonId]);

    useEffect(function() {
        if (!livraison || !livraison.delivery_person_id) return;
        var posRef = ref(database, 'positions/' + livraison.delivery_person_id);
        onValue(posRef, function(snapshot) {
            var data = snapshot.val();
            if (data) setPosition(data);
        });
        return function() { off(posRef); };
    }, [livraison]);

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

    useEffect(function() {
        if (!mapReady || !map.current || !position) return;
        var coords = [position.longitude, position.latitude];
        if (markerRef.current) {
            markerRef.current.setLngLat(coords);
        } else {
            var el = document.createElement('div');
            el.innerHTML = '<div style="text-align:center;">' +
                '<div style="background:#c9952e;color:white;font-size:9px;font-weight:700;padding:3px 8px;border-radius:10px;font-family:Poppins,sans-serif;margin-bottom:4px;white-space:nowrap;box-shadow:0 2px 8px rgba(0,0,0,0.25);">' +
                Math.round(position.speed || 0) + ' km/h</div>' +
                '<div style="width:40px;height:40px;border-radius:50%;background:linear-gradient(135deg,#c9952e,#7d5700);border:3px solid white;display:flex;align-items:center;justify-content:center;box-shadow:0 4px 14px rgba(0,0,0,0.3);margin:0 auto;font-size:20px;">🛵</div>' +
                '</div>';
            markerRef.current = new mapboxgl.Marker({ element: el, anchor: 'bottom' }).setLngLat(coords).addTo(map.current);
        }
        map.current.flyTo({ center: coords, zoom: 15, duration: 800 });
    }, [position, mapReady]);

    var statusInfo = livraison ? (STATUS_INFO[livraison.status] || STATUS_INFO['En_attente']) : null;
    var numFormate = String(livraisonId).padStart(5, '0');
    var otp = livraison && livraison.confirmations && livraison.confirmations.length > 0 ? livraison.confirmations[0].otp_code : null;

    if (loading) return (
        <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Poppins, sans-serif', background: 'linear-gradient(135deg, #2f3131, #1a1c1c)' }}>
            <div style={{ textAlign: 'center' }}>
                <p style={{ fontSize: '48px', margin: '0 0 16px' }}>⏳</p>
                <p style={{ color: 'rgba(255,255,255,0.5)', fontSize: '14px', margin: 0 }}>Chargement...</p>
            </div>
        </div>
    );

    if (error) return (
        <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', fontFamily: 'Poppins, sans-serif', backgroundColor: '#f5f5f5' }}>
            <div style={{ background: 'linear-gradient(135deg, #2f3131, #1a1c1c)', padding: '18px 24px', display: 'flex', alignItems: 'center', gap: '12px' }}>
                <button onClick={onBack} style={{ background: 'rgba(255,255,255,0.1)', border: 'none', color: '#fff', cursor: 'pointer', fontSize: '16px', padding: '7px 12px', borderRadius: '8px' }}>←</button>
                <p style={{ margin: 0, fontSize: '16px', fontWeight: 700, color: '#fff' }}>Livraison #{numFormate}</p>
            </div>
            <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '24px' }}>
                <div style={{ textAlign: 'center', backgroundColor: '#fff', borderRadius: '20px', padding: '40px 32px', boxShadow: '0 8px 32px rgba(0,0,0,0.1)', maxWidth: '400px', width: '100%' }}>
                    <p style={{ fontSize: '52px', margin: '0 0 16px' }}>🔍</p>
                    <p style={{ fontSize: '20px', fontWeight: 800, color: '#1a1c1c', margin: '0 0 10px' }}>Livraison introuvable</p>
                    <p style={{ fontSize: '14px', color: '#817564', margin: '0 0 28px', lineHeight: 1.6 }}>Le numero #{numFormate} ne correspond a aucune livraison.</p>
                    <button onClick={onBack} style={{ width: '100%', padding: '16px', borderRadius: '12px', border: 'none', background: 'linear-gradient(135deg, #7d5700, #c9952e)', color: '#fff', fontSize: '15px', fontWeight: 700, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                        Reessayer
                    </button>
                </div>
            </div>
        </div>
    );

    return (
        <div style={{ width: '100vw', height: '100vh', fontFamily: 'Poppins, sans-serif', position: 'relative', overflow: 'hidden' }}>
            <style>{`.mapboxgl-ctrl-attrib,.mapboxgl-ctrl-logo{display:none!important} * { box-sizing:border-box; } body { margin:0; }`}</style>

            {/* CARTE — plein ecran */}
            <div ref={mapContainer} style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }} />

            {/* HEADER — overlay en haut */}
            <div style={{ position: 'absolute', top: 0, left: 0, right: 0, zIndex: 10, background: 'linear-gradient(180deg, rgba(47,49,49,0.95) 0%, rgba(47,49,49,0.0) 100%)', padding: '14px 16px 40px' }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <button onClick={onBack} style={{ background: 'rgba(255,255,255,0.15)', backdropFilter: 'blur(8px)', border: 'none', color: '#fff', cursor: 'pointer', fontSize: '16px', padding: '8px 12px', borderRadius: '10px' }}>←</button>
                        <div>
                            <p style={{ margin: 0, fontSize: '9px', color: 'rgba(255,255,255,0.5)', textTransform: 'uppercase', letterSpacing: '0.12em' }}>Livraison</p>
                            <p style={{ margin: 0, fontSize: '20px', fontWeight: 900, color: '#c9952e', letterSpacing: '0.08em', fontFamily: 'monospace' }}>#{numFormate}</p>
                        </div>
                    </div>
                    {statusInfo && (
                        <span style={{ backgroundColor: statusInfo.bg, color: statusInfo.color, padding: '7px 14px', borderRadius: '20px', fontSize: '11px', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '5px', boxShadow: '0 2px 10px rgba(0,0,0,0.2)' }}>
                            {statusInfo.icon} {statusInfo.label}
                        </span>
                    )}
                </div>
            </div>

            {/* Badge GPS en attente */}
            {!position && livraison && ['En_cours', 'Assign_'].includes(livraison.status) && (
                <div style={{ position: 'absolute', top: '80px', left: '50%', transform: 'translateX(-50%)', zIndex: 10, backgroundColor: 'rgba(255,255,255,0.95)', backdropFilter: 'blur(10px)', borderRadius: '20px', padding: '8px 18px', display: 'flex', alignItems: 'center', gap: '8px', boxShadow: '0 4px 16px rgba(0,0,0,0.15)', whiteSpace: 'nowrap' }}>
                    <span style={{ fontSize: '12px' }}>📡</span>
                    <p style={{ margin: 0, fontSize: '12px', color: '#817564', fontWeight: 600 }}>En attente de la position GPS...</p>
                </div>
            )}

            {/* Badge vitesse GPS actif */}
            {position && (
                <div style={{ position: 'absolute', top: '80px', left: '50%', transform: 'translateX(-50%)', zIndex: 10, backgroundColor: 'rgba(47,49,49,0.9)', backdropFilter: 'blur(10px)', borderRadius: '20px', padding: '7px 16px', display: 'flex', alignItems: 'center', gap: '10px', boxShadow: '0 4px 16px rgba(0,0,0,0.25)', whiteSpace: 'nowrap' }}>
                    <div style={{ width: '7px', height: '7px', borderRadius: '50%', backgroundColor: '#22C55E', boxShadow: '0 0 6px #22C55E' }}></div>
                    <p style={{ margin: 0, fontSize: '12px', color: '#fff', fontWeight: 600 }}>
                        En direct • {Math.round(position.speed || 0)} km/h • {new Date(position.timestamp).toLocaleTimeString('fr-FR')}
                    </p>
                </div>
            )}

            {/* PANNEAU BAS — slide up */}
            <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, zIndex: 10 }}>

                {/* Handle pour ouvrir/fermer */}
                <div onClick={function() { setPanelOpen(!panelOpen); }}
                    style={{ display: 'flex', justifyContent: 'center', padding: '10px', cursor: 'pointer' }}>
                    <div style={{ width: '40px', height: '4px', borderRadius: '2px', backgroundColor: 'rgba(255,255,255,0.4)' }}></div>
                </div>

                <div style={{ backgroundColor: 'rgba(255,255,255,0.97)', backdropFilter: 'blur(20px)', borderRadius: '24px 24px 0 0', padding: '0 16px 24px', boxShadow: '0 -8px 40px rgba(0,0,0,0.2)', maxHeight: panelOpen ? '80vh' : '200px', overflow: 'hidden', transition: 'max-height 0.35s ease' }}>

                    {/* Livreur */}
                    {livraison && livraison.delivery_persons && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: '14px', padding: '16px 0 12px', borderBottom: panelOpen ? '1px solid #f3f3f3' : 'none' }}>
                            <div style={{ width: '50px', height: '50px', borderRadius: '50%', background: 'linear-gradient(135deg, #c9952e, #7d5700)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '22px', flexShrink: 0, boxShadow: '0 4px 12px rgba(201,149,46,0.4)' }}>🛵</div>
                            <div style={{ flex: 1, minWidth: 0 }}>
                                <p style={{ margin: '0 0 2px', fontSize: '10px', fontWeight: 700, color: '#c9952e', textTransform: 'uppercase', letterSpacing: '0.07em' }}>Votre livreur</p>
                                <p style={{ margin: '0 0 2px', fontSize: '16px', fontWeight: 800, color: '#1a1c1c', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                                    {livraison.delivery_persons.users ? livraison.delivery_persons.users.first_name + ' ' + livraison.delivery_persons.users.last_name : '—'}
                                </p>
                                <p style={{ margin: 0, fontSize: '11px', color: '#817564' }}>
                                    {livraison.delivery_persons.vehicules ? livraison.delivery_persons.vehicules.brand + ' ' + livraison.delivery_persons.vehicules.type + ' • ' + livraison.delivery_persons.vehicules.plate_number : ''}
                                </p>
                            </div>
                            <div style={{ textAlign: 'right', flexShrink: 0 }}>
                                <p style={{ margin: 0, fontSize: '11px', color: '#817564' }}>{panelOpen ? '▲ Reduire' : '▼ Voir plus'}</p>
                            </div>
                        </div>
                    )}

                    {/* En attente */}
                    {livraison && livraison.status === 'En_attente' && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '16px 0 12px' }}>
                            <span style={{ fontSize: '28px' }}>⏳</span>
                            <div>
                                <p style={{ margin: '0 0 2px', fontSize: '15px', fontWeight: 800, color: '#7d5700' }}>En attente d'un livreur</p>
                                <p style={{ margin: 0, fontSize: '12px', color: '#c9952e' }}>Votre commande sera prise en charge tres prochainement.</p>
                            </div>
                        </div>
                    )}

                    {/* Contenu etendu */}
                    {panelOpen && (
                        <div style={{ paddingTop: '12px' }}>

                            {/* Adresse */}
                            <div style={{ display: 'flex', alignItems: 'flex-start', gap: '12px', padding: '12px 0', borderBottom: '1px solid #f3f3f3' }}>
                                <div style={{ width: '36px', height: '36px', borderRadius: '10px', backgroundColor: '#ffdea9', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '18px', flexShrink: 0 }}>📍</div>
                                <div>
                                    <p style={{ margin: '0 0 3px', fontSize: '10px', fontWeight: 700, color: '#817564', textTransform: 'uppercase', letterSpacing: '0.07em' }}>Adresse de livraison</p>
                                    <p style={{ margin: '0 0 2px', fontSize: '14px', fontWeight: 700, color: '#1a1c1c' }}>{livraison && livraison.delivery_address}</p>
                                    {livraison && livraison.zone_bloc && <p style={{ margin: 0, fontSize: '12px', color: '#817564' }}>{livraison.zone_bloc}</p>}
                                </div>
                            </div>

                            {/* OTP */}
                            {livraison && livraison.status === 'En_cours' && otp && (
                                <div style={{ background: 'linear-gradient(135deg, #2f3131, #1a1c1c)', borderRadius: '20px', padding: '22px 20px', margin: '14px 0', textAlign: 'center' }}>
                                    <div style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', backgroundColor: 'rgba(201,149,46,0.15)', borderRadius: '20px', padding: '5px 14px', marginBottom: '12px' }}>
                                        <span>🔐</span>
                                        <p style={{ margin: 0, fontSize: '10px', fontWeight: 700, color: '#c9952e', textTransform: 'uppercase', letterSpacing: '0.1em' }}>Code de confirmation</p>
                                    </div>
                                    <p style={{ margin: '0 0 10px', fontSize: '52px', fontWeight: 900, color: '#c9952e', letterSpacing: '0.25em', fontFamily: 'monospace', lineHeight: 1 }}>{otp}</p>
                                    <p style={{ margin: 0, fontSize: '12px', color: 'rgba(255,255,255,0.4)', lineHeight: 1.6 }}>Donnez ce code au livreur en face de vous.</p>
                                </div>
                            )}

                            {/* Livraison completee */}
                            {livraison && livraison.status === 'Livr_' && (
                                <div style={{ backgroundColor: '#f0fdf4', borderRadius: '16px', padding: '24px', textAlign: 'center', border: '2px solid #a5d6a7', margin: '14px 0' }}>
                                    <p style={{ margin: '0 0 8px', fontSize: '44px' }}>✅</p>
                                    <p style={{ margin: '0 0 4px', fontSize: '18px', fontWeight: 900, color: '#1b5e20' }}>Livraison confirmee !</p>
                                    <p style={{ margin: 0, fontSize: '13px', color: '#4caf50', lineHeight: 1.6 }}>Votre colis a bien ete remis. Merci !</p>
                                </div>
                            )}

                            <p style={{ textAlign: 'center', fontSize: '11px', color: '#d3c4b0', marginTop: '12px' }}>Glotelho E-commerce — Douala, Cameroun</p>
                        </div>
                    )}

                    {/* OTP visible meme panel ferme si En_cours */}
                    {!panelOpen && livraison && livraison.status === 'En_cours' && otp && (
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 0 4px' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                <span style={{ fontSize: '16px' }}>🔐</span>
                                <p style={{ margin: 0, fontSize: '12px', color: '#817564' }}>Code livreur</p>
                            </div>
                            <p style={{ margin: 0, fontSize: '24px', fontWeight: 900, color: '#c9952e', letterSpacing: '0.15em', fontFamily: 'monospace' }}>{otp}</p>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}

// ── COMPOSANT PRINCIPAL ──────────────────────────────────────
export default function TrackingPublic() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [livraisonId, setLivraisonId] = useState(id || null);

    useEffect(function() {
        if (id) setLivraisonId(id);
    }, [id]);

    function handleSearch(num) {
        setLivraisonId(num);
        navigate('/suivi/' + num, { replace: true });
    }

    function handleBack() {
        setLivraisonId(null);
        navigate('/suivi', { replace: true });
    }

    if (!livraisonId) return <PageAccueil onSearch={handleSearch} />;
    return <PageTracking key={livraisonId} livraisonId={livraisonId} onBack={handleBack} />;
}