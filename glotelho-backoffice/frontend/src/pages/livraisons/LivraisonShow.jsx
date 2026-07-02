import { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';
import { IconTruck, IconCheck, IconClock, IconAlert, IconX, IconPackage } from '../../components/Icons';

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
    'En_attente': { bg: P.primaryFixed,        color: P.onPrimaryContainer,   label: 'En attente',  step: 1 },
    'Assign_':    { bg: P.secondaryContainer,   color: P.onSecondaryContainer, label: 'Assigne',     step: 2 },
    'En_cours':   { bg: P.tertiaryContainer,    color: P.onTertiaryContainer,  label: 'En cours',    step: 3 },
    'Livr_':      { bg: '#c8e6c9',              color: '#1b5e20',              label: 'Livre',       step: 4 },
    'Suspendu':   { bg: P.errorContainer,       color: P.onErrorContainer,     label: 'Suspendu',    step: 2 },
    'Annul_':     { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant,     label: 'Annule',      step: 0 },
};

export default function LivraisonShow() {
    const { id } = useParams();
    const [livraison, setLivraison] = useState(null);
    const [livreurs, setLivreurs]   = useState([]);
    const [rapport, setRapport]     = useState(null);
    const [loading, setLoading]     = useState(true);
    const [error, setError]         = useState('');
    const [successMsg, setSuccessMsg] = useState('');
    const [actionLoading, setActionLoading] = useState(false);

    const [showAssignerForm, setShowAssignerForm]   = useState(false);
    const [showSuspendreForm, setShowSuspendreForm] = useState(false);
    const [showReassignerForm, setShowReassignerForm] = useState(false);
    const [assignerForm, setAssignerForm]   = useState({ delivery_person_id: '' });
    const [suspendreForm, setSuspendreForm] = useState({ suspension_reason: '' });
    const [reassignerForm, setReassignerForm] = useState({ delivery_person_id: '' });

    function charger() {
        api.get('/livraisons/' + id)
            .then(res => {
                setLivraison(res.data);
                // Chercher rapport livreur dans rapports
                const rapports = res.data.rapports || [];
                const r = rapports.find(r => r.type === 'livraison') || null;
                setRapport(r);
            })
            .catch(() => setError('Livraison introuvable.'))
            .finally(() => setLoading(false));
    }

    useEffect(() => {
        charger();
        api.get('/livreurs').then(res => setLivreurs(res.data)).catch(() => {});
    }, [id]);

    async function doAction(route, body, msg) {
        setActionLoading(true); setError('');
        try {
            await (body ? api.post(route, body) : api.post(route));
            setSuccessMsg(msg);
            setShowAssignerForm(false);
            setShowSuspendreForm(false);
            setShowReassignerForm(false);
            charger();
        } catch (err) { setError(err.response?.data?.message || 'Erreur.'); }
        finally { setActionLoading(false); }
    }

    async function handleBordereau() {
        try {
            const response = await api.get('/bordereaux/livraison/' + id, { responseType: 'blob' });
            const url = window.URL.createObjectURL(new Blob([response.data], { type: 'application/pdf' }));
            const a = document.createElement('a'); a.href = url; a.download = 'bordereau-' + id + '.pdf';
            document.body.appendChild(a); a.click(); a.remove();
        } catch { setError('Impossible de generer le bordereau.'); }
    }

    if (loading) return <p style={{ fontFamily: 'Poppins, sans-serif', color: P.outline, textAlign: 'center', marginTop: '60px' }}>Chargement...</p>;
    if (error && !livraison) return <p style={{ fontFamily: 'Poppins, sans-serif', color: P.error, textAlign: 'center', marginTop: '60px' }}>{error}</p>;

    const sc = statusConfig[livraison?.status] || statusConfig['En_attente'];
    const border = '1px solid ' + P.outlineVariant;
    const cardStyle = { backgroundColor: P.surface, borderRadius: '14px', border, padding: '20px', boxShadow: '0 1px 4px rgba(0,0,0,0.05)', marginBottom: '14px' };
    const labelStyle = { fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.07em', margin: '0 0 3px 0' };
    const valueStyle = { fontSize: '13px', color: P.onSurface, fontWeight: 500, margin: 0 };
    const inputStyle = { width: '100%', padding: '10px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, fontSize: '13px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, boxSizing: 'border-box', outline: 'none', backgroundColor: P.surface };
    const btnPrimary = { padding: '10px 18px', borderRadius: '10px', border: 'none', backgroundColor: P.primary, color: '#fff', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: '0 2px 8px rgba(125,87,0,0.25)' };

    const steps = [
        { label: 'Creee', done: true },
        { label: 'Assignee', done: ['Assign_','En_cours','Livr_'].includes(livraison?.status) },
        { label: 'En cours',  done: ['En_cours','Livr_'].includes(livraison?.status) },
        { label: 'Livree',    done: livraison?.status === 'Livr_' },
    ];

    return (
        <div style={{ maxWidth: '900px', fontFamily: 'Poppins, sans-serif' }}>
            <BackButton to="/livraisons" />

            <div style={{ marginBottom: '20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                    <Link to="/livraisons" style={{ color: P.outline, textDecoration: 'none', fontSize: '13px' }}>Livraisons</Link>
                    <span style={{ color: P.outlineVariant, margin: '0 6px' }}>/</span>
                    <span style={{ color: P.onSurface, fontSize: '13px', fontWeight: 500 }}>Livraison #{String(livraison?.id).padStart(5,'0')}</span>
                </div>
                <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '5px 12px', borderRadius: '6px', fontSize: '12px', fontWeight: 600 }}>{sc.label}</span>
            </div>

            {/* Timeline */}
            {!['Annul_'].includes(livraison?.status) && (
                <div style={{ ...cardStyle, padding: '16px 20px' }}>
                    <p style={{ ...labelStyle, marginBottom: '12px' }}>Progression</p>
                    <div style={{ display: 'flex', alignItems: 'center' }}>
                        {steps.map((step, i) => (
                            <div key={i} style={{ display: 'flex', alignItems: 'center', flex: i < steps.length - 1 ? 1 : 'none' }}>
                                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '5px' }}>
                                    <div style={{ width: '26px', height: '26px', borderRadius: '50%', backgroundColor: step.done ? P.primaryContainer : P.surfaceContainerHigh, border: '2px solid ' + (step.done ? P.primaryContainer : P.outlineVariant), display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                                        {step.done ? <IconCheck style={{ width: '13px', height: '13px', color: '#fff' }} /> : <span style={{ width: '7px', height: '7px', borderRadius: '50%', backgroundColor: P.outlineVariant, display: 'block' }}></span>}
                                    </div>
                                    <span style={{ fontSize: '10px', fontWeight: step.done ? 600 : 400, color: step.done ? P.onSurface : P.outline, whiteSpace: 'nowrap' }}>{step.label}</span>
                                </div>
                                {i < steps.length - 1 && <div style={{ flex: 1, height: '2px', backgroundColor: step.done ? P.primaryContainer : P.surfaceContainerHigh, margin: '0 4px', marginBottom: '18px' }}></div>}
                            </div>
                        ))}
                    </div>
                </div>
            )}

            {livraison?.status === 'Suspendu' && (
                <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', borderRadius: '10px', padding: '12px 16px', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <IconAlert style={{ width: '15px', height: '15px', color: P.error, flexShrink: 0 }} />
                    <div>
                        <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onErrorContainer }}>Livraison suspendue</p>
                        <p style={{ margin: '2px 0 0 0', fontSize: '12px', color: P.error }}>Motif : {livraison?.suspension_reason || 'Non precise'}</p>
                    </div>
                </div>
            )}

            {successMsg && <div style={{ backgroundColor: '#c8e6c9', border: '1px solid #a5d6a7', color: '#1b5e20', padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>{successMsg}</div>}
            {error && <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>{error}</div>}

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                {/* Infos livraison */}
                <div style={cardStyle}>
                    <p style={{ fontSize: '14px', fontWeight: 700, color: P.onSurface, margin: '0 0 14px 0' }}>Details livraison</p>
                    <div style={{ display: 'grid', gap: '12px' }}>
                        <div><p style={labelStyle}>Adresse</p><p style={valueStyle}>{livraison?.delivery_address}</p></div>
                        {livraison?.zone_bloc && <div><p style={labelStyle}>Description lieu</p><p style={valueStyle}>{livraison.zone_bloc}</p></div>}
                        {livraison?.delivery_instructions && <div><p style={labelStyle}>Instructions</p><p style={valueStyle}>{livraison.delivery_instructions}</p></div>}
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
                            <div><p style={labelStyle}>A collecter</p><p style={{ ...valueStyle, fontWeight: 700, color: P.primary }}>{livraison?.amount_to_collect ? Number(livraison.amount_to_collect).toLocaleString('fr-FR') + ' FCFA' : '—'}</p></div>
                            <div><p style={labelStyle}>Collecte</p><p style={{ ...valueStyle, color: '#1b5e20', fontWeight: 600 }}>{livraison?.collected_amount ? Number(livraison.collected_amount).toLocaleString('fr-FR') + ' FCFA' : '0 FCFA'}</p></div>
                        </div>
                        <div><p style={labelStyle}>Date creation</p><p style={valueStyle}>{livraison?.creation_date ? new Date(livraison.creation_date).toLocaleString('fr-FR') : '—'}</p></div>
                        {livraison?.delivery_date && <div><p style={labelStyle}>Date livraison</p><p style={valueStyle}>{new Date(livraison.delivery_date).toLocaleString('fr-FR')}</p></div>}
                    </div>
                </div>

                {/* Client + Livreur */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                    <div style={{ ...cardStyle, marginBottom: 0 }}>
                        <p style={{ fontSize: '13px', fontWeight: 700, color: P.onSurface, margin: '0 0 12px 0' }}>Client</p>
                        {livraison?.customers ? (
                            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                <div style={{ width: '34px', height: '34px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '13px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>{livraison.customers.users?.first_name?.[0]}</div>
                                <div>
                                    <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onSurface }}>{livraison.customers.users?.first_name} {livraison.customers.users?.last_name}</p>
                                    <p style={{ margin: '2px 0 0 0', fontSize: '11px', color: P.outline }}>{livraison.customers.users?.phone}</p>
                                </div>
                            </div>
                        ) : <p style={{ color: P.outline, fontSize: '13px', margin: 0 }}>—</p>}
                    </div>
                    <div style={{ ...cardStyle, marginBottom: 0 }}>
                        <p style={{ fontSize: '13px', fontWeight: 700, color: P.onSurface, margin: '0 0 12px 0' }}>Livreur assigne</p>
                        {livraison?.delivery_persons ? (
                            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                <div style={{ width: '34px', height: '34px', borderRadius: '50%', backgroundColor: P.primaryContainer, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '13px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>{livraison.delivery_persons.users?.first_name?.[0]}</div>
                                <div>
                                    <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onSurface }}>{livraison.delivery_persons.users?.first_name} {livraison.delivery_persons.users?.last_name}</p>
                                    <p style={{ margin: '2px 0 0 0', fontSize: '11px', color: P.outline }}>{livraison.delivery_persons.vehicules?.brand} {livraison.delivery_persons.vehicules?.type} — {livraison.delivery_persons.vehicules?.plate_number}</p>
                                </div>
                                <Link to={'/livreurs/' + livraison.delivery_persons.id} style={{ marginLeft: 'auto', fontSize: '11px', color: P.primary, fontWeight: 600, textDecoration: 'none' }}>Voir fiche</Link>
                            </div>
                        ) : <p style={{ color: P.outline, fontSize: '13px', margin: 0 }}>Non assigne</p>}
                    </div>
                </div>
            </div>

            {/* Articles */}
            {livraison?.delivery_items?.length > 0 && (
                <div style={cardStyle}>
                    <p style={{ fontSize: '14px', fontWeight: 700, color: P.onSurface, margin: '0 0 12px 0' }}>Articles ({livraison.delivery_items.length})</p>
                    <div style={{ display: 'grid', gap: '6px' }}>
                        {livraison.delivery_items.map((item, i) => (
                            <div key={i} style={{ padding: '9px 14px', borderRadius: '8px', backgroundColor: P.surfaceContainerLow, border: '1px solid ' + P.outlineVariant, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                <span style={{ fontSize: '13px', fontWeight: 500, color: P.onSurface }}>{item.product_name}</span>
                                <span style={{ fontSize: '10px', fontWeight: 600, color: item.status === 'Disponible' ? '#1b5e20' : P.onPrimaryContainer, backgroundColor: item.status === 'Disponible' ? '#c8e6c9' : P.primaryFixed, padding: '2px 8px', borderRadius: '4px' }}>
                                    {item.status === 'Disponible' ? 'Disponible' : 'Plus tard'}
                                </span>
                            </div>
                        ))}
                    </div>
                </div>
            )}

            {/* ── RAPPORT LIVREUR après clôture ─────────────────────── */}
            {livraison?.status === 'Livr_' && (
                <div style={{ ...cardStyle, border: rapport ? '1px solid #a5d6a7' : '1px solid ' + P.outlineVariant, backgroundColor: rapport ? '#f0fdf4' : P.surface }}>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '12px' }}>
                        <p style={{ fontSize: '14px', fontWeight: 700, color: P.onSurface, margin: 0 }}>Rapport de livraison</p>
                        {rapport ? (
                            <span style={{ backgroundColor: '#c8e6c9', color: '#1b5e20', padding: '3px 10px', borderRadius: '5px', fontSize: '11px', fontWeight: 600 }}>Soumis par le livreur</span>
                        ) : (
                            <span style={{ backgroundColor: P.surfaceContainerHigh, color: P.onSurfaceVariant, padding: '3px 10px', borderRadius: '5px', fontSize: '11px', fontWeight: 600 }}>Aucun rapport</span>
                        )}
                    </div>
                    {rapport ? (
                        <div style={{ display: 'grid', gap: '12px' }}>
                            <div>
                                <p style={labelStyle}>Observations du livreur</p>
                                <div style={{ padding: '12px 14px', borderRadius: '8px', backgroundColor: '#fff', border: '1px solid #a5d6a7' }}>
                                    <p style={{ margin: 0, fontSize: '13px', color: P.onSurface, lineHeight: 1.6, whiteSpace: 'pre-wrap' }}>{rapport.contenu}</p>
                                </div>
                            </div>
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                                <div><p style={labelStyle}>Soumis le</p><p style={valueStyle}>{rapport.dateCreation ? new Date(rapport.dateCreation).toLocaleString('fr-FR') : '—'}</p></div>
                                <div><p style={labelStyle}>Auteur</p><p style={valueStyle}>{rapport.auteur || 'Livreur'}</p></div>
                            </div>
                            {/* Validation rapport par manager */}
                            <div style={{ padding: '12px 14px', borderRadius: '8px', backgroundColor: P.surfaceContainerLow, border: '1px solid ' + P.outlineVariant, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                                <p style={{ margin: 0, fontSize: '12px', color: P.onSurfaceVariant }}>Le manager peut valider ou contester ce rapport.</p>
                                <div style={{ display: 'flex', gap: '8px' }}>
                                    <button onClick={() => { if (window.confirm('Valider ce rapport ?')) { setSuccessMsg('Rapport valide.'); } }}
                                        style={{ padding: '6px 14px', borderRadius: '7px', backgroundColor: '#c8e6c9', color: '#1b5e20', fontSize: '11px', fontWeight: 600, border: 'none', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                        Valider
                                    </button>
                                    <button onClick={() => { if (window.confirm('Contester ce rapport ?')) { setSuccessMsg('Rapport conteste. A traiter.'); } }}
                                        style={{ padding: '6px 14px', borderRadius: '7px', backgroundColor: P.errorContainer, color: P.onErrorContainer, fontSize: '11px', fontWeight: 600, border: 'none', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                        Contester
                                    </button>
                                </div>
                            </div>
                        </div>
                    ) : (
                        <p style={{ margin: 0, fontSize: '13px', color: P.outline, fontStyle: 'italic' }}>
                            Aucun rapport soumis par le livreur pour cette livraison.
                        </p>
                    )}
                </div>
            )}

            {/* Actions */}
            <div style={cardStyle}>
                <p style={{ fontSize: '14px', fontWeight: 700, color: P.onSurface, margin: '0 0 6px 0' }}>Actions</p>
                <p style={{ fontSize: '11px', color: P.outline, margin: '0 0 16px 0' }}>
                    {livraison?.status === 'En_attente' && 'Assigner un livreur ou annuler la livraison.'}
                    {livraison?.status === 'Assign_'    && 'En attente d\'acceptation livreur. Suspension possible.'}
                    {livraison?.status === 'En_cours'   && 'Tracking actif. Suspension possible si incident.'}
                    {livraison?.status === 'Suspendu'   && 'Reassignez un nouveau livreur pour reprendre.'}
                    {livraison?.status === 'Livr_'      && 'Livraison completee.'}
                    {livraison?.status === 'Annul_'     && 'Livraison annulee.'}
                </p>

                <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap', marginBottom: '14px' }}>
                    {livraison?.status === 'En_attente' && (
                        <button onClick={() => setShowAssignerForm(!showAssignerForm)} style={btnPrimary}>Assigner un livreur</button>
                    )}
                    {livraison?.status === 'Suspendu' && (
                        <button onClick={() => setShowReassignerForm(!showReassignerForm)} style={btnPrimary}>Reassigner</button>
                    )}
                    {['Assign_','En_cours'].includes(livraison?.status) && (
                        <button onClick={() => setShowSuspendreForm(!showSuspendreForm)}
                            style={{ padding: '10px 18px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.primaryFixed, color: P.onPrimaryContainer, fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                            Suspendre
                        </button>
                    )}
                    {!['Livr_','Annul_'].includes(livraison?.status) && (
                        <Link to={'/livraisons/' + id + '/edit'}
                            style={{ padding: '10px 18px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, fontSize: '13px', fontWeight: 500, textDecoration: 'none', display: 'inline-flex', alignItems: 'center' }}>
                            Modifier
                        </Link>
                    )}
                    {['En_attente','Suspendu'].includes(livraison?.status) && (
                        <button onClick={() => { if (window.confirm('Annuler cette livraison ?')) doAction('/livraisons/' + id + '/annuler', null, 'Livraison annulee.'); }} disabled={actionLoading}
                            style={{ padding: '10px 18px', borderRadius: '10px', border: '1px solid rgba(186,26,26,0.3)', backgroundColor: P.errorContainer, color: P.onErrorContainer, fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                            Annuler
                        </button>
                    )}
                    <button onClick={handleBordereau}
                        style={{ padding: '10px 18px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, color: P.onSurfaceVariant, fontSize: '13px', fontWeight: 500, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                        Bordereau PDF
                    </button>
                </div>

                {/* Formulaire assignation */}
                {showAssignerForm && (
                    <div style={{ padding: '14px', backgroundColor: P.surfaceContainerLow, borderRadius: '10px', border: '1px solid ' + P.outlineVariant, marginBottom: '10px' }}>
                        <p style={{ margin: '0 0 10px 0', fontSize: '13px', fontWeight: 700, color: P.onSurface }}>Assigner un livreur</p>
                        <div style={{ display: 'flex', gap: '10px' }}>
                            <select value={assignerForm.delivery_person_id} onChange={e => setAssignerForm({ delivery_person_id: e.target.value })} required
                                style={{ flex: 1, padding: '10px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, fontSize: '13px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none', backgroundColor: P.surface }}>
                                <option value="">-- Selectionner --</option>
                                {livreurs.filter(l => l.status === 'Disponible').map(l => (
                                    <option key={l.id} value={l.id}>{l.users?.first_name} {l.users?.last_name} — {l.zone_affectee}</option>
                                ))}
                            </select>
                            <button onClick={() => doAction('/livraisons/' + id + '/assigner', assignerForm, 'Livraison assignee.')} disabled={actionLoading || !assignerForm.delivery_person_id} style={btnPrimary}>
                                {actionLoading ? '...' : 'Confirmer'}
                            </button>
                            <button onClick={() => setShowAssignerForm(false)} style={{ padding: '10px 14px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, fontSize: '13px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>Annuler</button>
                        </div>
                    </div>
                )}

                {/* Formulaire réassignation */}
                {showReassignerForm && (
                    <div style={{ padding: '14px', backgroundColor: P.errorContainer, borderRadius: '10px', border: '1px solid rgba(186,26,26,0.2)', marginBottom: '10px' }}>
                        <p style={{ margin: '0 0 10px 0', fontSize: '13px', fontWeight: 700, color: P.onErrorContainer }}>Reassigner a un nouveau livreur</p>
                        <div style={{ display: 'flex', gap: '10px' }}>
                            <select value={reassignerForm.delivery_person_id} onChange={e => setReassignerForm({ delivery_person_id: e.target.value })} required
                                style={{ flex: 1, padding: '10px 14px', borderRadius: '10px', border: '1.5px solid rgba(186,26,26,0.3)', fontSize: '13px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none', backgroundColor: P.surface }}>
                                <option value="">-- Nouveau livreur --</option>
                                {livreurs.filter(l => l.status === 'Disponible' && l.id !== livraison?.delivery_person_id).map(l => (
                                    <option key={l.id} value={l.id}>{l.users?.first_name} {l.users?.last_name} — {l.zone_affectee}</option>
                                ))}
                            </select>
                            <button onClick={() => doAction('/livraisons/' + id + '/assigner', reassignerForm, 'Livraison reassignee.')} disabled={actionLoading || !reassignerForm.delivery_person_id}
                                style={{ ...btnPrimary, backgroundColor: P.error }}>
                                {actionLoading ? '...' : 'Confirmer'}
                            </button>
                            <button onClick={() => setShowReassignerForm(false)} style={{ padding: '10px 14px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, fontSize: '13px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>Annuler</button>
                        </div>
                    </div>
                )}

                {/* Formulaire suspension */}
                {showSuspendreForm && (
                    <div style={{ padding: '14px', backgroundColor: P.surfaceContainerLow, borderRadius: '10px', border: '1px solid ' + P.outlineVariant }}>
                        <p style={{ margin: '0 0 10px 0', fontSize: '13px', fontWeight: 700, color: P.onSurface }}>Motif de suspension</p>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                            <select value={suspendreForm.suspension_reason} onChange={e => setSuspendreForm({ suspension_reason: e.target.value })} required
                                style={{ padding: '10px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, fontSize: '13px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none', backgroundColor: P.surface }}>
                                <option value="">-- Type incident --</option>
                                <option value="Panne vehicule">Panne vehicule</option>
                                <option value="Colis perdu">Colis perdu</option>
                                <option value="Colis casse">Colis casse</option>
                                <option value="Annulation client">Annulation client</option>
                                <option value="Autre">Autre</option>
                            </select>
                            <div style={{ display: 'flex', gap: '10px' }}>
                                <button onClick={() => doAction('/livraisons/' + id + '/suspendre', suspendreForm, 'Livraison suspendue.')} disabled={actionLoading || !suspendreForm.suspension_reason}
                                    style={{ ...btnPrimary, backgroundColor: P.onPrimaryContainer }}>
                                    {actionLoading ? '...' : 'Confirmer suspension'}
                                </button>
                                <button onClick={() => setShowSuspendreForm(false)} style={{ padding: '10px 14px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, fontSize: '13px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>Annuler</button>
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}