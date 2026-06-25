import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import api from '../../services/api';
import { IconAlert, IconCheck, IconClock, IconSearch, IconPlus } from '../../components/Icons';

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

const statusConfig = {
    'En_attente': { bg: P.primaryFixed,    color: P.onPrimaryContainer, label: 'En attente' },
    'Approuvee':  { bg: '#c8e6c9',         color: '#1b5e20',            label: 'Approuve' },
    'Rejetee':    { bg: P.errorContainer,  color: P.onErrorContainer,   label: 'Rejete' },
};

const typeLabels = {
    'Retour_produit': 'Retour produit',
    'Rabais': 'Rabais',
    'Livraison_gratuite': 'Livr. gratuite',
    'Autre': 'Autre',
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

export default function LitigeList() {
    const [litiges, setLitiges] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [search, setSearch] = useState('');
    const [filterStatus, setFilterStatus] = useState('');

    useEffect(() => {
        api.get('/litiges')
            .then(res => setLitiges(res.data))
            .catch(() => setError('Impossible de charger les litiges.'))
            .finally(() => setLoading(false));
    }, []);

    const filtered = litiges.filter(l => {
        const matchStatus = !filterStatus || l.status === filterStatus;
        const matchSearch = !search || [l.reason, l.orders?.customers?.users?.first_name, l.orders?.customers?.users?.last_name, typeLabels[l.type]].some(v => v?.toLowerCase().includes(search.toLowerCase()));
        return matchStatus && matchSearch;
    });

    const stats = {
        total: litiges.length,
        en_attente: litiges.filter(l => l.status === 'En_attente').length,
        approuves: litiges.filter(l => l.status === 'Approuvee').length,
        rejetes: litiges.filter(l => l.status === 'Rejetee').length,
    };

    const thStyle = { padding: '9px 14px', textAlign: 'left', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em', borderBottom: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, whiteSpace: 'nowrap' };
    const tdStyle = { padding: '12px 14px', fontSize: '13px', color: P.onSurface, borderBottom: '1px solid ' + P.surfaceContainerLow };

    return (
        <div style={{ fontFamily: 'Poppins, sans-serif' }}>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '10px', marginBottom: '18px' }}>
                <KpiCard icon={IconAlert} label="Total litiges" value={stats.total} iconColor={P.primaryContainer} iconBg="rgba(201,149,46,0.15)" />
                <KpiCard icon={IconClock} label="En attente" value={stats.en_attente} iconColor={P.primaryContainer} iconBg="rgba(246,189,83,0.15)" />
                <KpiCard icon={IconCheck} label="Approuves" value={stats.approuves} iconColor="#81c784" iconBg="rgba(129,199,132,0.15)" />
                <KpiCard icon={IconAlert} label="Rejetes" value={stats.rejetes} iconColor="#ef9a9a" iconBg="rgba(239,154,154,0.15)" />
            </div>

            {error && <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>{error}</div>}

            <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>
                <div style={{ padding: '13px 16px', borderBottom: '1px solid ' + P.surfaceContainerLow, display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
                    <div style={{ position: 'relative', flex: 1, minWidth: '180px' }}>
                        <IconSearch style={{ position: 'absolute', left: '9px', top: '50%', transform: 'translateY(-50%)', width: '13px', height: '13px', color: P.outline }} />
                        <input type="text" placeholder="Rechercher litige, client, raison..." value={search} onChange={e => setSearch(e.target.value)}
                            style={{ width: '100%', padding: '8px 12px 8px 28px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', backgroundColor: P.surfaceContainerLow, boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none' }} />
                    </div>
                    <select value={filterStatus} onChange={e => setFilterStatus(e.target.value)}
                        style={{ padding: '8px 12px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, backgroundColor: P.surface, outline: 'none' }}>
                        <option value="">Tous les statuts</option>
                        <option value="En_attente">En attente</option>
                        <option value="Approuvee">Approuve</option>
                        <option value="Rejetee">Rejete</option>
                    </select>
                    <Link to="/litiges/create" style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '8px 16px', backgroundColor: P.primary, color: '#fff', borderRadius: '8px', textDecoration: 'none', fontSize: '12px', fontWeight: 600, whiteSpace: 'nowrap', boxShadow: '0 2px 8px rgba(125,87,0,0.25)' }}>
                        <IconPlus style={{ width: '13px', height: '13px' }} />
                        Nouveau litige
                    </Link>
                </div>

                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead><tr>
                        {['ID', 'Client', 'Type', 'Raison', 'Montant', 'Statut', 'Date', 'Action'].map(h => <th key={h} style={thStyle}>{h}</th>)}
                    </tr></thead>
                    <tbody>
                        {loading ? (
                            <tr><td colSpan={8} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>Chargement...</td></tr>
                        ) : filtered.length === 0 ? (
                            <tr><td colSpan={8} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>
                                Aucun litige enregistre.{' '}<Link to="/litiges/create" style={{ color: P.primary, fontWeight: 600 }}>Declarer</Link>
                            </td></tr>
                        ) : filtered.map(l => {
                            const sc = statusConfig[l.status] || { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, label: l.status };
                            return (
                                <tr key={l.id} onMouseEnter={e => e.currentTarget.style.backgroundColor = P.surfaceContainerLow} onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'} style={{ transition: 'background 0.1s' }}>
                                    <td style={{ ...tdStyle, fontWeight: 700, color: P.primary, fontSize: '12px' }}>#{l.id}</td>
                                    <td style={tdStyle}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '7px' }}>
                                            <div style={{ width: '26px', height: '26px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '10px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>
                                                {l.orders?.customers?.users?.first_name?.[0]}
                                            </div>
                                            <span style={{ fontSize: '13px' }}>{l.orders?.customers?.users?.first_name} {l.orders?.customers?.users?.last_name}</span>
                                        </div>
                                    </td>
                                    <td style={{ ...tdStyle, fontSize: '12px' }}>
                                        <span style={{ backgroundColor: P.surfaceContainerHigh, color: P.onSurfaceVariant, padding: '2px 7px', borderRadius: '4px', fontSize: '10px', fontWeight: 600 }}>{typeLabels[l.type] || l.type}</span>
                                    </td>
                                    <td style={{ ...tdStyle, color: P.onSurfaceVariant, maxWidth: '180px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', fontSize: '12px' }}>{l.reason}</td>
                                    <td style={{ ...tdStyle, fontWeight: 500, fontSize: '12px' }}>{l.amount ? Number(l.amount).toLocaleString('fr-FR') + ' FCFA' : '—'}</td>
                                    <td style={tdStyle}>
                                        <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '3px 8px', borderRadius: '5px', fontSize: '10px', fontWeight: 600 }}>{sc.label}</span>
                                    </td>
                                    <td style={{ ...tdStyle, color: P.outline, fontSize: '12px', whiteSpace: 'nowrap' }}>{l.created_at ? new Date(l.created_at).toLocaleDateString('fr-FR') : '—'}</td>
                                    <td style={tdStyle}>
                                        <Link to={'/litiges/' + l.id} style={{ padding: '4px 8px', borderRadius: '6px', backgroundColor: P.secondaryContainer, color: P.onSecondaryContainer, fontSize: '11px', fontWeight: 600, textDecoration: 'none' }}>Voir</Link>
                                    </td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>

                <div style={{ padding: '11px 16px', borderTop: '1px solid ' + P.surfaceContainerLow }}>
                    <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>Affichage de {filtered.length} sur {litiges.length} litiges</p>
                </div>
            </div>
        </div>
    );
}
