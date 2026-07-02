import { useState, useEffect, useRef, useCallback } from 'react';
import api from '../services/api';
import { IconTruck, IconMap, IconCheck, IconAlert, IconX, IconUser } from '../components/Icons';
import { database, ref, onValue, off } from '../config/firebase';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    primaryFixed: '#ffdea9', onPrimaryContainer: '#483100',
    secondary: '#475e8b', secondaryContainer: '#b5ccff', onSecondaryContainer: '#3e5682',
    error: '#ba1a1a', errorContainer: '#ffdad6', onErrorContainer: '#93000a',
    surface: '#ffffff', background: '#f9f9f9',
    surfaceContainerLow: '#f3f3f3', surfaceContainerHigh: '#e8e8e8',
    inverseS: '#2f3131', inverseSOn: '#f1f1f1',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
};

// Couleurs distinctes par livreur (comme Yango/Uber)
const LIVREUR_COLORS = [
    '#22C55E', // vert vif
    '#3B82F6', // bleu
    '#F59E0B', // ambre
    '#EF4444', // rouge
    '#8B5CF6', // violet
    '#EC4899', // rose
    '#06B6D4', // cyan
    '#F97316', // orange
];

function getLivreurColor(index) {
    return LIVREUR_COLORS[index % LIVREUR_COLORS.length];
}

