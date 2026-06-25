import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import api from '../services/api';
import { IconPackage, IconTruck, IconCheck, IconClock, IconAlert, IconPlus, IconChevronRight, IconArrowUp, IconUser } from '../components/Icons';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    primaryFixed: '#ffdea9', primaryFixedDim: '#f6bd53',
    onPrimaryContainer: '#483100',
    secondary: '#475e8b', secondaryContainer: '#b5ccff', onSecondaryContainer: '#3e5682',
    tertiary: '#20619e', tertiaryContainer: '#6aa1e3', onTertiaryContainer: '#003762',
    error: '#ba1a1a', errorContainer: '#ffdad6', onErrorContainer: '#93000a',
    surface: '#ffffff', background: '#f9f9f9',
    surfaceContainerLow: '#f3f3f3', surfaceContainer: '#eeeeee', surfaceContainerHigh: '#e8e8e8',
    inverseS: '#2f3131', inverseSOn: '#f1f1f1',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
    surfaceTint: '#7d5700',
};

function KpiCard({ icon: Icon, label, value, trend, iconColor, iconBg, accentColor }) {
    const isUp = trend >= 0;
    return (
        <div style={{ backgroundColor: P.inverseS, borderRadius: '14px', padding: '18px', position: 'relative', overflow: 'hidden' }}>
            <div style={{ position: 'absolute', top: '-30px', right: '-30px', width: '110px', height: '110px', borderRadius: '50%', backgroundColor: 'rgba(241,241,241,0.02)' }}></div>
            <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '14px' }}>
                <div style={{ width: '38px', height: '38px', borderRadius: '10px', backgroundColor: iconBg || 'rgba(201,149,46,0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                    <Icon style={{ width: '18px', height: '18px', color: iconColor || P.primaryContainer }} />
                </div>
                <span style={{ fontSize: '11px', fontWeight: 600, color: isUp ? '#4ade80' : '#f87171', backgroundColor: isUp ? 'rgba(74,222,128,0.1)' : 'rgba(248,113,113,0.1)', padding: '3px 7px', borderRadius: '999px' }}>
                    {isUp ? '▲' : '▼'} {Math.abs(trend)}%
                </span>
            </div>
            <p style={{ margin: 0, fontSize: '30px', fontWeight: 800, color: P.inverseSOn, letterSpacing: '-0.03em', lineHeight: 1 }}>{value}</p>
            <p style={{ margin: '7px 0 0 0', fontSize: '12px', color: 'rgba(241,241,241,0.4)', fontWeight: 500 }}>{label}</p>
        </div>
    );
}

