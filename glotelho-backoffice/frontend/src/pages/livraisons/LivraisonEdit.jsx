import { useState, useEffect } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    primaryFixed: '#ffdea9', onPrimaryContainer: '#483100',
    error: '#ba1a1a', errorContainer: '#ffdad6', onErrorContainer: '#93000a',
    surface: '#ffffff', surfaceContainerLow: '#f3f3f3',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
};

export default function LivraisonEdit() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [form, setForm] = useState({
        delivery_address: '', zone_bloc: '',
        delivery_instructions: '', delivery_date: '',
        amount_to_collect: '', collected_amount: '',
    });
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        api.get('/livraisons/' + id).then(res => {
            const l = res.data;
            setForm({
                delivery_address: l.delivery_address || '',
                zone_bloc: l.zone_bloc || '',
                delivery_instructions: l.delivery_instructions || '',
                delivery_date: l.delivery_date ? l.delivery_date.slice(0, 16) : '',
                amount_to_collect: l.amount_to_collect || '',
                collected_amount: l.collected_amount || '0',
            });
        }).catch(() => setError('Livraison introuvable.'))
          .finally(() => setLoading(false));
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
            setError(err.response?.data?.message || 'Erreur.');
        } finally { setSaving(false); }
    }

    const inputStyle = { width: '100%', padding: '11px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, fontSize: '13px', color: P.onSurface, outline: 'none', boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif' };
    const labelStyle = { display: 'block', fontSize: '11px', fontWeight: 600, color: P.onSurfaceVariant, textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: '7px' };

    if (loading) return <p style={{ fontFamily: 'Poppins, sans-serif', color: P.outline, textAlign: 'center', marginTop: '60px' }}>Chargement...</p>;

    return (
        <div style={{ maxWidth: '680px', fontFamily: 'Poppins, sans-serif' }}>
            <BackButton to={'/livraisons/' + id} />
            <div style={{ marginBottom: '20px' }}>
                <Link to="/livraisons" style={{ color: P.outline, textDecoration: 'none', fontSize: '13px' }}>Livraisons</Link>
                <span style={{ color: P.outlineVariant, margin: '0 6px' }}>/</span>
                <Link to={'/livraisons/' + id} style={{ color: P.outline, textDecoration: 'none', fontSize: '13px' }}>#{String(id).padStart(5,'0')}</Link>
                <span style={{ color: P.outlineVariant, margin: '0 6px' }}>/</span>
                <span style={{ color: P.onSurface, fontSize: '13px', fontWeight: 500 }}>Modifier</span>
            </div>

            <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, padding: '28px', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>
                {error && <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', color: P.error, padding: '10px 14px', borderRadius: '10px', marginBottom: '20px', fontSize: '13px', fontWeight: 500 }}>{error}</div>}

                <form onSubmit={handleSubmit}>
                    <div style={{ display: 'grid', gap: '18px' }}>
                        <div>
                            <label style={labelStyle}>Adresse de livraison *</label>
                            <input type="text" name="delivery_address" value={form.delivery_address} onChange={handleChange} style={inputStyle} required placeholder="Adresse complete" />
                        </div>
                        <div>
                            <label style={labelStyle}>Description du lieu</label>
                            <input type="text" name="zone_bloc" value={form.zone_bloc} onChange={handleChange} style={inputStyle} placeholder="Apres le carrefour, portail rouge..." />
                        </div>
                        <div>
                            <label style={labelStyle}>Instructions de livraison</label>
                            <textarea name="delivery_instructions" value={form.delivery_instructions} onChange={handleChange} rows={3} style={{ ...inputStyle, resize: 'vertical' }} placeholder="Colis fragile, appeler avant..." />
                        </div>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                            <div>
                                <label style={labelStyle}>Montant a collecter (FCFA)</label>
                                <input type="number" name="amount_to_collect" value={form.amount_to_collect} onChange={handleChange} style={inputStyle} min="0" />
                            </div>
                            <div>
                                <label style={labelStyle}>Deja paye (FCFA)</label>
                                <input type="number" name="collected_amount" value={form.collected_amount} onChange={handleChange} style={inputStyle} min="0" />
                            </div>
                        </div>
                        <div>
                            <label style={labelStyle}>Date de livraison souhaitee</label>
                            <input type="datetime-local" name="delivery_date" value={form.delivery_date} onChange={handleChange} style={inputStyle} />
                        </div>
                        <div style={{ display: 'flex', gap: '12px', paddingTop: '8px', borderTop: '1px solid ' + P.outlineVariant }}>
                            <button type="submit" disabled={saving}
                                style={{ backgroundColor: saving ? P.outline : P.primary, color: '#fff', padding: '11px 24px', borderRadius: '10px', border: 'none', fontSize: '13px', fontWeight: 600, cursor: saving ? 'not-allowed' : 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: saving ? 'none' : '0 3px 10px rgba(125,87,0,0.25)' }}>
                                {saving ? 'Enregistrement...' : 'Enregistrer les modifications'}
                            </button>
                            <Link to={'/livraisons/' + id} style={{ padding: '11px 20px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, color: P.onSurface, fontSize: '13px', fontWeight: 500, textDecoration: 'none', display: 'inline-flex', alignItems: 'center' }}>
                                Annuler
                            </Link>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    );
}