function KpiCard({ icon: Icon, label, value, iconColor, iconBg }) {
    return (
        <div style={{ backgroundColor: P.inverseS, borderRadius: '12px', padding: '14px 16px', display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{ width: '34px', height: '34px', borderRadius: '8px', backgroundColor: iconBg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Icon style={{ width: '16px', height: '16px', color: iconColor }} />
            </div>
            <div>
                <p style={{ margin: 0, fontSize: '20px', fontWeight: 800, color: P.inverseSOn, lineHeight: 1 }}>{value}</p>
                <p style={{ margin: '3px 0 0 0', fontSize: '11px', color: 'rgba(241,241,241,0.4)', fontWeight: 500 }}>{label}</p>
            </div>
        </div>
    );
}

// Icone vehicule SVG selon le type
function VehicleIcon({ type, color, size = 28 }) {
    if (type === 'moto') {
        return (
            <svg width={size} height={size} viewBox="0 0 24 24" fill={color} stroke="white" strokeWidth="0.5">
                <circle cx="5" cy="17" r="3"/>
                <circle cx="19" cy="17" r="3"/>
                <path d="M5 17h3l3-6h5l2 4h2M11 11l2-4h4"/>
            </svg>
        );
    }
    return (
        <svg width={size} height={size} viewBox="0 0 24 24" fill={color} stroke="white" strokeWidth="0.5">
            <rect x="2" y="9" width="20" height="9" rx="2"/>
            <path d="M5 9l2-5h10l2 5"/>
            <circle cx="7" cy="18" r="2"/>
            <circle cx="17" cy="18" r="2"/>
            <rect x="8" y="11" width="4" height="3" rx="1"/>
            <rect x="13" y="11" width="4" height="3" rx="1"/>
        </svg>
    );
}

// positions GPS Firebase (toutes les 5s comme en production)
function useFirebasePositions(livreurs) {
    const [positions, setPositions] = useState({});

    useEffect(() => {
        if (livreurs.length === 0) return;
        const listeners = [];

        livreurs.filter(l => l.status === 'En_livraison').forEach(l => {
            const posRef = ref(database, 'positions/' + l.id);
            const unsubscribe = onValue(posRef, (snapshot) => {
                const data = snapshot.val();
                if (data) {
                    setPositions(prev => ({
                        ...prev,
                        [l.id]: {
                            lat: data.lat,
                            lng: data.lng,
                            vitesse: data.vitesse || 0,
                            lastUpdate: new Date(data.timestamp),
                        }
                    }));
                }
            });
            listeners.push({ posRef, unsubscribe });
        });

        return () => {
            listeners.forEach(({ posRef }) => off(posRef));
        };
    }, [livreurs.length]);

    return { positions, routes: {} };
}

// Carte OSM avec marqueurs et routes colores
function TrackingMap({ livreurs, positions, routes, selectedId, onSelect, colorMap }) {
    const mapRef = useRef(null);

    // Calcule centre de la carte
    const center = { lat: 4.0511, lng: 9.7085 };

    // Convertit coordonnees GPS en position pixel sur la carte
    // Viewport Douala : lat [3.98, 4.12], lng [9.65, 9.80]
    const LAT_MIN = 3.98, LAT_MAX = 4.14;
    const LNG_MIN = 9.65, LNG_MAX = 9.82;

    function toPixel(lat, lng, width, height) {
        const x = ((lng - LNG_MIN) / (LNG_MAX - LNG_MIN)) * width;
        const y = ((LAT_MAX - lat) / (LAT_MAX - LAT_MIN)) * height;
        return { x, y };
    }

    const mapWidth = 800;
    const mapHeight = 420;

    return (
        <div ref={mapRef} style={{ position: 'relative', width: '100%', height: mapHeight + 'px', borderRadius: '12px', overflow: 'hidden', border: '1px solid ' + P.outlineVariant }}>

            {/* Fond carte OSM */}
            <iframe
                src="https://www.openstreetmap.org/export/embed.html?bbox=9.65%2C3.98%2C9.82%2C4.14&layer=mapnik"
                style={{ width: '100%', height: '100%', border: 'none', display: 'block' }}
                title="Carte Douala GPS Tracking"
            />

            {/* Overlay SVG pour routes + marqueurs */}
            <svg
                style={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '100%', pointerEvents: 'none' }}
                viewBox={`0 0 ${mapWidth} ${mapHeight}`}
                preserveAspectRatio="none"
            >
                {/* Routes colorees par livreur */}
                {livreurs.filter(l => l.status === 'En_livraison').map((l, i) => {
                    const route = routes[l.id];
                    const color = colorMap[l.id];
                    if (!route || route.length < 2) return null;

                    const points = route.map(p => {
                        const { x, y } = toPixel(p.lat, p.lng, mapWidth, mapHeight);
                        return `${x},${y}`;
                    }).join(' ');

                    return (
                        <g key={l.id}>
                            {/* Ombre route */}
                            <polyline
                                points={points}
                                fill="none"
                                stroke="rgba(0,0,0,0.2)"
                                strokeWidth="8"
                                strokeLinecap="round"
                                strokeLinejoin="round"
                            />
                            {/* Route coloree */}
                            <polyline
                                points={points}
                                fill="none"
                                stroke={color}
                                strokeWidth="5"
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                strokeDasharray={l.status === 'En_livraison' ? 'none' : '8,6'}
                                opacity="0.9"
                            />
                        </g>
                    );
                })}

                {/* Marqueurs livreurs */}
                {livreurs.map((l, i) => {
                    const pos = positions[l.id];
                    if (!pos) return null;
                    const { x, y } = toPixel(pos.lat, pos.lng, mapWidth, mapHeight);
                    const color = colorMap[l.id];
                    const isSelected = selectedId === l.id;
                    const isMoto = l.vehicules?.type === 'moto';
                    const size = isSelected ? 36 : 28;

                    return (
                        <g key={l.id} style={{ pointerEvents: 'all', cursor: 'pointer' }}>
                            {/* Cercle de selection */}
                            {isSelected && (
                                <circle cx={x} cy={y} r={size * 0.8} fill={color} opacity="0.15" />
                            )}
                            {/* Fond marqueur */}
                            <circle cx={x} cy={y} r={size / 2} fill={color} stroke="white" strokeWidth="2.5" />
                            {/* Icone vehicule */}
                            <foreignObject x={x - size / 2} y={y - size / 2} width={size} height={size}>
                                <div xmlns="http://www.w3.org/1999/xhtml" style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                    {isMoto ? (
                                        <svg width={size * 0.6} height={size * 0.6} viewBox="0 0 24 24" fill="white">
                                            <circle cx="5" cy="17" r="3" stroke="white" strokeWidth="1.5" fill="none"/>
                                            <circle cx="19" cy="17" r="3" stroke="white" strokeWidth="1.5" fill="none"/>
                                            <path d="M5 17h3.5l2.5-5h5l1.5 3h2.5" stroke="white" strokeWidth="1.5" fill="none" strokeLinecap="round"/>
                                            <path d="M13 12l1.5-3h3" stroke="white" strokeWidth="1.5" fill="none" strokeLinecap="round"/>
                                        </svg>
                                    ) : (
                                        <svg width={size * 0.6} height={size * 0.6} viewBox="0 0 24 24" fill="white">
                                            <path d="M5 17H3a1 1 0 01-1-1v-4a1 1 0 011-1h12l4 3v2h-2" stroke="white" strokeWidth="1.5" fill="none" strokeLinecap="round"/>
                                            <circle cx="7.5" cy="17.5" r="2.5" stroke="white" strokeWidth="1.5" fill="none"/>
                                            <circle cx="17.5" cy="17.5" r="2.5" stroke="white" strokeWidth="1.5" fill="none"/>
                                            <path d="M5 11l2-4h8l2 4" stroke="white" strokeWidth="1.5" fill="none" strokeLinecap="round"/>
                                        </svg>
                                    )}
                                </div>
                            </foreignObject>
                        </g>
                    );
                })}

                {/* Destinations (drapeaux) */}
                {livreurs.filter(l => l.status === 'En_livraison').map((l, i) => {
                    const pos = positions[l.id];
                    if (!pos?.destination) return null;
                    const { x, y } = toPixel(pos.destination.lat, pos.destination.lng, mapWidth, mapHeight);
                    const color = colorMap[l.id];
                    return (
                        <g key={'dest-' + l.id}>
                            <circle cx={x} cy={y} r={10} fill={color} opacity="0.3" />
                            <circle cx={x} cy={y} r={5} fill={color} />
                            <text x={x + 8} y={y - 8} fontSize="10" fill={color} fontWeight="bold" fontFamily="Poppins, sans-serif">
                                {pos.destination.label}
                            </text>
                        </g>
                    );
                })}
            </svg>

            {/* Badge temps reel */}
            <div style={{ position: 'absolute', top: '10px', right: '10px', backgroundColor: 'rgba(47,49,49,0.85)', borderRadius: '20px', padding: '5px 12px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <div style={{ width: '7px', height: '7px', borderRadius: '50%', backgroundColor: '#22C55E', animation: 'pulse 2s infinite' }}></div>
                <span style={{ fontSize: '11px', fontWeight: 600, color: 'white' }}>GPS Live — toutes les 5s</span>
            </div>

            {/* Legende livreurs */}
            <div style={{ position: 'absolute', bottom: '10px', left: '10px', backgroundColor: 'rgba(255,255,255,0.92)', borderRadius: '10px', padding: '8px 12px', display: 'flex', flexDirection: 'column', gap: '5px', boxShadow: '0 2px 8px rgba(0,0,0,0.12)' }}>
                {livreurs.filter(l => l.status === 'En_livraison').map(l => (
                    <div key={l.id} style={{ display: 'flex', alignItems: 'center', gap: '7px', cursor: 'pointer' }}>
                        <div style={{ width: '10px', height: '10px', borderRadius: '50%', backgroundColor: colorMap[l.id], flexShrink: 0 }}></div>
                        <span style={{ fontSize: '11px', fontWeight: 600, color: P.onSurface }}>
                            {l.users?.first_name} {l.users?.last_name?.charAt(0)}.
                        </span>
                        <span style={{ fontSize: '10px', color: P.outline }}>{positions[l.id]?.vitesse || 0} km/h</span>
                    </div>
                ))}
                {livreurs.filter(l => l.status === 'En_livraison').length === 0 && (
                    <span style={{ fontSize: '11px', color: P.outline }}>Aucun livreur en cours</span>
                )}
            </div>
        </div>
    );
}

export default function Tracking() {
    const [livreurs, setLivreurs] = useState([]);
    const [livraisons, setLivraisons] = useState([]);
    const [loading, setLoading] = useState(true);
    const [selectedId, setSelectedId] = useState(null);

    useEffect(() => {
        Promise.all([
            api.get('/livreurs?all=true').catch(() => ({ data: [] })),
            api.get('/livraisons').catch(() => ({ data: [] })),
        ]).then(([lvRes, livRes]) => {
            setLivreurs(lvRes.data || []);
            setLivraisons(livRes.data || []);
        }).finally(() => setLoading(false));
    }, []);

    const { positions, routes } = useFirebasePositions(livreurs);

    // Map livreur id -> couleur fixe
    const colorMap = {};
    livreurs.forEach((l, i) => { colorMap[l.id] = getLivreurColor(i); });

    const actifs = livreurs.filter(l => l.status === 'En_livraison');
    const disponibles = livreurs.filter(l => l.status === 'Disponible');
    const enCours = livraisons.filter(l => l.status === 'En_cours');

    const selectedLivreur = selectedId ? livreurs.find(l => l.id === selectedId) : null;
    const selectedPos = selectedId ? positions[selectedId] : null;
    const selectedLivraison = selectedLivreur
        ? livraisons.find(l => l.delivery_persons?.id === selectedId && ['Assign_', 'En_cours'].includes(l.status))
        : null;

    const border = '1px solid ' + P.outlineVariant;

    return (
        <div style={{ fontFamily: 'Poppins, sans-serif' }}>

            {/* KPIs */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '10px', marginBottom: '16px' }}>
                <KpiCard icon={IconTruck} label="En livraison"     value={actifs.length}     iconColor={P.primaryContainer} iconBg="rgba(201,149,46,0.15)" />
                <KpiCard icon={IconCheck} label="Disponibles"      value={disponibles.length} iconColor="#81c784"            iconBg="rgba(129,199,132,0.15)" />
                <KpiCard icon={IconMap}   label="Livraisons cours" value={enCours.length}    iconColor="#6aa1e3"            iconBg="rgba(106,161,227,0.15)" />
                <KpiCard icon={IconUser}  label="Total livreurs"   value={livreurs.length}   iconColor={P.primaryContainer} iconBg="rgba(201,149,46,0.15)" />
            </div>

            {/* Bandeau Firebase */}
            {/*<div style={{ backgroundColor: P.primaryFixed, border: '1px solid ' + P.primaryContainer, borderRadius: '10px', padding: '10px 16px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '10px' }}>
                <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#22C55E', flexShrink: 0 }}></div>
                <p style={{ margin: 0, fontSize: '12px', color: P.onPrimaryContainer, fontWeight: 500 }}>
                 Mode simulation — positions GPS generees toutes les 5s. En production : connectez Firebase Realtime Database (<code style={{ fontSize: '11px', backgroundColor: 'rgba(125,87,0,0.1)', padding: '1px 5px', borderRadius: '3px' }}>VITE_FIREBASE_DATABASE_URL</code>) pour le tracking reel via <code style={{ fontSize: '11px', backgroundColor: 'rgba(125,87,0,0.1)', padding: '1px 5px', borderRadius: '3px' }}>positions/{"{"}id_livreur{"}"}</code>. </p>
            </div> */}
            <div style={{ display: 'grid', gridTemplateColumns: '260px 1fr', gap: '14px' }}>

                {/* LISTE LIVREURS */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>

                    {/* Livreurs en livraison */}
                    <div style={{ backgroundColor: P.surface, borderRadius: '14px', border, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}>
                        <div style={{ padding: '12px 16px', borderBottom: '1px solid ' + P.surfaceContainerLow, backgroundColor: P.surfaceContainerLow }}>
                            <p style={{ margin: 0, fontSize: '12px', fontWeight: 700, color: P.onSurface }}>En livraison ({actifs.length})</p>
                        </div>
                        {loading ? (
                            <p style={{ textAlign: 'center', color: P.outline, fontSize: '12px', padding: '20px' }}>Chargement...</p>
                        ) : actifs.length === 0 ? (
                            <div style={{ padding: '20px', textAlign: 'center' }}>
                                <IconTruck style={{ width: '24px', height: '24px', color: P.outlineVariant, margin: '0 auto 6px' }} />
                                <p style={{ margin: 0, fontSize: '12px', color: P.outline }}>Aucun livreur actif</p>
                            </div>
                        ) : actifs.map(l => {
                            const pos = positions[l.id];
                            const color = colorMap[l.id];
                            const isSelected = selectedId === l.id;
                            const livraison = livraisons.find(lv => lv.delivery_persons?.id === l.id && lv.status === 'En_cours');

                            return (
                                <button key={l.id} onClick={() => setSelectedId(isSelected ? null : l.id)}
                                    style={{ width: '100%', display: 'flex', alignItems: 'flex-start', gap: '10px', padding: '12px 14px', textAlign: 'left', background: isSelected ? P.primaryFixed : 'transparent', border: 'none', borderBottom: '1px solid ' + P.surfaceContainerLow, cursor: 'pointer', fontFamily: 'Poppins, sans-serif', transition: 'background 0.15s', borderLeft: isSelected ? '3px solid ' + color : '3px solid transparent' }}
                                    onMouseEnter={e => { if (!isSelected) e.currentTarget.style.backgroundColor = P.surfaceContainerLow; }}
                                    onMouseLeave={e => { if (!isSelected) e.currentTarget.style.backgroundColor = 'transparent'; }}
                                >
                                    {/* Avatar avec couleur GPS */}
                                    <div style={{ position: 'relative', flexShrink: 0 }}>
                                        <div style={{ width: '36px', height: '36px', borderRadius: '50%', backgroundColor: color, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '13px', fontWeight: 700, color: '#fff', border: '2px solid white', boxShadow: '0 2px 6px rgba(0,0,0,0.15)' }}>
                                            {l.users?.first_name?.[0]}
                                        </div>
                                        <div style={{ position: 'absolute', bottom: 0, right: 0, width: '10px', height: '10px', borderRadius: '50%', backgroundColor: '#22C55E', border: '2px solid white' }}></div>
                                    </div>

                                    <div style={{ flex: 1, minWidth: 0 }}>
                                        <p style={{ margin: 0, fontSize: '12px', fontWeight: 600, color: P.onSurface, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                                            {l.users?.first_name} {l.users?.last_name}
                                        </p>
                                        <p style={{ margin: '2px 0 0 0', fontSize: '10px', color: P.outline }}>
                                            {l.vehicules?.brand} {l.vehicules?.type}
                                        </p>
                                        {pos && (
                                            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginTop: '4px' }}>
                                                <span style={{ fontSize: '11px', fontWeight: 700, color: color }}>{pos.vitesse} km/h</span>
                                                <span style={{ fontSize: '10px', color: P.outline }}>· MAJ {pos.lastUpdate.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit', second: '2-digit' })}</span>
                                            </div>
                                        )}
                                        {livraison && (
                                            <p style={{ margin: '3px 0 0 0', fontSize: '10px', color: P.outline, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                                                → {livraison.delivery_address}
                                            </p>
                                        )}
                                    </div>

                                    {/* Pastille couleur */}
                                    <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: color, flexShrink: 0, marginTop: '4px' }}></div>
                                </button>
                            );
                        })}
                    </div>

                    {/* Livreurs disponibles */}
                    {disponibles.length > 0 && (
                        <div style={{ backgroundColor: P.surface, borderRadius: '14px', border, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}>
                            <div style={{ padding: '10px 16px', borderBottom: '1px solid ' + P.surfaceContainerLow, backgroundColor: P.surfaceContainerLow }}>
                                <p style={{ margin: 0, fontSize: '12px', fontWeight: 700, color: P.onSurface }}>Disponibles ({disponibles.length})</p>
                            </div>
                            {disponibles.map(l => (
                                <div key={l.id} style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '10px 14px', borderBottom: '1px solid ' + P.surfaceContainerLow }}>
                                    <div style={{ width: '30px', height: '30px', borderRadius: '50%', backgroundColor: P.surfaceContainerHigh, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '11px', fontWeight: 700, color: P.outline, flexShrink: 0 }}>
                                        {l.users?.first_name?.[0]}
                                    </div>
                                    <div style={{ flex: 1, minWidth: 0 }}>
                                        <p style={{ margin: 0, fontSize: '12px', fontWeight: 500, color: P.onSurface }}>{l.users?.first_name} {l.users?.last_name}</p>
                                        <p style={{ margin: 0, fontSize: '10px', color: P.outline }}>{l.zone_affectee}</p>
                                    </div>
                                    <span style={{ fontSize: '10px', fontWeight: 600, color: '#4caf50', backgroundColor: '#c8e6c9', padding: '2px 7px', borderRadius: '4px' }}>Libre</span>
                                </div>
                            ))}
                        </div>
                    )}
                </div>

                {/* ZONE DROITE — Carte + panneau info */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>

                    {/* CARTE */}
                    <div style={{ backgroundColor: P.surface, borderRadius: '14px', border, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}>
                        <div style={{ padding: '12px 16px', borderBottom: '1px solid ' + P.surfaceContainerLow, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                            <div>
                                <p style={{ margin: 0, fontSize: '13px', fontWeight: 700, color: P.onSurface }}>Carte de tracking — Douala</p>
                                <p style={{ margin: '2px 0 0 0', fontSize: '11px', color: P.outline }}>{actifs.length} livreur{actifs.length > 1 ? 's' : ''} actif{actifs.length > 1 ? 's' : ''} sur la carte · Chaque livreur a sa propre couleur de route</p>
                            </div>
                        </div>
                        <div style={{ padding: '0' }}>
                            <TrackingMap
                                livreurs={livreurs}
                                positions={positions}
                                routes={routes}
                                selectedId={selectedId}
                                onSelect={setSelectedId}
                                colorMap={colorMap}
                            />
                        </div>
                    </div>

                    {/* PANNEAU BAS — style Yango/Uber */}
                    {selectedLivreur && selectedPos && (
                        <div style={{ backgroundColor: P.surface, borderRadius: '14px', border, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}>
                            {/* Header avec couleur du livreur */}
                            <div style={{ padding: '14px 18px', borderBottom: '1px solid ' + P.surfaceContainerLow, backgroundColor: colorMap[selectedLivreur.id] + '18', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                    <div style={{ width: '42px', height: '42px', borderRadius: '50%', backgroundColor: colorMap[selectedLivreur.id], display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '16px', fontWeight: 800, color: '#fff', border: '2px solid white', boxShadow: '0 2px 8px rgba(0,0,0,0.15)' }}>
                                        {selectedLivreur.users?.first_name?.[0]}
                                    </div>
                                    <div>
                                        <p style={{ margin: 0, fontSize: '15px', fontWeight: 700, color: P.onSurface }}>{selectedLivreur.users?.first_name} {selectedLivreur.users?.last_name}</p>
                                        <p style={{ margin: '2px 0 0 0', fontSize: '12px', color: P.outline }}>
                                            {selectedLivreur.vehicules?.brand} {selectedLivreur.vehicules?.type} · {selectedLivreur.vehicules?.plate_number}
                                        </p>
                                    </div>
                                </div>
                                <button onClick={() => setSelectedId(null)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: P.outline, padding: '4px' }}>
                                    <IconX style={{ width: '16px', height: '16px' }} />
                                </button>
                            </div>

                            <div style={{ padding: '16px 18px' }}>
                                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px', marginBottom: '16px' }}>
                                    {[
                                        { label: 'Vitesse', value: selectedPos.vitesse + ' km/h', color: colorMap[selectedLivreur.id] },
                                        { label: 'Latitude', value: selectedPos.lat.toFixed(5), color: P.onSurface },
                                        { label: 'Longitude', value: selectedPos.lng.toFixed(5), color: P.onSurface },
                                        { label: 'MAJ GPS', value: selectedPos.lastUpdate.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit', second: '2-digit' }), color: P.outline },
                                    ].map((s, i) => (
                                        <div key={i} style={{ padding: '10px 12px', backgroundColor: P.surfaceContainerLow, borderRadius: '10px', border: '1px solid ' + P.outlineVariant }}>
                                            <p style={{ margin: '0 0 3px 0', fontSize: '10px', color: P.outline, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em' }}>{s.label}</p>
                                            <p style={{ margin: 0, fontSize: '13px', fontWeight: 700, color: s.color }}>{s.value}</p>
                                        </div>
                                    ))}
                                </div>

                                {selectedLivraison && (
                                    <div style={{ padding: '12px 16px', backgroundColor: colorMap[selectedLivreur.id] + '12', borderRadius: '10px', border: '1px solid ' + colorMap[selectedLivreur.id] + '40', display: 'flex', alignItems: 'flex-start', gap: '12px' }}>
                                        <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: colorMap[selectedLivreur.id], flexShrink: 0, marginTop: '4px' }}></div>
                                        <div>
                                            <p style={{ margin: 0, fontSize: '12px', fontWeight: 600, color: P.onSurface }}>
                                                Livraison #{String(selectedLivraison.id).padStart(5,'0')} en cours
                                            </p>
                                            <p style={{ margin: '3px 0 0 0', fontSize: '12px', color: P.onSurfaceVariant }}>
                                                Destination : {selectedLivraison.delivery_address}
                                            </p>
                                            <p style={{ margin: '2px 0 0 0', fontSize: '11px', color: P.outline }}>
                                                Client : {selectedLivraison.customers?.users?.first_name} {selectedLivraison.customers?.users?.last_name} · {selectedLivraison.customers?.users?.phone}
                                            </p>
                                            {selectedPos?.destination && (
                                                <p style={{ margin: '4px 0 0 0', fontSize: '11px', color: colorMap[selectedLivreur.id], fontWeight: 600 }}>
                                                    → ETA : ~{Math.floor(8 + Math.random() * 12)} min · {selectedPos.destination.label}
                                                </p>
                                            )}
                                        </div>
                                    </div>
                                )}
                            </div>
                        </div>
                    )}

                    {/* Tableau livraisons en cours */}
                    {enCours.length > 0 && (
                        <div style={{ backgroundColor: P.surface, borderRadius: '14px', border, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}>
                            <div style={{ padding: '12px 16px', borderBottom: '1px solid ' + P.surfaceContainerLow, backgroundColor: P.surfaceContainerLow }}>
                                <p style={{ margin: 0, fontSize: '12px', fontWeight: 700, color: P.onSurface }}>Livraisons en cours ({enCours.length})</p>
                            </div>
                            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                                <thead>
                                    <tr>
                                        {['', 'ID', 'Client', 'Livreur', 'Adresse', 'Vitesse GPS'].map(h => (
                                            <th key={h} style={{ padding: '8px 12px', textAlign: 'left', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.07em', borderBottom: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, whiteSpace: 'nowrap' }}>{h}</th>
                                        ))}
                                    </tr>
                                </thead>
                                <tbody>
                                    {enCours.map(l => {
                                        const livreurId = l.delivery_persons?.id;
                                        const pos = livreurId ? positions[livreurId] : null;
                                        const color = livreurId ? colorMap[livreurId] : P.outline;
                                        return (
                                            <tr key={l.id}
                                                onClick={() => livreurId && setSelectedId(livreurId)}
                                                onMouseEnter={e => e.currentTarget.style.backgroundColor = P.surfaceContainerLow}
                                                onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}
                                                style={{ cursor: livreurId ? 'pointer' : 'default', transition: 'background 0.1s', borderBottom: '1px solid ' + P.surfaceContainerLow }}
                                            >
                                                <td style={{ padding: '10px 12px' }}>
                                                    <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: color }}></div>
                                                </td>
                                                <td style={{ padding: '10px 12px', fontWeight: 700, color: P.primary, fontSize: '12px' }}>#{String(l.id).padStart(5,'0')}</td>
                                                <td style={{ padding: '10px 12px', fontSize: '12px', color: P.onSurface }}>{l.customers?.users?.first_name} {l.customers?.users?.last_name}</td>
                                                <td style={{ padding: '10px 12px', fontSize: '12px', color: P.onSurface }}>{l.delivery_persons?.users?.first_name}</td>
                                                <td style={{ padding: '10px 12px', fontSize: '12px', color: P.onSurfaceVariant, maxWidth: '140px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{l.delivery_address}</td>
                                                <td style={{ padding: '10px 12px' }}>
                                                    {pos ? (
                                                        <span style={{ fontSize: '12px', fontWeight: 700, color: color }}>{pos.vitesse} km/h</span>
                                                    ) : (
                                                        <span style={{ fontSize: '11px', color: P.outlineVariant }}>—</span>
                                                    )}
                                                </td>
                                            </tr>
                                        );
                                    })}
                                </tbody>
                            </table>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}