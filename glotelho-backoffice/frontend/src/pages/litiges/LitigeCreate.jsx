import { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';

export default function LitigeCreate() {
    const [form, setForm] = useState({ order_id: '', type: '', reason: '', amount: '' });
    const [orders, setOrders] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const navigate = useNavigate();

    useEffect(() => {
        api.get('/orders').then(res => setOrders(res.data)).catch(() => {});
    }, []);

    function handleChange(e) { setForm({ ...form, [e.target.name]: e.target.value }); }

    async function handleSubmit(e) {
        e.preventDefault();
        setError('');
        setLoading(true);
        try {
            await api.post('/litiges', form);
            navigate('/litiges');
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur lors de la creation.');
        } finally { setLoading(false); }
    }

    const inputStyle = { width: '100%', padding: '11px 14px', borderRadius: '12px', border: '1px solid #ECECF2', backgroundColor: '#FAFAFC', fontSize: '14px', color: '#1C1C2E', outline: 'none', boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif' };
    const labelStyle = { display: 'block', fontSize: '11px', fontWeight: 600, color: '#8A8AA3', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: '8px' };

    return (
        <div style={{ maxWidth: '680px' }}>
            <BackButton to="/litiges" />

            <div style={{ marginBottom: '24px' }}>
                <Link to="/litiges" style={{ color: '#8A8AA3', textDecoration: 'none', fontSize: '14px' }}>Litiges</Link>
                <span style={{ color: '#8A8AA3', margin: '0 8px' }}>/</span>
                <span style={{ color: '#1C1C2E', fontSize: '14px', fontWeight: 500 }}>Nouveau litige</span>
            </div>

            <div style={{ backgroundColor: 'white', borderRadius: '24px', border: '1px solid #ECECF2', padding: '32px', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
                {error && <div style={{ backgroundColor: '#FEF2F2', border: '1px solid #FECACA', color: '#DC2626', padding: '12px 16px', borderRadius: '12px', marginBottom: '24px', fontSize: '14px' }}>{error}</div>}

                <form onSubmit={handleSubmit}>
                    <div style={{ display: 'grid', gap: '20px' }}>
                        <div>
                            <label style={labelStyle}>Commande concernee *</label>
                            <select name="order_id" value={form.order_id} onChange={handleChange} style={inputStyle} required>
                                <option value="">-- Selectionner une commande --</option>
                                {orders.map(o => (
                                    <option key={o.id} value={o.id}>
                                        Commande #{o.id} — {Number(o.total_amount).toLocaleString('fr-FR')} FCFA
                                    </option>
                                ))}
                            </select>
                        </div>
                        <div>
                            <label style={labelStyle}>Type de litige *</label>
                            <select name="type" value={form.type} onChange={handleChange} style={inputStyle} required>
                                <option value="">-- Selectionner --</option>
                                <option value="Retour_produit">Retour produit</option>
                                <option value="Rabais">Rabais</option>
                                <option value="Livraison_gratuite">Livraison gratuite</option>
                                <option value="Autre">Autre</option>
                            </select>
                        </div>
                        <div>
                            <label style={labelStyle}>Raison *</label>
                            <textarea name="reason" value={form.reason} onChange={handleChange} rows={4} style={{ ...inputStyle, resize: 'vertical' }} placeholder="Decrivez la raison du litige..." required />
                        </div>
                        <div>
                            <label style={labelStyle}>Montant de la compensation (FCFA) <span style={{ textTransform: 'none', fontWeight: 400 }}>(optionnel)</span></label>
                            <input type="number" name="amount" value={form.amount} onChange={handleChange} style={inputStyle} placeholder="0" min="0" />
                        </div>
                        <div style={{ display: 'flex', gap: '12px', marginTop: '8px' }}>
                            <button type="submit" disabled={loading} style={{ background: 'linear-gradient(to right, #E8580A, #FF7A33)', color: 'white', padding: '12px 28px', borderRadius: '12px', border: 'none', fontSize: '14px', fontWeight: 600, cursor: loading ? 'not-allowed' : 'pointer', opacity: loading ? 0.7 : 1, boxShadow: '0 4px 12px rgba(232,88,10,0.25)', fontFamily: 'Poppins, sans-serif' }}>
                                {loading ? 'Creation...' : 'Creer le litige'}
                            </button>
                            <Link to="/litiges" style={{ padding: '12px 24px', borderRadius: '12px', border: '1px solid #ECECF2', backgroundColor: '#FAFAFC', color: '#1C1C2E', fontSize: '14px', fontWeight: 500, textDecoration: 'none', display: 'inline-flex', alignItems: 'center' }}>
                                Annuler
                            </Link>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    );
}
