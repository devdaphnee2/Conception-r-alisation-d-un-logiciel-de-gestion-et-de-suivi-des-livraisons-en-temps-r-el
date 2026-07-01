import { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';
import { IconTruck, IconCheck, IconClock, IconAlert, IconX } from '../../components/Icons';

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
    'En_attente': { bg: P.primaryFixed,       color: P.onPrimaryContainer,   label: 'En attente' },
    'Assign_':    { bg: P.secondaryContainer,  color: P.onSecondaryContainer, label: 'Assigne' },
    'En_cours':   { bg: P.tertiaryContainer,   color: P.onTertiaryContainer,  label: 'En cours' },
    'Livr_':      { bg: '#c8e6c9',             color: '#1b5e20',              label: 'Livre' },
    'Suspendu':   { bg: P.errorContainer,      color: P.onErrorContainer,     label: 'Suspendu' },
    'Annul_':     { bg: P.surfaceContainerHigh,color: P.onSurfaceVariant,     label: 'Annule' },
};

const statusLivreur = {
    'Disponible':   { dot: '#4caf50', bg: '#c8e6c9', color: '#1b5e20',            label: 'Disponible' },
    'En_livraison': { dot: P.primaryContainer, bg: P.primaryFixed, color: P.onPrimaryContainer, label: 'En livraison' },
    'Suspendu':     { dot: P.error, bg: P.errorContainer, color: P.onErrorContainer, label: 'Suspendu' },
    'Indisponible': { dot: P.outline, bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, label: 'Indisponible' },
};

