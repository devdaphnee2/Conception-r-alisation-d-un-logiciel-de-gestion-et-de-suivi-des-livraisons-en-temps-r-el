import { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';

const statusStyles = {
    'En_attente':  { background: '#FFF9C4', color: '#B45309' },
    'Approuvee':   { background: '#F0FDF4', color: '#15803D' },
    'Rejetee':     { background: '#FEF2F2', color: '#DC2626' },
};

const statusLabels = {
    'En_attente': 'En attente',
    'Approuvee': 'Approuve',
    'Rejetee': 'Rejete',
};

const typeLabels = {
    'Retour_produit': 'Retour produit',
    'Rabais': 'Rabais',
    'Livraison_gratuite': 'Livraison gratuite',
    'Autre': 'Autre',
};

export default function LitigeShow() {
    const { id } = useParams();
    const [litige, setLitige] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [successMsg, setSuccessMsg] = useState('');
    const [actionLoading, setActionLoading] = useState(false);
    const [showResoudreForm, setShowResoudreForm] = useState(false);
    const [decisionForm, setDecisionForm] = useState({ decision: '', amount: '' });

    function charger() {
        api.get('/litiges/' + id)
            .then(res => setLitige(res.data))
            .catch(() => setError('Litige introuvable.'))
            .finally(() => setLoading(false));
    }

    useEffect(() => { charger(); }, [id]);

    async function handlePrendreEnCharge() {
        setActionLoading(true);
        setError('');
        try {
            const res = await api.post('/litiges/' + id + '/prendre-en-charge');
            setSuccessMsg(res.data.message);
            charger();
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur.');
        } finally { setActionLoading(false); }
    }

    async function handleResoudre(e) {
        e.preventDefault();
        setActionLoading(true);
        setError('');
        try {
            const res = await api.post('/litiges/' + id + '/resoudre', decisionForm);
            setSuccessMsg(res.data.message);
            setShowResoudreForm(false);
            charger();
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur.');
        } finally { setActionLoading(false); }
    }

    async function handleRejeter() {
        if (!window.confirm('Confirmer le rejet de ce litige ?')) return;
        setActionLoading(true);
        setError('');
        try {
            const res = await api.post('/litiges/' + id + '/rejeter');
            setSuccessMsg(res.data.message);
            charger();
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur.');
        } finally { setActionLoading(false); }
    }

    if (loading) return <p style={{ color: '#8A8AA3', textAlign: 'center', marginTop: '60px' }}>Chargement...</p>;
    if (error && !litige) return <p style={{ color: '#DC2626', textAlign: 'center', marginTop: '60px' }}>{error}</p>;

    const statusStyle = statusStyles[litige?.status] || { background: '#F3F4F6', color: '#6B7280' };
    const cardStyle = { backgroundColor: 'white', borderRadius: '20px', border: '1px solid #ECECF2', padding: '24px', boxShadow: '0 1px 3px rgba(0,0,0,0.04)', marginBottom: '20px' };
    const labelStyle = { fontSize: '11px', fontWeight: 600, color: '#8A8AA3', textTransform: 'uppercase', letterSpacing: '0.08em', margin: 0 };
    const valueStyle = { fontSize: '15px', color: '#1C1C2E', fontWeight: 500, margin: '4px 0 0 0' };
    const inputStyle = { width: '100%', padding: '11px 14px', borderRadius: '12px', border: '1px solid #ECECF2', backgroundColor: '#FAFAFC', fontSize: '14px', color: '#1C1C2E', outline: 'none', boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif', marginTop: '8px' };
    const btnPrimary = { padding: '10px 20px', borderRadius: '12px', border: 'none', background: 'linear-gradient(to right, #E8580A, #FF7A33)', color: 'white', fontSize: '14px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' };
    const btnSecondary = { padding: '10px 20px', borderRadius: '12px', border: '1px solid #ECECF2', backgroundColor: '#FAFAFC', color: '#1C1C2E', fontSize: '14px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' };
    const btnSuccess = { padding: '10px 20px', borderRadius: '12px', border: 'none', backgroundColor: '#15803D', color: 'white', fontSize: '14px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' };
    const btnDanger = { padding: '10px 20px', borderRadius: '12px', border: '1px solid #FECACA', backgroundColor: '#FEF2F2', color: '#DC2626', fontSize: '14px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' };

    return (
        <div style={{ maxWidth: '780px' }}>
            <BackButton to="/litiges" />

            <div style={{ marginBottom: '24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                    <Link to="/litiges" style={{ color: '#8A8AA3', textDecoration: 'none', fontSize: '14px' }}>Litiges</Link>
                    <span style={{ color: '#8A8AA3', margin: '0 8px' }}>/</span>
                    <span style={{ color: '#1C1C2E', fontSize: '14px', fontWeight: 500 }}>Litige #{id}</span>
                </div>
                <span style={{ ...statusStyle, padding: '6px 14px', borderRadius: '999px', fontSize: '13px', fontWeight: 600 }}>
                    {statusLabels[litige?.status] || litige?.status}
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

            <div style={cardStyle}>
                <p style={{ fontSize: '16px', fontWeight: 700, color: '#1C1C2E', margin: '0 0 20px 0' }}>Informations du litige</p>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                    <div><p style={labelStyle}>Type</p><p style={valueStyle}>{typeLabels[litige?.type] || litige?.type}</p></div>
                    <div><p style={labelStyle}>Montant compensation</p><p style={valueStyle}>{litige?.amount ? Number(litige.amount).toLocaleString('fr-FR') + ' FCFA' : '—'}</p></div>
                    <div style={{ gridColumn: '1 / -1' }}><p style={labelStyle}>Raison</p><p style={{ ...valueStyle, fontSize: '14px', lineHeight: '1.6' }}>{litige?.reason}</p></div>
                    <div><p style={labelStyle}>Date creation</p><p style={valueStyle}>{litige?.created_at ? new Date(litige.created_at).toLocaleString('fr-FR') : '—'}</p></div>
                    <div><p style={labelStyle}>Traite par</p><p style={valueStyle}>{litige?.managers?.users?.first_name} {litige?.managers?.users?.last_name}</p></div>
                </div>
            </div>

            <div style={cardStyle}>
                <p style={{ fontSize: '15px', fontWeight: 700, color: '#1C1C2E', margin: '0 0 16px 0' }}>Client</p>
                {litige?.orders?.customers ? (
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '16px' }}>
                        <div><p style={labelStyle}>Nom</p><p style={valueStyle}>{litige.orders.customers.users?.first_name} {litige.orders.customers.users?.last_name}</p></div>
                        <div><p style={labelStyle}>Telephone</p><p style={valueStyle}>{litige.orders.customers.users?.phone}</p></div>
                        <div><p style={labelStyle}>Commande ref</p><p style={valueStyle}>#{litige.orders?.id} — {Number(litige.orders?.total_amount).toLocaleString('fr-FR')} FCFA</p></div>
                    </div>
                ) : <p style={{ color: '#8A8AA3' }}>—</p>}
            </div>

            {litige?.orders?.delivery_items?.length > 0 && (
                <div style={cardStyle}>
                    <p style={{ fontSize: '15px', fontWeight: 700, color: '#1C1C2E', margin: '0 0 16px 0' }}>Articles de la commande</p>
                    <div style={{ display: 'grid', gap: '8px' }}>
                        {litige.orders.delivery_items.map((item, i) => (
                            <div key={i} style={{ padding: '12px 16px', borderRadius: '12px', backgroundColor: '#FAFAFC', border: '1px solid #ECECF2', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                <span style={{ fontSize: '13px', fontWeight: 500, color: '#1C1C2E' }}>{item.product_name}</span>
                                <span style={{ fontSize: '11px', fontWeight: 600, color: item.status === 'Disponible' ? '#15803D' : '#B45309', backgroundColor: item.status === 'Disponible' ? '#F0FDF4' : '#FFF9C4', padding: '3px 10px', borderRadius: '999px' }}>
                                    {item.status}
                                </span>
                            </div>
                        ))}
                    </div>
                </div>
            )}

            <div style={{ ...cardStyle, marginBottom: 0 }}>
                <p style={{ fontSize: '16px', fontWeight: 700, color: '#1C1C2E', margin: '0 0 20px 0' }}>Actions</p>

                <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
                    {litige?.status === 'En_attente' && (
                        <button onClick={handlePrendreEnCharge} disabled={actionLoading} style={btnPrimary}>
                            Prendre en charge
                        </button>
                    )}

                    {litige?.status === 'En_attente' && (
                        <button onClick={() => setShowResoudreForm(!showResoudreForm)} style={btnSuccess}>
                            Resoudre le litige
                        </button>
                    )}

                    {litige?.status === 'En_attente' && (
                        <button onClick={handleRejeter} disabled={actionLoading} style={btnDanger}>
                            Rejeter
                        </button>
                    )}
                </div>

                {showResoudreForm && (
                    <div style={{ marginTop: '20px', padding: '20px', backgroundColor: '#FAFAFC', borderRadius: '16px', border: '1px solid #ECECF2' }}>
                        <p style={{ fontSize: '14px', fontWeight: 600, color: '#1C1C2E', marginBottom: '16px' }}>Resoudre le litige</p>
                        <form onSubmit={handleResoudre}>
                            <div style={{ display: 'grid', gap: '16px' }}>
                                <div>
                                    <label style={{ ...labelStyle, display: 'block', marginBottom: '8px' }}>Decision *</label>
                                    <select value={decisionForm.decision} onChange={e => setDecisionForm({ ...decisionForm, decision: e.target.value })} style={inputStyle} required>
                                        <option value="">-- Selectionner une decision --</option>
                                        <option value="Retour_produit">Retour produit</option>
                                        <option value="Rabais">Rabais</option>
                                        <option value="Livraison_gratuite">Livraison gratuite</option>
                                        <option value="Autre">Autre</option>
                                    </select>
                                </div>
                                <div>
                                    <label style={{ ...labelStyle, display: 'block', marginBottom: '8px' }}>Montant compensation (FCFA)</label>
                                    <input type="number" value={decisionForm.amount} onChange={e => setDecisionForm({ ...decisionForm, amount: e.target.value })} style={inputStyle} placeholder="0" min="0" />
                                </div>
                                <div style={{ display: 'flex', gap: '10px' }}>
                                    <button type="submit" disabled={actionLoading} style={btnSuccess}>
                                        {actionLoading ? 'En cours...' : 'Confirmer la resolution'}
                                    </button>
                                    <button type="button" onClick={() => setShowResoudreForm(false)} style={btnSecondary}>Annuler</button>
                                </div>
                            </div>
                        </form>
                    </div>
                )}
            </div>
        </div>
    );
}
