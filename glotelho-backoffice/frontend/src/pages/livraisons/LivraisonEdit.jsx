import { useState, useEffect } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';

export default function LivraisonEdit() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [form, setForm] = useState({ delivery_address: '', zone_bloc: '', amount_to_collect: '', delivery_date: '' });
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        api.get('/livraisons/' + id).then(res => {
            const l = res.data;
            setForm({
                delivery_address: l.delivery_address || '',
                zone_bloc: l.zone_bloc || '',
                amount_to_collect: l.amount_to_collect || '',
                delivery_date: l.delivery_date ? new Date(l.delivery_date).toISOString().slice(0, 16) : '',
            });
        }).catch(() => setError('Livraison introuvable.')).finally(() => setLoading(false));
    }, [id]);

    function handleChange(e) { setForm({ ...form, [e.target.name]: e.target.value }); }

    async function handleSubmit(e) {
        e.preventDefault();
        setError('');
        setSaving(true);
        try {
            await api.put('/livraisons/' + id, form);
            navigate('/livraisons/' + id);
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur lors de la modification.');
        } finally {
            setSaving(false);
        }
    }

    const inputStyle = { width: '100%', padding: '12px 16px', borderRadius: '12px', border: '1px solid #ECECF2', backgroundColor: '#FAFAFC', fontSize: '14px', color: '#1C1C2E', outline: 'none', boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif' };
    const labelStyle = { display: 'block', fontSize: '11px', fontWeight: 600, color: '#8A8AA3', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: '8px' };

    if (loading) return <p style={{ color: '#8A8AA3', textAlign: 'center', marginTop: '60px' }}>Chargement...</p>;

    return (
        <div style={{ maxWidth: '680px' }}>
            <BackButton to={'/livraisons/' + id} />

            <div style={{ marginBottom: '24px' }}>
                <Link to="/livraisons" style={{ color: '#8A8AA3', textDecoration: 'none', fontSize: '14px' }}>Livraisons</Link>
                <span style={{ color: '#8A8AA3', margin: '0 8px' }}>/</span>
                <Link to={'/livraisons/' + id} style={{ color: '#8A8AA3', textDecoration: 'none', fontSize: '14px' }}>Livraison #{id}</Link>
                <span style={{ color: '#8A8AA3', margin: '0 8px' }}>/</span>
                <span style={{ color: '#1C1C2E', fontSize: '14px', fontWeight: 500 }}>Modifier</span>
            </div>

            <div style={{ backgroundColor: 'white', borderRadius: '24px', border: '1px solid #ECECF2', padding: '32px', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
                {error && <div style={{ backgroundColor: '#FEF2F2', border: '1px solid #FECACA', color: '#DC2626', padding: '12px 16px', borderRadius: '12px', marginBottom: '24px', fontSize: '14px' }}>{error}</div>}

                <form onSubmit={handleSubmit}>
                    <div style={{ display: 'grid', gap: '20px' }}>
                        <div>
                            <label style={labelStyle}>Adresse de livraison *</label>
                            <input type="text" name="delivery_address" value={form.delivery_address} onChange={handleChange} style={inputStyle} required />
                        </div>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                            <div>
                                <label style={labelStyle}>Zone / Bloc</label>
                                <input type="text" name="zone_bloc" value={form.zone_bloc} onChange={handleChange} style={inputStyle} placeholder="Ex: Zone 3, Bloc B" />
                            </div>
                            <div>
                                <label style={labelStyle}>Montant a recouvrer (FCFA)</label>
                                <input type="number" name="amount_to_collect" value={form.amount_to_collect} onChange={handleChange} style={inputStyle} min="0" />
                            </div>
                        </div>
                        <div>
                            <label style={labelStyle}>Date de livraison souhaitee</label>
                            <input type="datetime-local" name="delivery_date" value={form.delivery_date} onChange={handleChange} style={inputStyle} />
                        </div>
                        <div style={{ display: 'flex', gap: '12px', marginTop: '8px' }}>
                            <button type="submit" disabled={saving} style={{ background: 'linear-gradient(to right, #E8580A, #FF7A33)', color: 'white', padding: '12px 28px', borderRadius: '12px', border: 'none', fontSize: '14px', fontWeight: 600, cursor: saving ? 'not-allowed' : 'pointer', opacity: saving ? 0.7 : 1, boxShadow: '0 4px 12px rgba(232,88,10,0.25)', fontFamily: 'Poppins, sans-serif' }}>
                                {saving ? 'Enregistrement...' : 'Enregistrer les modifications'}
                            </button>
                            <Link to={'/livraisons/' + id} style={{ padding: '12px 24px', borderRadius: '12px', border: '1px solid #ECECF2', backgroundColor: '#FAFAFC', color: '#1C1C2E', fontSize: '14px', fontWeight: 500, textDecoration: 'none', display: 'inline-flex', alignItems: 'center' }}>
                                Annuler
                            </Link>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    );
}