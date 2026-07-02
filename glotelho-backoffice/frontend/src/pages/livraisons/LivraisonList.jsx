import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import api from '../../services/api';
import { IconPackage, IconSearch, IconCheck, IconClock, IconAlert, IconTruck } from '../../components/Icons';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    primaryFixed: '#ffdea9', onPrimaryContainer: '#483100',
    secondary: '#475e8b', secondaryContainer: '#b5ccff', onSecondaryContainer: '#3e5682',
    tertiary: '#20619e', tertiaryContainer: '#6aa1e3', onTertiaryContainer: '#003762',
    error: '#ba1a1a', errorContainer: '#ffdad6', onErrorContainer: '#93000a',
    surface: '#ffffff', surfaceContainerLow: '#f3f3f3', surfaceContainerHigh: '#e8e8e8',
    inverseS: '#2f3131', inverseSOn: '#f1f1f1',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
};

const statusConfig = {
    'En_attente': { bg: P.primaryFixed,       color: P.onPrimaryContainer,   label: 'En attente' },
    'Assign_':    { bg: P.secondaryContainer,  color: P.onSecondaryContainer, label: 'Assigne' },
    'En_cours':   { bg: P.tertiaryContainer,   color: P.onTertiaryContainer,  label: 'En cours' },
    'Livr_':      { bg: '#c8e6c9',             color: '#1b5e20',              label: 'Livre' },
    'Suspendu':   { bg: P.errorContainer,      color: P.onErrorContainer,     label: 'Suspendu' },
    'Annul_':     { bg: P.surfaceContainerHigh,color: P.onSurfaceVariant,     label: 'Annule' },
};

