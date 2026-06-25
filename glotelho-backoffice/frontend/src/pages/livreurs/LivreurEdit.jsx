import { useState, useEffect } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';

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
            setForm({
                last_name: l.users?.last_name || '',
                first_name: l.users?.first_name || '',
                phone: l.users?.phone || '',
                zone_affectee: l.zone_affectee || '',
                vehicle_id: l.vehicle_id || '',
            });
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
            setError(err.response?.data?.message || 'Erreur lors de la modification.');
        } finally { setSaving(false); }
    }

    const inputStyle = { width: '100%', padding: '11px 14px', borderRadius: '12px', border: '1px solid #ECECF2', backgroundColor: '#FAFAFC', fontSize: '14px', color: '#1C1C2E', outline: 'none', boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif' };
    const labelStyle = { display: 'block', fontSize: '11px', fontWeight: 600, color: '#8A8AA3', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: '8px' };

    if (loading) return <p style={{ color: '#8A8AA3', textAlign: 'center', marginTop: '60px' }}>Chargement...</p>;

    return (
        <div style={{ maxWidth: '680px' }}>
            <BackButton to={'/livreurs/' + id} />

            <div style={{ marginBottom: '24px' }}>
                <Link to="/livreurs" style={{ color: '#8A8AA3', textDecoration: 'none', fontSize: '14px' }}>Livreurs</Link>
                <span style={{ color: '#8A8AA3', margin: '0 8px' }}>/</span>
                <Link to={'/livreurs/' + id} style={{ color: '#8A8AA3', textDecoration: 'none', fontSize: '14px' }}>Livreur #{id}</Link>
                <span style={{ color: '#8A8AA3', margin: '0 8px' }}>/</span>
                <span style={{ color: '#1C1C2E', fontSize: '14px', fontWeight: 500 }}>Modifier</span>
            </div>

            <div style={{ backgroundColor: 'white', borderRadius: '24px', border: '1px solid #ECECF2', padding: '32px', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
                {error && <div style={{ backgroundColor: '#FEF2F2', border: '1px solid #FECACA', color: '#DC2626', padding: '12px 16px', borderRadius: '12px', marginBottom: '24px', fontSize: '14px' }}>{error}</div>}

                <form onSubmit={handleSubmit}>
                    <div style={{ display: 'grid', gap: '20px' }}>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
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
                        <div style={{ display: 'flex', gap: '12px', marginTop: '8px' }}>
                            <button type="submit" disabled={saving} style={{ background: 'linear-gradient(to right, #E8580A, #FF7A33)', color: 'white', padding: '12px 28px', borderRadius: '12px', border: 'none', fontSize: '14px', fontWeight: 600, cursor: saving ? 'not-allowed' : 'pointer', opacity: saving ? 0.7 : 1, fontFamily: 'Poppins, sans-serif' }}>
                                {saving ? 'Enregistrement...' : 'Enregistrer'}
                            </button>
                            <Link to={'/livreurs/' + id} style={{ padding: '12px 24px', borderRadius: '12px', border: '1px solid #ECECF2', backgroundColor: '#FAFAFC', color: '#1C1C2E', fontSize: '14px', fontWeight: 500, textDecoration: 'none', display: 'inline-flex', alignItems: 'center' }}>
                                Annuler
                            </Link>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    );
}
