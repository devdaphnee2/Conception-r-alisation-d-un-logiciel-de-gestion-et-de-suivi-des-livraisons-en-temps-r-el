import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import api from '../services/api';
import { IconPackage, IconTruck, IconAlert, IconCheck, IconClock, IconMap, IconUser } from '../components/Icons';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    primaryFixed: '#ffdea9', onPrimaryContainer: '#483100',
    secondary: '#475e8b', secondaryContainer: '#b5ccff', onSecondaryContainer: '#3e5682',
    tertiary: '#20619e', tertiaryContainer: '#6aa1e3', onTertiaryContainer: '#003762',
    error: '#ba1a1a', errorContainer: '#ffdad6', onErrorContainer: '#93000a',
    surface: '#ffffff', background: '#f9f9f9',
    surfaceContainerLow: '#f3f3f3', surfaceContainerHigh: '#e8e8e8',
    inverseS: '#2f3131', inverseSOn: '#f1f1f1',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
};

const statusLivraison = {
    'En_attente': { bg: P.primaryFixed, color: P.onPrimaryContainer, label: 'En attente' },
    'Assign_':    { bg: P.secondaryContainer, color: P.onSecondaryContainer, label: 'Assigne' },
    'En_cours':   { bg: P.tertiaryContainer, color: P.onTertiaryContainer, label: 'En cours' },
    'Livr_':      { bg: '#c8e6c9', color: '#1b5e20', label: 'Livre' },
    'Suspendu':   { bg: P.errorContainer, color: P.onErrorContainer, label: 'Suspendu' },
    'Annul_':     { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, label: 'Annule' },
};

