import { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    primaryFixed: '#ffdea9', onPrimaryContainer: '#483100',
    secondary: '#475e8b', secondaryContainer: '#b5ccff',
    error: '#ba1a1a', errorContainer: '#ffdad6', onErrorContainer: '#93000a',
    surface: '#ffffff', surfaceContainerLow: '#f3f3f3', surfaceContainerHigh: '#e8e8e8',
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

function Field({ label, value }) {
    return (
        <div>
            <p style={{ margin: '0 0 3px 0', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.07em' }}>{label}</p>
            <p style={{ margin: 0, fontSize: '13px', color: P.onSurface, fontWeight: 500, lineHeight: 1.5 }}>
                {value || <span style={{ color: P.outlineVariant, fontStyle: 'italic' }}>Non renseigne</span>}
            </p>
        </div>
    );
}

function DocPhoto({ label, url, required }) {
    return (
        <div style={{ borderRadius: '12px', border: '1px solid ' + (url ? P.outlineVariant : P.error), overflow: 'hidden' }}>
            <div style={{ padding: '8px 12px', backgroundColor: url ? P.surfaceContainerLow : P.errorContainer, display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '1px solid ' + (url ? P.outlineVariant : P.error) }}>
                <p style={{ margin: 0, fontSize: '11px', fontWeight: 600, color: url ? P.onSurface : P.onErrorContainer }}>
                    {label}{required && <span style={{ color: P.error }}> *</span>}
                </p>
                <span style={{ fontSize: '10px', fontWeight: 600, padding: '2px 8px', borderRadius: '4px', backgroundColor: url ? '#c8e6c9' : P.errorContainer, color: url ? '#1b5e20' : P.onErrorContainer }}>
                    {url ? 'Fourni' : 'MANQUANT'}
                </span>
            </div>
            {url ? (
                <a href={url} target="_blank" rel="noreferrer">
                    <img src={url} alt={label} style={{ width: '100%', height: '140px', objectFit: 'cover', display: 'block', backgroundColor: P.surfaceContainerHigh }} />
                </a>
            ) : (
                <div style={{ height: '140px', display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#fff5f5' }}>
                    <p style={{ margin: 0, fontSize: '11px', color: P.error, fontWeight: 600 }}>Document manquant</p>
                </div>
            )}
        </div>
    );
}

const JOURS_SEMAINE = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

export default function ProfilDetail() {
    const { id } = useParams();
    const [livreur, setLivreur] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [successMsg, setSuccessMsg] = useState('');
    const [actionLoading, setActionLoading] = useState(false);
    const [showRejetModal, setShowRejetModal] = useState(false);
    const [motifRejet, setMotifRejet] = useState('');
    const [showSmsModal, setShowSmsModal] = useState(false);
    const [montantCaution, setMontantCaution] = useState('50000');

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

    async function handleAction(route, body, msg) {
        setActionLoading(true);
        setError('');
        try {
            const r = await api.post(route, body);
            setSuccessMsg(r.data.message || msg);
            charger();
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur.');
        } finally {
            setActionLoading(false);
        }
    }

    if (loading) return <p style={{ fontFamily: 'Poppins, sans-serif', color: P.outline, textAlign: 'center', marginTop: '60px' }}>Chargement...</p>;
    if (error && !livreur) return <p style={{ fontFamily: 'Poppins, sans-serif', color: P.error, textAlign: 'center', marginTop: '60px' }}>{error}</p>;

    const statusConfig = {
        'Indisponible': { bg: P.primaryFixed,  color: P.onPrimaryContainer, label: 'En attente de validation' },
        'Disponible':   { bg: '#c8e6c9',        color: '#1b5e20',            label: 'Approuve' },
        'Hors_service': { bg: P.errorContainer, color: P.onErrorContainer,   label: 'Rejete' },
        'Suspendu':     { bg: P.errorContainer, color: P.onErrorContainer,   label: 'Suspendu' },
    };
    const sc = statusConfig[livreur?.status] || statusConfig['Indisponible'];

    const jours = livreur?.disponibilite_jours ? livreur.disponibilite_jours.split(',') : [];

    // Documents manquants
    const alertes = [];
    if (!livreur?.photo_profil) alertes.push('Photo de profil manquante');
    if (!livreur?.cni_numero) alertes.push('Numero CNI manquant');
    if (!livreur?.cni_photo_avant) alertes.push('Photo CNI recto manquante');
    if (!livreur?.cni_photo_arriere) alertes.push('Photo CNI verso manquante');
    if (!livreur?.permis_photo) alertes.push('Photo permis manquante');
    if (!livreur?.photo_vehicule) alertes.push('Photo vehicule manquante');
    if (!livreur?.assurance_numero) alertes.push('Numero assurance manquant');
    if (!livreur?.mobile_money_numero) alertes.push('Numero Mobile Money manquant');
    if (!livreur?.caution_payee) alertes.push('Caution non reglee — ' + Number(livreur?.caution_montant || 50000).toLocaleString('fr-FR') + ' FCFA');

    const inputStyle = { width: '100%', padding: '10px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, fontSize: '13px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none', boxSizing: 'border-box' };
    const btnPrimary = { padding: '11px 22px', borderRadius: '10px', border: 'none', backgroundColor: P.primary, color: '#fff', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' };

    return (
        <div style={{ maxWidth: '960px', fontFamily: 'Poppins, sans-serif' }}>
            <BackButton to="/livreurs/profils" />

            {/* Header */}
            <div style={{ marginBottom: '16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                    <Link to="/livreurs/profils" style={{ color: P.outline, textDecoration: 'none', fontSize: '13px' }}>Profils en attente</Link>
                    <span style={{ color: P.outlineVariant, margin: '0 6px' }}>/</span>
                    <span style={{ fontSize: '13px', fontWeight: 500, color: P.onSurface }}>{livreur?.user?.first_name} {livreur?.user?.last_name}</span>
                </div>
                <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '5px 14px', borderRadius: '6px', fontSize: '12px', fontWeight: 600 }}>{sc.label}</span>
            </div>

            {/* Alertes */}
            {alertes.length > 0 && (
                <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.25)', borderRadius: '12px', padding: '14px 18px', marginBottom: '16px' }}>
                    <p style={{ margin: '0 0 6px', fontSize: '13px', fontWeight: 700, color: P.onErrorContainer }}>Dossier incomplet — {alertes.length} point(s) a corriger</p>
                    {alertes.map((a, i) => <p key={i} style={{ margin: '2px 0 0 12px', fontSize: '12px', color: P.error }}>• {a}</p>)}
                </div>
            )}

            {alertes.length === 0 && (
                <div style={{ backgroundColor: '#f0fdf4', border: '1px solid #a5d6a7', borderRadius: '12px', padding: '12px 18px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: '#1b5e20' }}>✅ Dossier complet — pret pour approbation.</p>
                </div>
            )}

            {successMsg && <div style={{ backgroundColor: '#c8e6c9', color: '#1b5e20', padding: '10px 16px', borderRadius: '10px', marginBottom: '16px', fontSize: '13px' }}>{successMsg}</div>}
            {error && <div style={{ backgroundColor: P.errorContainer, color: P.error, padding: '10px 16px', borderRadius: '10px', marginBottom: '16px', fontSize: '13px' }}>{error}</div>}

            {/* IDENTITE */}
            <Section title="Identite du candidat">
                <div style={{ display: 'flex', gap: '20px', alignItems: 'flex-start', marginBottom: '20px' }}>
                    {/* Photo profil */}
                    <div style={{ flexShrink: 0 }}>
                        <div style={{ width: '100px', height: '100px', borderRadius: '14px', overflow: 'hidden', border: '2px solid ' + (livreur?.photo_profil ? '#a5d6a7' : P.error), backgroundColor: P.surfaceContainerHigh }}>
                            {livreur?.photo_profil
                                ? <img src={livreur.photo_profil} alt="Photo profil" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                                : <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                    <p style={{ margin: 0, fontSize: '10px', color: P.error, fontWeight: 700, textAlign: 'center' }}>MANQUANTE</p>
                                  </div>
                            }
                        </div>
                        <p style={{ margin: '4px 0 0', textAlign: 'center', fontSize: '10px', fontWeight: 600, color: livreur?.photo_profil ? '#1b5e20' : P.error }}>Photo profil *</p>
                    </div>
                    <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                        <Field label="Prenom" value={livreur?.user?.first_name} />
                        <Field label="Nom" value={livreur?.user?.last_name} />
                        <Field label="Date de naissance" value={livreur?.date_naissance ? new Date(livreur.date_naissance).toLocaleDateString('fr-FR') : null} />
                        <Field label="Telephone" value={livreur?.user?.phone} />
                        <Field label="Email" value={livreur?.user?.email} />
                        <Field label="Adresse de residence" value={livreur?.adresse_domicile} />
                        <Field label="Numero CNI" value={livreur?.cni_numero} />
                        <Field label="Date candidature" value={livreur?.date_candidature ? new Date(livreur.date_candidature).toLocaleDateString('fr-FR') : null} />
                    </div>
                </div>
            </Section>

            {/* VEHICULE + DOCUMENTS */}
            <Section title="Vehicule et documents">
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '14px', marginBottom: '16px' }}>
                    <Field label="Type de vehicule" value={livreur?.vehicules?.type} />
                    <Field label="Marque" value={livreur?.vehicules?.brand} />
                    <Field label="Modele" value={livreur?.vehicule_modele} />
                    <Field label="Immatriculation" value={livreur?.vehicules?.plate_number} />
                    <Field label="Categorie permis" value={livreur?.permis_categorie} />
                    <Field label="Assurance — N° police" value={livreur?.assurance_numero} />
                    <Field label="Assurance — Expiration" value={livreur?.assurance_expiration ? new Date(livreur.assurance_expiration).toLocaleDateString('fr-FR') : null} />
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: '12px' }}>
                    <DocPhoto label="CNI — Recto" url={livreur?.cni_photo_avant} required />
                    <DocPhoto label="CNI — Verso" url={livreur?.cni_photo_arriere} required />
                    <DocPhoto label="Permis de conduire" url={livreur?.permis_photo} required />
                    <DocPhoto label="Photo vehicule" url={livreur?.photo_vehicule} required />
                </div>
            </Section>

            {/* DISPONIBILITE */}
            <Section title="Disponibilite">
                <div style={{ marginBottom: '14px' }}>
                    <p style={{ margin: '0 0 10px', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.07em' }}>Jours disponibles</p>
                    <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                        {JOURS_SEMAINE.map(j => (
                            <span key={j} style={{ padding: '4px 12px', borderRadius: '20px', fontSize: '11px', fontWeight: 600, backgroundColor: jours.includes(j) ? P.primaryFixed : P.surfaceContainerHigh, color: jours.includes(j) ? P.onPrimaryContainer : P.outline, border: '1px solid ' + (jours.includes(j) ? P.primaryContainer : P.outlineVariant) }}>
                                {j}
                            </span>
                        ))}
                    </div>
                    {jours.length === 0 && <p style={{ margin: '8px 0 0', fontSize: '12px', color: P.outline, fontStyle: 'italic' }}>Non renseigne</p>}
                </div>
                <Field label="Horaires" value={livreur?.disponibilite_heures} />
            </Section>

            {/* MOBILE MONEY */}
            <Section title="Mobile Money">
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '14px' }}>
                    <Field label="Type" value={livreur?.mobile_money_type} />
                    <Field label="Numero" value={livreur?.mobile_money_numero} />
                    <Field label="Titulaire du compte" value={livreur?.mobile_money_nom} />
                </div>
            </Section>

            {/* CONTACT URGENCE */}
            {(livreur?.contact_urgence_nom || livreur?.contact_urgence_tel) && (
                <Section title="Contact d'urgence">
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                        <Field label="Nom" value={livreur?.contact_urgence_nom} />
                        <Field label="Telephone" value={livreur?.contact_urgence_tel} />
                    </div>
                </Section>
            )}

            {/* EXPERIENCE */}
            {livreur?.experience && (
                <Section title="Experience">
                    <p style={{ margin: 0, fontSize: '13px', color: P.onSurface, lineHeight: 1.7 }}>{livreur.experience}</p>
                </Section>
            )}

            {/* NOTE MANAGER */}
            {livreur?.note_manager && (
                <Section title="Note du manager">
                    <p style={{ margin: 0, fontSize: '13px', color: P.onSurface, lineHeight: 1.7 }}>{livreur.note_manager}</p>
                </Section>
            )}

            {/* CAUTION */}
            <Section title="Caution">
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '16px', borderRadius: '12px', backgroundColor: livreur?.caution_payee ? '#f0fdf4' : '#fff5f5', border: '1px solid ' + (livreur?.caution_payee ? '#a5d6a7' : P.error), marginBottom: '14px' }}>
                    <div>
                        <p style={{ margin: '0 0 3px', fontSize: '13px', fontWeight: 700, color: livreur?.caution_payee ? '#1b5e20' : P.error }}>
                            {livreur?.caution_payee ? 'Caution reglee' : 'Caution non reglee'}
                        </p>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                        <p style={{ margin: '0 0 4px', fontSize: '22px', fontWeight: 800, color: livreur?.caution_payee ? '#1b5e20' : P.error }}>
                            {Number(livreur?.caution_montant || 50000).toLocaleString('fr-FR')} FCFA
                        </p>
                        <span style={{ fontSize: '11px', fontWeight: 700, padding: '3px 10px', borderRadius: '4px', backgroundColor: livreur?.caution_payee ? '#c8e6c9' : P.errorContainer, color: livreur?.caution_payee ? '#1b5e20' : P.onErrorContainer }}>
                            {livreur?.caution_payee ? 'PAYEE' : 'NON PAYEE'}
                        </span>
                    </div>
                </div>
                {!livreur?.caution_payee && (
                    <div style={{ display: 'flex', gap: '10px' }}>
                        <button onClick={() => setShowSmsModal(true)}
                            style={{ padding: '10px 18px', borderRadius: '10px', border: 'none', backgroundColor: P.secondary, color: '#fff', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                            Envoyer SMS caution
                        </button>
                        <button onClick={() => { if (window.confirm('Confirmer caution payee ?')) handleAction('/profils/' + id + '/caution-payee', {}, 'Caution marquee comme payee.'); }}
                            style={{ padding: '10px 18px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, color: P.onSurface, fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                            Marquer comme payee
                        </button>
                    </div>
                )}
            </Section>

            {/* ACTIONS — uniquement si en attente */}
            {livreur?.status === 'Indisponible' && (
                <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, padding: '20px', marginBottom: '16px' }}>
                    <p style={{ margin: '0 0 6px', fontSize: '13px', fontWeight: 700, color: P.onSurface }}>Decision finale</p>
                    <p style={{ margin: '0 0 16px', fontSize: '12px', color: P.outline }}>
                        {alertes.length > 0 ? alertes.length + ' point(s) incomplet(s) — verifiez avant d\'approuver.' : 'Dossier complet. Vous pouvez approuver.'}
                    </p>
                    <div style={{ display: 'flex', gap: '12px' }}>
                        <button onClick={() => { if (window.confirm('Approuver ce profil ?')) handleAction('/profils/' + id + '/approuver', {}, 'Profil approuve.'); }}
                            disabled={actionLoading} style={btnPrimary}>
                            Approuver et activer
                        </button>
                        <button onClick={() => setShowRejetModal(true)}
                            style={{ padding: '11px 22px', borderRadius: '10px', border: '1px solid rgba(186,26,26,0.3)', backgroundColor: P.errorContainer, color: P.onErrorContainer, fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                            Rejeter
                        </button>
                    </div>
                </div>
            )}

            {/* MODAL REJET */}
            {showRejetModal && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.55)', zIndex: 100, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }}>
                    <div style={{ backgroundColor: P.surface, borderRadius: '16px', padding: '28px', maxWidth: '480px', width: '100%', boxShadow: '0 20px 60px rgba(0,0,0,0.2)' }}>
                        <p style={{ margin: '0 0 6px', fontSize: '16px', fontWeight: 700, color: P.onSurface }}>Rejeter le profil</p>
                        <p style={{ margin: '0 0 20px', fontSize: '13px', color: P.outline }}>Precisez le motif du rejet.</p>
                        <textarea value={motifRejet} onChange={e => setMotifRejet(e.target.value)} rows={4}
                            placeholder="Ex: Photo CNI non lisible, assurance expiree..."
                            style={{ ...inputStyle, resize: 'vertical', marginBottom: '16px' }} />
                        <div style={{ display: 'flex', gap: '10px' }}>
                            <button onClick={() => { handleAction('/profils/' + id + '/rejeter', { motif: motifRejet }, 'Profil rejete.'); setShowRejetModal(false); }}
                                disabled={actionLoading}
                                style={{ flex: 1, padding: '11px', borderRadius: '10px', backgroundColor: P.error, color: '#fff', border: 'none', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                Confirmer le rejet
                            </button>
                            <button onClick={() => setShowRejetModal(false)}
                                style={{ padding: '11px 20px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, fontSize: '13px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                Annuler
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* MODAL SMS CAUTION */}
            {showSmsModal && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.55)', zIndex: 100, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }}>
                    <div style={{ backgroundColor: P.surface, borderRadius: '16px', padding: '28px', maxWidth: '480px', width: '100%', boxShadow: '0 20px 60px rgba(0,0,0,0.2)' }}>
                        <p style={{ margin: '0 0 6px', fontSize: '16px', fontWeight: 700, color: P.onSurface }}>SMS Caution</p>
                        <p style={{ margin: '0 0 20px', fontSize: '13px', color: P.outline }}>Envoyer a {livreur?.user?.first_name} ({livreur?.user?.phone})</p>
                        <label style={{ display: 'block', fontSize: '11px', fontWeight: 600, color: P.outline, marginBottom: '7px', textTransform: 'uppercase', letterSpacing: '0.07em' }}>Montant (FCFA)</label>
                        <input type="number" value={montantCaution} onChange={e => setMontantCaution(e.target.value)} style={{ ...inputStyle, marginBottom: '16px' }} />
                        <div style={{ display: 'flex', gap: '10px' }}>
                            <button onClick={() => { handleAction('/profils/' + id + '/notifier-caution', { montant: parseFloat(montantCaution) }, 'SMS envoye.'); setShowSmsModal(false); }}
                                disabled={actionLoading}
                                style={{ flex: 1, padding: '11px', borderRadius: '10px', backgroundColor: P.secondary, color: '#fff', border: 'none', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                Envoyer
                            </button>
                            <button onClick={() => setShowSmsModal(false)}
                                style={{ padding: '11px 20px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, fontSize: '13px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                Annuler
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}