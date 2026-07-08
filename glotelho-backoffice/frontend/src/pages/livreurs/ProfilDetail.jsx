import { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';

const P = {
    primary: '#7d5700', error: '#ba1a1a', errorContainer: '#ffdad6', onErrorContainer: '#93000a',
    surface: '#ffffff', surfaceContainerLow: '#f3f3f3', onSurface: '#1a1c1c', outline: '#817564', outlineVariant: '#d3c4b0',
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

    function charger() {
        api.get('/profils/' + id).then(res => setLivreur(res.data)).finally(() => setLoading(false));
    }
    useEffect(() => { charger(); }, [id]);

    async function handleApprouver() {
        if (!window.confirm('Approuver ce profil ?')) return;
        await api.post('/profils/' + id + '/approuver');
        charger();
    }

    if (loading) return <p>Chargement...</p>;

    const alertes = [];
    if (!livreur?.photo_profil_url) alertes.push('Photo de profil manquante');
    if (!livreur?.cni_numero) alertes.push('Numéro CNI manquant');
    if (!livreur?.cni_recto_url) alertes.push('Photo CNI recto manquante');
    if (!livreur?.cni_verso_url) alertes.push('Photo CNI verso manquante');
    if (!livreur?.permis_url) alertes.push('Photo permis manquante');
    if (!livreur?.vehicule_photo_url) alertes.push('Photo véhicule manquante');

    return (
        <div style={{ maxWidth: '960px', fontFamily: 'Poppins, sans-serif' }}>
            <BackButton to="/livreurs/profils" />

            {/* Alertes */}
            {alertes.length > 0 && (
                <div style={{ backgroundColor: P.errorContainer, padding: '14px 18px', borderRadius: '12px', marginBottom: '16px' }}>
                    <p style={{ margin: '0 0 6px', fontWeight: 700, color: P.onErrorContainer }}>Dossier incomplet — {alertes.length} point(s) à corriger</p>
                    {alertes.map((a, i) => <p key={i} style={{ margin: 0, fontSize: '12px', color: P.error }}>• {a}</p>)}
                </div>
            )}

            <Section title="Identité du candidat">
                <div style={{ display: 'flex', gap: '20px' }}>
                    <img src={livreur?.photo_profil_url || 'https://via.placeholder.com/100'} alt="Profil" style={{ width: '100px', height: '100px', borderRadius: '14px', objectFit: 'cover' }} />
                    <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                        <Field label="Prénom & Nom" value={`${livreur?.user?.first_name} ${livreur?.user?.last_name}`} />
                        <Field label="Téléphone" value={livreur?.user?.phone} />
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
                    <DocPhoto label="CNI — Recto" url={livreur?.cni_recto_url} required />
                    <DocPhoto label="CNI — Verso" url={livreur?.cni_verso_url} required />
                    <DocPhoto label="Permis" url={livreur?.permis_url} required />
                    <DocPhoto label="Photo Véhicule" url={livreur?.vehicule_photo_url} required />
                </div>
            </Section>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                <Section title="Mobile Money">
                    <Field label="Titulaire" value={livreur?.mobile_money_titulaire} />
                    <Field label="Numéro" value={livreur?.mobile_money_numero} />
                </Section>
                <Section title="Disponibilités">
                    <Field label="Horaires / Jours" value={livreur?.disponibilites} />
                </Section>
            </div>

            {livreur?.status === 'Indisponible' && (
                <button onClick={handleApprouver} style={{ padding: '11px 22px', backgroundColor: P.primary, color: '#fff', borderRadius: '10px', border: 'none', cursor: 'pointer' }}>
                    Approuver et activer le compte
                </button>
            )}
        </div>
    );
}