function KpiCard({ icon: Icon, label, value, sub, iconColor, iconBg, to }) {
    const content = (
        <div style={{ backgroundColor: P.inverseS, borderRadius: '14px', padding: '18px', display: 'flex', alignItems: 'center', gap: '14px', cursor: to ? 'pointer' : 'default', transition: 'transform 0.15s', textDecoration: 'none' }}
            onMouseEnter={e => { if (to) e.currentTarget.style.transform = 'translateY(-2px)'; }}
            onMouseLeave={e => { if (to) e.currentTarget.style.transform = 'none'; }}>
            <div style={{ width: '42px', height: '42px', borderRadius: '12px', backgroundColor: iconBg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Icon style={{ width: '20px', height: '20px', color: iconColor }} />
            </div>
            <div>
                <p style={{ margin: 0, fontSize: '26px', fontWeight: 800, color: P.inverseSOn, lineHeight: 1 }}>{value}</p>
                <p style={{ margin: '4px 0 0 0', fontSize: '12px', color: 'rgba(241,241,241,0.5)', fontWeight: 500 }}>{label}</p>
                {sub && <p style={{ margin: '2px 0 0 0', fontSize: '10px', color: iconColor, fontWeight: 600 }}>{sub}</p>}
            </div>
        </div>
    );
    return to ? <Link to={to} style={{ textDecoration: 'none', display: 'block' }}>{content}</Link> : content;
}

export default function Dashboard() {
    const [livraisons, setLivraisons]   = useState([]);
    const [livreurs, setLivreurs]       = useState([]);
    const [litiges, setLitiges]         = useState([]);
    const [commandes, setCommandes]     = useState([]);
    const [recouvrements, setRecouvrements] = useState([]);
    const [profils, setProfils]         = useState([]);
    const [loading, setLoading]         = useState(true);

    useEffect(() => {
        Promise.all([
            api.get('/livraisons').catch(() => ({ data: [] })),
            api.get('/livreurs?all=true').catch(() => ({ data: [] })),
            api.get('/litiges').catch(() => ({ data: [] })),
            api.get('/orders').catch(() => ({ data: [] })),
            api.get('/recouvrements').catch(() => ({ data: [] })),
            api.get('/profils/en-attente').catch(() => ({ data: [] })),
        ]).then(([liv, lvr, lit, ord, rec, prof]) => {
            setLivraisons(liv.data || []);
            setLivreurs(lvr.data || []);
            setLitiges(lit.data || []);
            setCommandes(ord.data || []);
            setRecouvrements(rec.data || []);
            setProfils(prof.data || []);
        }).finally(() => setLoading(false));
    }, []);

    // Stats calculées
    const stats = {
        livraisons_total: livraisons.length,
        en_cours: livraisons.filter(l => l.status === 'En_cours').length,
        en_attente: livraisons.filter(l => l.status === 'En_attente').length,
        livrees: livraisons.filter(l => l.status === 'Livr_').length,
        suspendues: livraisons.filter(l => l.status === 'Suspendu').length,
        livreurs_actifs: livreurs.filter(l => l.status === 'En_livraison').length,
        livreurs_dispo: livreurs.filter(l => l.status === 'Disponible').length,
        litiges_ouverts: litiges.filter(l => l.status === 'En_attente').length,
        commandes_total: commandes.length,
        profils_attente: profils.length,
        dette_total: recouvrements.reduce((s, r) => s + Number(r.amount_to_collect || 0) - Number(r.amount_collected || 0), 0),
        ca_total: commandes.reduce((s, c) => s + Number(c.total_amount || 0), 0),
    };

    const recentLivraisons = [...livraisons].sort((a, b) => new Date(b.creation_date) - new Date(a.creation_date)).slice(0, 8);
    const alertes = [];
    if (stats.profils_attente > 0) alertes.push({ type: 'warning', msg: stats.profils_attente + ' profil(s) livreur en attente de validation', to: '/livreurs/profils' });
    if (stats.litiges_ouverts > 0) alertes.push({ type: 'error', msg: stats.litiges_ouverts + ' litige(s) non traite(s)', to: '/litiges' });
    if (stats.suspendues > 0) alertes.push({ type: 'error', msg: stats.suspendues + ' livraison(s) suspendue(s) — reassignation requise', to: '/livraisons' });
    if (stats.dette_total > 0) alertes.push({ type: 'warning', msg: stats.dette_total.toLocaleString('fr-FR') + ' FCFA de dettes livreurs non recouvrees', to: '/recouvrements' });

    const border = '1px solid ' + P.outlineVariant;

    if (loading) return (
        <div style={{ fontFamily: 'Poppins, sans-serif', display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}>
            <p style={{ color: P.outline, fontSize: '14px' }}>Chargement du tableau de bord...</p>
        </div>
    );

    return (
        <div style={{ fontFamily: 'Poppins, sans-serif' }}>

            {/* Alertes */}
            {alertes.length > 0 && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '20px' }}>
                    {alertes.map((a, i) => (
                        <Link key={i} to={a.to} style={{ textDecoration: 'none' }}>
                            <div style={{ backgroundColor: a.type === 'error' ? P.errorContainer : P.primaryFixed, border: '1px solid ' + (a.type === 'error' ? 'rgba(186,26,26,0.25)' : P.primaryContainer), borderRadius: '10px', padding: '10px 16px', display: 'flex', alignItems: 'center', gap: '10px' }}>
                                <IconAlert style={{ width: '14px', height: '14px', color: a.type === 'error' ? P.error : P.primary, flexShrink: 0 }} />
                                <p style={{ margin: 0, fontSize: '13px', color: a.type === 'error' ? P.onErrorContainer : P.onPrimaryContainer, fontWeight: 500 }}>{a.msg}</p>
                                <span style={{ marginLeft: 'auto', fontSize: '11px', color: a.type === 'error' ? P.error : P.primary, fontWeight: 600 }}>Voir →</span>
                            </div>
                        </Link>
                    ))}
                </div>
            )}

            {/* KPI row 1 */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px', marginBottom: '12px' }}>
                <KpiCard icon={IconPackage} label="Livraisons totales" value={stats.livraisons_total} sub={stats.en_cours + ' en cours'} iconColor={P.primaryContainer} iconBg="rgba(201,149,46,0.15)" to="/livraisons" />
                <KpiCard icon={IconTruck} label="Livreurs actifs" value={stats.livreurs_actifs} sub={stats.livreurs_dispo + ' disponibles'} iconColor="#81c784" iconBg="rgba(129,199,132,0.15)" to="/livreurs" />
                <KpiCard icon={IconAlert} label="Litiges ouverts" value={stats.litiges_ouverts} sub="A traiter" iconColor="#ef9a9a" iconBg="rgba(239,154,154,0.15)" to="/litiges" />
                <KpiCard icon={IconUser} label="Commandes" value={stats.commandes_total} sub={'CA: ' + (stats.ca_total / 1000).toFixed(0) + 'k FCFA'} iconColor="#6aa1e3" iconBg="rgba(106,161,227,0.15)" to="/commandes" />
            </div>

            {/* KPI row 2 */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px', marginBottom: '20px' }}>
                <KpiCard icon={IconCheck} label="Livrees" value={stats.livrees} iconColor="#81c784" iconBg="rgba(129,199,132,0.1)" />
                <KpiCard icon={IconClock} label="En attente" value={stats.en_attente} iconColor={P.primaryContainer} iconBg="rgba(201,149,46,0.1)" />
                <KpiCard icon={IconAlert} label="Suspendues" value={stats.suspendues} iconColor="#ef9a9a" iconBg="rgba(239,154,154,0.1)" />
                <KpiCard icon={IconUser} label="Profils en attente" value={stats.profils_attente} iconColor={P.primaryContainer} iconBg="rgba(201,149,46,0.1)" to="/livreurs/profils" />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 340px', gap: '16px' }}>

                {/* Livraisons récentes */}
                <div style={{ backgroundColor: P.surface, borderRadius: '14px', border, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>
                    <div style={{ padding: '14px 18px', borderBottom: '1px solid ' + P.surfaceContainerLow, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                        <p style={{ margin: 0, fontSize: '14px', fontWeight: 700, color: P.onSurface }}>Livraisons recentes</p>
                        <Link to="/livraisons" style={{ fontSize: '12px', color: P.primary, fontWeight: 600, textDecoration: 'none' }}>Voir toutes →</Link>
                    </div>
                    <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                        <thead><tr>
                            {['ID', 'Client', 'Livreur', 'Statut', 'Date'].map(h => (
                                <th key={h} style={{ padding: '8px 14px', textAlign: 'left', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em', borderBottom: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow }}>{h}</th>
                            ))}
                        </tr></thead>
                        <tbody>
                            {recentLivraisons.length === 0 ? (
                                <tr><td colSpan={5} style={{ padding: '30px', textAlign: 'center', color: P.outline, fontSize: '13px' }}>Aucune livraison.</td></tr>
                            ) : recentLivraisons.map(l => {
                                const sc = statusLivraison[l.status] || { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, label: l.status };
                                return (
                                    <tr key={l.id}
                                        onMouseEnter={e => e.currentTarget.style.backgroundColor = P.surfaceContainerLow}
                                        onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}
                                        style={{ transition: 'background 0.1s', cursor: 'pointer' }}
                                        onClick={() => window.location.href = '/livraisons/' + l.id}
                                    >
                                        <td style={{ padding: '11px 14px', fontWeight: 700, color: P.primary, fontSize: '12px' }}>#{String(l.id).padStart(5,'0')}</td>
                                        <td style={{ padding: '11px 14px', fontSize: '12px', color: P.onSurface, borderBottom: '1px solid ' + P.surfaceContainerLow }}>
                                            {l.customers?.users?.first_name} {l.customers?.users?.last_name}
                                        </td>
                                        <td style={{ padding: '11px 14px', fontSize: '12px', color: P.onSurfaceVariant, borderBottom: '1px solid ' + P.surfaceContainerLow }}>
                                            {l.delivery_persons?.users?.first_name || '—'}
                                        </td>
                                        <td style={{ padding: '11px 14px', borderBottom: '1px solid ' + P.surfaceContainerLow }}>
                                            <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '2px 8px', borderRadius: '4px', fontSize: '10px', fontWeight: 600 }}>{sc.label}</span>
                                        </td>
                                        <td style={{ padding: '11px 14px', fontSize: '11px', color: P.outline, borderBottom: '1px solid ' + P.surfaceContainerLow, whiteSpace: 'nowrap' }}>
                                            {l.creation_date ? new Date(l.creation_date).toLocaleDateString('fr-FR') : '—'}
                                        </td>
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                </div>

                {/* Colonne droite */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>

                    {/* Livreurs actifs */}
                    <div style={{ backgroundColor: P.surface, borderRadius: '14px', border, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>
                        <div style={{ padding: '13px 16px', borderBottom: '1px solid ' + P.surfaceContainerLow, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                            <p style={{ margin: 0, fontSize: '13px', fontWeight: 700, color: P.onSurface }}>Livreurs ({livreurs.length})</p>
                            <Link to="/livreurs" style={{ fontSize: '11px', color: P.primary, fontWeight: 600, textDecoration: 'none' }}>Voir tous →</Link>
                        </div>
                        {livreurs.slice(0, 6).map(l => {
                            const dot = l.status === 'En_livraison' ? P.primaryContainer : l.status === 'Disponible' ? '#4caf50' : P.outline;
                            return (
                                <Link key={l.id} to={'/livreurs/' + l.id} style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '10px 16px', borderBottom: '1px solid ' + P.surfaceContainerLow, textDecoration: 'none' }}
                                    onMouseEnter={e => e.currentTarget.style.backgroundColor = P.surfaceContainerLow}
                                    onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}
                                >
                                    <div style={{ width: '30px', height: '30px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '11px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>
                                        {l.users?.first_name?.[0]}
                                    </div>
                                    <div style={{ flex: 1, minWidth: 0 }}>
                                        <p style={{ margin: 0, fontSize: '12px', fontWeight: 600, color: P.onSurface }}>{l.users?.first_name} {l.users?.last_name}</p>
                                        <p style={{ margin: 0, fontSize: '10px', color: P.outline }}>{l.zone_affectee || 'Sans zone'}</p>
                                    </div>
                                    <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: dot, flexShrink: 0 }}></div>
                                </Link>
                            );
                        })}
                    </div>

                    {/* Recouvrements */}
                    {stats.dette_total > 0 && (
                        <div style={{ backgroundColor: P.errorContainer, borderRadius: '14px', border: '1px solid rgba(186,26,26,0.2)', padding: '16px', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>
                            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '10px' }}>
                                <p style={{ margin: 0, fontSize: '13px', fontWeight: 700, color: P.onErrorContainer }}>Dettes livreurs</p>
                                <Link to="/recouvrements" style={{ fontSize: '11px', color: P.error, fontWeight: 600, textDecoration: 'none' }}>Gerer →</Link>
                            </div>
                            <p style={{ margin: 0, fontSize: '24px', fontWeight: 800, color: P.error }}>{stats.dette_total.toLocaleString('fr-FR')} FCFA</p>
                            <p style={{ margin: '4px 0 0 0', fontSize: '11px', color: P.onErrorContainer }}>a recouvrer aupres de {recouvrements.filter(r => Number(r.amount_collected || 0) < Number(r.amount_to_collect || 0)).length} livreur(s)</p>
                        </div>
                    )}

                    {/* Accès rapides */}
                    <div style={{ backgroundColor: P.surface, borderRadius: '14px', border, padding: '16px', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>
                        <p style={{ margin: '0 0 12px 0', fontSize: '13px', fontWeight: 700, color: P.onSurface }}>Actions rapides</p>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                            {[
                                { label: 'Nouvelle livraison', to: '/livraisons/create', bg: P.primary, color: '#fff' },
                                { label: 'Tracking GPS', to: '/tracking', bg: P.inverseS, color: P.inverseSOn },
                                { label: 'Nouveau litige', to: '/litiges/create', bg: P.errorContainer, color: P.onErrorContainer },
                                { label: 'Profils a valider', to: '/livreurs/profils', bg: P.primaryFixed, color: P.onPrimaryContainer },
                            ].map(a => (
                                <Link key={a.to} to={a.to} style={{ padding: '10px 12px', borderRadius: '10px', backgroundColor: a.bg, color: a.color, fontSize: '12px', fontWeight: 600, textDecoration: 'none', textAlign: 'center', display: 'block', transition: 'opacity 0.15s' }}
                                    onMouseEnter={e => e.currentTarget.style.opacity = '0.85'}
                                    onMouseLeave={e => e.currentTarget.style.opacity = '1'}
                                >
                                    {a.label}
                                </Link>
                            ))}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}