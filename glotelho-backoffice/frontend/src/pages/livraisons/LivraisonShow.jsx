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
    const [waLink, setWaLink] = useState('');
    const [trackingUrl, setTrackingUrl] = useState('');

    const [showAssignerForm, setShowAssignerForm]     = useState(false);
    const [showReassignerForm, setShowReassignerForm] = useState(false);
    const [assignerForm, setAssignerForm]     = useState({ delivery_person_id: '' });
    const [reassignerForm, setReassignerForm] = useState({ delivery_person_id: '' });

    function charger() {
        api.get('/livraisons/' + id)
            .then(res => {
                setLivraison(res.data);
                const rapports = res.data.rapports || [];
                const r = rapports.find(function(r) { return r.type === 'livraison'; }) || null;
                setRapport(r);
            })
            .catch(function() { setError('Livraison introuvable.'); })
            .finally(function() { setLoading(false); });
    }

    useEffect(function() {
        charger();
        api.get('/livreurs').then(function(res) { setLivreurs(res.data); }).catch(function() {});
    }, [id]);

    async function doAction(route, body, msg) {
        setActionLoading(true);
        setError('');
        try {
            var r = await (body ? api.post(route, body) : api.post(route));
            setSuccessMsg(msg);

            // Si la reponse contient un lien WhatsApp — ouvrir automatiquement
            if (r.data && r.data.whatsapp_link) {
                setWaLink(r.data.whatsapp_link);
                window.open(r.data.whatsapp_link, '_blank');
            }
            if (r.data && r.data.tracking_url) {
                setTrackingUrl(r.data.tracking_url);
            }

            setShowAssignerForm(false);
            setShowReassignerForm(false);
            charger();
        } catch (err) {
            setError(
                (err.response && err.response.data && err.response.data.message)
                    ? err.response.data.message
                    : 'Erreur.'
            );
        } finally {
            setActionLoading(false);
        }
    }

    async function handleBordereau() {
        try {
            var response = await api.get('/bordereaux/livraison/' + id, { responseType: 'blob' });
            var url = window.URL.createObjectURL(new Blob([response.data], { type: 'application/pdf' }));
            var a = document.createElement('a');
            a.href = url;
            a.download = 'bordereau-' + id + '.pdf';
            document.body.appendChild(a);
            a.click();
            a.remove();
        } catch (e) {
            setError('Impossible de generer le bordereau.');
        }
    }

    if (loading) return <p style={{ fontFamily: 'Poppins, sans-serif', color: P.outline, textAlign: 'center', marginTop: '60px' }}>Chargement...</p>;
    if (error && !livraison) return <p style={{ fontFamily: 'Poppins, sans-serif', color: P.error, textAlign: 'center', marginTop: '60px' }}>{error}</p>;

    var sc = statusConfig[livraison && livraison.status] || statusConfig['En_attente'];
    var border = '1px solid ' + P.outlineVariant;
    var cardStyle = { backgroundColor: P.surface, borderRadius: '14px', border: border, padding: '20px', boxShadow: '0 1px 4px rgba(0,0,0,0.05)', marginBottom: '14px' };
    var labelStyle = { fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.07em', margin: '0 0 3px 0' };
    var valueStyle = { fontSize: '13px', color: P.onSurface, fontWeight: 500, margin: 0 };
    var btnPrimary = { padding: '10px 18px', borderRadius: '10px', border: 'none', backgroundColor: P.primary, color: '#fff', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: '0 2px 8px rgba(125,87,0,0.25)' };

    var livraisonId = livraison && livraison.id ? String(livraison.id).padStart(5, '0') : '00000';

    var steps = [
        { label: 'Creee',    done: true },
        { label: 'Assignee', done: livraison && ['Assign_','En_cours','Livr_'].includes(livraison.status) },
        { label: 'En cours', done: livraison && ['En_cours','Livr_'].includes(livraison.status) },
        { label: 'Livree',   done: livraison && livraison.status === 'Livr_' },
    ];

    // Construire le lien WhatsApp depuis les infos de la livraison
    var waLinkFromLivraison = '';
    if (livraison) {
        var waTel = (livraison.client_whatsapp || livraison.client_telephone || '').replace(/\s/g, '').replace(/\+/g, '');
        if (waTel && !waTel.startsWith('237')) waTel = '237' + waTel;
        var otp = '';
        if (livraison.confirmations && livraison.confirmations.length > 0) {
            otp = livraison.confirmations[0].otp_code || '';
        }
        var clientNom = livraison.client_nom || (livraison.customers && livraison.customers.users ? livraison.customers.users.first_name + ' ' + livraison.customers.users.last_name : 'Client');
        var waMsg = 'Bonjour ' + clientNom + ' !\n\n' +
            'Votre commande Glotelho est en cours de livraison.\n' +
            'Numero : ' + livraisonId + '\n\n' +
            'Suivez votre livreur :\n' + (trackingUrl || 'http://localhost:5173/suivi/' + livraison.id) + '\n\n' +
            'Code a donner au livreur :\n*' + otp + '*\n\nNe partagez pas ce code.';
        waLinkFromLivraison = waTel ? 'https://wa.me/' + waTel + '?text=' + encodeURIComponent(waMsg) : '';
    }

    var finalWaLink = waLink || waLinkFromLivraison;

    return (
        <div style={{ maxWidth: '900px', fontFamily: 'Poppins, sans-serif' }}>
            <BackButton to="/livraisons" />

            {/* Header */}
            <div style={{ marginBottom: '20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                    <Link to="/livraisons" style={{ color: P.outline, textDecoration: 'none', fontSize: '13px' }}>Livraisons</Link>
                    <span style={{ color: P.outlineVariant, margin: '0 6px' }}>/</span>
                    <span style={{ color: P.onSurface, fontSize: '13px', fontWeight: 500 }}>Livraison #{livraisonId}</span>
                </div>
                <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '5px 12px', borderRadius: '6px', fontSize: '12px', fontWeight: 600 }}>{sc.label}</span>
            </div>

            {/* Timeline progression */}
            {livraison && livraison.status !== 'Annul_' && (
                <div style={{ ...cardStyle, padding: '16px 20px' }}>
                    <p style={{ ...labelStyle, marginBottom: '12px' }}>Progression</p>
                    <div style={{ display: 'flex', alignItems: 'center' }}>
                        {steps.map(function(step, i) {
                            return (
                                <div key={i} style={{ display: 'flex', alignItems: 'center', flex: i < steps.length - 1 ? 1 : 'none' }}>
                                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '5px' }}>
                                        <div style={{ width: '26px', height: '26px', borderRadius: '50%', backgroundColor: step.done ? P.primaryContainer : P.surfaceContainerHigh, border: '2px solid ' + (step.done ? P.primaryContainer : P.outlineVariant), display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                                            {step.done
                                                ? <IconCheck style={{ width: '13px', height: '13px', color: '#fff' }} />
                                                : <span style={{ width: '7px', height: '7px', borderRadius: '50%', backgroundColor: P.outlineVariant, display: 'block' }}></span>
                                            }
                                        </div>
                                        <span style={{ fontSize: '10px', fontWeight: step.done ? 600 : 400, color: step.done ? P.onSurface : P.outline, whiteSpace: 'nowrap' }}>{step.label}</span>
                                    </div>
                                    {i < steps.length - 1 && <div style={{ flex: 1, height: '2px', backgroundColor: step.done ? P.primaryContainer : P.surfaceContainerHigh, margin: '0 4px', marginBottom: '18px' }}></div>}
                                </div>
                            );
                        })}
                    </div>
                </div>
            )}

            {/* Alerte suspendu */}
            {livraison && livraison.status === 'Suspendu' && (
                <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', borderRadius: '10px', padding: '12px 16px', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <IconAlert style={{ width: '15px', height: '15px', color: P.error, flexShrink: 0 }} />
                    <div>
                        <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onErrorContainer }}>Livraison suspendue</p>
                        <p style={{ margin: '2px 0 0 0', fontSize: '12px', color: P.error }}>Motif : {livraison.suspension_reason || 'Non precise'}</p>
                    </div>
                </div>
            )}

            {successMsg && (
                <div style={{ backgroundColor: '#c8e6c9', border: '1px solid #a5d6a7', color: '#1b5e20', padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>
                    {successMsg}
                </div>
            )}
            {error && (
                <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>
                    {error}
                </div>
            )}

            {/* Bouton WhatsApp — visible si livraison en cours ou assignee */}
            {livraison && ['Assign_', 'En_cours'].includes(livraison.status) && finalWaLink && (
                <div style={{ backgroundColor: '#f0fdf4', border: '1px solid #a5d6a7', borderRadius: '12px', padding: '14px 18px', marginBottom: '14px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <div>
                        <p style={{ margin: '0 0 3px 0', fontSize: '13px', fontWeight: 700, color: '#1b5e20' }}>Notification client</p>
                        <p style={{ margin: 0, fontSize: '12px', color: '#4caf50' }}>
                            Envoyez le lien de tracking et le code OTP au client via WhatsApp.
                        </p>
                    </div>
                    <a href={finalWaLink} target="_blank" rel="noreferrer"
                        style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', padding: '11px 20px', borderRadius: '10px', backgroundColor: '#25D366', color: '#fff', textDecoration: 'none', fontSize: '13px', fontWeight: 700, flexShrink: 0, boxShadow: '0 3px 10px rgba(37,211,102,0.35)' }}>
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="white"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/></svg>
                        Envoyer sur WhatsApp
                    </a>
                </div>
            )}

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                {/* Infos livraison */}
                <div style={cardStyle}>
                    <p style={{ fontSize: '14px', fontWeight: 700, color: P.onSurface, margin: '0 0 14px 0' }}>Details livraison</p>
                    <div style={{ display: 'grid', gap: '12px' }}>
                        <div><p style={labelStyle}>Adresse</p><p style={valueStyle}>{livraison && livraison.delivery_address}</p></div>
                        {livraison && livraison.zone_bloc && <div><p style={labelStyle}>Description lieu</p><p style={valueStyle}>{livraison.zone_bloc}</p></div>}
                        {livraison && livraison.delivery_instructions && <div><p style={labelStyle}>Instructions</p><p style={valueStyle}>{livraison.delivery_instructions}</p></div>}
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
                            <div><p style={labelStyle}>A collecter</p><p style={{ ...valueStyle, fontWeight: 700, color: P.primary }}>{livraison && livraison.amount_to_collect ? Number(livraison.amount_to_collect).toLocaleString('fr-FR') + ' FCFA' : '—'}</p></div>
                            <div><p style={labelStyle}>Collecte</p><p style={{ ...valueStyle, color: '#1b5e20', fontWeight: 600 }}>{livraison && livraison.collected_amount ? Number(livraison.collected_amount).toLocaleString('fr-FR') + ' FCFA' : '0 FCFA'}</p></div>
                        </div>
                        <div><p style={labelStyle}>Date creation</p><p style={valueStyle}>{livraison && livraison.creation_date ? new Date(livraison.creation_date).toLocaleString('fr-FR') : '—'}</p></div>
                        {livraison && livraison.delivery_date && <div><p style={labelStyle}>Date livraison souhaitee</p><p style={valueStyle}>{new Date(livraison.delivery_date).toLocaleString('fr-FR')}</p></div>}
                    </div>
                </div>

                {/* Client + Livreur */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                    {/* Client */}
                    <div style={{ ...cardStyle, marginBottom: 0 }}>
                        <p style={{ fontSize: '13px', fontWeight: 700, color: P.onSurface, margin: '0 0 12px 0' }}>Client</p>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                            <div style={{ width: '34px', height: '34px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '13px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>
                                {livraison && livraison.client_nom ? livraison.client_nom[0] : (livraison && livraison.customers && livraison.customers.users ? livraison.customers.users.first_name[0] : '?')}
                            </div>
                            <div>
                                <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onSurface }}>
                                    {livraison && (livraison.client_nom || (livraison.customers && livraison.customers.users ? livraison.customers.users.first_name + ' ' + livraison.customers.users.last_name : '—'))}
                                </p>
                                <p style={{ margin: '2px 0 0 0', fontSize: '11px', color: P.outline }}>
                                    {livraison && (livraison.client_telephone || (livraison.customers && livraison.customers.users ? livraison.customers.users.phone : ''))}
                                </p>
                                {livraison && livraison.client_whatsapp && livraison.client_whatsapp !== livraison.client_telephone && (
                                    <p style={{ margin: '1px 0 0 0', fontSize: '11px', color: '#25D366' }}>WA : {livraison.client_whatsapp}</p>
                                )}
                            </div>
                        </div>
                    </div>

                    {/* Livreur */}
                    <div style={{ ...cardStyle, marginBottom: 0 }}>
                        <p style={{ fontSize: '13px', fontWeight: 700, color: P.onSurface, margin: '0 0 12px 0' }}>Livreur assigne</p>
                        {livraison && livraison.delivery_persons ? (function() {
                            var dp = livraison.delivery_persons;
                            var livreurUser = Array.isArray(dp.users)
                                ? (dp.users.find(function(u) { return u.id === dp.user_id; }) || dp.users[0] || null)
                                : (dp.users || dp.user || null);
                            var photo = dp.photo_profil_url;
                            var nom   = livreurUser ? livreurUser.first_name + ' ' + livreurUser.last_name : '—';
                            var initiale = livreurUser ? livreurUser.first_name[0] : '?';
                            return (
                                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                    <div style={{ width: '40px', height: '40px', borderRadius: '50%', overflow: 'hidden', flexShrink: 0, border: '2px solid ' + P.primaryContainer }}>
                                        {photo
                                            ? <img src={photo} alt={nom} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                                            : <div style={{ width: '100%', height: '100%', backgroundColor: P.primaryContainer, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '14px', fontWeight: 700, color: '#fff' }}>{initiale}</div>
                                        }
                                    </div>
                                    <div>
                                        <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onSurface }}>{nom}</p>
                                        <p style={{ margin: '2px 0 0 0', fontSize: '11px', color: P.outline }}>
                                            {dp.vehicules ? dp.vehicules.brand + ' ' + dp.vehicules.type + ' — ' + dp.vehicules.plate_number : dp.vehicule_type + ' ' + dp.vehicule_marque}
                                        </p>
                                        {livreurUser && livreurUser.phone && <p style={{ margin: '1px 0 0 0', fontSize: '11px', color: P.outline }}>📞 {livreurUser.phone}</p>}
                                    </div>
                                    <Link to={'/livreurs/' + dp.id} style={{ marginLeft: 'auto', fontSize: '11px', color: P.primary, fontWeight: 600, textDecoration: 'none' }}>Voir fiche</Link>
                                </div>
                            );
                        })() : <p style={{ color: P.outline, fontSize: '13px', margin: 0 }}>Non assigne</p>}
                    </div>
                </div>
            </div>

            {/* OTP */}
            {livraison && livraison.confirmations && livraison.confirmations.length > 0 && livraison.confirmations[0].otp_code && (
                <div style={{ ...cardStyle, backgroundColor: P.inverseS, border: 'none' }}>
                    <p style={{ ...labelStyle, color: 'rgba(241,241,241,0.4)', marginBottom: '8px' }}>Code OTP de confirmation</p>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                        <p style={{ margin: 0, fontSize: '32px', fontWeight: 900, color: P.primaryContainer, letterSpacing: '0.2em', fontFamily: 'monospace' }}>
                            {livraison.confirmations[0].otp_code}
                        </p>
                        <p style={{ margin: 0, fontSize: '11px', color: 'rgba(241,241,241,0.3)', maxWidth: '200px', textAlign: 'right' }}>
                            Ce code sera demande par le livreur au client pour confirmer la remise du colis.
                        </p>
                    </div>
                </div>
            )}

            {/* Articles */}
            {livraison && livraison.delivery_items && livraison.delivery_items.length > 0 && (
                <div style={cardStyle}>
                    <p style={{ fontSize: '14px', fontWeight: 700, color: P.onSurface, margin: '0 0 12px 0' }}>Articles ({livraison.delivery_items.length})</p>
                    <div style={{ display: 'grid', gap: '6px' }}>
                        {livraison.delivery_items.map(function(item, i) {
                            return (
                                <div key={i} style={{ padding: '10px 14px', borderRadius: '8px', backgroundColor: P.surfaceContainerLow, border: '1px solid ' + P.outlineVariant, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                    <div>
                                        <span style={{ fontSize: '13px', fontWeight: 500, color: P.onSurface }}>{item.product_name}</span>
                                        {item.quantity && <span style={{ fontSize: '11px', color: P.outline, marginLeft: '8px' }}>x{item.quantity}</span>}
                                    </div>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                        {item.unit_price && (
                                            <span style={{ fontSize: '12px', fontWeight: 600, color: P.primary }}>
                                                {(Number(item.unit_price) * (item.quantity || 1)).toLocaleString('fr-FR')} FCFA
                                            </span>
                                        )}
                                        <span style={{ fontSize: '10px', fontWeight: 600, color: item.status === 'Disponible' ? '#1b5e20' : P.onPrimaryContainer, backgroundColor: item.status === 'Disponible' ? '#c8e6c9' : P.primaryFixed, padding: '2px 8px', borderRadius: '4px' }}>
                                            {item.status === 'Disponible' ? 'Disponible' : item.status || 'En attente'}
                                        </span>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                </div>
            )}

            {/* Rapport livreur */}
            {livraison && livraison.status === 'Livr_' && (
                <div style={{ ...cardStyle, border: rapport ? '1px solid #a5d6a7' : border, backgroundColor: rapport ? '#f0fdf4' : P.surface }}>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '12px' }}>
                        <p style={{ fontSize: '14px', fontWeight: 700, color: P.onSurface, margin: 0 }}>Rapport de livraison</p>
                        {rapport
                            ? <span style={{ backgroundColor: '#c8e6c9', color: '#1b5e20', padding: '3px 10px', borderRadius: '5px', fontSize: '11px', fontWeight: 600 }}>Soumis</span>
                            : <span style={{ backgroundColor: P.surfaceContainerHigh, color: P.onSurfaceVariant, padding: '3px 10px', borderRadius: '5px', fontSize: '11px', fontWeight: 600 }}>Aucun rapport</span>
                        }
                    </div>
                    {rapport ? (
                        <div style={{ display: 'grid', gap: '12px' }}>
                            <div>
                                <p style={labelStyle}>Observations</p>
                                <div style={{ padding: '12px 14px', borderRadius: '8px', backgroundColor: '#fff', border: '1px solid #a5d6a7' }}>
                                    <p style={{ margin: 0, fontSize: '13px', color: P.onSurface, lineHeight: 1.6, whiteSpace: 'pre-wrap' }}>{rapport.observations || rapport.contenu}</p>
                                </div>
                            </div>
                        </div>
                    ) : (
                        <p style={{ margin: 0, fontSize: '13px', color: P.outline, fontStyle: 'italic' }}>Aucun rapport soumis par le livreur.</p>
                    )}
                </div>
            )}

            {/* Actions */}
            <div style={cardStyle}>
                <p style={{ fontSize: '14px', fontWeight: 700, color: P.onSurface, margin: '0 0 6px 0' }}>Actions</p>
                <p style={{ fontSize: '11px', color: P.outline, margin: '0 0 16px 0' }}>
                    {livraison && livraison.status === 'En_attente' && 'Assigner un livreur ou annuler la livraison.'}
                    {livraison && livraison.status === 'Assign_'    && 'En attente d\'acceptation livreur.'}
                    {livraison && livraison.status === 'En_cours'   && 'Livraison en cours — tracking actif.'}
                    {livraison && livraison.status === 'Suspendu'   && 'Reassignez un nouveau livreur pour reprendre.'}
                    {livraison && livraison.status === 'Livr_'      && 'Livraison completee avec succes.'}
                    {livraison && livraison.status === 'Annul_'     && 'Livraison annulee.'}
                </p>

                <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap', marginBottom: '14px' }}>
                    {livraison && livraison.status === 'En_attente' && (
                        <button onClick={function() { setShowAssignerForm(!showAssignerForm); }} style={btnPrimary}>
                            Assigner un livreur
                        </button>
                    )}
                    {livraison && livraison.status === 'Suspendu' && (
                        <button onClick={function() { setShowReassignerForm(!showReassignerForm); }} style={btnPrimary}>
                            Reassigner
                        </button>
                    )}
                    {livraison && !['Livr_','Annul_'].includes(livraison.status) && (
                        <Link to={'/livraisons/' + id + '/edit'}
                            style={{ padding: '10px 18px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, fontSize: '13px', fontWeight: 500, textDecoration: 'none', display: 'inline-flex', alignItems: 'center' }}>
                            Modifier
                        </Link>
                    )}
                    {livraison && ['En_attente','Suspendu'].includes(livraison.status) && (
                        <button onClick={function() { if (window.confirm('Annuler cette livraison ?')) doAction('/livraisons/' + id + '/annuler', null, 'Livraison annulee.'); }} disabled={actionLoading}
                            style={{ padding: '10px 18px', borderRadius: '10px', border: '1px solid rgba(186,26,26,0.3)', backgroundColor: P.errorContainer, color: P.onErrorContainer, fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                            Annuler
                        </button>
                    )}
                    <button onClick={handleBordereau}
                        style={{ padding: '10px 18px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, color: P.onSurfaceVariant, fontSize: '13px', fontWeight: 500, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                        Bordereau PDF
                    </button>

                    {/* Bouton Tracking GPS — visible si livraison en cours */}
                    {livraison && ['Assign_', 'En_cours'].includes(livraison.status) && (
                        <Link to={'/suivi/' + id}
                            style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', padding: '10px 18px', borderRadius: '10px', backgroundColor: '#2f3131', color: '#fff', textDecoration: 'none', fontSize: '13px', fontWeight: 700, boxShadow: '0 2px 8px rgba(0,0,0,0.2)' }}>
                            📍 Tracking GPS
                        </Link>
                    )}

                    {/* Bouton WhatsApp toujours visible si livraison active */}
                    {livraison && ['Assign_','En_cours'].includes(livraison.status) && finalWaLink && (
                        <a href={finalWaLink} target="_blank" rel="noreferrer"
                            style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', padding: '10px 18px', borderRadius: '10px', backgroundColor: '#25D366', color: '#fff', textDecoration: 'none', fontSize: '13px', fontWeight: 700, boxShadow: '0 2px 8px rgba(37,211,102,0.3)' }}>
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="white"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/></svg>
                            Notifier client WhatsApp
                        </a>
                    )}
                </div>

                {/* Formulaire assignation */}
                {showAssignerForm && (
                    <div style={{ padding: '14px', backgroundColor: P.surfaceContainerLow, borderRadius: '10px', border: '1px solid ' + P.outlineVariant, marginBottom: '10px' }}>
                        <p style={{ margin: '0 0 10px 0', fontSize: '13px', fontWeight: 700, color: P.onSurface }}>Assigner un livreur</p>
                        <div style={{ display: 'flex', gap: '10px' }}>
                            <select value={assignerForm.delivery_person_id}
                                onChange={function(e) { setAssignerForm({ delivery_person_id: e.target.value }); }}
                                style={{ flex: 1, padding: '10px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, fontSize: '13px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none', backgroundColor: P.surface }}>
                                <option value="">-- Selectionner --</option>
                                {livreurs.filter(function(l) { return l.status === 'Disponible'; }).map(function(l) {
                                    var u = Array.isArray(l.users) ? l.users.find(function(u) { return u.id === l.user_id; }) : l.users;
                                    return <option key={l.id} value={l.id}>{u && u.first_name} {u && u.last_name} — {l.zone_affectee || 'Sans zone'}</option>;
                                })}
                            </select>
                            <button onClick={function() { doAction('/livraisons/' + id + '/assigner', assignerForm, 'Livraison assignee. WhatsApp ouvert automatiquement.'); }}
                                disabled={actionLoading || !assignerForm.delivery_person_id} style={btnPrimary}>
                                {actionLoading ? '...' : 'Confirmer'}
                            </button>
                            <button onClick={function() { setShowAssignerForm(false); }}
                                style={{ padding: '10px 14px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, fontSize: '13px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                Annuler
                            </button>
                        </div>
                    </div>
                )}

                {/* Formulaire reassignation */}
                {showReassignerForm && (
                    <div style={{ padding: '14px', backgroundColor: P.errorContainer, borderRadius: '10px', border: '1px solid rgba(186,26,26,0.2)', marginBottom: '10px' }}>
                        <p style={{ margin: '0 0 10px 0', fontSize: '13px', fontWeight: 700, color: P.onErrorContainer }}>Reassigner a un nouveau livreur</p>
                        <div style={{ display: 'flex', gap: '10px' }}>
                            <select value={reassignerForm.delivery_person_id}
                                onChange={function(e) { setReassignerForm({ delivery_person_id: e.target.value }); }}
                                style={{ flex: 1, padding: '10px 14px', borderRadius: '10px', border: '1.5px solid rgba(186,26,26,0.3)', fontSize: '13px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none', backgroundColor: P.surface }}>
                                <option value="">-- Nouveau livreur --</option>
                                {livreurs.filter(function(l) { return l.status === 'Disponible' && l.id !== (livraison && livraison.delivery_person_id); }).map(function(l) {
                                    var u = Array.isArray(l.users) ? l.users.find(function(u) { return u.id === l.user_id; }) : l.users;
                                    return <option key={l.id} value={l.id}>{u && u.first_name} {u && u.last_name} — {l.zone_affectee || 'Sans zone'}</option>;
                                })}
                            </select>
                            <button onClick={function() { doAction('/livraisons/' + id + '/assigner', reassignerForm, 'Livraison reassignee.'); }}
                                disabled={actionLoading || !reassignerForm.delivery_person_id}
                                style={{ ...btnPrimary, backgroundColor: P.error }}>
                                {actionLoading ? '...' : 'Confirmer'}
                            </button>
                            <button onClick={function() { setShowReassignerForm(false); }}
                                style={{ padding: '10px 14px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, fontSize: '13px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                Annuler
                            </button>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}