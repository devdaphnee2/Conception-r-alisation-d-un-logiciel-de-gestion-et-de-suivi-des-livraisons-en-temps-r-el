import { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';
import { IconAlert, IconCheck, IconX, IconUser, IconClock } from '../../components/Icons';

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

// Correspond aux statuts du diagramme de sequence : ouvert/en_cours/resolu/cloture
const statusConfig = {
    'En_attente':  { bg: P.primaryFixed,    color: P.onPrimaryContainer, label: 'En attente',   step: 1 },
    'Approuvee':   { bg: '#c8e6c9',         color: '#1b5e20',            label: 'Resolu',        step: 3 },
    'Rejetee':     { bg: P.errorContainer,  color: P.onErrorContainer,   label: 'Rejete',        step: 3 },
    'Cloture':     { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, label: 'Cloture',    step: 4 },
};

const typeLabels = {
    'Retour_produit': 'Retour produit',
    'Rabais': 'Rabais sur prix',
    'Livraison_gratuite': 'Livraison gratuite prochaine commande',
    'Autre': 'Autre',
};

export default function LitigeShow() {
    const { id } = useParams();
    const [litige, setLitige] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [successMsg, setSuccessMsg] = useState('');
    const [actionLoading, setActionLoading] = useState(false);
    const [showResoudreForm, setShowResoudreForm] = useState(false);
    const [decisionForm, setDecisionForm] = useState({ decision: '', amount: '' });

    function charger() {
        api.get('/litiges/' + id)
            .then(res => setLitige(res.data))
            .catch(() => setError('Litige introuvable.'))
            .finally(() => setLoading(false));
    }

    useEffect(() => { charger(); }, [id]);

    async function handlePrendreEnCharge() {
        setActionLoading(true);
        setError('');
        try {
            // Etape 7-8 du diagramme : Prendre en charge -> UPDATE statut=en_cours, manager_id
            const res = await api.post('/litiges/' + id + '/prendre-en-charge');
            setSuccessMsg('Litige pris en charge. Statut mis a jour.');
            charger();
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur.');
        } finally { setActionLoading(false); }
    }

    async function handleResoudre(e) {
        e.preventDefault();
        setActionLoading(true);
        setError('');
        try {
            // Etape 9-10 : Resoudre -> UPDATE statut=resolu, decision, motif
            const res = await api.post('/litiges/' + id + '/resoudre', decisionForm);
            setSuccessMsg('Litige resolu. Decision enregistree et notification envoyee.');
            setShowResoudreForm(false);
            charger();
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur.');
        } finally { setActionLoading(false); }
    }

    async function handleRejeter() {
        if (!window.confirm('Confirmer le rejet de ce litige ?')) return;
        setActionLoading(true);
        setError('');
        try {
            const res = await api.post('/litiges/' + id + '/rejeter');
            setSuccessMsg('Litige rejete. Notification envoyee au demandeur.');
            charger();
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur.');
        } finally { setActionLoading(false); }
    }

    async function handleCloturer() {
        if (!window.confirm('Cloturer definitivement ce litige ?')) return;
        setActionLoading(true);
        setError('');
        try {
            // Etape 13-14 : Cloturer -> UPDATE statut=cloture, date_cloture
            const res = await api.post('/litiges/' + id + '/cloturer');
            setSuccessMsg('Litige cloture. Date de cloture enregistree.');
            charger();
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur action. Verifiez que la route /cloturer est implementee.');
        } finally { setActionLoading(false); }
    }

    if (loading) return <p style={{ color: P.outline, textAlign: 'center', marginTop: '60px', fontFamily: 'Poppins, sans-serif' }}>Chargement...</p>;
    if (error && !litige) return <p style={{ color: P.error, textAlign: 'center', marginTop: '60px', fontFamily: 'Poppins, sans-serif' }}>{error}</p>;

    const sc = statusConfig[litige?.status] || statusConfig['En_attente'];
    const border = '1px solid ' + P.outlineVariant;
    const cardStyle = { backgroundColor: P.surface, borderRadius: '14px', border, padding: '20px', boxShadow: '0 1px 4px rgba(0,0,0,0.05)', marginBottom: '14px' };
    const labelStyle = { fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.07em', margin: '0 0 4px 0' };
    const valueStyle = { fontSize: '14px', color: P.onSurface, fontWeight: 500, margin: 0 };
    const inputStyle = { width: '100%', padding: '10px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, fontSize: '13px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, boxSizing: 'border-box', outline: 'none', backgroundColor: P.surface };

    // Timeline du diagramme de sequence (4 etapes)
    const steps = [
        { label: 'Declare', done: true },
        { label: 'En cours', done: ['Approuvee', 'Rejetee', 'Cloture'].includes(litige?.status) },
        { label: 'Resolu / Rejete', done: ['Approuvee', 'Rejetee', 'Cloture'].includes(litige?.status) },
        { label: 'Cloture', done: litige?.status === 'Cloture' },
    ];

    return (
        <div style={{ maxWidth: '800px', fontFamily: 'Poppins, sans-serif' }}>
            <BackButton to="/litiges" />

            {/* BREADCRUMB + STATUT */}
            <div style={{ marginBottom: '20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                    <Link to="/litiges" style={{ color: P.outline, textDecoration: 'none', fontSize: '13px' }}>Litiges</Link>
                    <span style={{ color: P.outlineVariant, margin: '0 6px' }}>/</span>
                    <span style={{ color: P.onSurface, fontSize: '13px', fontWeight: 500 }}>Litige #{id}</span>
                </div>
                <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '5px 12px', borderRadius: '6px', fontSize: '12px', fontWeight: 600 }}>
                    {sc.label}
                </span>
            </div>

            {/* TIMELINE — correspond aux 14 etapes du diagramme */}
            <div style={{ ...cardStyle, padding: '16px 20px' }}>
                <p style={{ ...labelStyle, marginBottom: '12px' }}>Progression du litige</p>
                <div style={{ display: 'flex', alignItems: 'center', gap: 0 }}>
                    {steps.map((step, i) => (
                        <div key={i} style={{ display: 'flex', alignItems: 'center', flex: i < steps.length - 1 ? 1 : 'none' }}>
                            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '6px' }}>
                                <div style={{ width: '28px', height: '28px', borderRadius: '50%', backgroundColor: step.done ? P.primaryContainer : P.surfaceContainerHigh, border: '2px solid ' + (step.done ? P.primaryContainer : P.outlineVariant), display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                                    {step.done
                                        ? <IconCheck style={{ width: '14px', height: '14px', color: '#fff' }} />
                                        : <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: P.outlineVariant, display: 'block' }}></span>
                                    }
                                </div>
                                <span style={{ fontSize: '10px', fontWeight: step.done ? 600 : 400, color: step.done ? P.onSurface : P.outline, whiteSpace: 'nowrap' }}>{step.label}</span>
                            </div>
                            {i < steps.length - 1 && (
                                <div style={{ flex: 1, height: '2px', backgroundColor: step.done ? P.primaryContainer : P.surfaceContainerHigh, margin: '0 4px', marginBottom: '20px' }}></div>
                            )}
                        </div>
                    ))}
                </div>
            </div>

            {successMsg && <div style={{ backgroundColor: '#c8e6c9', border: '1px solid #a5d6a7', color: '#1b5e20', padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>{successMsg}</div>}
            {error && <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>{error}</div>}

            {/* INFOS LITIGE */}
            <div style={cardStyle}>
                <p style={{ fontSize: '14px', fontWeight: 700, color: P.onSurface, margin: '0 0 16px 0' }}>Informations du litige</p>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                    <div><p style={labelStyle}>Type</p><p style={valueStyle}>{typeLabels[litige?.type] || litige?.type}</p></div>
                    <div><p style={labelStyle}>Montant compensation</p><p style={{ ...valueStyle, color: P.primary, fontWeight: 700 }}>{litige?.amount ? Number(litige.amount).toLocaleString('fr-FR') + ' FCFA' : '—'}</p></div>
                    <div style={{ gridColumn: '1 / -1' }}><p style={labelStyle}>Raison declaree</p><p style={{ ...valueStyle, fontSize: '13px', lineHeight: '1.6', color: P.onSurfaceVariant }}>{litige?.reason}</p></div>
                    <div><p style={labelStyle}>Date declaration</p><p style={valueStyle}>{litige?.created_at ? new Date(litige.created_at).toLocaleString('fr-FR') : '—'}</p></div>
                    <div><p style={labelStyle}>Manager responsable</p><p style={valueStyle}>{litige?.managers?.users?.first_name || '—'} {litige?.managers?.users?.last_name || ''}</p></div>
                    {litige?.status === 'Approuvee' && (
                        <>
                            <div><p style={labelStyle}>Decision appliquee</p>
                                <span style={{ backgroundColor: '#c8e6c9', color: '#1b5e20', padding: '3px 10px', borderRadius: '5px', fontSize: '11px', fontWeight: 600 }}>
                                    {typeLabels[litige?.type] || litige?.type}
                                </span>
                            </div>
                        </>
                    )}
                </div>
            </div>

            {/* CLIENT */}
            <div style={cardStyle}>
                <p style={{ fontSize: '14px', fontWeight: 700, color: P.onSurface, margin: '0 0 14px 0' }}>Client concerne</p>
                {litige?.orders?.customers ? (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        <div style={{ width: '38px', height: '38px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '14px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>
                            {litige.orders.customers.users?.first_name?.[0]}
                        </div>
                        <div>
                            <p style={{ margin: 0, fontSize: '14px', fontWeight: 600, color: P.onSurface }}>
                                {litige.orders.customers.users?.first_name} {litige.orders.customers.users?.last_name}
                            </p>
                            <p style={{ margin: '2px 0 0 0', fontSize: '12px', color: P.outline }}>{litige.orders.customers.users?.phone}</p>
                        </div>
                        <div style={{ marginLeft: 'auto' }}>
                            <p style={labelStyle}>Commande ref.</p>
                            <p style={{ ...valueStyle, color: P.primary, fontWeight: 700 }}>#{litige.orders?.id} — {Number(litige.orders?.total_amount).toLocaleString('fr-FR')} FCFA</p>
                        </div>
                    </div>
                ) : <p style={{ color: P.outline, fontSize: '13px' }}>—</p>}
            </div>

            {/* ARTICLES */}
            {litige?.orders?.delivery_items?.length > 0 && (
                <div style={cardStyle}>
                    <p style={{ fontSize: '14px', fontWeight: 700, color: P.onSurface, margin: '0 0 12px 0' }}>Articles de la commande</p>
                    <div style={{ display: 'grid', gap: '6px' }}>
                        {litige.orders.delivery_items.map((item, i) => (
                            <div key={i} style={{ padding: '10px 14px', borderRadius: '8px', backgroundColor: P.surfaceContainerLow, border: '1px solid ' + P.outlineVariant, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                <span style={{ fontSize: '13px', fontWeight: 500, color: P.onSurface }}>{item.product_name}</span>
                                <span style={{ fontSize: '11px', fontWeight: 600, color: item.status === 'Disponible' ? '#1b5e20' : P.onPrimaryContainer, backgroundColor: item.status === 'Disponible' ? '#c8e6c9' : P.primaryFixed, padding: '2px 8px', borderRadius: '4px' }}>
                                    {item.status}
                                </span>
                            </div>
                        ))}
                    </div>
                </div>
            )}

            {/* ACTIONS — correspondent exactement aux etapes 7 a 14 du diagramme */}
            <div style={cardStyle}>
                <p style={{ fontSize: '14px', fontWeight: 700, color: P.onSurface, margin: '0 0 16px 0' }}>Actions</p>
                <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>

                    {/* Etape 7 — Prendre en charge */}
                    {litige?.status === 'En_attente' && (
                        <button onClick={handlePrendreEnCharge} disabled={actionLoading}
                            style={{ padding: '10px 18px', borderRadius: '10px', border: 'none', backgroundColor: P.primary, color: '#fff', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: '0 2px 8px rgba(125,87,0,0.25)' }}>
                            Prendre en charge
                        </button>
                    )}

                    {/* Etape 9 — Resoudre */}
                    {litige?.status === 'En_attente' && (
                        <button onClick={() => setShowResoudreForm(!showResoudreForm)}
                            style={{ padding: '10px 18px', borderRadius: '10px', border: 'none', backgroundColor: '#1b5e20', color: '#fff', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                            Resoudre le litige
                        </button>
                    )}

                    {/* Rejeter */}
                    {litige?.status === 'En_attente' && (
                        <button onClick={handleRejeter} disabled={actionLoading}
                            style={{ padding: '10px 18px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.errorContainer, color: P.onErrorContainer, fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                            Rejeter
                        </button>
                    )}

                    {/* Etape 13 — Cloturer (apres resolution) */}
                    {(litige?.status === 'Approuvee' || litige?.status === 'Rejetee') && (
                        <button onClick={handleCloturer} disabled={actionLoading}
                            style={{ padding: '10px 18px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerHigh, color: P.onSurfaceVariant, fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                            Cloturer le litige
                        </button>
                    )}

                    {litige?.status === 'Cloture' && (
                        <div style={{ padding: '10px 18px', borderRadius: '10px', backgroundColor: P.surfaceContainerLow, border: '1px solid ' + P.outlineVariant }}>
                            <p style={{ margin: 0, fontSize: '13px', color: P.outline, fontWeight: 500 }}>Litige cloture — aucune action disponible</p>
                        </div>
                    )}
                </div>

                {/* FORMULAIRE RESOLUTION */}
                {showResoudreForm && (
                    <div style={{ marginTop: '16px', padding: '18px', backgroundColor: P.surfaceContainerLow, borderRadius: '12px', border: '1px solid ' + P.outlineVariant }}>
                        <p style={{ margin: '0 0 14px 0', fontSize: '13px', fontWeight: 700, color: P.onSurface }}>Rédiger la decision (etape 9-10)</p>
                        <form onSubmit={handleResoudre}>
                            <div style={{ display: 'grid', gap: '14px' }}>
                                <div>
                                    <label style={{ ...labelStyle, display: 'block', marginBottom: '6px' }}>Decision *</label>
                                    <select value={decisionForm.decision} onChange={e => setDecisionForm({ ...decisionForm, decision: e.target.value })} style={inputStyle} required>
                                        <option value="">-- Selectionner la decision --</option>
                                        <option value="Retour_produit">Retour produit</option>
                                        <option value="Rabais">Rabais sur prix</option>
                                        <option value="Livraison_gratuite">Livraison gratuite prochaine commande</option>
                                        <option value="Autre">Autre</option>
                                    </select>
                                </div>
                                <div>
                                    <label style={{ ...labelStyle, display: 'block', marginBottom: '6px' }}>Montant compensation (FCFA)</label>
                                    <input type="number" value={decisionForm.amount} onChange={e => setDecisionForm({ ...decisionForm, amount: e.target.value })} style={inputStyle} placeholder="0" min="0" />
                                </div>
                                <div style={{ display: 'flex', gap: '10px' }}>
                                    <button type="submit" disabled={actionLoading}
                                        style={{ padding: '10px 20px', borderRadius: '10px', border: 'none', backgroundColor: '#1b5e20', color: '#fff', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                        {actionLoading ? 'En cours...' : 'Confirmer la resolution'}
                                    </button>
                                    <button type="button" onClick={() => setShowResoudreForm(false)}
                                        style={{ padding: '10px 18px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, fontSize: '13px', fontWeight: 500, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                        Annuler
                                    </button>
                                </div>
                            </div>
                        </form>
                    </div>
                )}
            </div>
        </div>
    );
}
