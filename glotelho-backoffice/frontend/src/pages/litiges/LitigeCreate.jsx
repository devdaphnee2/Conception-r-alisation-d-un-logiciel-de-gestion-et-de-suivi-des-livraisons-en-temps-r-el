import { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    error: '#ba1a1a', errorContainer: '#ffdad6', onErrorContainer: '#93000a',
    surface: '#ffffff', surfaceContainerLow: '#f3f3f3',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
};

export default function LitigeCreate() {
    const [form, setForm] = useState({ order_id: '', type: '', reason: '', amount: '' });
    const [orders, setOrders] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const navigate = useNavigate();

    useEffect(() => { api.get('/orders').then(res => setOrders(res.data)).catch(() => {}); }, []);

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

    const inputStyle = { width: '100%', padding: '11px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, fontSize: '13px', color: P.onSurface, outline: 'none', boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif' };
    const labelStyle = { display: 'block', fontSize: '11px', fontWeight: 600, color: P.onSurfaceVariant, textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: '7px' };

    return (
        <div style={{ maxWidth: '680px', fontFamily: 'Poppins, sans-serif' }}>
            <BackButton to="/litiges" />
            <div style={{ marginBottom: '20px' }}>
                <Link to="/litiges" style={{ color: P.outline, textDecoration: 'none', fontSize: '13px' }}>Litiges</Link>
                <span style={{ color: P.outlineVariant, margin: '0 6px' }}>/</span>
                <span style={{ color: P.onSurface, fontSize: '13px', fontWeight: 500 }}>Nouveau litige</span>
            </div>
            <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, padding: '28px', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>
                {error && <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', color: P.error, padding: '10px 14px', borderRadius: '10px', marginBottom: '20px', fontSize: '13px', fontWeight: 500 }}>{error}</div>}
                <form onSubmit={handleSubmit}>
                    <div style={{ display: 'grid', gap: '18px' }}>
                        <div>
                            <label style={labelStyle}>Commande concernee *</label>
                            <select name="order_id" value={form.order_id} onChange={handleChange} style={inputStyle} required>
                                <option value="">-- Selectionner une commande --</option>
                                {orders.map(o => (
                                    <option key={o.id} value={o.id}>
                                        Commande #{o.id} — {o.customers?.users?.first_name} {o.customers?.users?.last_name} — {Number(o.total_amount).toLocaleString('fr-FR')} FCFA
                                    </option>
                                ))}
                            </select>
                        </div>
                        <div>
                            <label style={labelStyle}>Type de litige *</label>
                            <select name="type" value={form.type} onChange={handleChange} style={inputStyle} required>
                                <option value="">-- Selectionner le type --</option>
                                <option value="Retour_produit">Retour produit</option>
                                <option value="Rabais">Rabais sur prix</option>
                                <option value="Livraison_gratuite">Livraison gratuite prochaine commande</option>
                                <option value="Autre">Autre</option>
                            </select>
                        </div>
                        <div>
                            <label style={labelStyle}>Raison detaillee *</label>
                            <textarea name="reason" value={form.reason} onChange={handleChange} rows={4} style={{ ...inputStyle, resize: 'vertical' }} placeholder="Decrivez precisement le probleme rencontre..." required />
                        </div>
                        <div>
                            <label style={labelStyle}>
                                Montant de compensation (FCFA)
                                <span style={{ textTransform: 'none', fontWeight: 400, marginLeft: '4px' }}>(optionnel)</span>
                            </label>
                            <input type="number" name="amount" value={form.amount} onChange={handleChange} style={inputStyle} placeholder="0" min="0" />
                        </div>
                        <div style={{ display: 'flex', gap: '12px', paddingTop: '8px', borderTop: '1px solid ' + P.outlineVariant }}>
                            <button type="submit" disabled={loading}
                                style={{ backgroundColor: loading ? P.outline : P.primary, color: '#fff', padding: '11px 24px', borderRadius: '10px', border: 'none', fontSize: '13px', fontWeight: 600, cursor: loading ? 'not-allowed' : 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: loading ? 'none' : '0 3px 10px rgba(125,87,0,0.25)' }}>
                                {loading ? 'Creation...' : 'Declarer le litige'}
                            </button>
                            <Link to="/litiges" style={{ padding: '11px 20px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, color: P.onSurface, fontSize: '13px', fontWeight: 500, textDecoration: 'none', display: 'inline-flex', alignItems: 'center' }}>Annuler</Link>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    );
}