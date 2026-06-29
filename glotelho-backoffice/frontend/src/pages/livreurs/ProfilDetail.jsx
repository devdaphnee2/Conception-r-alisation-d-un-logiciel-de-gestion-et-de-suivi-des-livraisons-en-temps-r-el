import { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';
import { IconCheck, IconX, IconAlert, IconUser, IconBell } from '../../components/Icons';

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

function Section({ title, children }) {
    return (
        <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, marginBottom: '16px', overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}>
            <div style={{ padding: '11px 20px', borderBottom: '1px solid ' + P.surfaceContainerLow, backgroundColor: P.surfaceContainerLow }}>
                <p style={{ margin: 0, fontSize: '11px', fontWeight: 700, color: P.onSurface, textTransform: 'uppercase', letterSpacing: '0.08em' }}>{title}</p>
            </div>
            <div style={{ padding: '20px' }}>{children}</div>
        </div>
    );
}

function Field({ label, value, highlight }) {
    return (
        <div>
            <p style={{ margin: '0 0 3px 0', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.07em' }}>{label}</p>
            <p style={{ margin: 0, fontSize: '13px', color: highlight ? P.primary : P.onSurface, fontWeight: highlight ? 700 : 500, lineHeight: 1.5 }}>
                {value || <span style={{ color: P.outlineVariant, fontStyle: 'italic' }}>Non renseigne</span>}
            </p>
        </div>
    );
}

function DocPhoto({ label, url, required }) {
    const present = !!url;
    return (
        <div style={{ borderRadius: '12px', border: '1px solid ' + (present ? P.outlineVariant : P.error), overflow: 'hidden' }}>
            <div style={{ padding: '8px 12px', backgroundColor: present ? P.surfaceContainerLow : P.errorContainer, display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '1px solid ' + (present ? P.outlineVariant : P.error) }}>
                <p style={{ margin: 0, fontSize: '11px', fontWeight: 600, color: present ? P.onSurface : P.onErrorContainer }}>
                    {label}{required && <span style={{ color: P.error }}> *</span>}
                </p>
                {present
                    ? <span style={{ fontSize: '10px', fontWeight: 600, color: '#1b5e20', backgroundColor: '#c8e6c9', padding: '2px 8px', borderRadius: '4px' }}>Fourni</span>
                    : <span style={{ fontSize: '10px', fontWeight: 600, color: P.onErrorContainer, backgroundColor: P.errorContainer, padding: '2px 8px', borderRadius: '4px' }}>MANQUANT</span>
                }
            </div>
            {present ? (
                <img src={url} alt={label} style={{ width: '100%', height: '150px', objectFit: 'cover', display: 'block', backgroundColor: P.surfaceContainerHigh }} />
            ) : (
                <div style={{ height: '150px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', backgroundColor: '#fff5f5', gap: '8px' }}>
                    <IconX style={{ width: '28px', height: '28px', color: P.error }} />
                    <p style={{ margin: 0, fontSize: '11px', color: P.error, fontWeight: 600, textAlign: 'center' }}>
                        Document manquant<br /><span style={{ fontWeight: 400, color: P.outline }}>A demander au candidat</span>
                    </p>
                </div>
            )}
        </div>
    );
}

export default function ProfilDetail() {
    const { id } = useParams();
    const [livreur, setLivreur] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [successMsg, setSuccessMsg] = useState('');
    const [actionLoading, setActionLoading] = useState(false);
    const [showRejetModal, setShowRejetModal] = useState(false);
    const [motifRejet, setMotifRejet] = useState('');

    // Notification SMS caution
    const [showSmsModal, setShowSmsModal] = useState(false);
    const [montantCaution, setMontantCaution] = useState('50000');
    const [smsPreview, setSmsPreview] = useState('');
    const [smsEnvoye, setSmsEnvoye] = useState(false);

    function charger() {
        api.get('/profils/' + id)
            .then(res => {
                setLivreur(res.data);
                setMontantCaution(String(res.data.caution_montant || 50000));
            })
            .catch(() => setError('Profil introuvable.'))
            .finally(() => setLoading(false));
    }

    useEffect(() => { charger(); }, [id]);

    // Generer preview SMS
    useEffect(() => {
        if (!livreur) return;
        const montant = Number(montantCaution || 50000);
        const montantStr = montant.toLocaleString('fr-FR');
        setSmsPreview(
            `Bonjour ${livreur.users?.first_name},\n\nVotre profil Glotelho a ete retenu ! 🎉\n\nPour finaliser votre inscription, reglez votre caution de ${montantStr} FCFA dans les 48h :\n\n📱 Orange Money\nCode marchand : 698000000\n*144*1*698000000*${montant}# (puis valider)\n\n📱 MTN MoMo\nCode marchand : 677000000\n*126*1*677000000*${montant}# (puis valider)\n\n📲 Payer via l'app :\nhttps://glotelho.cm/app/livreur/caution\n\nUne fois la caution reglee, votre acces sera active sous 24h.\n\nMerci et bienvenue chez Glotelho !`
        );
    }, [livreur, montantCaution]);

    async function handleEnvoyerSMS(e) {
        e.preventDefault();
        setActionLoading(true);
        setError('');
        try {
            const res = await api.post('/profils/' + id + '/notifier-caution', { montant: parseFloat(montantCaution) });
            setSuccessMsg('SMS envoye a ' + livreur.users?.phone + '. Le livreur a ete notifie.');
            setSmsEnvoye(true);
            setShowSmsModal(false);
            charger();
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur envoi SMS.');
        } finally { setActionLoading(false); }
    }

    async function handleCautionPayee() {
        setActionLoading(true);
        setError('');
        try {
            await api.post('/profils/' + id + '/caution-payee');
            setSuccessMsg('Caution marquee comme payee. Vous pouvez maintenant approuver le profil.');
            charger();
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur.');
        } finally { setActionLoading(false); }
    }

    async function handleApprouver() {
        if (!livreur?.caution_payee) {
            if (!window.confirm('La caution n\'est pas encore marquee comme payee.\nApprouver quand meme ?')) return;
        } else {
            if (!window.confirm('Approuver le profil de ' + livreur?.users?.first_name + ' ' + livreur?.users?.last_name + ' ?')) return;
        }
        setActionLoading(true);
        try {
            const res = await api.post('/profils/' + id + '/approuver');
            setSuccessMsg(res.data.message);
            charger();
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur.');
        } finally { setActionLoading(false); }
    }

    async function handleRejeter(e) {
        e.preventDefault();
        setActionLoading(true);
        try {
            const res = await api.post('/profils/' + id + '/rejeter', { motif: motifRejet });
            setSuccessMsg(res.data.message);
            setShowRejetModal(false);
            charger();
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur.');
        } finally { setActionLoading(false); }
    }

    if (loading) return <p style={{ fontFamily: 'Poppins, sans-serif', color: P.outline, textAlign: 'center', marginTop: '60px' }}>Chargement...</p>;
    if (error && !livreur) return <p style={{ fontFamily: 'Poppins, sans-serif', color: P.error, textAlign: 'center', marginTop: '60px' }}>{error}</p>;

    const statusConfig = {
        'Indisponible': { bg: P.primaryFixed, color: P.onPrimaryContainer, label: 'En attente de validation' },
        'Disponible':   { bg: '#c8e6c9', color: '#1b5e20', label: 'Approuve — Actif' },
        'Hors_service': { bg: P.errorContainer, color: P.onErrorContainer, label: 'Rejete' },
    };
    const sc = statusConfig[livreur?.status] || statusConfig['Indisponible'];

    const alertes = [];
    if (!livreur?.cni_numero) alertes.push('Numero CNI manquant');
    if (!livreur?.cni_photo_avant) alertes.push('Photo CNI recto manquante');
    if (!livreur?.cni_photo_arriere) alertes.push('Photo CNI verso manquante');
    if (!livreur?.permis_photo) alertes.push('Photo permis manquante');

    const inputStyle = { width: '100%', padding: '10px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, fontSize: '13px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none', boxSizing: 'border-box' };
    const btnPrimary = { padding: '11px 22px', borderRadius: '10px', border: 'none', backgroundColor: P.primary, color: '#fff', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: '0 2px 8px rgba(125,87,0,0.25)' };

    return (
        <div style={{ maxWidth: '900px', fontFamily: 'Poppins, sans-serif' }}>
            <BackButton to="/livreurs/profils" />

            {/* BREADCRUMB + STATUT */}
            <div style={{ marginBottom: '20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                    <Link to="/livreurs/profils" style={{ color: P.outline, textDecoration: 'none', fontSize: '13px' }}>Profils en attente</Link>
                    <span style={{ color: P.outlineVariant, margin: '0 6px' }}>/</span>
                    <span style={{ fontSize: '13px', fontWeight: 500, color: P.onSurface }}>{livreur?.users?.first_name} {livreur?.users?.last_name}</span>
                </div>
                <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '5px 14px', borderRadius: '6px', fontSize: '12px', fontWeight: 600 }}>{sc.label}</span>
            </div>

            {/* ALERTES DOSSIER */}
            {alertes.length > 0 && (
                <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.25)', borderRadius: '12px', padding: '14px 18px', marginBottom: '16px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '6px' }}>
                        <IconAlert style={{ width: '15px', height: '15px', color: P.error, flexShrink: 0 }} />
                        <p style={{ margin: 0, fontSize: '13px', fontWeight: 700, color: P.onErrorContainer }}>Dossier incomplet — {alertes.length} point{alertes.length > 1 ? 's' : ''} a corriger</p>
                    </div>
                    {alertes.map((a, i) => <p key={i} style={{ margin: '2px 0 0 12px', fontSize: '12px', color: P.error }}>• {a}</p>)}
                </div>
            )}

            {alertes.length === 0 && (
                <div style={{ backgroundColor: '#f0fdf4', border: '1px solid #a5d6a7', borderRadius: '12px', padding: '12px 18px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <IconCheck style={{ width: '15px', height: '15px', color: '#1b5e20', flexShrink: 0 }} />
                    <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: '#1b5e20' }}>Dossier complet — tous les documents sont fournis.</p>
                </div>
            )}

            {successMsg && <div style={{ backgroundColor: '#c8e6c9', border: '1px solid #a5d6a7', color: '#1b5e20', padding: '10px 16px', borderRadius: '10px', marginBottom: '16px', fontSize: '13px', fontWeight: 500 }}>{successMsg}</div>}
            {error && <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', color: P.error, padding: '10px 16px', borderRadius: '10px', marginBottom: '16px', fontSize: '13px', fontWeight: 500 }}>{error}</div>}

            {/* IDENTITE */}
            <Section title="Identite du candidat">
                <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '20px', paddingBottom: '16px', borderBottom: '1px solid ' + P.surfaceContainerLow }}>
                    <div style={{ width: '56px', height: '56px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '20px', fontWeight: 800, color: '#fff', flexShrink: 0 }}>
                        {livreur?.users?.first_name?.[0]}
                    </div>
                    <div>
                        <p style={{ margin: 0, fontSize: '18px', fontWeight: 700, color: P.onSurface }}>{livreur?.users?.first_name} {livreur?.users?.last_name}</p>
                        <p style={{ margin: '3px 0 0 0', fontSize: '12px', color: P.outline }}>
                            Dossier #{id} — soumis le {livreur?.date_candidature ? new Date(livreur.date_candidature).toLocaleDateString('fr-FR', { day: '2-digit', month: 'long', year: 'numeric' }) : '—'}
                        </p>
                    </div>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                    <Field label="Prenom" value={livreur?.users?.first_name} />
                    <Field label="Nom" value={livreur?.users?.last_name} />
                    <Field label="Telephone" value={livreur?.users?.phone} />
                    <Field label="Email" value={livreur?.users?.email} />
                    <Field label="Adresse domicile" value={livreur?.adresse_domicile} />
                    <Field label="Zone de livraison souhaitee" value={livreur?.zone_affectee} />
                    <Field label="Numero CNI" value={livreur?.cni_numero} highlight />
                    <Field label="Contact urgence" value={livreur?.contact_urgence_nom ? livreur.contact_urgence_nom + ' — ' + livreur.contact_urgence_tel : null} />
                </div>
            </Section>

            {/* VEHICULE */}
            <Section title="Vehicule et permis">
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: '16px' }}>
                    <Field label="Type" value={livreur?.vehicules?.type} />
                    <Field label="Marque" value={livreur?.vehicules?.brand} />
                    <Field label="Plaque" value={livreur?.vehicules?.plate_number} highlight />
                    <Field label="Categorie permis" value={livreur?.permis_categorie ? 'Cat. ' + livreur.permis_categorie : null} highlight />
                </div>
            </Section>

            {/* EXPERIENCE */}
            <Section title="Experience professionnelle">
                <p style={{ margin: 0, fontSize: '13px', color: P.onSurface, lineHeight: 1.7 }}>
                    {livreur?.experience || <span style={{ color: P.outlineVariant, fontStyle: 'italic' }}>Aucune experience renseignee</span>}
                </p>
            </Section>

            {/* DOCUMENTS */}
            <Section title="Documents obligatoires">
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '14px' }}>
                    <DocPhoto label="CNI — Recto" url={livreur?.cni_photo_avant} required />
                    <DocPhoto label="CNI — Verso" url={livreur?.cni_photo_arriere} required />
                    <DocPhoto label="Permis de conduire" url={livreur?.permis_photo} required />
                </div>
            </Section>

            {/* CAUTION — section manager */}
            {livreur?.status === 'Indisponible' && (
                <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, marginBottom: '16px', overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}>
                    <div style={{ padding: '11px 20px', borderBottom: '1px solid ' + P.surfaceContainerLow, backgroundColor: P.surfaceContainerLow }}>
                        <p style={{ margin: 0, fontSize: '11px', fontWeight: 700, color: P.onSurface, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Gestion de la caution</p>
                    </div>
                    <div style={{ padding: '20px' }}>

                        {/* Statut caution */}
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '16px 20px', borderRadius: '12px', backgroundColor: livreur?.caution_payee ? '#f0fdf4' : '#fff5f5', border: '1px solid ' + (livreur?.caution_payee ? '#a5d6a7' : P.error), marginBottom: '20px' }}>
                            <div>
                                <p style={{ margin: '0 0 3px 0', fontSize: '13px', fontWeight: 700, color: livreur?.caution_payee ? '#1b5e20' : P.error }}>
                                    {livreur?.caution_payee ? 'Caution reglee' : 'Caution non reglee'}
                                </p>
                                <p style={{ margin: 0, fontSize: '12px', color: livreur?.caution_payee ? '#4caf50' : P.outline }}>
                                    {livreur?.caution_payee
                                        ? 'Le livreur a verse sa caution. Vous pouvez approuver le profil.'
                                        : 'En attente de paiement. Envoyez la notification SMS au livreur.'}
                                </p>
                            </div>
                            <div style={{ textAlign: 'right' }}>
                                <p style={{ margin: '0 0 6px 0', fontSize: '24px', fontWeight: 800, color: livreur?.caution_payee ? '#1b5e20' : P.error }}>
                                    {Number(livreur?.caution_montant || 50000).toLocaleString('fr-FR')} FCFA
                                </p>
                                <span style={{ fontSize: '11px', fontWeight: 700, padding: '3px 10px', borderRadius: '4px', backgroundColor: livreur?.caution_payee ? '#c8e6c9' : P.errorContainer, color: livreur?.caution_payee ? '#1b5e20' : P.onErrorContainer }}>
                                    {livreur?.caution_payee ? 'PAYEE' : 'NON PAYEE'}
                                </span>
                            </div>
                        </div>

                        <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
                            {/* Envoyer SMS */}
                            {!livreur?.caution_payee && (
                                <button onClick={() => setShowSmsModal(true)}
                                    style={{ display: 'inline-flex', alignItems: 'center', gap: '7px', padding: '10px 20px', borderRadius: '10px', border: 'none', backgroundColor: P.secondary, color: '#fff', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: '0 2px 8px rgba(71,94,139,0.25)' }}>
                                    <IconBell style={{ width: '14px', height: '14px' }} />
                                    Envoyer notification SMS au livreur
                                </button>
                            )}

                            {/* Cocher caution payee */}
                            {!livreur?.caution_payee && (
                                <label style={{ display: 'inline-flex', alignItems: 'center', gap: '10px', padding: '10px 20px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, cursor: 'pointer', fontSize: '13px', fontWeight: 600, color: P.onSurface }}>
                                    <input
                                        type="checkbox"
                                        checked={false}
                                        onChange={() => {
                                            if (window.confirm('Confirmer que la caution a bien ete reglee par ' + livreur?.users?.first_name + ' ?')) {
                                                handleCautionPayee();
                                            }
                                        }}
                                        style={{ width: '16px', height: '16px', accentColor: P.primary, cursor: 'pointer' }}
                                    />
                                    Marquer la caution comme payee
                                </label>
                            )}

                            {livreur?.caution_payee && (
                                <div style={{ display: 'inline-flex', alignItems: 'center', gap: '7px', padding: '10px 20px', borderRadius: '10px', backgroundColor: '#c8e6c9', color: '#1b5e20', fontSize: '13px', fontWeight: 600 }}>
                                    <IconCheck style={{ width: '14px', height: '14px' }} />
                                    Caution confirmee — pret pour approbation
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            )}

            {/* NOTE INTERNE */}
            {livreur?.note_manager && (
                <Section title="Journal — notes internes manager">
                    <p style={{ margin: 0, fontSize: '12px', color: P.onSurface, lineHeight: 1.8, whiteSpace: 'pre-wrap', fontFamily: 'monospace', backgroundColor: P.surfaceContainerLow, padding: '12px', borderRadius: '8px' }}>
                        {livreur.note_manager}
                    </p>
                </Section>
            )}

            {/* DECISION FINALE */}
            {livreur?.status === 'Indisponible' && (
                <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, padding: '20px', boxShadow: '0 1px 4px rgba(0,0,0,0.04)', marginBottom: '16px' }}>
                    <p style={{ margin: '0 0 6px 0', fontSize: '11px', fontWeight: 700, color: P.onSurface, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Decision finale</p>
                    <p style={{ margin: '0 0 16px 0', fontSize: '12px', color: P.outline }}>
                        {livreur?.caution_payee
                            ? 'La caution est reglee. Vous pouvez approuver le profil — le livreur aura acces a la plateforme.'
                            : 'La caution n\'est pas encore reglee. Vous pouvez quand meme approuver ou rejeter le profil.'}
                    </p>
                    <div style={{ display: 'flex', gap: '12px' }}>
                        <button onClick={handleApprouver} disabled={actionLoading} style={btnPrimary}>
                            Approuver et activer l'acces
                        </button>
                        <button onClick={() => setShowRejetModal(true)}
                            style={{ padding: '11px 22px', borderRadius: '10px', border: '1px solid rgba(186,26,26,0.3)', backgroundColor: P.errorContainer, color: P.onErrorContainer, fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                            Rejeter le profil
                        </button>
                    </div>
                </div>
            )}

            {/* MODAL SMS */}
            {showSmsModal && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.55)', zIndex: 100, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }}>
                    <div style={{ backgroundColor: P.surface, borderRadius: '16px', padding: '28px', maxWidth: '540px', width: '100%', boxShadow: '0 20px 60px rgba(0,0,0,0.2)', maxHeight: '90vh', overflowY: 'auto' }}>
                        <p style={{ margin: '0 0 4px 0', fontSize: '16px', fontWeight: 700, color: P.onSurface }}>Notification SMS — Caution</p>
                        <p style={{ margin: '0 0 20px 0', fontSize: '13px', color: P.outline }}>
                            Envoyer un SMS a <strong>{livreur?.users?.first_name}</strong> ({livreur?.users?.phone}) avec les instructions de paiement de la caution.
                        </p>

                        <form onSubmit={handleEnvoyerSMS}>
                            <div style={{ marginBottom: '16px' }}>
                                <label style={{ display: 'block', fontSize: '11px', fontWeight: 600, color: P.onSurfaceVariant, textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: '7px' }}>
                                    Montant de la caution (FCFA)
                                </label>
                                <input
                                    type="number"
                                    value={montantCaution}
                                    onChange={e => setMontantCaution(e.target.value)}
                                    style={inputStyle}
                                    min="10000"
                                    step="5000"
                                    required
                                />
                                <p style={{ margin: '6px 0 0 0', fontSize: '11px', color: P.outline }}>Standard : 50 000 FCFA (moto) / 75 000 FCFA (voiture)</p>
                            </div>

                            {/* Apercu SMS */}
                            <div style={{ marginBottom: '20px' }}>
                                <p style={{ margin: '0 0 7px 0', fontSize: '11px', fontWeight: 600, color: P.onSurfaceVariant, textTransform: 'uppercase', letterSpacing: '0.07em' }}>Apercu du SMS</p>
                                <div style={{ backgroundColor: P.surfaceContainerLow, borderRadius: '10px', padding: '14px', border: '1px solid ' + P.outlineVariant }}>
                                    <pre style={{ margin: 0, fontSize: '12px', color: P.onSurface, lineHeight: 1.7, whiteSpace: 'pre-wrap', fontFamily: 'Poppins, sans-serif' }}>
                                        {smsPreview}
                                    </pre>
                                </div>
                            </div>

                            <div style={{ display: 'flex', gap: '10px' }}>
                                <button type="submit" disabled={actionLoading}
                                    style={{ flex: 1, padding: '11px', borderRadius: '10px', border: 'none', backgroundColor: P.secondary, color: '#fff', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                    {actionLoading ? 'Envoi...' : 'Envoyer le SMS'}
                                </button>
                                <button type="button" onClick={() => setShowSmsModal(false)}
                                    style={{ padding: '11px 20px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, fontSize: '13px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                    Annuler
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* MODAL REJET */}
            {showRejetModal && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.55)', zIndex: 100, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }}>
                    <div style={{ backgroundColor: P.surface, borderRadius: '16px', padding: '28px', maxWidth: '480px', width: '100%', boxShadow: '0 20px 60px rgba(0,0,0,0.2)' }}>
                        <p style={{ margin: '0 0 6px 0', fontSize: '16px', fontWeight: 700, color: P.onSurface }}>Rejeter le profil</p>
                        <p style={{ margin: '0 0 20px 0', fontSize: '13px', color: P.outline }}>
                            Le profil de <strong>{livreur?.users?.first_name} {livreur?.users?.last_name}</strong> sera rejete. Precisez le motif.
                        </p>
                        <form onSubmit={handleRejeter}>
                            <label style={{ display: 'block', fontSize: '11px', fontWeight: 600, color: P.onSurfaceVariant, textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: '8px' }}>Motif du rejet *</label>
                            <textarea
                                value={motifRejet}
                                onChange={e => setMotifRejet(e.target.value)}
                                required
                                rows={4}
                                placeholder="Ex: CNI verso manquante, experience insuffisante, vehicule non conforme..."
                                style={{ ...inputStyle, resize: 'vertical' }}
                            />
                            <div style={{ display: 'flex', gap: '10px', marginTop: '16px' }}>
                                <button type="submit" disabled={actionLoading}
                                    style={{ flex: 1, padding: '11px', borderRadius: '10px', backgroundColor: P.error, color: '#fff', border: 'none', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                    {actionLoading ? 'En cours...' : 'Confirmer le rejet'}
                                </button>
                                <button type="button" onClick={() => setShowRejetModal(false)}
                                    style={{ padding: '11px 20px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, fontSize: '13px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                    Annuler
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}