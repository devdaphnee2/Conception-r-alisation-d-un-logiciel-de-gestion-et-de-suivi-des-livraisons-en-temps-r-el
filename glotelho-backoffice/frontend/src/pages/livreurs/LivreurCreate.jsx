import { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';

export default function LivreurCreate() {
    const [form, setForm] = useState({ last_name: '', first_name: '', email: '', password: '', phone: '', zone_affectee: '', vehicle_id: '' });
    const [vehicules, setVehicules] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const navigate = useNavigate();

    useEffect(() => {
        api.get('/vehicules').then(res => setVehicules(res.data)).catch(() => {});
    }, []);

    function handleChange(e) { setForm({ ...form, [e.target.name]: e.target.value }); }

    async function handleSubmit(e) {
        e.preventDefault();
        setError('');
        setLoading(true);
        try {
            await api.post('/livreurs', form);
            navigate('/livreurs');
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur lors de la creation.');
        } finally { setLoading(false); }
    }

    const inputStyle = { width: '100%', padding: '11px 14px', borderRadius: '12px', border: '1px solid #ECECF2', backgroundColor: '#FAFAFC', fontSize: '14px', color: '#1C1C2E', outline: 'none', boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif' };
    const labelStyle = { display: 'block', fontSize: '11px', fontWeight: 600, color: '#8A8AA3', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: '8px' };

    return (
        <div style={{ maxWidth: '680px' }}>
            <BackButton to="/livreurs" />

            <div style={{ marginBottom: '24px' }}>
                <Link to="/livreurs" style={{ color: '#8A8AA3', textDecoration: 'none', fontSize: '14px' }}>Livreurs</Link>
                <span style={{ color: '#8A8AA3', margin: '0 8px' }}>/</span>
                <span style={{ color: '#1C1C2E', fontSize: '14px', fontWeight: 500 }}>Nouveau livreur</span>
            </div>

            <div style={{ backgroundColor: 'white', borderRadius: '24px', border: '1px solid #ECECF2', padding: '32px', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
                {error && <div style={{ backgroundColor: '#FEF2F2', border: '1px solid #FECACA', color: '#DC2626', padding: '12px 16px', borderRadius: '12px', marginBottom: '24px', fontSize: '14px' }}>{error}</div>}

                <form onSubmit={handleSubmit}>
                    <div style={{ display: 'grid', gap: '20px' }}>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                            <div><label style={labelStyle}>Nom *</label><input type="text" name="last_name" value={form.last_name} onChange={handleChange} style={inputStyle} required /></div>
                            <div><label style={labelStyle}>Prenom *</label><input type="text" name="first_name" value={form.first_name} onChange={handleChange} style={inputStyle} required /></div>
                        </div>
                        <div><label style={labelStyle}>Email *</label><input type="email" name="email" value={form.email} onChange={handleChange} style={inputStyle} required /></div>
                        <div><label style={labelStyle}>Mot de passe *</label><input type="password" name="password" value={form.password} onChange={handleChange} style={inputStyle} required /></div>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                            <div><label style={labelStyle}>Telephone *</label><input type="text" name="phone" value={form.phone} onChange={handleChange} style={inputStyle} required /></div>
                            <div><label style={labelStyle}>Zone affectee</label><input type="text" name="zone_affectee" value={form.zone_affectee} onChange={handleChange} style={inputStyle} placeholder="Ex: Bonamoussadi" /></div>
                        </div>
                        <div>
                            <label style={labelStyle}>Vehicule</label>
                            <select name="vehicle_id" value={form.vehicle_id} onChange={handleChange} style={inputStyle}>
                                <option value="">-- Aucun vehicule --</option>
                                {vehicules.map(v => <option key={v.id} value={v.id}>{v.brand} {v.type} — {v.plate_number}</option>)}
                            </select>
                        </div>
                        <div style={{ display: 'flex', gap: '12px', marginTop: '8px' }}>
                            <button type="submit" disabled={loading} style={{ background: 'linear-gradient(to right, #E8580A, #FF7A33)', color: 'white', padding: '12px 28px', borderRadius: '12px', border: 'none', fontSize: '14px', fontWeight: 600, cursor: loading ? 'not-allowed' : 'pointer', opacity: loading ? 0.7 : 1, boxShadow: '0 4px 12px rgba(232,88,10,0.25)', fontFamily: 'Poppins, sans-serif' }}>
                                {loading ? 'Creation...' : 'Creer le livreur'}
                            </button>
                            <Link to="/livreurs" style={{ padding: '12px 24px', borderRadius: '12px', border: '1px solid #ECECF2', backgroundColor: '#FAFAFC', color: '#1C1C2E', fontSize: '14px', fontWeight: 500, textDecoration: 'none', display: 'inline-flex', alignItems: 'center' }}>
                                Annuler
                            </Link>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    );
}
