import { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';

const P = {
    primary: '#7d5700', error: '#ba1a1a', errorContainer: '#ffdad6', onErrorContainer: '#93000a',
    surface: '#ffffff', surfaceContainerLow: '#f3f3f3', onSurface: '#1a1c1c', outline: '#817564', outlineVariant: '#d3c4b0',
};

const getFullImageUrl = (url) => {
    if (!url) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    const backendBase = api.defaults?.baseURL || 'http://localhost:5000';
    const rootUrl = backendBase.replace(/\/api\/?$/, ''); 
    const cleanPath = url.replace(/\\/g, '/');
    return `${rootUrl}/${cleanPath.startsWith('/') ? cleanPath.slice(1) : cleanPath}`;
};

function Section({ title, children }) {
    return (
        <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, marginBottom: '16px', overflow: 'hidden' }}>
            <div style={{ padding: '11px 20px', borderBottom: '1px solid ' + P.surfaceContainerLow, backgroundColor: P.surfaceContainerLow }}>
                <p style={{ margin: 0, fontSize: '11px', fontWeight: 700, color: P.onSurface, textTransform: 'uppercase' }}>{title}</p>
            </div>
            <div style={{ padding: '20px' }}>{children}</div>
        </div>
    );
}

function Field({ label, value }) {
    return (
        <div>
            <p style={{ margin: '0 0 3px 0', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase' }}>{label}</p>
            <p style={{ margin: 0, fontSize: '13px', color: P.onSurface, fontWeight: 500 }}>{value || <span style={{ color: P.outlineVariant, fontStyle: 'italic' }}>Non renseigné</span>}</p>
        </div>
    );
}

function DocPhoto({ label, url, required }) {
    return (
        <div style={{ borderRadius: '12px', border: '1px solid ' + (url ? P.outlineVariant : P.error), overflow: 'hidden' }}>
            <div style={{ padding: '8px 12px', backgroundColor: url ? P.surfaceContainerLow : P.errorContainer, display: 'flex', justifyContent: 'space-between' }}>
                <p style={{ margin: 0, fontSize: '11px', fontWeight: 600, color: url ? P.onSurface : P.onErrorContainer }}>{label}{required && ' *'}</p>
                <span style={{ fontSize: '10px', fontWeight: 600, padding: '2px 8px', borderRadius: '4px', backgroundColor: url ? '#c8e6c9' : P.errorContainer, color: url ? '#1b5e20' : P.onErrorContainer }}>{url ? 'Fourni' : 'MANQUANT'}</span>
            </div>
            {url ? <img src={url} alt={label} style={{ width: '100%', height: '140px', objectFit: 'cover' }} /> : <div style={{ height: '140px', backgroundColor: '#fff5f5' }} />}
        </div>
    );
}

export default function ProfilDetail() {
    const { id } = useParams();
    const [livreur, setLivreur] = useState(null);
    const [loading, setLoading] = useState(true);
    
    // État pour gérer la notification temporaire
    const [toast, setToast] = useState({ visible: false, message: '', type: 'success' });

    function showToast(message, type = 'success') {
        setToast({ visible: true, message, type });
        setTimeout(() => setToast({ visible: false, message: '', type }), 3000);
    }

    function charger() {
        api.get('/profils/' + id).then(res => setLivreur(res.data)).finally(() => setLoading(false));
    }
    useEffect(() => { charger(); }, [id]);

    async function handleApprouver() {
        if (!window.confirm('Approuver ce profil ?')) return;
        try {
            await api.post('/profils/' + id + '/approuver');
            showToast('Profil approuvé et compte activé !');
            charger();
        } catch (err) {
            showToast('Erreur lors de l\'approbation.', 'error');
        }
    }

    if (loading) return <p>Chargement...</p>;

    const u = livreur?.user || livreur?.users;
    const p = Array.isArray(livreur?.photos) ? livreur?.photos[0] : livreur?.photos;

    const photoProfil = livreur?.photo_profil_url || livreur?.photo_profil || p?.photo_profil_url || p?.photo_profil;
    const cniRecto = livreur?.cni_recto_url || livreur?.cni_photo_avant || p?.cni_recto_url || p?.cni_photo_avant || p?.cni_recto;
    const cniVerso = livreur?.cni_verso_url || livreur?.cni_photo_arriere || p?.cni_verso_url || p?.cni_photo_arriere || p?.cni_verso;
    const permis = livreur?.permis_url || livreur?.permis_photo || p?.permis_url || p?.permis_photo || p?.permis;
    const vehiculePhoto = livreur?.vehicule_photo_url || livreur?.vehicule_photo || p?.vehicule_photo_url || p?.vehicule_photo || p?.photo_vehicule;

    const alertes = [];
    if (!photoProfil) alertes.push('Photo de profil manquante');
    if (!livreur?.cni_numero) alertes.push('Numéro CNI manquant');
    if (!cniRecto) alertes.push('Photo CNI recto manquante');
    if (!cniVerso) alertes.push('Photo CNI verso manquante');
    if (!permis) alertes.push('Photo permis manquante');
    if (!vehiculePhoto) alertes.push('Photo véhicule manquante');

    return (
        <div style={{ maxWidth: '960px', fontFamily: 'Poppins, sans-serif' }}>
            <BackButton to="/livreurs/profils" />

            {alertes.length > 0 && (
                <div style={{ backgroundColor: P.errorContainer, padding: '14px 18px', borderRadius: '12px', marginBottom: '16px' }}>
                    <p style={{ margin: '0 0 6px', fontWeight: 700, color: P.onErrorContainer }}>Dossier incomplet — {alertes.length} point(s) à corriger</p>
                    {alertes.map((a, i) => <p key={i} style={{ margin: 0, fontSize: '12px', color: P.error }}>• {a}</p>)}
                </div>
            )}

            <Section title="Identité du candidat">
                <div style={{ display: 'flex', gap: '20px' }}>
                    <img src={getFullImageUrl(photoProfil) || 'https://via.placeholder.com/100'} alt="Profil" style={{ width: '100px', height: '100px', borderRadius: '14px', objectFit: 'cover' }} />
                    <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                        <Field label="Prénom & Nom" value={`${u?.first_name || ''} ${u?.last_name || ''}`.trim()} />
                        <Field label="Téléphone" value={u?.phone} />
                        <Field label="Adresse Résidence" value={livreur?.adresse_residence} />
                        <Field label="Numéro CNI" value={livreur?.cni_numero} />
                    </div>
                </div>
            </Section>

            <Section title="Véhicule et documents">
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '14px', marginBottom: '16px' }}>
                    <Field label="Véhicule" value={`${livreur?.vehicule_type || ''} ${livreur?.vehicule_marque || ''}`.trim()} />
                    <Field label="Immatriculation" value={livreur?.vehicule_immatriculation} />
                    <Field label="Assurance (Expire le)" value={livreur?.assurance_expiration ? new Date(livreur.assurance_expiration).toLocaleDateString() : null} />
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: '12px' }}>
                    <DocPhoto label="CNI — Recto" url={getFullImageUrl(cniRecto)} required />
                    <DocPhoto label="CNI — Verso" url={getFullImageUrl(cniVerso)} required />
                    <DocPhoto label="Permis" url={getFullImageUrl(permis)} required />
                    <DocPhoto label="Photo Véhicule" url={getFullImageUrl(vehiculePhoto)} required />
                </div>
            </Section>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '16px' }}>
                <Section title="Mobile Money">
                    <Field label="Titulaire" value={livreur?.mobile_money_titulaire} />
                    <Field label="Numéro" value={livreur?.mobile_money_numero} />
                </Section>
                
                <Section title="Disponibilités">
                    <p style={{ margin: '0 0 3px 0', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase' }}>Horaires / Jours</p>
                    {(() => {
                        if (!livreur?.disponibilites) return <p style={{ margin: 0, fontSize: '13px', color: P.outline, fontStyle: 'italic' }}>Non renseigné</p>;
                        
                        let list = null;
                        try {
                            if (typeof livreur.disponibilites === 'object') {
                                list = livreur.disponibilites;
                            } else {
                                list = JSON.parse(livreur.disponibilites);
                                if (typeof list === 'string') {
                                    list = JSON.parse(list);
                                }
                            }
                        } catch(e) {
                            console.error("Échec du décodage des disponibilités:", e);
                        }

                        if (Array.isArray(list)) {
                            return (
                                <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                                    {list.map((d, i) => (
                                        <div key={i} style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 12px', backgroundColor: P.surfaceContainerLow, borderRadius: '6px', fontSize: '13px' }}>
                                            <strong style={{ color: P.onSurface }}>{d.jour || '—'}</strong>
                                            <span style={{ fontWeight: 500, color: P.outline }}>
                                                {d.heureDebut || d.heure_debut || '—'} - {d.heureFin || d.heure_fin || '—'}
                                            </span>
                                        </div>
                                    ))}
                                </div>
                            );
                        }

                        return <p style={{ margin: 0, fontSize: '13px', color: P.onSurface }}>{String(livreur.disponibilites)}</p>;
                    })()}
                </Section>
            </div>

            {livreur?.status === 'Indisponible' && (
                <button onClick={handleApprouver} style={{ padding: '11px 22px', backgroundColor: P.primary, color: '#fff', borderRadius: '10px', border: 'none', cursor: 'pointer' }}>
                    Approuver et activer le compte
                </button>
            )}

            {/* Notification Toast Temporaire */}
            {toast.visible && (
                <div style={{
                    position: 'fixed', bottom: '24px', right: '24px',
                    backgroundColor: toast.type === 'error' ? P.error : '#1b5e20',
                    color: '#ffffff', padding: '12px 24px', borderRadius: '10px',
                    boxShadow: '0 4px 12px rgba(0,0,0,0.15)', fontSize: '13px', fontWeight: 600,
                    zIndex: 9999, display: 'flex', alignItems: 'center', gap: '8px'
                }}>
                    {toast.type === 'success' ? '✓ ' : '⚠️ '}
                    {toast.message}
                </div>
            )}
        </div>
    );
}