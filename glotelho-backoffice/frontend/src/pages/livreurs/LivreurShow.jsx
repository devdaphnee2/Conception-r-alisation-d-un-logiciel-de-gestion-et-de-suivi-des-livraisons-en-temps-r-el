import { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import api from '../../services/api';

const P = {
    surface: '#ffffff',
    surfaceContainerLow: '#f4f4f4',
    surfaceContainerHigh: '#e8e8e8',
    onSurface: '#1a1c1c',
    outline: '#817564',
    outlineVariant: '#d3c4b0',
    primary: '#2e7d32', // Vert pour valider
    error: '#b71c1c',   // Rouge pour suspendre
};

// --- COMPOSANTS DE MISE EN PAGE ---

function BackButton({ to }) {
    return (
        <Link to={to} style={{ 
            display: 'inline-flex', alignItems: 'center', gap: '6px', 
            padding: '8px 16px', borderRadius: '8px', border: '1px solid ' + P.surfaceContainerHigh, 
            backgroundColor: P.surface, color: P.onSurface, textDecoration: 'none', 
            fontSize: '13px', fontWeight: 600, marginBottom: '20px', boxShadow: '0 1px 2px rgba(0,0,0,0.05)' 
        }}>
            <span style={{ fontSize: '16px' }}>&lt;</span> Retour
        </Link>
    );
}

function Section({ title, children }) {
    return (
        <div style={{ backgroundColor: P.surface, borderRadius: '12px', border: '1px solid ' + P.outlineVariant, marginBottom: '16px', overflow: 'hidden' }}>
            <div style={{ padding: '14px 20px', borderBottom: '1px solid ' + P.surfaceContainerLow, backgroundColor: P.surfaceContainerLow }}>
                <p style={{ margin: 0, fontSize: '12px', fontWeight: 800, color: P.onSurface, textTransform: 'uppercase' }}>{title}</p>
            </div>
            <div style={{ padding: '20px' }}>{children}</div>
        </div>
    );
}

function Field({ label, value }) {
    return (
        <div>
            <p style={{ margin: '0 0 6px 0', fontSize: '10px', fontWeight: 700, color: P.outline, textTransform: 'uppercase' }}>{label}</p>
            {value ? (
                <p style={{ margin: 0, fontSize: '14px', color: P.onSurface, fontWeight: 500 }}>{value}</p>
            ) : (
                <p style={{ margin: 0, fontSize: '14px', color: P.outlineVariant, fontStyle: 'italic', fontWeight: 600 }}>Non renseigné</p>
            )}
        </div>
    );
}

function DocPhoto({ label, url }) {
    return (
        <div style={{ borderRadius: '12px', border: '1px solid ' + P.surfaceContainerHigh, overflow: 'hidden' }}>
            <div style={{ padding: '10px 14px', backgroundColor: P.surfaceContainerHigh, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <p style={{ margin: 0, fontSize: '11px', fontWeight: 700, color: P.outline }}>{label}</p>
                <span style={{ fontSize: '11px', fontWeight: 700, color: url ? '#2e7d32' : P.outline }}>
                    {url ? 'Fourni' : 'Manquant'}
                </span>
            </div>
            {url ? (
                <a href={url} target="_blank" rel="noreferrer">
                    <img src={url} alt={label} style={{ width: '100%', height: '140px', objectFit: 'cover', display: 'block' }} />
                </a>
            ) : (
                <div style={{ height: '140px', display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#fafafa' }}>
                    <p style={{ margin: 0, fontSize: '12px', color: P.outlineVariant, fontWeight: 600 }}>Aucun document</p>
                </div>
            )}
        </div>
    );
}

// --- PAGE PRINCIPALE ---

export default function LivreurShow() {
    const { id } = useParams();
    const [livreur, setLivreur] = useState(null);
    const [loading, setLoading] = useState(true);

    function charger() {
        api.get('/livreurs/' + id)
            .then(res => setLivreur(res.data))
            .finally(() => setLoading(false));
    }

    useEffect(() => { charger(); }, [id]);

    async function handleAction(route) {
        if (!window.confirm('Confirmer cette action ?')) return;
        try {
            await api.post(`/livreurs/${id}/${route}`);
            charger();
        } catch (error) {
            alert('Erreur lors de l\'action');
        }
    }

    if (loading) return <p style={{ fontFamily: 'Poppins, sans-serif', padding: '20px' }}>Chargement des données...</p>;
    if (!livreur) return <p style={{ fontFamily: 'Poppins, sans-serif', padding: '20px', color: P.error }}>Livreur introuvable.</p>;

    const user = livreur?.users || livreur?.user;

    return (
        <div style={{ maxWidth: '980px', fontFamily: 'Poppins, sans-serif', paddingBottom: '40px' }}>
            <BackButton to="/livreurs" />

            {/* SECTION 1 : INFORMATIONS PERSONNELLES */}
            <Section title="Informations Personnelles">
                <div style={{ display: 'flex', gap: '30px', alignItems: 'flex-start' }}>
                    {livreur?.photo_profil_url ? (
                        <img src={livreur.photo_profil_url} alt="Profil" style={{ width: '80px', height: '80px', borderRadius: '8px', objectFit: 'cover' }} />
                    ) : (
                        <div style={{ width: '80px', height: '80px', borderRadius: '8px', backgroundColor: P.surfaceContainerHigh, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            <span style={{ fontSize: '12px', color: P.outline, fontWeight: 600 }}>Profil</span>
                        </div>
                    )}
                    
                    <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '24px' }}>
                        <Field label="Prénom & Nom" value={`${user?.first_name || ''} ${user?.last_name || ''}`.trim()} />
                        <Field label="Téléphone" value={user?.phone} />
                        <Field label="Numéro CNI" value={livreur?.cni_numero} />
                        <Field label="Adresse Résidence" value={livreur?.adresse_residence} />
                        <Field label="Date Naissance" value={livreur?.date_naissance ? new Date(livreur.date_naissance).toLocaleDateString('fr-FR') : null} />
                    </div>
                </div>
            </Section>

            {/* SECTION 2 : VÉHICULE ET DOCUMENTS LOGISTIQUES */}
            <Section title="Véhicule et Documents Logistiques">
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '24px', marginBottom: '24px' }}>
                    <Field label="Type & Marque" value={`${livreur?.vehicule_type || ''} ${livreur?.vehicule_marque || ''}`.trim()} />
                    <Field label="Modèle" value={livreur?.vehicule_modele} />
                    <Field label="Immatriculation" value={livreur?.vehicule_immatriculation} />
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: '16px' }}>
                    <DocPhoto label="CNI Recto" url={livreur?.cni_recto_url} />
                    <DocPhoto label="CNI Verso" url={livreur?.cni_verso_url} />
                    <DocPhoto label="Permis" url={livreur?.permis_url} />
                    <DocPhoto label="Photo Véhicule" url={livreur?.vehicule_photo_url} />
                </div>
            </Section>

            {/* SECTION 3 & 4 : FINANCES ET DISPONIBILITÉS */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '24px' }}>
                <Section title="Finances & Paiement">
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                        <Field label="Titulaire Mobile Money" value={livreur?.mobile_money_titulaire} />
                        <Field label="Numéro Mobile Money" value={livreur?.mobile_money_numero} />
                    </div>
                </Section>
                <Section title="Disponibilités">
                    <Field label="Horaires et Jours" value={livreur?.disponibilites} />
                </Section>
            </div>
            
            {/* BOUTONS D'ACTION */}
            <div style={{ display: 'flex', gap: '12px' }}>
                {livreur?.caution_payee !== 1 && (
                    <button 
                        onClick={() => handleAction('caution-payee')} 
                        style={{ padding: '12px 24px', backgroundColor: P.primary, color: '#fff', borderRadius: '8px', border: 'none', fontWeight: 600, fontSize: '14px', cursor: 'pointer' }}
                    >
                        Marquer caution payée
                    </button>
                )}
                
                {livreur?.status !== 'Suspendu' ? (
                    <button 
                        onClick={() => handleAction('suspendre')} 
                        style={{ padding: '12px 24px', backgroundColor: P.error, color: '#fff', borderRadius: '8px', border: 'none', fontWeight: 600, fontSize: '14px', cursor: 'pointer' }}
                    >
                        Suspendre
                    </button>
                ) : (
                    <button 
                        onClick={() => handleAction('reactiver')} 
                        style={{ padding: '12px 24px', backgroundColor: P.outline, color: '#fff', borderRadius: '8px', border: 'none', fontWeight: 600, fontSize: '14px', cursor: 'pointer' }}
                    >
                        Réactiver
                    </button>
                )}
            </div>
        </div>
    );
}