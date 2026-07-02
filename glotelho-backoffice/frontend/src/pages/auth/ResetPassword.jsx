import { useState, useEffect } from 'react';
import { Link, useSearchParams, useNavigate } from 'react-router-dom';
import api from '../../services/api';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    error: '#ba1a1a', errorContainer: '#ffdad6',
    surface: '#ffffff', surfaceContainerLow: '#f3f3f3',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
};

export default function ResetPassword() {
    const [searchParams] = useSearchParams();
    const token = searchParams.get('token');
    const navigate = useNavigate();

    const [form, setForm] = useState({ password: '', confirm: '' });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState(false);
    const [tokenValid, setTokenValid] = useState(null);

    useEffect(() => {
        if (!token) { setTokenValid(false); return; }
        api.get('/auth/verify-reset-token?token=' + token)
            .then(() => setTokenValid(true))
            .catch(() => setTokenValid(false));
    }, [token]);

    function handleChange(e) { setForm({ ...form, [e.target.name]: e.target.value }); }

    async function handleSubmit(e) {
        e.preventDefault();
        setError('');
        if (form.password !== form.confirm) { setError('Les mots de passe ne correspondent pas.'); return; }
        if (form.password.length < 8) { setError('Le mot de passe doit contenir au moins 8 caracteres.'); return; }

        setLoading(true);
        try {
            await api.post('/auth/reset-password', { token, password: form.password });
            setSuccess(true);
            setTimeout(() => navigate('/login'), 2500);
        } catch (err) {
            setError(err.response?.data?.message || 'Le lien a expire ou est invalide.');
        } finally { setLoading(false); }
    }

    const inputStyle = { width: '100%', padding: '12px 16px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, fontSize: '14px', color: P.onSurface, outline: 'none', boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif' };

    return (
        <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#f9f9f9', fontFamily: 'Poppins, sans-serif', padding: '20px' }}>
            <div style={{ width: '100%', maxWidth: '420px', backgroundColor: P.surface, borderRadius: '20px', padding: '40px', boxShadow: '0 8px 32px rgba(0,0,0,0.08)', border: '1px solid ' + P.outlineVariant }}>

                <div style={{ width: '56px', height: '56px', backgroundColor: P.surfaceContainerLow, borderRadius: '14px', padding: '8px', margin: '0 auto 24px' }}>
                    <img src="/logo_glotelho.png" alt="Glotelho" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                </div>

                {tokenValid === null && (
                    <p style={{ textAlign: 'center', color: P.outline, fontSize: '13px' }}>Verification du lien...</p>
                )}

                {tokenValid === false && (
                    <>
                        <h1 style={{ fontSize: '18px', fontWeight: 800, color: P.error, textAlign: 'center', margin: '0 0 10px 0' }}>Lien invalide ou expire</h1>
                        <p style={{ fontSize: '13px', color: P.outline, textAlign: 'center', margin: '0 0 24px 0', lineHeight: 1.6 }}>
                            Ce lien de reinitialisation n'est plus valide. Demandez-en un nouveau.
                        </p>
                        <Link to="/forgot-password" style={{ display: 'block', textAlign: 'center', backgroundColor: P.primary, color: '#fff', padding: '13px', borderRadius: '10px', fontSize: '14px', fontWeight: 600, textDecoration: 'none' }}>
                            Demander un nouveau lien
                        </Link>
                    </>
                )}

                {tokenValid === true && !success && (
                    <>
                        <h1 style={{ fontSize: '20px', fontWeight: 800, color: P.onSurface, textAlign: 'center', margin: '0 0 8px 0' }}>Nouveau mot de passe</h1>
                        <p style={{ fontSize: '13px', color: P.outline, textAlign: 'center', margin: '0 0 28px 0' }}>Choisissez un nouveau mot de passe securise.</p>

                        {error && <div style={{ backgroundColor: P.errorContainer, color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '16px', fontSize: '13px', fontWeight: 500 }}>{error}</div>}

                        <form onSubmit={handleSubmit}>
                            <div style={{ marginBottom: '16px' }}>
                                <label style={{ display: 'block', fontSize: '11px', fontWeight: 600, color: P.onSurfaceVariant, textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: '8px' }}>Nouveau mot de passe</label>
                                <input type="password" name="password" value={form.password} onChange={handleChange} style={inputStyle} required minLength={8} />
                            </div>
                            <div>
                                <label style={{ display: 'block', fontSize: '11px', fontWeight: 600, color: P.onSurfaceVariant, textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: '8px' }}>Confirmer le mot de passe</label>
                                <input type="password" name="confirm" value={form.confirm} onChange={handleChange} style={inputStyle} required minLength={8} />
                            </div>
                            <p style={{ margin: '8px 0 0 0', fontSize: '11px', color: P.outline }}>Minimum 8 caracteres.</p>

                            <button type="submit" disabled={loading}
                                style={{ width: '100%', marginTop: '20px', backgroundColor: loading ? P.outline : P.primary, color: '#fff', padding: '13px', borderRadius: '10px', border: 'none', fontSize: '14px', fontWeight: 600, cursor: loading ? 'not-allowed' : 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: loading ? 'none' : '0 4px 14px rgba(125,87,0,0.3)' }}>
                                {loading ? 'Modification...' : 'Reinitialiser le mot de passe'}
                            </button>
                        </form>
                    </>
                )}

                {success && (
                    <>
                        <div style={{ width: '52px', height: '52px', borderRadius: '50%', backgroundColor: '#c8e6c9', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 20px' }}>
                            <svg width="24" height="24" fill="none" stroke="#1b5e20" viewBox="0 0 24 24" strokeWidth="2.5"><path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7"/></svg>
                        </div>
                        <h1 style={{ fontSize: '18px', fontWeight: 800, color: P.onSurface, textAlign: 'center', margin: '0 0 10px 0' }}>Mot de passe reinitialise</h1>
                        <p style={{ fontSize: '13px', color: P.outline, textAlign: 'center', margin: 0 }}>Redirection vers la connexion...</p>
                    </>
                )}
            </div>
        </div>
    );
}