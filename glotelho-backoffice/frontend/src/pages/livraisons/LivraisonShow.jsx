import { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';
import { IconTruck, IconCheck, IconClock, IconAlert, IconX, IconUser, IconPackage } from '../../components/Icons';

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

const statusConfig = {
    'En_attente': { bg: P.primaryFixed,       color: P.onPrimaryContainer,   label: 'En attente',  step: 1 },
    'Assign_':    { bg: P.secondaryContainer,  color: P.onSecondaryContainer, label: 'Assigne',     step: 2 },
    'En_cours':   { bg: P.tertiaryContainer,   color: P.onTertiaryContainer,  label: 'En cours',    step: 3 },
    'Livr_':      { bg: '#c8e6c9',             color: '#1b5e20',              label: 'Livre',       step: 4 },
    'Suspendu':   { bg: P.errorContainer,      color: P.onErrorContainer,     label: 'Suspendu',    step: 2 },
    'Annul_':     { bg: P.surfaceContainerHigh,color: P.onSurfaceVariant,     label: 'Annule',      step: 0 },
};

export default function LivraisonShow() {
    const { id } = useParams();
    const [livraison, setLivraison] = useState(null);
    const [livreurs, setLivreurs] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [successMsg, setSuccessMsg] = useState('');
    const [actionLoading, setActionLoading] = useState(false);

    const [showAssignerForm, setShowAssignerForm] = useState(false);
    const [showSuspendreForm, setShowSuspendreForm] = useState(false);
    const [showReassignerForm, setShowReassignerForm] = useState(false);
    const [assignerForm, setAssignerForm] = useState({ delivery_person_id: '' });
    const [suspendreForm, setSuspendreForm] = useState({ suspension_reason: '' });
    const [reassignerForm, setReassignerForm] = useState({ delivery_person_id: '' });

    function charger() {
        api.get('/livraisons/' + id)
            .then(res => setLivraison(res.data))
            .catch(() => setError('Livraison introuvable.'))
            .finally(() => setLoading(false));
    }

    useEffect(() => {
        charger();
        api.get('/livreurs').then(res => setLivreurs(res.data)).catch(() => {});
    }, [id]);

    async function handleAssigner(e) {
        e.preventDefault();
        setActionLoading(true); setError('');
        try {
            await api.post('/livraisons/' + id + '/assigner', assignerForm);
            setSuccessMsg('Livraison assignee. Notification FCM envoyee au livreur.');
            setShowAssignerForm(false);
            charger();
        } catch (err) { setError(err.response?.data?.message || 'Erreur.'); }
        finally { setActionLoading(false); }
    }

    async function handleSuspendre(e) {
        e.preventDefault();
        setActionLoading(true); setError('');
        try {
            await api.post('/livraisons/' + id + '/suspendre', suspendreForm);
            setSuccessMsg('Livraison suspendue. Motif enregistre.');
            setShowSuspendreForm(false);
            charger();
        } catch (err) { setError(err.response?.data?.message || 'Erreur.'); }
        finally { setActionLoading(false); }
    }

    // Scenario 2 — Reassignation apres suspension
    async function handleReassigner(e) {
        e.preventDefault();
        setActionLoading(true); setError('');
        try {
            await api.post('/livraisons/' + id + '/assigner', reassignerForm);
            setSuccessMsg('Livraison reassignee a un nouveau livreur. FCM envoye.');
            setShowReassignerForm(false);
            charger();
        } catch (err) { setError(err.response?.data?.message || 'Erreur.'); }
        finally { setActionLoading(false); }
    }

    async function handleAnnuler() {
        if (!window.confirm('Confirmer l\'annulation ? Le tracking sera bloque.')) return;
        setActionLoading(true); setError('');
        try {
            await api.post('/livraisons/' + id + '/annuler');
            setSuccessMsg('Livraison annulee. Tracking GPS bloque (tracking_blocked = true).');
            charger();
        } catch (err) { setError(err.response?.data?.message || 'Erreur.'); }
        finally { setActionLoading(false); }
    }

    async function handleBordereau() {
        try {
            const response = await api.get('/bordereaux/livraison/' + id, { responseType: 'blob' });
            const url = window.URL.createObjectURL(new Blob([response.data], { type: 'application/pdf' }));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', 'bordereau-' + id + '.pdf');
            document.body.appendChild(link);
            link.click();
            link.remove();
        } catch (err) { setError('Impossible de generer le bordereau.'); }
    }

    if (loading) return <p style={{ color: P.outline, textAlign: 'center', marginTop: '60px', fontFamily: 'Poppins, sans-serif' }}>Chargement...</p>;
    if (error && !livraison) return <p style={{ color: P.error, textAlign: 'center', marginTop: '60px', fontFamily: 'Poppins, sans-serif' }}>{error}</p>;

    const sc = statusConfig[livraison?.status] || statusConfig['En_attente'];
    const border = '1px solid ' + P.outlineVariant;
    const cardStyle = { backgroundColor: P.surface, borderRadius: '14px', border, padding: '20px', boxShadow: '0 1px 4px rgba(0,0,0,0.05)', marginBottom: '14px' };
    const labelStyle = { fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.07em', margin: '0 0 4px 0' };
    const valueStyle = { fontSize: '13px', color: P.onSurface, fontWeight: 500, margin: 0 };
    const inputStyle = { width: '100%', padding: '10px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, fontSize: '13px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, boxSizing: 'border-box', outline: 'none', backgroundColor: P.surface };
    const btnPrimary = { padding: '10px 18px', borderRadius: '10px', border: 'none', backgroundColor: P.primary, color: '#fff', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: '0 2px 8px rgba(125,87,0,0.25)' };

    // Timeline scenario 1 — Creation et Assignation
    const steps = [
        { label: 'Creee', done: true },
        { label: 'Assignee', done: ['Assign_','En_cours','Livr_'].includes(livraison?.status) },
        { label: 'En cours', done: ['En_cours','Livr_'].includes(livraison?.status) },
        { label: 'Livree', done: livraison?.status === 'Livr_' },
    ];

    return (
        <div style={{ maxWidth: '860px', fontFamily: 'Poppins, sans-serif' }}>
            <BackButton to="/livraisons" />

            <div style={{ marginBottom: '20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                    <Link to="/livraisons" style={{ color: P.outline, textDecoration: 'none', fontSize: '13px' }}>Livraisons</Link>
                    <span style={{ color: P.outlineVariant, margin: '0 6px' }}>/</span>
                    <span style={{ color: P.onSurface, fontSize: '13px', fontWeight: 500 }}>Livraison #{String(livraison?.id).padStart(5,'0')}</span>
                </div>
                <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '5px 12px', borderRadius: '6px', fontSize: '12px', fontWeight: 600 }}>
                    {sc.label}
                </span>
            </div>

            {/* TIMELINE */}
            {!['Annul_'].includes(livraison?.status) && (
                <div style={{ ...cardStyle, padding: '16px 20px' }}>
                    <p style={{ ...labelStyle, marginBottom: '12px' }}>Progression (Scenario 1 — Diagramme de sequence)</p>
                    <div style={{ display: 'flex', alignItems: 'center' }}>
                        {steps.map((step, i) => (
                            <div key={i} style={{ display: 'flex', alignItems: 'center', flex: i < steps.length - 1 ? 1 : 'none' }}>
                                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '5px' }}>
                                    <div style={{ width: '26px', height: '26px', borderRadius: '50%', backgroundColor: step.done ? P.primaryContainer : P.surfaceContainerHigh, border: '2px solid ' + (step.done ? P.primaryContainer : P.outlineVariant), display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                                        {step.done ? <IconCheck style={{ width: '13px', height: '13px', color: '#fff' }} /> : <span style={{ width: '7px', height: '7px', borderRadius: '50%', backgroundColor: P.outlineVariant, display: 'block' }}></span>}
                                    </div>
                                    <span style={{ fontSize: '10px', fontWeight: step.done ? 600 : 400, color: step.done ? P.onSurface : P.outline, whiteSpace: 'nowrap' }}>{step.label}</span>
                                </div>
                                {i < steps.length - 1 && (
                                    <div style={{ flex: 1, height: '2px', backgroundColor: step.done ? P.primaryContainer : P.surfaceContainerHigh, margin: '0 4px', marginBottom: '18px' }}></div>
                                )}
                            </div>
                        ))}
                    </div>
                </div>
            )}

            {livraison?.status === 'Suspendu' && (
                <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', borderRadius: '10px', padding: '12px 16px', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <IconAlert style={{ width: '16px', height: '16px', color: P.error, flexShrink: 0 }} />
                    <div>
                        <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onErrorContainer }}>Livraison suspendue</p>
                        <p style={{ margin: '2px 0 0 0', fontSize: '12px', color: P.error }}>Motif : {livraison?.suspension_reason || 'Non precise'}</p>
                        <p style={{ margin: '2px 0 0 0', fontSize: '11px', color: P.onErrorContainer }}>Scenario 2 — Reassignez un nouveau livreur pour continuer la livraison.</p>
                    </div>
                </div>
            )}

            {successMsg && <div style={{ backgroundColor: '#c8e6c9', border: '1px solid #a5d6a7', color: '#1b5e20', padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>{successMsg}</div>}
            {error && <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>{error}</div>}

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>

                {/* INFOS LIVRAISON */}
                <div style={cardStyle}>
                    <p style={{ fontSize: '14px', fontWeight: 700, color: P.onSurface, margin: '0 0 14px 0' }}>Livraison</p>
                    <div style={{ display: 'grid', gap: '12px' }}>
                        <div><p style={labelStyle}>Adresse de livraison</p><p style={valueStyle}>{livraison?.delivery_address}</p></div>
                        {livraison?.zone_bloc && <div><p style={labelStyle}>Zone / Description lieu</p><p style={valueStyle}>{livraison.zone_bloc}</p></div>}
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
                            <div><p style={labelStyle}>Montant a collecter</p><p style={{ ...valueStyle, fontWeight: 700, color: P.primary }}>{livraison?.amount_to_collect ? Number(livraison.amount_to_collect).toLocaleString('fr-FR') + ' FCFA' : '—'}</p></div>
                            <div><p style={labelStyle}>Deja paye</p><p style={{ ...valueStyle, color: '#1b5e20', fontWeight: 600 }}>{livraison?.collected_amount ? Number(livraison.collected_amount).toLocaleString('fr-FR') + ' FCFA' : '0 FCFA'}</p></div>
                        </div>
                        <div><p style={labelStyle}>Date creation</p><p style={valueStyle}>{livraison?.creation_date ? new Date(livraison.creation_date).toLocaleString('fr-FR') : '—'}</p></div>
                        {livraison?.delivery_date && <div><p style={labelStyle}>Date livraison effective</p><p style={valueStyle}>{new Date(livraison.delivery_date).toLocaleString('fr-FR')}</p></div>}
                        {livraison?.tracking_blocked && <div><p style={{ ...valueStyle, color: P.error, fontSize: '12px', fontWeight: 600 }}>Tracking GPS bloque (annulation)</p></div>}
                    </div>
                </div>

                {/* CLIENT + LIVREUR */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                    <div style={cardStyle}>
                        <p style={{ fontSize: '13px', fontWeight: 700, color: P.onSurface, margin: '0 0 12px 0' }}>Client</p>
                        {livraison?.customers ? (
                            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                <div style={{ width: '34px', height: '34px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '13px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>
                                    {livraison.customers.users?.first_name?.[0]}
                                </div>
                                <div>
                                    <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onSurface }}>{livraison.customers.users?.first_name} {livraison.customers.users?.last_name}</p>
                                    <p style={{ margin: '2px 0 0 0', fontSize: '11px', color: P.outline }}>{livraison.customers.users?.phone}</p>
                                </div>
                            </div>
                        ) : <p style={{ color: P.outline, fontSize: '13px' }}>—</p>}
                    </div>

                    <div style={{ ...cardStyle, marginBottom: 0 }}>
                        <p style={{ fontSize: '13px', fontWeight: 700, color: P.onSurface, margin: '0 0 12px 0' }}>Livreur assigne</p>
                        {livraison?.delivery_persons ? (
                            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                <div style={{ width: '34px', height: '34px', borderRadius: '50%', backgroundColor: P.primaryContainer, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '13px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>
                                    {livraison.delivery_persons.users?.first_name?.[0]}
                                </div>
                                <div>
                                    <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onSurface }}>{livraison.delivery_persons.users?.first_name} {livraison.delivery_persons.users?.last_name}</p>
                                    <p style={{ margin: '2px 0 0 0', fontSize: '11px', color: P.outline }}>{livraison.delivery_persons.vehicules?.brand} {livraison.delivery_persons.vehicules?.type} — {livraison.delivery_persons.vehicules?.plate_number}</p>
                                </div>
                                <Link to={'/livreurs/' + livraison.delivery_persons.id} style={{ marginLeft: 'auto', fontSize: '11px', color: P.primary, fontWeight: 600, textDecoration: 'none' }}>Voir fiche</Link>
                            </div>
                        ) : (
                            <p style={{ color: P.outline, fontSize: '13px' }}>Aucun livreur assigne</p>
                        )}
                    </div>
                </div>
            </div>

            {/* ARTICLES */}
            {livraison?.delivery_items?.length > 0 && (
                <div style={cardStyle}>
                    <p style={{ fontSize: '14px', fontWeight: 700, color: P.onSurface, margin: '0 0 12px 0' }}>Articles ({livraison.delivery_items.length})</p>
                    <div style={{ display: 'grid', gap: '6px' }}>
                        {livraison.delivery_items.map((item, i) => (
                            <div key={i} style={{ padding: '9px 14px', borderRadius: '8px', backgroundColor: P.surfaceContainerLow, border: '1px solid ' + P.outlineVariant, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                <span style={{ fontSize: '13px', fontWeight: 500, color: P.onSurface }}>{item.product_name}</span>
                                <span style={{ fontSize: '11px', fontWeight: 600, color: item.status === 'Disponible' ? '#1b5e20' : P.onPrimaryContainer, backgroundColor: item.status === 'Disponible' ? '#c8e6c9' : P.primaryFixed, padding: '2px 8px', borderRadius: '4px' }}>
                                    {item.status === 'Disponible' ? 'Disponible' : 'Plus tard'}
                                </span>
                            </div>
                        ))}
                    </div>
                </div>
            )}

            {/* ACTIONS — correspondent aux scenarios 1 et 2 du diagramme */}
            <div style={cardStyle}>
                <p style={{ fontSize: '14px', fontWeight: 700, color: P.onSurface, margin: '0 0 4px 0' }}>Actions</p>
                <p style={{ fontSize: '11px', color: P.outline, margin: '0 0 16px 0' }}>
                    {livraison?.status === 'En_attente' && 'Scenario 1 — Assigner un livreur ou annuler'}
                    {livraison?.status === 'Assign_' && 'Scenario 1 — En attente d\'acceptation livreur. Vous pouvez suspendre.'}
                    {livraison?.status === 'En_cours' && 'Scenario 3 — Tracking en cours. Suspension possible si incident.'}
                    {livraison?.status === 'Suspendu' && 'Scenario 2 — Reassignez un nouveau livreur pour reprendre la livraison.'}
                    {livraison?.status === 'Livr_' && 'Livraison completee. Bordereau disponible.'}
                    {livraison?.status === 'Annul_' && 'Livraison annulee. Aucune action disponible.'}
                </p>

                <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap', marginBottom: '14px' }}>

                    {/* Assigner — Scenario 1 */}
                    {livraison?.status === 'En_attente' && (
                        <button onClick={() => setShowAssignerForm(!showAssignerForm)} style={btnPrimary}>
                            Assigner un livreur
                        </button>
                    )}

                    {/* Reassigner apres suspension — Scenario 2 */}
                    {livraison?.status === 'Suspendu' && (
                        <button onClick={() => setShowReassignerForm(!showReassignerForm)} style={btnPrimary}>
                            Reassigner (Scenario 2)
                        </button>
                    )}

                    {/* Suspendre — Scenarios 1 et 3 */}
                    {['Assign_', 'En_cours'].includes(livraison?.status) && (
                        <button onClick={() => setShowSuspendreForm(!showSuspendreForm)}
                            style={{ padding: '10px 18px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.primaryFixed, color: P.onPrimaryContainer, fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                            Suspendre
                        </button>
                    )}

                    {/* Modifier */}
                    {!['Livr_', 'Annul_'].includes(livraison?.status) && (
                        <Link to={'/livraisons/' + id + '/edit'}
                            style={{ padding: '10px 18px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, fontSize: '13px', fontWeight: 500, textDecoration: 'none', display: 'inline-flex', alignItems: 'center' }}>
                            Modifier
                        </Link>
                    )}

                    {/* Annuler */}
                    {['En_attente', 'Suspendu'].includes(livraison?.status) && (
                        <button onClick={handleAnnuler} disabled={actionLoading}
                            style={{ padding: '10px 18px', borderRadius: '10px', border: '1px solid rgba(186,26,26,0.3)', backgroundColor: P.errorContainer, color: P.onErrorContainer, fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                            Annuler
                        </button>
                    )}

                    {/* Bordereau PDF */}
                    <button onClick={handleBordereau}
                        style={{ padding: '10px 18px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, color: P.onSurfaceVariant, fontSize: '13px', fontWeight: 500, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                        Telecharger bordereau PDF
                    </button>
                </div>

                {/* FORMULAIRE ASSIGNATION */}
                {showAssignerForm && (
                    <div style={{ padding: '16px', backgroundColor: P.surfaceContainerLow, borderRadius: '12px', border: '1px solid ' + P.outlineVariant, marginBottom: '10px' }}>
                        <p style={{ margin: '0 0 12px 0', fontSize: '13px', fontWeight: 700, color: P.onSurface }}>Assigner un livreur (Scenario 1)</p>
                        <form onSubmit={handleAssigner} style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                            <select value={assignerForm.delivery_person_id} onChange={e => setAssignerForm({ delivery_person_id: e.target.value })} required
                                style={{ flex: 1, minWidth: '200px', padding: '10px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, fontSize: '13px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none', backgroundColor: P.surface }}>
                                <option value="">-- Selectionner un livreur --</option>
                                {livreurs.filter(l => l.status === 'Disponible').map(l => (
                                    <option key={l.id} value={l.id}>{l.users?.first_name} {l.users?.last_name} — {l.zone_affectee || 'Sans zone'}</option>
                                ))}
                            </select>
                            <button type="submit" disabled={actionLoading} style={btnPrimary}>{actionLoading ? 'Assignation...' : 'Confirmer'}</button>
                            <button type="button" onClick={() => setShowAssignerForm(false)} style={{ padding: '10px 14px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, fontSize: '13px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>Annuler</button>
                        </form>
                    </div>
                )}

                {/* FORMULAIRE REASSIGNATION — Scenario 2 */}
                {showReassignerForm && (
                    <div style={{ padding: '16px', backgroundColor: P.errorContainer, borderRadius: '12px', border: '1px solid rgba(186,26,26,0.2)', marginBottom: '10px' }}>
                        <p style={{ margin: '0 0 4px 0', fontSize: '13px', fontWeight: 700, color: P.onErrorContainer }}>Reassigner la livraison (Scenario 2)</p>
                        <p style={{ margin: '0 0 12px 0', fontSize: '11px', color: P.error }}>
                            {livraison?.suspension_reason?.toLowerCase().includes('panne') ? 'Panne : le nouveau livreur recupere le colis au point GPS d\'arret du livreur initial.' :
                             livraison?.suspension_reason?.toLowerCase().includes('perdu') ? 'Colis perdu : dette financiere creee. Le nouveau livreur repart du depot.' :
                             livraison?.suspension_reason?.toLowerCase().includes('casse') ? 'Colis casse : dette financiere + course retour. Le nouveau livreur repart du depot.' :
                             'Selectionnez un nouveau livreur disponible.'}
                        </p>
                        <form onSubmit={handleReassigner} style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                            <select value={reassignerForm.delivery_person_id} onChange={e => setReassignerForm({ delivery_person_id: e.target.value })} required
                                style={{ flex: 1, minWidth: '200px', padding: '10px 14px', borderRadius: '10px', border: '1.5px solid rgba(186,26,26,0.3)', fontSize: '13px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none', backgroundColor: P.surface }}>
                                <option value="">-- Nouveau livreur --</option>
                                {livreurs.filter(l => l.status === 'Disponible' && l.id !== livraison?.delivery_person_id).map(l => (
                                    <option key={l.id} value={l.id}>{l.users?.first_name} {l.users?.last_name} — {l.zone_affectee || 'Sans zone'}</option>
                                ))}
                            </select>
                            <button type="submit" disabled={actionLoading} style={{ ...btnPrimary, backgroundColor: P.error }}>{actionLoading ? 'Reassignation...' : 'Confirmer reassignation'}</button>
                            <button type="button" onClick={() => setShowReassignerForm(false)} style={{ padding: '10px 14px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, fontSize: '13px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>Annuler</button>
                        </form>
                    </div>
                )}

                {/* FORMULAIRE SUSPENSION */}
                {showSuspendreForm && (
                    <div style={{ padding: '16px', backgroundColor: P.surfaceContainerLow, borderRadius: '12px', border: '1px solid ' + P.outlineVariant }}>
                        <p style={{ margin: '0 0 12px 0', fontSize: '13px', fontWeight: 700, color: P.onSurface }}>Motif de suspension</p>
                        <form onSubmit={handleSuspendre} style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                            <select value={suspendreForm.suspension_reason} onChange={e => setSuspendreForm({ suspension_reason: e.target.value })} required
                                style={{ padding: '10px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, fontSize: '13px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none', backgroundColor: P.surface }}>
                                <option value="">-- Type d'incident (Scenario 2) --</option>
                                <option value="Panne vehicule">Panne vehicule — L2 recupere au point GPS d'arret</option>
                                <option value="Colis perdu">Colis perdu — Dette financiere + L2 depuis depot</option>
                                <option value="Colis casse">Colis casse — Dette financiere + course retour debris</option>
                                <option value="Annulation client">Annulation client — Course retour depot</option>
                                <option value="Autre">Autre motif</option>
                            </select>
                            <div style={{ display: 'flex', gap: '10px' }}>
                                <button type="submit" disabled={actionLoading} style={{ ...btnPrimary, backgroundColor: P.onPrimaryContainer }}>{actionLoading ? 'Suspension...' : 'Confirmer suspension'}</button>
                                <button type="button" onClick={() => setShowSuspendreForm(false)} style={{ padding: '10px 14px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, fontSize: '13px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>Annuler</button>
                            </div>
                        </form>
                    </div>
                )}
            </div>
        </div>
    );
}