export default function LivreurShow() {
    const { id } = useParams();
    const [livreur, setLivreur] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [successMsg, setSuccessMsg] = useState('');
    const [actionLoading, setActionLoading] = useState(false);

    function charger() {
        api.get('/livreurs/' + id)
            .then(res => setLivreur(res.data))
            .catch(() => setError('Livreur introuvable.'))
            .finally(() => setLoading(false));
    }
    useEffect(() => { charger(); }, [id]);

    async function handleSuspendre() {
        if (!window.confirm('Confirmer la suspension ?')) return;
        setActionLoading(true);
        try { const r = await api.post('/livreurs/' + id + '/suspendre'); setSuccessMsg(r.data.message); charger(); }
        catch (err) { setError(err.response?.data?.message || 'Erreur.'); }
        finally { setActionLoading(false); }
    }
    async function handleReactiver() {
        if (!window.confirm('Confirmer la reactivation ?')) return;
        setActionLoading(true);
        try { const r = await api.post('/livreurs/' + id + '/reactiver'); setSuccessMsg(r.data.message); charger(); }
        catch (err) { setError(err.response?.data?.message || 'Erreur.'); }
        finally { setActionLoading(false); }
    }

    if (loading) return <p style={{ fontFamily: 'Poppins, sans-serif', color: P.outline, textAlign: 'center', marginTop: '60px' }}>Chargement...</p>;
    if (error && !livreur) return <p style={{ fontFamily: 'Poppins, sans-serif', color: P.error, textAlign: 'center', marginTop: '60px' }}>{error}</p>;

    const sc = statusLivreur[livreur?.status] || { dot: P.outline, bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, label: livreur?.status };
    const livraisons = livreur?.deliveryorders || [];
    const stats = {
        total: livraisons.length,
        livrees: livraisons.filter(l => l.status === 'Livr_').length,
        en_cours: livraisons.filter(l => l.status === 'En_cours').length,
        annulees: livraisons.filter(l => l.status === 'Annul_').length,
    };

    const cardStyle = { backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, padding: '20px', boxShadow: '0 1px 4px rgba(0,0,0,0.04)', marginBottom: '14px' };
    const thStyle = { padding: '8px 12px', textAlign: 'left', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em', borderBottom: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow };
    const tdStyle = { padding: '11px 12px', fontSize: '12px', color: P.onSurface, borderBottom: '1px solid ' + P.surfaceContainerLow };

    return (
        <div style={{ maxWidth: '900px', fontFamily: 'Poppins, sans-serif' }}>
            <BackButton to="/livreurs" />

            <div style={{ marginBottom: '20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                    <Link to="/livreurs" style={{ color: P.outline, textDecoration: 'none', fontSize: '13px' }}>Livreurs</Link>
                    <span style={{ color: P.outlineVariant, margin: '0 6px' }}>/</span>
                    <span style={{ fontSize: '13px', fontWeight: 500, color: P.onSurface }}>{livreur?.users?.first_name} {livreur?.users?.last_name}</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: sc.dot }}></div>
                    <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '4px 12px', borderRadius: '6px', fontSize: '12px', fontWeight: 600 }}>{sc.label}</span>
                </div>
            </div>

            {successMsg && <div style={{ backgroundColor: '#c8e6c9', border: '1px solid #a5d6a7', color: '#1b5e20', padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>{successMsg}</div>}
            {error && <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>{error}</div>}

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px', marginBottom: '14px' }}>
                {/* Identite */}
                <div style={cardStyle}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '14px', marginBottom: '18px' }}>
                        <div style={{ width: '52px', height: '52px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '20px', fontWeight: 800, color: '#fff', flexShrink: 0 }}>
                            {livreur?.users?.first_name?.[0]}
                        </div>
                        <div>
                            <p style={{ margin: 0, fontSize: '16px', fontWeight: 700, color: P.onSurface }}>{livreur?.users?.first_name} {livreur?.users?.last_name}</p>
                            <p style={{ margin: '3px 0 0 0', fontSize: '12px', color: P.outline }}>Livreur #{String(livreur?.id).padStart(3,'0')}</p>
                        </div>
                    </div>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                        {[['Telephone', livreur?.users?.phone], ['Email', livreur?.users?.email], ['Zone', livreur?.zone_affectee || '—'], ['Disponible', livreur?.available ? 'Oui' : 'Non']].map(([l, v]) => (
                            <div key={l}>
                                <p style={{ margin: '0 0 2px 0', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.06em' }}>{l}</p>
                                <p style={{ margin: 0, fontSize: '13px', fontWeight: 500, color: P.onSurface }}>{v}</p>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Vehicule */}
                <div style={cardStyle}>
                    <p style={{ margin: '0 0 14px 0', fontSize: '13px', fontWeight: 700, color: P.onSurface }}>Vehicule</p>
                    {livreur?.vehicules ? (
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                            {[['Type', livreur.vehicules.type], ['Marque', livreur.vehicules.brand || '—'], ['Plaque', livreur.vehicules.plate_number], ['Statut', livreur.vehicules.status]].map(([l, v]) => (
                                <div key={l}>
                                    <p style={{ margin: '0 0 2px 0', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.06em' }}>{l}</p>
                                    <p style={{ margin: 0, fontSize: '13px', fontWeight: 500, color: P.onSurface }}>{v}</p>
                                </div>
                            ))}
                        </div>
                    ) : <p style={{ color: P.outline, fontSize: '13px', margin: 0 }}>Aucun vehicule assigne</p>}
                </div>
            </div>

            {/* Stats */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '10px', marginBottom: '14px' }}>
                {[
                    { label: 'Total', value: stats.total, color: P.primaryContainer, bg: 'rgba(201,149,46,0.12)' },
                    { label: 'Livrees', value: stats.livrees, color: '#4caf50', bg: 'rgba(76,175,80,0.12)' },
                    { label: 'En cours', value: stats.en_cours, color: P.tertiary, bg: 'rgba(32,97,158,0.12)' },
                    { label: 'Annulees', value: stats.annulees, color: P.error, bg: 'rgba(186,26,26,0.1)' },
                ].map((s, i) => (
                    <div key={i} style={{ backgroundColor: P.inverseS, borderRadius: '12px', padding: '14px', textAlign: 'center' }}>
                        <div style={{ width: '36px', height: '36px', borderRadius: '10px', backgroundColor: s.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 8px' }}>
                            <span style={{ fontSize: '18px', fontWeight: 800, color: s.color }}>{s.value}</span>
                        </div>
                        <p style={{ margin: 0, fontSize: '10px', color: 'rgba(241,241,241,0.45)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>{s.label}</p>
                    </div>
                ))}
            </div>

            {/* Actions */}
            <div style={{ ...cardStyle, marginBottom: '14px' }}>
                <p style={{ margin: '0 0 14px 0', fontSize: '13px', fontWeight: 700, color: P.onSurface }}>Actions</p>
                <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                    <Link to={'/livreurs/' + id + '/edit'}
                        style={{ padding: '9px 18px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, color: P.onSurface, fontSize: '13px', fontWeight: 500, textDecoration: 'none' }}>
                        Modifier le profil
                    </Link>
                    {livreur?.status !== 'Suspendu' ? (
                        <button onClick={handleSuspendre} disabled={actionLoading}
                            style={{ padding: '9px 18px', borderRadius: '10px', border: '1px solid rgba(186,26,26,0.3)', backgroundColor: P.errorContainer, color: P.onErrorContainer, fontSize: '13px', fontWeight: 600, cursor: 'pointer', border: 'none', fontFamily: 'Poppins, sans-serif' }}>
                            Suspendre
                        </button>
                    ) : (
                        <button onClick={handleReactiver} disabled={actionLoading}
                            style={{ padding: '9px 18px', borderRadius: '10px', border: 'none', backgroundColor: '#c8e6c9', color: '#1b5e20', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                            Reactiver
                        </button>
                    )}
                </div>
            </div>

            {/* Historique livraisons */}
            <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}>
                <div style={{ padding: '13px 16px', borderBottom: '1px solid ' + P.surfaceContainerLow, backgroundColor: P.surfaceContainerLow }}>
                    <p style={{ margin: 0, fontSize: '13px', fontWeight: 700, color: P.onSurface }}>Historique des livraisons ({livraisons.length})</p>
                </div>
                {livraisons.length === 0 ? (
                    <p style={{ textAlign: 'center', color: P.outline, fontSize: '13px', padding: '30px' }}>Aucune livraison effectuee.</p>
                ) : (
                    <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                        <thead><tr>
                            {['ID', 'Client', 'Adresse', 'Statut', 'Date', ''].map(h => <th key={h} style={thStyle}>{h}</th>)}
                        </tr></thead>
                        <tbody>
                            {livraisons.map(l => {
                                const sc = statusLivraison[l.status] || { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, label: l.status };
                                return (
                                    <tr key={l.id} onMouseEnter={e => e.currentTarget.style.backgroundColor = P.surfaceContainerLow} onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'} style={{ transition: 'background 0.1s' }}>
                                        <td style={{ ...tdStyle, fontWeight: 700, color: P.primary }}>#{String(l.id).padStart(5,'0')}</td>
                                        <td style={tdStyle}>{l.customers?.users?.first_name} {l.customers?.users?.last_name}</td>
                                        <td style={{ ...tdStyle, color: P.onSurfaceVariant, maxWidth: '160px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{l.delivery_address}</td>
                                        <td style={tdStyle}><span style={{ backgroundColor: sc.bg, color: sc.color, padding: '2px 7px', borderRadius: '4px', fontSize: '10px', fontWeight: 600 }}>{sc.label}</span></td>
                                        <td style={{ ...tdStyle, color: P.outline, whiteSpace: 'nowrap' }}>{l.creation_date ? new Date(l.creation_date).toLocaleDateString('fr-FR') : '—'}</td>
                                        <td style={tdStyle}><Link to={'/livraisons/' + l.id} style={{ color: P.primary, fontWeight: 600, textDecoration: 'none', fontSize: '12px' }}>Voir</Link></td>
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                )}
            </div>
        </div>
    );
}