function KpiCard({ icon: Icon, label, value, iconColor, iconBg }) {
    return (
        <div style={{ backgroundColor: P.inverseS, borderRadius: '12px', padding: '16px', display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '9px', backgroundColor: iconBg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Icon style={{ width: '17px', height: '17px', color: iconColor }} />
            </div>
            <div>
                <p style={{ margin: 0, fontSize: '22px', fontWeight: 800, color: P.inverseSOn, lineHeight: 1 }}>{value}</p>
                <p style={{ margin: '4px 0 0 0', fontSize: '11px', color: 'rgba(241,241,241,0.4)', fontWeight: 500 }}>{label}</p>
            </div>
        </div>
    );
}

export default function LivraisonList() {
    const [livraisons, setLivraisons] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [filterStatus, setFilterStatus] = useState('');
    const [error, setError] = useState('');

    useEffect(() => {
        api.get('/livraisons')
            .then(res => setLivraisons(res.data))
            .catch(() => setError('Impossible de charger les livraisons.'))
            .finally(() => setLoading(false));
    }, []);

    const filtered = livraisons.filter(l => {
        const matchStatus = !filterStatus || l.status === filterStatus;
        const matchSearch = !search || [
            l.customers?.users?.first_name, l.customers?.users?.last_name,
            l.delivery_persons?.users?.first_name, l.delivery_address, '#' + l.id,
        ].some(v => v?.toLowerCase().includes(search.toLowerCase()));
        return matchStatus && matchSearch;
    });

    const stats = {
        total: livraisons.length,
        en_cours: livraisons.filter(l => l.status === 'En_cours').length,
        livrees: livraisons.filter(l => l.status === 'Livr_').length,
        suspendues: livraisons.filter(l => l.status === 'Suspendu').length,
        en_attente: livraisons.filter(l => l.status === 'En_attente').length,
    };

    const thStyle = { padding: '9px 14px', textAlign: 'left', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em', borderBottom: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, whiteSpace: 'nowrap' };
    const tdStyle = { padding: '12px 14px', fontSize: '13px', color: P.onSurface, borderBottom: '1px solid ' + P.surfaceContainerLow };

    return (
        <div style={{ fontFamily: 'Poppins, sans-serif' }}>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: '10px', marginBottom: '18px' }}>
                <KpiCard icon={IconPackage} label="Total"        value={stats.total}       iconColor={P.primaryContainer} iconBg="rgba(201,149,46,0.15)" />
                <KpiCard icon={IconClock}   label="En attente"   value={stats.en_attente}  iconColor={P.primaryContainer} iconBg="rgba(201,149,46,0.1)" />
                <KpiCard icon={IconTruck}   label="En cours"     value={stats.en_cours}    iconColor="#6aa1e3"            iconBg="rgba(106,161,227,0.15)" />
                <KpiCard icon={IconCheck}   label="Livrees"      value={stats.livrees}     iconColor="#81c784"            iconBg="rgba(129,199,132,0.15)" />
                <KpiCard icon={IconAlert}   label="Suspendues"   value={stats.suspendues}  iconColor="#ef9a9a"            iconBg="rgba(239,154,154,0.15)" />
            </div>

            {error && <div style={{ backgroundColor: P.errorContainer, color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px' }}>{error}</div>}

            <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>
                <div style={{ padding: '13px 16px', borderBottom: '1px solid ' + P.surfaceContainerLow, display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
                    <div style={{ position: 'relative', flex: 1, minWidth: '200px' }}>
                        <IconSearch style={{ position: 'absolute', left: '9px', top: '50%', transform: 'translateY(-50%)', width: '13px', height: '13px', color: P.outline }} />
                        <input type="text" placeholder="Rechercher par client, livreur, adresse..." value={search} onChange={e => setSearch(e.target.value)}
                            style={{ width: '100%', padding: '8px 12px 8px 28px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', backgroundColor: P.surfaceContainerLow, boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none' }} />
                    </div>
                    <select value={filterStatus} onChange={e => setFilterStatus(e.target.value)}
                        style={{ padding: '8px 12px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, backgroundColor: P.surface, outline: 'none' }}>
                        <option value="">Tous les statuts</option>
                        <option value="En_attente">En attente</option>
                        <option value="Assign_">Assigne</option>
                        <option value="En_cours">En cours</option>
                        <option value="Livr_">Livre</option>
                        <option value="Suspendu">Suspendu</option>
                        <option value="Annul_">Annule</option>
                    </select>
                    <Link to="/livraisons/create"
                        style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '8px 16px', backgroundColor: P.primary, color: '#fff', borderRadius: '8px', textDecoration: 'none', fontSize: '12px', fontWeight: 600, whiteSpace: 'nowrap', boxShadow: '0 2px 8px rgba(125,87,0,0.2)' }}>
                        <IconPackage style={{ width: '13px', height: '13px' }} />
                        Nouvelle livraison
                    </Link>
                </div>

                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead><tr>
                        {['ID', 'Client', 'Livreur', 'Adresse', 'Montant', 'Statut', 'Date', ''].map(h => (
                            <th key={h} style={thStyle}>{h}</th>
                        ))}
                    </tr></thead>
                    <tbody>
                        {loading ? (
                            <tr><td colSpan={8} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>Chargement...</td></tr>
                        ) : filtered.length === 0 ? (
                            <tr><td colSpan={8} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>Aucune livraison trouvee.</td></tr>
                        ) : filtered.map(l => {
                            const sc = statusConfig[l.status] || { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, label: l.status };
                            return (
                                <tr key={l.id}
                                    onMouseEnter={e => e.currentTarget.style.backgroundColor = P.surfaceContainerLow}
                                    onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}
                                    style={{ transition: 'background 0.1s', cursor: 'pointer' }}
                                    onClick={() => window.location.href = '/livraisons/' + l.id}
                                >
                                    <td style={{ ...tdStyle, fontWeight: 700, color: P.primary }}>#{String(l.id).padStart(5,'0')}</td>
                                    <td style={tdStyle}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                            <div style={{ width: '26px', height: '26px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '10px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>
                                                {l.customers?.users?.first_name?.[0]}
                                            </div>
                                            <div>
                                                <p style={{ margin: 0, fontSize: '12px', fontWeight: 500 }}>{l.customers?.users?.first_name} {l.customers?.users?.last_name}</p>
                                                <p style={{ margin: 0, fontSize: '10px', color: P.outline }}>{l.customers?.users?.phone}</p>
                                            </div>
                                        </div>
                                    </td>
                                    <td style={{ ...tdStyle, fontSize: '12px' }}>{l.delivery_persons?.users?.first_name || <span style={{ color: P.outlineVariant, fontStyle: 'italic' }}>Non assigne</span>}</td>
                                    <td style={{ ...tdStyle, color: P.onSurfaceVariant, maxWidth: '150px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', fontSize: '12px' }}>{l.delivery_address}</td>
                                    <td style={{ ...tdStyle, fontWeight: 700, color: P.primary, whiteSpace: 'nowrap', fontSize: '12px' }}>
                                        {l.amount_to_collect ? Number(l.amount_to_collect).toLocaleString('fr-FR') + ' F' : '—'}
                                    </td>
                                    <td style={tdStyle}>
                                        <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '3px 8px', borderRadius: '5px', fontSize: '10px', fontWeight: 600 }}>{sc.label}</span>
                                    </td>
                                    <td style={{ ...tdStyle, color: P.outline, fontSize: '11px', whiteSpace: 'nowrap' }}>
                                        {l.creation_date ? new Date(l.creation_date).toLocaleDateString('fr-FR') : '—'}
                                    </td>
                                    <td style={tdStyle} onClick={e => e.stopPropagation()}>
                                        <Link to={'/livraisons/' + l.id} style={{ color: P.primary, fontWeight: 600, textDecoration: 'none', fontSize: '12px' }}>Voir</Link>
                                    </td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>

                <div style={{ padding: '11px 16px', borderTop: '1px solid ' + P.surfaceContainerLow }}>
                    <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>{filtered.length} livraison{filtered.length > 1 ? 's' : ''} affichee{filtered.length > 1 ? 's' : ''}</p>
                </div>
            </div>
        </div>
    );
}