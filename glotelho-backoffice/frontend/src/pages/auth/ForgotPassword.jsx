import { useState } from 'react';
import { Link } from 'react-router-dom';
import api from '../../services/api';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    error: '#ba1a1a', errorContainer: '#ffdad6',
    surface: '#ffffff', surfaceContainerLow: '#f3f3f3',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
    inverseS: '#2f3131', inverseSOn: '#f1f1f1',
};

export default function ForgotPassword() {
    const [email, setEmail] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [sent, setSent] = useState(false);

    async function handleSubmit(e) {
        e.preventDefault();
        setError('');
        setLoading(true);
        try {
            await api.post('/auth/forgot-password', { email });
            setSent(true);
        } catch (err) {
            // Pour la securite, on affiche toujours le meme message succes
            // meme si l'email n'existe pas (evite l'enumeration de comptes)
            setSent(true);
        } finally { setLoading(false); }
    }

    const inputStyle = { width: '100%', padding: '12px 16px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, fontSize: '14px', color: P.onSurface, outline: 'none', boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif' };

    return (
        <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#f9f9f9', fontFamily: 'Poppins, sans-serif', padding: '20px' }}>
            <div style={{ width: '100%', maxWidth: '420px', backgroundColor: P.surface, borderRadius: '20px', padding: '40px', boxShadow: '0 8px 32px rgba(0,0,0,0.08)', border: '1px solid ' + P.outlineVariant }}>

                <div style={{ width: '56px', height: '56px', backgroundColor: P.surfaceContainerLow, borderRadius: '14px', padding: '8px', margin: '0 auto 24px' }}>
                    <img src="/logo_glotelho.png" alt="Glotelho" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                </div>

                {!sent ? (
                    <>
                        <h1 style={{ fontSize: '20px', fontWeight: 800, color: P.onSurface, textAlign: 'center', margin: '0 0 8px 0' }}>Mot de passe oublie</h1>
                        <p style={{ fontSize: '13px', color: P.outline, textAlign: 'center', margin: '0 0 28px 0', lineHeight: 1.5 }}>
                            Entrez votre adresse email. Un lien de reinitialisation vous sera envoye.
                        </p>

                        {error && <div style={{ backgroundColor: P.errorContainer, color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '16px', fontSize: '13px', fontWeight: 500 }}>{error}</div>}

                        <form onSubmit={handleSubmit}>
                            <label style={{ display: 'block', fontSize: '11px', fontWeight: 600, color: P.onSurfaceVariant, textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: '8px' }}>Email</label>
                            <input type="email" value={email} onChange={e => setEmail(e.target.value)} style={inputStyle} placeholder="manager@glotelho.com" required />

                            <button type="submit" disabled={loading}
                                style={{ width: '100%', marginTop: '20px', backgroundColor: loading ? P.outline : P.primary, color: '#fff', padding: '13px', borderRadius: '10px', border: 'none', fontSize: '14px', fontWeight: 600, cursor: loading ? 'not-allowed' : 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: loading ? 'none' : '0 4px 14px rgba(125,87,0,0.3)' }}>
                                {loading ? 'Envoi en cours...' : 'Envoyer le lien de reinitialisation'}
                            </button>
                        </form>
                    </>
                ) : (
                    <>
                        <div style={{ width: '52px', height: '52px', borderRadius: '50%', backgroundColor: '#c8e6c9', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 20px' }}>
                            <svg width="24" height="24" fill="none" stroke="#1b5e20" viewBox="0 0 24 24" strokeWidth="2.5"><path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7"/></svg>
                        </div>
                        <h1 style={{ fontSize: '18px', fontWeight: 800, color: P.onSurface, textAlign: 'center', margin: '0 0 10px 0' }}>Email envoye</h1>
                        <p style={{ fontSize: '13px', color: P.outline, textAlign: 'center', margin: '0 0 24px 0', lineHeight: 1.6 }}>
                            Si un compte existe avec l'adresse <strong>{email}</strong>, un lien de reinitialisation a ete envoye. Verifiez votre boite de reception.
                        </p>
                    </>
                )}

                <p style={{ textAlign: 'center', marginTop: '24px', fontSize: '13px' }}>
                    <Link to="/login" style={{ color: P.primary, fontWeight: 600, textDecoration: 'none' }}>Retour a la connexion</Link>
                </p>
            </div>
        </div>
    );
}