import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import api from '../../services/api';
import { IconTruck, IconCheck, IconAlert, IconSearch, IconPlus, IconUser } from '../../components/Icons';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    primaryFixed: '#ffdea9', primaryFixedDim: '#f6bd53', onPrimaryContainer: '#483100',
    secondary: '#475e8b', secondaryContainer: '#b5ccff', onSecondaryContainer: '#3e5682',
    tertiary: '#20619e', tertiaryContainer: '#6aa1e3', onTertiaryContainer: '#003762',
    error: '#ba1a1a', errorContainer: '#ffdad6', onErrorContainer: '#93000a',
    surface: '#ffffff', background: '#f9f9f9',
    surfaceContainerLow: '#f3f3f3', surfaceContainer: '#eeeeee', surfaceContainerHigh: '#e8e8e8',
    inverseS: '#2f3131', inverseSOn: '#f1f1f1',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
};

const statusConfig = {
    'Disponible':   { bg: '#c8e6c9', color: '#1b5e20', dot: '#4caf50',   label: 'Disponible' },
    'En_livraison': { bg: P.primaryFixed, color: P.onPrimaryContainer, dot: P.primaryContainer, label: 'En livraison' },
    'Indisponible': { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, dot: P.outline, label: 'Indisponible' },
    'Suspendu':     { bg: P.errorContainer, color: P.onErrorContainer, dot: P.error, label: 'Suspendu' },
    'Hors_service': { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, dot: P.onSurfaceVariant, label: 'Hors service' },
};

