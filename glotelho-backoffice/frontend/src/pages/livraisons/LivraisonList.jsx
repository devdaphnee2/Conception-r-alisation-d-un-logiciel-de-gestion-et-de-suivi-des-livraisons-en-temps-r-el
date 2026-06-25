import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import api from '../../services/api';
import { IconPackage, IconClock, IconTruck, IconCheck, IconAlert, IconSearch, IconPlus } from '../../components/Icons';

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

const statusChip = {
    'En_attente': { bg: P.primaryFixed,       color: P.onPrimaryContainer,    label: 'En attente' },
    'Assign_':    { bg: P.secondaryContainer,  color: P.onSecondaryContainer,  label: 'Assigne' },
    'En_cours':   { bg: P.tertiaryContainer,   color: P.onTertiaryContainer,   label: 'En cours' },
    'Livr_':      { bg: '#c8e6c9',             color: '#1b5e20',               label: 'Livre' },
    'Suspendu':   { bg: P.errorContainer,      color: P.onErrorContainer,      label: 'Suspendu' },
    'Annul_':     { bg: P.surfaceContainerHigh,color: P.onSurfaceVariant,      label: 'Annule' },
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

export default function LivraisonList() {
    const [livraisons, setLivraisons] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [actionMsg, setActionMsg] = useState('');
    const [filterStatus, setFilterStatus] = useState('');
    const [search, setSearch] = useState('');

    function charger() {
        api.get('/livraisons')
            .then(res => setLivraisons(res.data))
            .catch(() => setError('Impossible de charger les livraisons.'))
            .finally(() => setLoading(false));
    }

    useEffect(() => { charger(); }, []);

    async function handleSuspendre(id) {
        const reason = window.prompt('Raison de la suspension :');
        if (!reason) return;
        try {
            await api.post('/livraisons/' + id + '/suspendre', { suspension_reason: reason });
            setActionMsg('Livraison suspendue.');
            charger();
        } catch (err) { setError(err.response?.data?.message || 'Erreur.'); }
    }

    async function handleAnnuler(id) {
        if (!window.confirm('Confirmer l\'annulation ?')) return;
        try {
            await api.post('/livraisons/' + id + '/annuler');
            setActionMsg('Livraison annulee.');
            charger();
        } catch (err) { setError(err.response?.data?.message || 'Erreur.'); }
    }

    const filtered = livraisons.filter(l => {
        const matchStatus = !filterStatus || l.status === filterStatus;
        const matchSearch = !search || [l.delivery_address, l.customers?.users?.first_name, l.customers?.users?.last_name, l.delivery_persons?.users?.first_name, '#' + l.id].some(v => v?.toLowerCase().includes(search.toLowerCase()));
        return matchStatus && matchSearch;
    });

    const stats = {
        total: livraisons.length,
        en_attente: livraisons.filter(l => l.status === 'En_attente').length,
        assignees: livraisons.filter(l => l.status === 'Assign_').length,
        livrees: livraisons.filter(l => l.status === 'Livr_').length,
        exceptions: livraisons.filter(l => ['Suspendu', 'Annul_'].includes(l.status)).length,
    };

    const thStyle = { padding: '9px 14px', textAlign: 'left', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em', borderBottom: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, whiteSpace: 'nowrap' };
    const tdStyle = { padding: '12px 14px', fontSize: '13px', color: P.onSurface, borderBottom: '1px solid ' + P.surfaceContainerLow };

    return (
        <div style={{ fontFamily: 'Poppins, sans-serif' }}>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: '10px', marginBottom: '18px' }}>
                <KpiCard icon={IconPackage} label="Total" value={stats.total} iconColor={P.primaryContainer} iconBg="rgba(201,149,46,0.15)" />
                <KpiCard icon={IconClock} label="En attente" value={stats.en_attente} iconColor={P.primaryFixedDim} iconBg="rgba(246,189,83,0.15)" />
                <KpiCard icon={IconTruck} label="Assignees" value={stats.assignees} iconColor="#6aa1e3" iconBg="rgba(106,161,227,0.15)" />
                <KpiCard icon={IconCheck} label="Livrees" value={stats.livrees} iconColor="#81c784" iconBg="rgba(129,199,132,0.15)" />
                <KpiCard icon={IconAlert} label="Exceptions" value={stats.exceptions} iconColor="#ef9a9a" iconBg="rgba(239,154,154,0.15)" />
            </div>

            {actionMsg && <div style={{ backgroundColor: '#c8e6c9', border: '1px solid #a5d6a7', color: '#1b5e20', padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>{actionMsg}</div>}
            {error && <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>{error}</div>}

            <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>

                <div style={{ padding: '13px 16px', borderBottom: '1px solid ' + P.surfaceContainerLow, display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
                    <div style={{ position: 'relative', flex: 1, minWidth: '180px' }}>
                        <IconSearch style={{ position: 'absolute', left: '9px', top: '50%', transform: 'translateY(-50%)', width: '13px', height: '13px', color: P.outline }} />
                        <input type="text" placeholder="Rechercher livraison, client, adresse..." value={search} onChange={e => setSearch(e.target.value)}
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
                    <Link to="/livraisons/create" style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '8px 16px', backgroundColor: P.primary, color: '#fff', borderRadius: '8px', textDecoration: 'none', fontSize: '12px', fontWeight: 600, whiteSpace: 'nowrap', boxShadow: '0 2px 8px rgba(125,87,0,0.25)' }}>
                        <IconPlus style={{ width: '13px', height: '13px' }} />
                        Nouvelle livraison
                    </Link>
                </div>

                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead><tr>
                        {['ID', 'Client', 'Livreur', 'Statut', 'Adresse', 'Date', 'Actions'].map(h => <th key={h} style={thStyle}>{h}</th>)}
                    </tr></thead>
                    <tbody>
                        {loading ? (
                            <tr><td colSpan={7} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>Chargement...</td></tr>
                        ) : filtered.length === 0 ? (
                            <tr><td colSpan={7} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>
                                Aucune livraison.{' '}<Link to="/livraisons/create" style={{ color: P.primary, fontWeight: 600 }}>Creer</Link>
                            </td></tr>
                        ) : filtered.map(l => {
                            const sc = statusChip[l.status] || { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, label: l.status };
                            return (
                                <tr key={l.id} onMouseEnter={e => e.currentTarget.style.backgroundColor = P.surfaceContainerLow} onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'} style={{ transition: 'background 0.1s' }}>
                                    <td style={{ ...tdStyle, fontWeight: 700, color: P.primary, fontSize: '12px' }}>#{String(l.id).padStart(5,'0')}</td>
                                    <td style={tdStyle}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '7px' }}>
                                            <div style={{ width: '26px', height: '26px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '10px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>{l.customers?.users?.first_name?.[0]}</div>
                                            <span>{l.customers?.users?.first_name} {l.customers?.users?.last_name}</span>
                                        </div>
                                    </td>
                                    <td style={tdStyle}>
                                        {l.delivery_persons ? (
                                            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                                <div style={{ width: '22px', height: '22px', borderRadius: '50%', backgroundColor: P.primaryContainer, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '9px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>{l.delivery_persons?.users?.first_name?.[0]}</div>
                                                <span style={{ fontSize: '12px' }}>{l.delivery_persons?.users?.first_name}</span>
                                            </div>
                                        ) : <span style={{ color: P.outlineVariant, fontSize: '12px' }}>Non assigne</span>}
                                    </td>
                                    <td style={tdStyle}>
                                        <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '3px 8px', borderRadius: '5px', fontSize: '10px', fontWeight: 600 }}>{sc.label}</span>
                                    </td>
                                    <td style={{ ...tdStyle, color: P.onSurfaceVariant, maxWidth: '160px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', fontSize: '12px' }}>{l.delivery_address}</td>
                                    <td style={{ ...tdStyle, color: P.outline, fontSize: '12px', whiteSpace: 'nowrap' }}>{l.creation_date ? new Date(l.creation_date).toLocaleDateString('fr-FR') : '—'}</td>
                                    <td style={tdStyle}>
                                        <div style={{ display: 'flex', gap: '4px', flexWrap: 'wrap' }}>
                                            <Link to={'/livraisons/' + l.id} style={{ padding: '4px 8px', borderRadius: '6px', backgroundColor: P.secondaryContainer, color: P.onSecondaryContainer, fontSize: '11px', fontWeight: 600, textDecoration: 'none' }}>Voir</Link>
                                            {!['Livr_','Annul_'].includes(l.status) && <Link to={'/livraisons/' + l.id + '/edit'} style={{ padding: '4px 8px', borderRadius: '6px', backgroundColor: P.surfaceContainerHigh, color: P.onSurfaceVariant, fontSize: '11px', fontWeight: 600, textDecoration: 'none' }}>Modif.</Link>}
                                            {['Assign_','En_cours'].includes(l.status) && <button onClick={() => handleSuspendre(l.id)} style={{ padding: '4px 8px', borderRadius: '6px', backgroundColor: P.primaryFixed, color: P.onPrimaryContainer, fontSize: '11px', fontWeight: 600, border: 'none', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>Suspendre</button>}
                                            {['En_attente','Suspendu'].includes(l.status) && <button onClick={() => handleAnnuler(l.id)} style={{ padding: '4px 8px', borderRadius: '6px', backgroundColor: P.errorContainer, color: P.onErrorContainer, fontSize: '11px', fontWeight: 600, border: 'none', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>Annuler</button>}
                                        </div>
                                    </td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>

                <div style={{ padding: '11px 16px', borderTop: '1px solid ' + P.surfaceContainerLow, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>Affichage de {filtered.length} sur {livraisons.length} livraisons</p>
                </div>
            </div>
        </div>
    );
}
