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
            <p style={{ margin: 0, fontSize: '13px', color: highlight ? P.primary : P.onSurface, fontWeight: highlight ? 700 : 500, lineHeight: 1.5 }}>{value || <span style={{ color: P.outlineVariant, fontStyle: 'italic' }}>Non renseigne</span>}</p>
        </div>
    );
}

function DocPhoto({ label, url, required }) {
    const present = !!url;
    return (
        <div style={{ borderRadius: '12px', border: '1px solid ' + (present ? P.outlineVariant : P.error), overflow: 'hidden' }}>
            <div style={{ padding: '8px 12px', backgroundColor: present ? P.surfaceContainerLow : P.errorContainer, display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '1px solid ' + (present ? P.outlineVariant : P.error) }}>
                <p style={{ margin: 0, fontSize: '11px', fontWeight: 600, color: present ? P.onSurface : P.onErrorContainer }}>{label}{required && <span style={{ color: P.error }}> *</span>}</p>
                {present
                    ? <span style={{ fontSize: '10px', fontWeight: 600, color: '#1b5e20', backgroundColor: '#c8e6c9', padding: '2px 8px', borderRadius: '4px' }}>Fourni</span>
                    : <span style={{ fontSize: '10px', fontWeight: 600, color: P.onErrorContainer, backgroundColor: P.errorContainer, padding: '2px 8px', borderRadius: '4px' }}>MANQUANT</span>
                }
            </div>
            {present ? (
                <img src={url} alt={label} style={{ width: '100%', height: '140px', objectFit: 'cover', display: 'block', backgroundColor: P.surfaceContainerHigh }} />
            ) : (
                <div style={{ height: '140px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', backgroundColor: '#fff5f5', gap: '8px' }}>
                    <IconX style={{ width: '28px', height: '28px', color: P.error }} />
                    <p style={{ margin: 0, fontSize: '11px', color: P.error, fontWeight: 600, textAlign: 'center' }}>Document manquant<br/><span style={{ fontWeight: 400, color: P.outline }}>A demander au candidat</span></p>
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
    const [showModal, setShowModal] = useState(false);
    const [motifRejet, setMotifRejet] = useState('');
    const [showSmsModal, setShowSmsModal] = useState(false);
    const [montantCaution, setMontantCaution] = useState('50000');

    function charger() {
        api.get('/profils/' + id)
            .then(res => { setLivreur(res.data); setMontantCaution(String(res.data.caution_montant || 50000)); })
            .catch(() => setError('Profil introuvable.'))
            .finally(() => setLoading(false));
    }
    useEffect(() => { charger(); }, [id]);

    async function handleApprouver() {
        if (!livreur?.photo_profil) {
            if (!window.confirm('La photo de profil est manquante — obligatoire pour acceder a la plateforme.\nApprouver quand meme ?')) return;
        } else if (!livreur?.caution_payee) {
            if (!window.confirm('La caution n\'est pas reglee.\nApprouver quand meme ?')) return;
        } else {
            if (!window.confirm('Approuver le profil de ' + livreur?.users?.first_name + ' ?')) return;
        }
        setActionLoading(true);
        try {
            const res = await api.post('/profils/' + id + '/approuver');
            setSuccessMsg(res.data.message);
            charger();
        } catch (err) { setError(err.response?.data?.message || 'Erreur.'); }
        finally { setActionLoading(false); }
    }

    async function handleRejeter(e) {
        e.preventDefault();
        setActionLoading(true);
        try {
            const res = await api.post('/profils/' + id + '/rejeter', { motif: motifRejet });
            setSuccessMsg(res.data.message);
            setShowModal(false);
            charger();
        } catch (err) { setError(err.response?.data?.message || 'Erreur.'); }
        finally { setActionLoading(false); }
    }

    async function handleCautionPayee() {
        setActionLoading(true);
        try {
            await api.post('/profils/' + id + '/caution-payee');
            setSuccessMsg('Caution marquee comme payee.');
            charger();
        } catch (err) { setError(err.response?.data?.message || 'Erreur.'); }
        finally { setActionLoading(false); }
    }

    async function handleEnvoyerSMS(e) {
        e.preventDefault();
        setActionLoading(true);
        try {
            await api.post('/profils/' + id + '/notifier-caution', { montant: parseFloat(montantCaution) });
            setSuccessMsg('SMS envoye a ' + livreur.users?.phone);
            setShowSmsModal(false);
            charger();
        } catch (err) { setError(err.response?.data?.message || 'Erreur.'); }
        finally { setActionLoading(false); }
    }

    if (loading) return <p style={{ fontFamily: 'Poppins, sans-serif', color: P.outline, textAlign: 'center', marginTop: '60px' }}>Chargement...</p>;
    if (error && !livreur) return <p style={{ fontFamily: 'Poppins, sans-serif', color: P.error, textAlign: 'center', marginTop: '60px' }}>{error}</p>;

    const statusConfig = {
        'Indisponible': { bg: P.primaryFixed, color: P.onPrimaryContainer, label: 'En attente de validation' },
        'Disponible':   { bg: '#c8e6c9', color: '#1b5e20', label: 'Approuve' },
        'Hors_service': { bg: P.errorContainer, color: P.onErrorContainer, label: 'Rejete' },
    };
    const sc = statusConfig[livreur?.status] || statusConfig['Indisponible'];

    // Alertes dossier — photo de profil incluse en premier (priorite)
    const alertes = [];
    if (!livreur?.photo_profil) alertes.push('Photo de profil (visage) manquante — OBLIGATOIRE');
    if (!livreur?.cni_numero) alertes.push('Numero CNI manquant');
    if (!livreur?.cni_photo_avant) alertes.push('Photo CNI recto manquante');
    if (!livreur?.cni_photo_arriere) alertes.push('Photo CNI verso manquante');
    if (!livreur?.permis_photo) alertes.push('Photo permis de conduire manquante');
    if (!livreur?.caution_payee) alertes.push('Caution non reglee — ' + Number(livreur?.caution_montant || 50000).toLocaleString('fr-FR') + ' FCFA dus');

    const inputStyle = { width: '100%', padding: '10px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, fontSize: '13px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none', boxSizing: 'border-box' };
    const btnPrimary = { padding: '11px 22px', borderRadius: '10px', border: 'none', backgroundColor: P.primary, color: '#fff', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: '0 2px 8px rgba(125,87,0,0.25)' };

    return (
        <div style={{ maxWidth: '900px', fontFamily: 'Poppins, sans-serif' }}>
            <BackButton to="/livreurs/profils" />

            <div style={{ marginBottom: '20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                    <Link to="/livreurs/profils" style={{ color: P.outline, textDecoration: 'none', fontSize: '13px' }}>Profils en attente</Link>
                    <span style={{ color: P.outlineVariant, margin: '0 6px' }}>/</span>
                    <span style={{ fontSize: '13px', fontWeight: 500, color: P.onSurface }}>{livreur?.users?.first_name} {livreur?.users?.last_name}</span>
                </div>
                <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '5px 14px', borderRadius: '6px', fontSize: '12px', fontWeight: 600 }}>{sc.label}</span>
            </div>

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

            {/* IDENTITE — avec photo de profil mise en avant */}
            <Section title="Identite du candidat">
                <div style={{ display: 'flex', alignItems: 'flex-start', gap: '20px', marginBottom: '20px', paddingBottom: '16px', borderBottom: '1px solid ' + P.surfaceContainerLow }}>

                    {/* Photo de profil — obligatoire, mise en avant */}
                    <div style={{ flexShrink: 0 }}>
                        <div style={{ width: '110px', height: '110px', borderRadius: '14px', overflow: 'hidden', border: '2px solid ' + (livreur?.photo_profil ? '#a5d6a7' : P.error), position: 'relative', backgroundColor: P.surfaceContainerHigh }}>
                            {livreur?.photo_profil ? (
                                <img src={livreur.photo_profil} alt="Photo de profil" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                            ) : (
                                <div style={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: '4px' }}>
                                    <IconUser style={{ width: '32px', height: '32px', color: P.error }} />
                                    <span style={{ fontSize: '9px', color: P.error, fontWeight: 700 }}>MANQUANTE</span>
                                </div>
                            )}
                        </div>
                        <span style={{ display: 'block', textAlign: 'center', marginTop: '6px', fontSize: '10px', fontWeight: 600, color: livreur?.photo_profil ? '#1b5e20' : P.error }}>
                            {livreur?.photo_profil ? 'Photo conforme' : 'Photo requise *'}
                        </span>
                    </div>

                    <div>
                        <p style={{ margin: 0, fontSize: '18px', fontWeight: 700, color: P.onSurface }}>{livreur?.users?.first_name} {livreur?.users?.last_name}</p>
                        <p style={{ margin: '3px 0 0 0', fontSize: '12px', color: P.outline }}>
                            Dossier #{id} — soumis le {livreur?.date_candidature ? new Date(livreur.date_candidature).toLocaleDateString('fr-FR', { day: '2-digit', month: 'long', year: 'numeric' }) : '—'}
                        </p>
                        {!livreur?.photo_profil && (
                            <div style={{ marginTop: '10px', padding: '8px 12px', backgroundColor: P.errorContainer, borderRadius: '8px', maxWidth: '320px' }}>
                                <p style={{ margin: 0, fontSize: '11px', color: P.onErrorContainer, lineHeight: 1.5 }}>
                                    NB : Photo visage obligatoire (cadrage net, bien centre). Sans cette photo, le profil ne peut pas etre approuve.
                                </p>
                            </div>
                        )}
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
                </div>
            </Section>

            <Section title="Vehicule et permis de conduire">
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: '16px' }}>
                    <Field label="Type de vehicule" value={livreur?.vehicules?.type} />
                    <Field label="Marque" value={livreur?.vehicules?.brand} />
                    <Field label="Plaque d'immatriculation" value={livreur?.vehicules?.plate_number} highlight />
                    <Field label="Categorie permis" value={livreur?.permis_categorie ? 'Categorie ' + livreur.permis_categorie : null} highlight />
                </div>
            </Section>

            <Section title="Experience professionnelle">
                <p style={{ margin: 0, fontSize: '13px', color: P.onSurface, lineHeight: 1.7 }}>
                    {livreur?.experience || <span style={{ color: P.outlineVariant, fontStyle: 'italic' }}>Aucune experience renseignee</span>}
                </p>
            </Section>

            <Section title="Contact en cas d'urgence">
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                    <Field label="Nom du contact" value={livreur?.contact_urgence_nom} />
                    <Field label="Telephone" value={livreur?.contact_urgence_tel} />
                </div>
            </Section>

            {/* CAUTION */}
            {livreur?.status === 'Indisponible' && (
                <Section title="Gestion de la caution">
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '16px 20px', borderRadius: '12px', backgroundColor: livreur?.caution_payee ? '#f0fdf4' : '#fff5f5', border: '1px solid ' + (livreur?.caution_payee ? '#a5d6a7' : P.error), marginBottom: '16px' }}>
                        <div>
                            <p style={{ margin: '0 0 3px 0', fontSize: '13px', fontWeight: 700, color: livreur?.caution_payee ? '#1b5e20' : P.error }}>
                                {livreur?.caution_payee ? 'Caution reglee' : 'Caution non reglee'}
                            </p>
                            <p style={{ margin: 0, fontSize: '12px', color: livreur?.caution_payee ? '#4caf50' : P.outline }}>
                                {livreur?.caution_payee ? 'Le livreur a verse sa caution.' : 'Envoyez la notification SMS au livreur.'}
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
                        {!livreur?.caution_payee && (
                            <>
                                <button onClick={() => setShowSmsModal(true)}
                                    style={{ display: 'inline-flex', alignItems: 'center', gap: '7px', padding: '10px 20px', borderRadius: '10px', border: 'none', backgroundColor: P.secondary, color: '#fff', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                    <IconBell style={{ width: '14px', height: '14px' }} />
                                    Envoyer SMS caution
                                </button>
                                <button onClick={() => { if (window.confirm('Confirmer que la caution a ete reglee ?')) handleCautionPayee(); }}
                                    style={{ padding: '10px 20px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, color: P.onSurface, fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                    Marquer comme payee
                                </button>
                            </>
                        )}
                    </div>
                </Section>
            )}

            <Section title="Documents obligatoires">
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '14px' }}>
                    <DocPhoto label="CNI — Recto" url={livreur?.cni_photo_avant} required />
                    <DocPhoto label="CNI — Verso" url={livreur?.cni_photo_arriere} required />
                    <DocPhoto label="Permis de conduire" url={livreur?.permis_photo} required />
                </div>
            </Section>

            {livreur?.note_manager && (
                <Section title="Journal — notes internes manager">
                    <p style={{ margin: 0, fontSize: '12px', color: P.onSurface, lineHeight: 1.8, whiteSpace: 'pre-wrap', fontFamily: 'monospace', backgroundColor: P.surfaceContainerLow, padding: '12px', borderRadius: '8px' }}>
                        {livreur.note_manager}
                    </p>
                </Section>
            )}

            {livreur?.status === 'Indisponible' && (
                <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, padding: '20px', boxShadow: '0 1px 4px rgba(0,0,0,0.04)', marginBottom: '16px' }}>
                    <p style={{ margin: '0 0 6px 0', fontSize: '11px', fontWeight: 700, color: P.onSurface, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Decision finale</p>
                    <p style={{ margin: '0 0 16px 0', fontSize: '12px', color: P.outline }}>
                        {!livreur?.photo_profil
                            ? 'Photo de profil manquante — le livreur risque un rejet sans ce document.'
                            : livreur?.caution_payee
                                ? 'Dossier pret. Vous pouvez approuver.'
                                : 'La caution n\'est pas reglee. Vous pouvez quand meme approuver ou rejeter.'}
                    </p>
                    <div style={{ display: 'flex', gap: '12px' }}>
                        <button onClick={handleApprouver} disabled={actionLoading} style={btnPrimary}>Approuver et activer l'acces</button>
                        <button onClick={() => setShowModal(true)}
                            style={{ padding: '11px 22px', borderRadius: '10px', border: '1px solid rgba(186,26,26,0.3)', backgroundColor: P.errorContainer, color: P.onErrorContainer, fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                            Rejeter le profil
                        </button>
                    </div>
                </div>
            )}

            {/* MODAL SMS */}
            {showSmsModal && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.55)', zIndex: 100, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }}>
                    <div style={{ backgroundColor: P.surface, borderRadius: '16px', padding: '28px', maxWidth: '480px', width: '100%', boxShadow: '0 20px 60px rgba(0,0,0,0.2)' }}>
                        <p style={{ margin: '0 0 4px 0', fontSize: '16px', fontWeight: 700, color: P.onSurface }}>Notification SMS — Caution</p>
                        <p style={{ margin: '0 0 20px 0', fontSize: '13px', color: P.outline }}>Envoyer a {livreur?.users?.first_name} ({livreur?.users?.phone})</p>
                        <form onSubmit={handleEnvoyerSMS}>
                            <label style={{ display: 'block', fontSize: '11px', fontWeight: 600, color: P.onSurfaceVariant, textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: '7px' }}>Montant (FCFA)</label>
                            <input type="number" value={montantCaution} onChange={e => setMontantCaution(e.target.value)} style={inputStyle} required />
                            <div style={{ display: 'flex', gap: '10px', marginTop: '16px' }}>
                                <button type="submit" disabled={actionLoading} style={{ flex: 1, padding: '11px', borderRadius: '10px', border: 'none', backgroundColor: P.secondary, color: '#fff', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                    {actionLoading ? 'Envoi...' : 'Envoyer le SMS'}
                                </button>
                                <button type="button" onClick={() => setShowSmsModal(false)} style={{ padding: '11px 20px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, fontSize: '13px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>Annuler</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* MODAL REJET */}
            {showModal && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.55)', zIndex: 100, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }}>
                    <div style={{ backgroundColor: P.surface, borderRadius: '16px', padding: '28px', maxWidth: '480px', width: '100%', boxShadow: '0 20px 60px rgba(0,0,0,0.2)' }}>
                        <p style={{ margin: '0 0 6px 0', fontSize: '16px', fontWeight: 700, color: P.onSurface }}>Rejeter le profil</p>
                        <p style={{ margin: '0 0 20px 0', fontSize: '13px', color: P.outline }}>Precisez le motif du rejet.</p>
                        <form onSubmit={handleRejeter}>
                            <label style={{ display: 'block', fontSize: '11px', fontWeight: 600, color: P.onSurfaceVariant, textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: '8px' }}>Motif du rejet *</label>
                            <textarea value={motifRejet} onChange={e => setMotifRejet(e.target.value)} required rows={4}
                                placeholder="Ex: Photo de profil manquante, CNI verso manquante, caution non reglee..."
                                style={{ ...inputStyle, resize: 'vertical' }} />
                            <div style={{ display: 'flex', gap: '10px', marginTop: '16px' }}>
                                <button type="submit" disabled={actionLoading} style={{ flex: 1, padding: '11px', borderRadius: '10px', backgroundColor: P.error, color: '#fff', border: 'none', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                    {actionLoading ? 'En cours...' : 'Confirmer le rejet'}
                                </button>
                                <button type="button" onClick={() => setShowModal(false)} style={{ padding: '11px 20px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, fontSize: '13px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>Annuler</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}