function KpiCard({ icon: Icon, label, value, iconColor, iconBg }) {
    return (
        <div style={{ backgroundColor: P.inverseS, borderRadius: '12px', padding: '16px', display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '9px', backgroundColor: iconBg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Icon style={{ width: '17px', height: '17px', color: iconColor }} />
            </div>
            <div>
                <p style={{ margin: 0, fontSize: '22px', fontWeight: 800, color: P.inverseSOn, letterSpacing: '-0.02em', lineHeight: 1 }}>{value}</p>
                <p style={{ margin: '4px 0 0 0', fontSize: '11px', color: 'rgba(241,241,241,0.4)', fontWeight: 500 }}>{label}</p>
            </div>
        </div>
    );
}

export default function LivreurList() {
    const [livreurs, setLivreurs] = useState([]);
    const [loading, setLoading] = useState(true);
    const [actionMsg, setActionMsg] = useState('');
    const [error, setError] = useState('');
    const [search, setSearch] = useState('');
    const [filterStatus, setFilterStatus] = useState('');

    function charger() {
        api.get('/livreurs?all=true')
            .then(res => setLivreurs(res.data))
            .catch(() => setError('Impossible de charger les livreurs.'))
            .finally(() => setLoading(false));
    }

    useEffect(() => { charger(); }, []);

    async function handleSuspendre(id) {
        if (!window.confirm('Confirmer la suspension ?')) return;
        try { await api.post('/livreurs/' + id + '/suspendre'); setActionMsg('Livreur suspendu.'); charger(); }
        catch (err) { setError(err.response?.data?.message || 'Erreur.'); }
    }

    async function handleReactiver(id) {
        if (!window.confirm('Confirmer la reactivation ?')) return;
        try { await api.post('/livreurs/' + id + '/reactiver'); setActionMsg('Livreur reactive.'); charger(); }
        catch (err) { setError(err.response?.data?.message || 'Erreur.'); }
    }

    const filtered = livreurs.filter(l => {
        const matchStatus = !filterStatus || l.status === filterStatus;
        const matchSearch = !search || [l.users?.first_name, l.users?.last_name, l.users?.phone, l.zone_affectee, l.vehicules?.plate_number].some(v => v?.toLowerCase().includes(search.toLowerCase()));
        return matchStatus && matchSearch;
    });

    const stats = {
        total: livreurs.length,
        actifs: livreurs.filter(l => l.status === 'Disponible').length,
        en_livraison: livreurs.filter(l => l.status === 'En_livraison').length,
        inactifs: livreurs.filter(l => ['Suspendu','Hors_service'].includes(l.status)).length,
    };

    const thStyle = { padding: '9px 14px', textAlign: 'left', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em', borderBottom: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, whiteSpace: 'nowrap' };
    const tdStyle = { padding: '12px 14px', fontSize: '13px', color: P.onSurface, borderBottom: '1px solid ' + P.surfaceContainerLow };

    return (
        <div style={{ fontFamily: 'Poppins, sans-serif' }}>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '10px', marginBottom: '18px' }}>
                <KpiCard icon={IconUser} label="Total livreurs" value={stats.total} iconColor={P.primaryContainer} iconBg="rgba(201,149,46,0.15)" />
                <KpiCard icon={IconCheck} label="Disponibles" value={stats.actifs} iconColor="#81c784" iconBg="rgba(129,199,132,0.15)" />
                <KpiCard icon={IconTruck} label="En livraison" value={stats.en_livraison} iconColor="#6aa1e3" iconBg="rgba(106,161,227,0.15)" />
                <KpiCard icon={IconAlert} label="Inactifs" value={stats.inactifs} iconColor="#ef9a9a" iconBg="rgba(239,154,154,0.15)" />
            </div>

            {actionMsg && <div style={{ backgroundColor: '#c8e6c9', border: '1px solid #a5d6a7', color: '#1b5e20', padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>{actionMsg}</div>}
            {error && <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>{error}</div>}

            <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>
                <div style={{ padding: '13px 16px', borderBottom: '1px solid ' + P.surfaceContainerLow, display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
                    <div style={{ position: 'relative', flex: 1, minWidth: '180px' }}>
                        <IconSearch style={{ position: 'absolute', left: '9px', top: '50%', transform: 'translateY(-50%)', width: '13px', height: '13px', color: P.outline }} />
                        <input type="text" placeholder="Rechercher par nom, telephone, vehicule..." value={search} onChange={e => setSearch(e.target.value)}
                            style={{ width: '100%', padding: '8px 12px 8px 28px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', backgroundColor: P.surfaceContainerLow, boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none' }} />
                    </div>
                    <select value={filterStatus} onChange={e => setFilterStatus(e.target.value)}
                        style={{ padding: '8px 12px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, backgroundColor: P.surface, outline: 'none' }}>
                        <option value="">Tous les statuts</option>
                        <option value="Disponible">Disponible</option>
                        <option value="En_livraison">En livraison</option>
                        <option value="Indisponible">Indisponible</option>
                        <option value="Suspendu">Suspendu</option>
                        <option value="Hors_service">Hors service</option>
                    </select>
                    <Link to="/livreurs/create" style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '8px 16px', backgroundColor: P.primary, color: '#fff', borderRadius: '8px', textDecoration: 'none', fontSize: '12px', fontWeight: 600, whiteSpace: 'nowrap', boxShadow: '0 2px 8px rgba(125,87,0,0.25)' }}>
                        <IconPlus style={{ width: '13px', height: '13px' }} />
                        Nouveau livreur
                    </Link>
                </div>

                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead><tr>
                        {['Livreur', 'Contact', 'Vehicule', 'Zone', 'Statut', 'Actions'].map(h => <th key={h} style={thStyle}>{h}</th>)}
                    </tr></thead>
                    <tbody>
                        {loading ? (
                            <tr><td colSpan={6} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>Chargement...</td></tr>
                        ) : filtered.length === 0 ? (
                            <tr><td colSpan={6} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>
                                Aucun livreur.{' '}<Link to="/livreurs/create" style={{ color: P.primary, fontWeight: 600 }}>Creer</Link>
                            </td></tr>
                        ) : filtered.map(l => {
                            const sc = statusConfig[l.status] || { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, dot: P.outline, label: l.status };
                            return (
                                <tr key={l.id} onMouseEnter={e => e.currentTarget.style.backgroundColor = P.surfaceContainerLow} onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'} style={{ transition: 'background 0.1s' }}>
                                    <td style={tdStyle}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                            <div style={{ position: 'relative', flexShrink: 0 }}>
                                                <div style={{ width: '32px', height: '32px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '11px', fontWeight: 700, color: '#fff' }}>{l.users?.first_name?.[0]}</div>
                                                <div style={{ position: 'absolute', bottom: 0, right: 0, width: '8px', height: '8px', borderRadius: '50%', backgroundColor: sc.dot, border: '2px solid white' }}></div>
                                            </div>
                                            <div>
                                                <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onSurface }}>{l.users?.first_name} {l.users?.last_name}</p>
                                                <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>#{String(l.id).padStart(3,'0')}</p>
                                            </div>
                                        </div>
                                    </td>
                                    <td style={tdStyle}>
                                        <p style={{ margin: 0, fontSize: '13px', color: P.onSurface }}>{l.users?.phone}</p>
                                        <p style={{ margin: '2px 0 0 0', fontSize: '11px', color: P.outline }}>{l.users?.email}</p>
                                    </td>
                                    <td style={tdStyle}>
                                        {l.vehicules ? (
                                            <div>
                                                <p style={{ margin: 0, fontSize: '13px', color: P.onSurface }}>{l.vehicules.brand} {l.vehicules.type}</p>
                                                <p style={{ margin: '2px 0 0 0', fontSize: '11px', color: P.outline }}>{l.vehicules.plate_number}</p>
                                            </div>
                                        ) : <span style={{ color: P.outlineVariant }}>—</span>}
                                    </td>
                                    <td style={{ ...tdStyle, color: P.onSurfaceVariant, fontSize: '12px' }}>{l.zone_affectee || '—'}</td>
                                    <td style={tdStyle}>
                                        <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '3px 8px', borderRadius: '5px', fontSize: '10px', fontWeight: 600 }}>{sc.label}</span>
                                    </td>
                                    <td style={tdStyle}>
                                        <div style={{ display: 'flex', gap: '4px' }}>
                                            <Link to={'/livreurs/' + l.id} style={{ padding: '4px 8px', borderRadius: '6px', backgroundColor: P.secondaryContainer, color: P.onSecondaryContainer, fontSize: '11px', fontWeight: 600, textDecoration: 'none' }}>Voir</Link>
                                            <Link to={'/livreurs/' + l.id + '/edit'} style={{ padding: '4px 8px', borderRadius: '6px', backgroundColor: P.surfaceContainerHigh, color: P.onSurfaceVariant, fontSize: '11px', fontWeight: 600, textDecoration: 'none' }}>Modif.</Link>
                                            {l.status !== 'Suspendu' ? (
                                                <button onClick={() => handleSuspendre(l.id)} style={{ padding: '4px 8px', borderRadius: '6px', backgroundColor: P.primaryFixed, color: P.onPrimaryContainer, fontSize: '11px', fontWeight: 600, border: 'none', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>Suspendre</button>
                                            ) : (
                                                <button onClick={() => handleReactiver(l.id)} style={{ padding: '4px 8px', borderRadius: '6px', backgroundColor: '#c8e6c9', color: '#1b5e20', fontSize: '11px', fontWeight: 600, border: 'none', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>Reactiver</button>
                                            )}
                                        </div>
                                    </td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>

                <div style={{ padding: '11px 16px', borderTop: '1px solid ' + P.surfaceContainerLow }}>
                    <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>Affichage de {filtered.length} sur {livreurs.length} livreurs</p>
                </div>
            </div>
        </div>
    );
}
