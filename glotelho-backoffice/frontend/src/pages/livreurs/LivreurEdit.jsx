import { useState, useEffect } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    error: '#ba1a1a', errorContainer: '#ffdad6', onErrorContainer: '#93000a',
    surface: '#ffffff', surfaceContainerLow: '#f3f3f3',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
};

export default function LivreurEdit() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [form, setForm] = useState({ last_name: '', first_name: '', phone: '', zone_affectee: '', vehicle_id: '' });
    const [vehicules, setVehicules] = useState([]);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        api.get('/livreurs/' + id).then(res => {
            const l = res.data;
            setForm({ last_name: l.users?.last_name || '', first_name: l.users?.first_name || '', phone: l.users?.phone || '', zone_affectee: l.zone_affectee || '', vehicle_id: l.vehicle_id || '' });
        }).catch(() => setError('Livreur introuvable.')).finally(() => setLoading(false));
        api.get('/vehicules').then(res => setVehicules(res.data)).catch(() => {});
    }, [id]);

    function handleChange(e) { setForm({ ...form, [e.target.name]: e.target.value }); }

    async function handleSubmit(e) {
        e.preventDefault();
        setError('');
        setSaving(true);
        try {
            await api.put('/livreurs/' + id, form);
            navigate('/livreurs/' + id);
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur.');
        } finally { setSaving(false); }
    }

    const inputStyle = { width: '100%', padding: '11px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, fontSize: '13px', color: P.onSurface, outline: 'none', boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif' };
    const labelStyle = { display: 'block', fontSize: '11px', fontWeight: 600, color: P.onSurfaceVariant, textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: '7px' };

    if (loading) return <p style={{ fontFamily: 'Poppins, sans-serif', color: P.outline, textAlign: 'center', marginTop: '60px' }}>Chargement...</p>;

    return (
        <div style={{ maxWidth: '680px', fontFamily: 'Poppins, sans-serif' }}>
            <BackButton to={'/livreurs/' + id} />
            <div style={{ marginBottom: '20px' }}>
                <Link to="/livreurs" style={{ color: P.outline, textDecoration: 'none', fontSize: '13px' }}>Livreurs</Link>
                <span style={{ color: P.outlineVariant, margin: '0 6px' }}>/</span>
                <Link to={'/livreurs/' + id} style={{ color: P.outline, textDecoration: 'none', fontSize: '13px' }}>Livreur #{id}</Link>
                <span style={{ color: P.outlineVariant, margin: '0 6px' }}>/</span>
                <span style={{ color: P.onSurface, fontSize: '13px', fontWeight: 500 }}>Modifier</span>
            </div>
            <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, padding: '28px', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>
                {error && <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', color: P.error, padding: '10px 14px', borderRadius: '10px', marginBottom: '20px', fontSize: '13px', fontWeight: 500 }}>{error}</div>}
                <form onSubmit={handleSubmit}>
                    <div style={{ display: 'grid', gap: '18px' }}>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                            <div><label style={labelStyle}>Nom *</label><input type="text" name="last_name" value={form.last_name} onChange={handleChange} style={inputStyle} required /></div>
                            <div><label style={labelStyle}>Prenom *</label><input type="text" name="first_name" value={form.first_name} onChange={handleChange} style={inputStyle} required /></div>
                        </div>
                        <div><label style={labelStyle}>Telephone *</label><input type="text" name="phone" value={form.phone} onChange={handleChange} style={inputStyle} required /></div>
                        <div><label style={labelStyle}>Zone affectee</label><input type="text" name="zone_affectee" value={form.zone_affectee} onChange={handleChange} style={inputStyle} placeholder="Ex: Bonamoussadi" /></div>
                        <div>
                            <label style={labelStyle}>Vehicule</label>
                            <select name="vehicle_id" value={form.vehicle_id} onChange={handleChange} style={inputStyle}>
                                <option value="">-- Aucun vehicule --</option>
                                {vehicules.map(v => <option key={v.id} value={v.id}>{v.brand} {v.type} — {v.plate_number}</option>)}
                            </select>
                        </div>
                        <div style={{ display: 'flex', gap: '12px', paddingTop: '8px', borderTop: '1px solid ' + P.outlineVariant }}>
                            <button type="submit" disabled={saving}
                                style={{ backgroundColor: saving ? P.outline : P.primary, color: '#fff', padding: '11px 24px', borderRadius: '10px', border: 'none', fontSize: '13px', fontWeight: 600, cursor: saving ? 'not-allowed' : 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: saving ? 'none' : '0 3px 10px rgba(125,87,0,0.25)' }}>
                                {saving ? 'Enregistrement...' : 'Enregistrer'}
                            </button>
                            <Link to={'/livreurs/' + id} style={{ padding: '11px 20px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, color: P.onSurface, fontSize: '13px', fontWeight: 500, textDecoration: 'none', display: 'inline-flex', alignItems: 'center' }}>Annuler</Link>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    );
}