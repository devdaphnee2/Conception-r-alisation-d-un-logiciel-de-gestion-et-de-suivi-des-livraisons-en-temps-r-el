import { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';

const statusStyles = {
    'Disponible':   { background: '#F0FDF4', color: '#15803D' },
    'En_livraison': { background: '#FFF1E8', color: '#E8580A' },
    'Indisponible': { background: '#FFF9C4', color: '#B45309' },
    'Suspendu':     { background: '#FEF2F2', color: '#DC2626' },
    'Hors_service': { background: '#F3F4F6', color: '#6B7280' },
};

const livraisonStatusStyles = {
    'En_attente': { background: '#FFF9C4', color: '#B45309' },
    'Assign_':    { background: '#EFF6FF', color: '#1D4ED8' },
    'En_cours':   { background: '#FFF1E8', color: '#E8580A' },
    'Livr_':      { background: '#F0FDF4', color: '#15803D' },
    'Suspendu':   { background: '#FEF2F2', color: '#DC2626' },
    'Annul_':     { background: '#F3F4F6', color: '#6B7280' },
};

const livraisonLabels = {
    'En_attente': 'En attente', 'Assign_': 'Assigne',
    'En_cours': 'En cours', 'Livr_': 'Livre',
    'Suspendu': 'Suspendu', 'Annul_': 'Annule',
};

export default function LivreurShow() {
    const { id } = useParams();
    const [livreur, setLivreur] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [successMsg, setSuccessMsg] = useState('');
    const [actionLoading, setActionLoading] = useState(false);

    function charger() {
        api.get('/livreurs/' + id)
            .then(res => setLivreur(res.data))
            .catch(() => setError('Livreur introuvable.'))
            .finally(() => setLoading(false));
    }

    useEffect(() => { charger(); }, [id]);

    async function handleSuspendre() {
        if (!window.confirm('Confirmer la suspension de ce livreur ?')) return;
        setActionLoading(true);
        try {
            const res = await api.post('/livreurs/' + id + '/suspendre');
            setSuccessMsg(res.data.message);
            charger();
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur.');
        } finally { setActionLoading(false); }
    }

    async function handleReactiver() {
        if (!window.confirm('Confirmer la reactivation de ce livreur ?')) return;
        setActionLoading(true);
        try {
            const res = await api.post('/livreurs/' + id + '/reactiver');
            setSuccessMsg(res.data.message);
            charger();
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur.');
        } finally { setActionLoading(false); }
    }

    if (loading) return <p style={{ color: '#8A8AA3', textAlign: 'center', marginTop: '60px' }}>Chargement...</p>;
    if (error && !livreur) return <p style={{ color: '#DC2626', textAlign: 'center', marginTop: '60px' }}>{error}</p>;

    const statusStyle = statusStyles[livreur?.status] || { background: '#F3F4F6', color: '#6B7280' };
    const cardStyle = { backgroundColor: 'white', borderRadius: '20px', border: '1px solid #ECECF2', padding: '24px', boxShadow: '0 1px 3px rgba(0,0,0,0.04)', marginBottom: '20px' };
    const labelStyle = { fontSize: '11px', fontWeight: 600, color: '#8A8AA3', textTransform: 'uppercase', letterSpacing: '0.08em', margin: 0 };
    const valueStyle = { fontSize: '15px', color: '#1C1C2E', fontWeight: 500, margin: '4px 0 0 0' };
    const btnPrimary = { padding: '10px 20px', borderRadius: '12px', border: 'none', background: 'linear-gradient(to right, #E8580A, #FF7A33)', color: 'white', fontSize: '14px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' };
    const btnSecondary = { padding: '10px 20px', borderRadius: '12px', border: '1px solid #ECECF2', backgroundColor: '#FAFAFC', color: '#1C1C2E', fontSize: '14px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' };
    const btnDanger = { padding: '10px 20px', borderRadius: '12px', border: '1px solid #FECACA', backgroundColor: '#FEF2F2', color: '#DC2626', fontSize: '14px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' };
    const btnSuccess = { padding: '10px 20px', borderRadius: '12px', border: '1px solid #BBF7D0', backgroundColor: '#F0FDF4', color: '#15803D', fontSize: '14px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' };

    const livraisons = livreur?.deliveryorders || [];
    const stats = {
        total: livraisons.length,
        livrees: livraisons.filter(l => l.status === 'Livr_').length,
        en_cours: livraisons.filter(l => l.status === 'En_cours').length,
        annulees: livraisons.filter(l => l.status === 'Annul_').length,
    };

    return (
        <div style={{ maxWidth: '900px' }}>
            <BackButton to="/livreurs" />

            <div style={{ marginBottom: '24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                    <Link to="/livreurs" style={{ color: '#8A8AA3', textDecoration: 'none', fontSize: '14px' }}>Livreurs</Link>
                    <span style={{ color: '#8A8AA3', margin: '0 8px' }}>/</span>
                    <span style={{ color: '#1C1C2E', fontSize: '14px', fontWeight: 500 }}>
                        {livreur?.users?.first_name} {livreur?.users?.last_name}
                    </span>
                </div>
                <span style={{ ...statusStyle, padding: '6px 14px', borderRadius: '999px', fontSize: '13px', fontWeight: 600 }}>
                    {livreur?.status?.replace('_', ' ')}
                </span>
            </div>

            {successMsg && (
                <div style={{ backgroundColor: '#F0FDF4', border: '1px solid #BBF7D0', color: '#15803D', padding: '12px 16px', borderRadius: '12px', marginBottom: '20px', fontSize: '14px' }}>
                    {successMsg}
                </div>
            )}
            {error && (
                <div style={{ backgroundColor: '#FEF2F2', border: '1px solid #FECACA', color: '#DC2626', padding: '12px 16px', borderRadius: '12px', marginBottom: '20px', fontSize: '14px' }}>
                    {error}
                </div>
            )}

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', marginBottom: '20px' }}>
                <div style={cardStyle}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '20px' }}>
                        <div style={{ width: '56px', height: '56px', borderRadius: '50%', background: 'linear-gradient(135deg, #E8580A, #FF8A4C)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '20px', fontWeight: 700, color: 'white', flexShrink: 0 }}>
                            {livreur?.users?.first_name?.[0]}
                        </div>
                        <div>
                            <p style={{ fontSize: '18px', fontWeight: 700, color: '#1C1C2E', margin: 0 }}>
                                {livreur?.users?.first_name} {livreur?.users?.last_name}
                            </p>
                            <p style={{ fontSize: '13px', color: '#8A8AA3', margin: '4px 0 0 0' }}>Livreur #{livreur?.id}</p>
                        </div>
                    </div>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                        <div><p style={labelStyle}>Telephone</p><p style={valueStyle}>{livreur?.users?.phone}</p></div>
                        <div><p style={labelStyle}>Email</p><p style={{ ...valueStyle, fontSize: '13px' }}>{livreur?.users?.email}</p></div>
                        <div><p style={labelStyle}>Zone affectee</p><p style={valueStyle}>{livreur?.zone_affectee || '—'}</p></div>
                        <div><p style={labelStyle}>Disponible</p><p style={valueStyle}>{livreur?.available ? 'Oui' : 'Non'}</p></div>
                    </div>
                </div>

                <div style={cardStyle}>
                    <p style={{ fontSize: '15px', fontWeight: 700, color: '#1C1C2E', margin: '0 0 16px 0' }}>Vehicule</p>
                    {livreur?.vehicules ? (
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                            <div><p style={labelStyle}>Type</p><p style={valueStyle}>{livreur.vehicules.type}</p></div>
                            <div><p style={labelStyle}>Marque</p><p style={valueStyle}>{livreur.vehicules.brand || '—'}</p></div>
                            <div><p style={labelStyle}>Plaque</p><p style={valueStyle}>{livreur.vehicules.plate_number}</p></div>
                            <div><p style={labelStyle}>Statut</p>
                                <p style={{ ...valueStyle, color: livreur.vehicules.status === 'Disponible' ? '#15803D' : '#E8580A' }}>
                                    {livreur.vehicules.status?.replace('_', ' ')}
                                </p>
                            </div>
                        </div>
                    ) : (
                        <p style={{ color: '#8A8AA3', fontSize: '14px' }}>Aucun vehicule assigne</p>
                    )}
                </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px', marginBottom: '20px' }}>
                {[
                    { label: 'Total livraisons', value: stats.total, color: '#E8580A', bg: '#FFF1E8' },
                    { label: 'Livrees', value: stats.livrees, color: '#15803D', bg: '#F0FDF4' },
                    { label: 'En cours', value: stats.en_cours, color: '#1D4ED8', bg: '#EFF6FF' },
                    { label: 'Annulees', value: stats.annulees, color: '#6B7280', bg: '#F3F4F6' },
                ].map((s, i) => (
                    <div key={i} style={{ backgroundColor: 'white', borderRadius: '16px', border: '1px solid #ECECF2', padding: '16px', textAlign: 'center' }}>
                        <div style={{ width: '36px', height: '36px', borderRadius: '10px', backgroundColor: s.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 10px' }}>
                            <span style={{ fontSize: '16px', fontWeight: 800, color: s.color }}>{s.value}</span>
                        </div>
                        <p style={{ fontSize: '11px', color: '#8A8AA3', margin: 0, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>{s.label}</p>
                    </div>
                ))}
            </div>

            <div style={{ ...cardStyle, marginBottom: '20px' }}>
                <p style={{ fontSize: '15px', fontWeight: 700, color: '#1C1C2E', margin: '0 0 20px 0' }}>Actions</p>
                <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
                    <Link to={'/livreurs/' + id + '/edit'} style={{ ...btnSecondary, textDecoration: 'none', display: 'inline-flex', alignItems: 'center' }}>
                        Modifier le profil
                    </Link>
                    {livreur?.status !== 'Suspendu' ? (
                        <button onClick={handleSuspendre} disabled={actionLoading} style={btnDanger}>
                            Suspendre le livreur
                        </button>
                    ) : (
                        <button onClick={handleReactiver} disabled={actionLoading} style={btnSuccess}>
                            Reactiver le livreur
                        </button>
                    )}
                </div>
            </div>

            <div style={cardStyle}>
                <p style={{ fontSize: '15px', fontWeight: 700, color: '#1C1C2E', margin: '0 0 16px 0' }}>
                    Historique des livraisons ({livraisons.length})
                </p>
                {livraisons.length === 0 ? (
                    <p style={{ color: '#8A8AA3', fontSize: '14px' }}>Aucune livraison effectuee.</p>
                ) : (
                    <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
                        <thead>
                            <tr style={{ backgroundColor: '#FAFAFC', borderBottom: '1px solid #ECECF2' }}>
                                {['ID', 'Client', 'Adresse', 'Statut', 'Date', 'Action'].map(h => (
                                    <th key={h} style={{ padding: '10px 14px', textAlign: 'left', fontSize: '11px', fontWeight: 600, color: '#8A8AA3', textTransform: 'uppercase', letterSpacing: '0.08em' }}>
                                        {h}
                                    </th>
                                ))}
                            </tr>
                        </thead>
                        <tbody>
                            {livraisons.map((l, i) => {
                                const s = livraisonStatusStyles[l.status] || { background: '#F3F4F6', color: '#6B7280' };
                                return (
                                    <tr key={l.id}
                                        style={{ borderBottom: i < livraisons.length - 1 ? '1px solid #ECECF2' : 'none' }}
                                        onMouseEnter={e => e.currentTarget.style.backgroundColor = '#FAFAFC'}
                                        onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}
                                    >
                                        <td style={{ padding: '12px 14px', fontWeight: 700, color: '#1C1C2E' }}>#{l.id}</td>
                                        <td style={{ padding: '12px 14px', color: '#8A8AA3' }}>
                                            {l.customers?.users?.first_name} {l.customers?.users?.last_name}
                                        </td>
                                        <td style={{ padding: '12px 14px', color: '#1C1C2E', maxWidth: '180px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                                            {l.delivery_address}
                                        </td>
                                        <td style={{ padding: '12px 14px' }}>
                                            <span style={{ ...s, padding: '3px 10px', borderRadius: '999px', fontSize: '11px', fontWeight: 600 }}>
                                                {livraisonLabels[l.status] || l.status}
                                            </span>
                                        </td>
                                        <td style={{ padding: '12px 14px', color: '#8A8AA3' }}>
                                            {l.creation_date ? new Date(l.creation_date).toLocaleDateString('fr-FR') : '—'}
                                        </td>
                                        <td style={{ padding: '12px 14px' }}>
                                            <Link to={'/livraisons/' + l.id} style={{ color: '#E8580A', fontWeight: 600, textDecoration: 'none', fontSize: '12px' }}>
                                                Voir
                                            </Link>
                                        </td>
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                )}
            </div>
        </div>
    );
}