export default function Dashboard() {
    const { user } = useAuth();
    const [stats, setStats] = useState({ total: 0, en_attente: 0, assignees: 0, livrees: 0, litiges: 0 });
    const [livraisons, setLivraisons] = useState([]);
    const [livreurs, setLivreurs] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        Promise.all([
            api.get('/livraisons').catch(() => ({ data: [] })),
            api.get('/livreurs?all=true').catch(() => ({ data: [] })),
            api.get('/litiges').catch(() => ({ data: [] })),
        ]).then(([livRes, lvRes, litRes]) => {
            const l = livRes.data || [];
            setLivraisons(l.slice(0, 6));
            setLivreurs((lvRes.data || []).slice(0, 5));
            setStats({ total: l.length, en_attente: l.filter(x => x.status === 'En_attente').length, assignees: l.filter(x => x.status === 'Assign_').length, livrees: l.filter(x => x.status === 'Livr_').length, litiges: litRes.data?.length || 0 });
        }).finally(() => setLoading(false));
    }, []);

    const statusChip = {
        'En_attente': { bg: P.primaryFixed, color: P.onPrimaryContainer, label: 'En attente' },
        'Assign_':    { bg: P.secondaryContainer, color: P.onSecondaryContainer, label: 'Assigne' },
        'En_cours':   { bg: P.tertiaryContainer, color: P.onTertiaryContainer, label: 'En cours' },
        'Livr_':      { bg: '#c8e6c9', color: '#1b5e20', label: 'Livre' },
        'Suspendu':   { bg: P.errorContainer, color: P.onErrorContainer, label: 'Suspendu' },
        'Annul_':     { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, label: 'Annule' },
    };

    const livreurDot = { 'Disponible': '#4caf50', 'En_livraison': P.primaryContainer, 'Suspendu': P.error, 'Indisponible': P.outline };

    const thStyle = { padding: '9px 14px', textAlign: 'left', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em', borderBottom: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow };
    const tdStyle = { padding: '12px 14px', fontSize: '13px', color: P.onSurface, borderBottom: '1px solid ' + P.surfaceContainerLow };

    return (
        <div style={{ fontFamily: 'Poppins, sans-serif' }}>

            {/* GREETING */}
            <div style={{ marginBottom: '20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                    <p style={{ margin: 0, fontSize: '19px', fontWeight: 700, color: P.onSurface }}>
                        Bonjour, <span style={{ color: P.primary }}>{user?.first_name}</span>
                    </p>
                    <p style={{ margin: '3px 0 0 0', fontSize: '12px', color: P.outline }}>
                        {new Date().toLocaleDateString('fr-FR', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
                    </p>
                </div>
                <Link to="/livraisons/create" style={{ display: 'inline-flex', alignItems: 'center', gap: '7px', padding: '9px 18px', backgroundColor: P.primary, color: '#fff', borderRadius: '10px', textDecoration: 'none', fontSize: '13px', fontWeight: 600, boxShadow: '0 4px 14px rgba(125,87,0,0.28)' }}>
                    <IconPlus style={{ width: '14px', height: '14px' }} />
                    Nouvelle livraison
                </Link>
            </div>

            {/* KPIs */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: '12px', marginBottom: '20px' }}>
                <KpiCard icon={IconPackage} label="Total livraisons" value={stats.total} trend={12.4} iconColor={P.primaryContainer} iconBg="rgba(201,149,46,0.15)" />
                <KpiCard icon={IconClock} label="En attente" value={stats.en_attente} trend={7.2} iconColor={P.primaryFixedDim} iconBg="rgba(246,189,83,0.15)" />
                <KpiCard icon={IconTruck} label="Assignees" value={stats.assignees} trend={12.4} iconColor="#6aa1e3" iconBg="rgba(106,161,227,0.15)" />
                <KpiCard icon={IconCheck} label="Livrees" value={stats.livrees} trend={20.8} iconColor="#81c784" iconBg="rgba(129,199,132,0.15)" />
                <KpiCard icon={IconAlert} label="Litiges" value={stats.litiges} trend={-6.3} iconColor="#ef9a9a" iconBg="rgba(239,154,154,0.15)" />
            </div>

            {/* GRID */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 300px', gap: '16px' }}>

                {/* TABLE */}
                <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>
                    <div style={{ padding: '14px 18px', borderBottom: '1px solid ' + P.surfaceContainerLow, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                        <div>
                            <p style={{ margin: 0, fontSize: '14px', fontWeight: 700, color: P.onSurface }}>Livraisons recentes</p>
                            <p style={{ margin: '2px 0 0 0', fontSize: '11px', color: P.outline }}>{livraisons.length} enregistrements</p>
                        </div>
                        <Link to="/livraisons" style={{ display: 'inline-flex', alignItems: 'center', gap: '3px', fontSize: '12px', fontWeight: 600, color: P.primary, textDecoration: 'none' }}>
                            Voir tout <IconArrowUp style={{ width: '11px', height: '11px' }} />
                        </Link>
                    </div>
                    <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                        <thead><tr>
                            <th style={thStyle}>ID</th>
                            <th style={thStyle}>Client</th>
                            <th style={thStyle}>Statut</th>
                            <th style={thStyle}>Livreur</th>
                            <th style={thStyle}>Date</th>
                            <th style={thStyle}></th>
                        </tr></thead>
                        <tbody>
                            {loading ? (
                                <tr><td colSpan={6} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>Chargement...</td></tr>
                            ) : livraisons.length === 0 ? (
                                <tr><td colSpan={6} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>
                                    Aucune livraison —{' '}<Link to="/livraisons/create" style={{ color: P.primary, fontWeight: 600 }}>Creer</Link>
                                </td></tr>
                            ) : livraisons.map(l => {
                                const sc = statusChip[l.status] || { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, label: l.status };
                                return (
                                    <tr key={l.id} onMouseEnter={e => e.currentTarget.style.backgroundColor = P.surfaceContainerLow} onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'} style={{ transition: 'background 0.1s' }}>
                                        <td style={{ ...tdStyle, fontWeight: 700, color: P.primary, fontSize: '12px' }}>#{String(l.id).padStart(5,'0')}</td>
                                        <td style={tdStyle}>
                                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                                <div style={{ width: '26px', height: '26px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '10px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>
                                                    {l.customers?.users?.first_name?.[0]}
                                                </div>
                                                <span style={{ fontSize: '13px' }}>{l.customers?.users?.first_name} {l.customers?.users?.last_name}</span>
                                            </div>
                                        </td>
                                        <td style={tdStyle}>
                                            <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '3px 8px', borderRadius: '5px', fontSize: '10px', fontWeight: 600 }}>{sc.label}</span>
                                        </td>
                                        <td style={{ ...tdStyle, color: P.onSurfaceVariant, fontSize: '12px' }}>
                                            {l.delivery_persons ? (
                                                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                                    <div style={{ width: '22px', height: '22px', borderRadius: '50%', backgroundColor: P.primaryContainer, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '9px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>
                                                        {l.delivery_persons?.users?.first_name?.[0]}
                                                    </div>
                                                    {l.delivery_persons?.users?.first_name}
                                                </div>
                                            ) : <span style={{ color: P.outlineVariant }}>—</span>}
                                        </td>
                                        <td style={{ ...tdStyle, color: P.outline, fontSize: '12px', whiteSpace: 'nowrap' }}>{l.creation_date ? new Date(l.creation_date).toLocaleDateString('fr-FR') : '—'}</td>
                                        <td style={tdStyle}>
                                            <Link to={'/livraisons/' + l.id} style={{ color: P.primary, textDecoration: 'none', display: 'flex' }}>
                                                <IconChevronRight style={{ width: '16px', height: '16px' }} />
                                            </Link>
                                        </td>
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                </div>

                {/* RIGHT COLUMN */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>

                    {/* QUICK ACTIONS */}
                    <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, padding: '16px', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>
                        <p style={{ margin: '0 0 12px 0', fontSize: '13px', fontWeight: 700, color: P.onSurface }}>Actions rapides</p>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                            {[
                                { label: 'Livraison', sub: 'Creer', to: '/livraisons/create', icon: IconPackage, iconColor: P.primaryContainer, iconBg: P.primaryFixed, hover: P.primaryFixed },
                                { label: 'Livreur', sub: 'Creer', to: '/livreurs/create', icon: IconTruck, iconColor: P.secondary, iconBg: P.secondaryContainer, hover: P.secondaryContainer },
                                { label: 'Livraisons', sub: 'Voir', to: '/livraisons', icon: IconCheck, iconColor: '#2e7d32', iconBg: '#c8e6c9', hover: '#c8e6c9' },
                                { label: 'Litige', sub: 'Declarer', to: '/litiges/create', icon: IconAlert, iconColor: P.error, iconBg: P.errorContainer, hover: P.errorContainer },
                            ].map((a, i) => {
                                const Icon = a.icon;
                                return (
                                    <Link key={i} to={a.to} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '8px', padding: '14px 8px', borderRadius: '10px', backgroundColor: P.surfaceContainerLow, textDecoration: 'none', transition: 'all 0.15s', border: '1px solid ' + P.outlineVariant }}
                                        onMouseEnter={e => { e.currentTarget.style.backgroundColor = a.hover; }}
                                        onMouseLeave={e => { e.currentTarget.style.backgroundColor = P.surfaceContainerLow; }}
                                    >
                                        <div style={{ width: '36px', height: '36px', borderRadius: '10px', backgroundColor: a.iconBg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                            <Icon style={{ width: '16px', height: '16px', color: a.iconColor }} />
                                        </div>
                                        <div style={{ textAlign: 'center' }}>
                                            <p style={{ margin: 0, fontSize: '10px', color: P.outline, fontWeight: 500 }}>{a.sub}</p>
                                            <p style={{ margin: 0, fontSize: '12px', fontWeight: 600, color: P.onSurface }}>{a.label}</p>
                                        </div>
                                    </Link>
                                );
                            })}
                        </div>
                    </div>

                    {/* LIVREURS */}
                    <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>
                        <div style={{ padding: '13px 16px', borderBottom: '1px solid ' + P.surfaceContainerLow, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                            <p style={{ margin: 0, fontSize: '13px', fontWeight: 700, color: P.onSurface }}>Livreurs</p>
                            <Link to="/livreurs" style={{ fontSize: '11px', fontWeight: 600, color: P.primary, textDecoration: 'none' }}>Voir tout</Link>
                        </div>
                        <div>
                            {loading ? (
                                <p style={{ textAlign: 'center', color: P.outline, fontSize: '13px', padding: '20px' }}>Chargement...</p>
                            ) : livreurs.length === 0 ? (
                                <p style={{ textAlign: 'center', color: P.outline, fontSize: '13px', padding: '20px' }}>Aucun livreur.</p>
                            ) : livreurs.map(l => (
                                <Link key={l.id} to={'/livreurs/' + l.id} style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '10px 16px', textDecoration: 'none', borderBottom: '1px solid ' + P.surfaceContainerLow, transition: 'background 0.1s' }}
                                    onMouseEnter={e => e.currentTarget.style.backgroundColor = P.surfaceContainerLow}
                                    onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}
                                >
                                    <div style={{ position: 'relative', flexShrink: 0 }}>
                                        <div style={{ width: '30px', height: '30px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '11px', fontWeight: 700, color: '#fff' }}>
                                            {l.users?.first_name?.[0]}
                                        </div>
                                        <div style={{ position: 'absolute', bottom: 0, right: 0, width: '8px', height: '8px', borderRadius: '50%', backgroundColor: livreurDot[l.status] || P.outline, border: '2px solid white' }}></div>
                                    </div>
                                    <div style={{ flex: 1, minWidth: 0 }}>
                                        <p style={{ margin: 0, fontSize: '12px', fontWeight: 600, color: P.onSurface, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                                            {l.users?.first_name} {l.users?.last_name}
                                        </p>
                                        <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>{l.zone_affectee || 'Sans zone'}</p>
                                    </div>
                                    <span style={{ fontSize: '10px', fontWeight: 600, color: livreurDot[l.status] || P.outline }}>
                                        {l.status?.replace('_', ' ')}
                                    </span>
                                </Link>
                            ))}
                        </div>
                    </div>

                </div>
            </div>
        </div>
    );
}
