import { useState, useEffect, useRef } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import api from '../../services/api';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    error: '#ba1a1a', errorContainer: '#ffdad6',
    surface: '#ffffff', surfaceContainerLow: '#f3f3f3',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
    inverseS: '#2f3131', inverseSOn: '#f1f1f1',
};

const GOOGLE_CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID || 'TON_CLIENT_ID.apps.googleusercontent.com';

export default function Login() {
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const { login } = useAuth();
    const navigate = useNavigate();
    const googleBtnRef = useRef(null);

    // Connexion classique — nom d'utilisateur (email) + mot de passe
    async function handleSubmit(e) {
        e.preventDefault();
        setError('');
        setLoading(true);
        try {
            await login(username, password);
            navigate('/dashboard');
        } catch (err) {
            setError(err.response?.data?.message || 'Identifiants incorrects.');
        } finally { setLoading(false); }
    }

    // Connexion Google — compte deja existant uniquement
    async function handleGoogleCredential(response) {
        setError('');
        setLoading(true);
        try {
            const res = await api.post('/auth/google-login', { credential: response.credential });
            localStorage.setItem('token', res.data.token);
            localStorage.setItem('user', JSON.stringify(res.data.user));
            window.location.href = '/dashboard';
        } catch (err) {
            setError(err.response?.data?.message || 'Connexion Google impossible. Avez-vous deja un compte ?');
        } finally { setLoading(false); }
    }

    // ── Chargement du script Google Identity Services ────────
    // Evite la double initialisation (warning GSI_LOGGER) en
    // verifiant si le script est deja present dans le DOM avant
    // de le recreer, et nettoie au demontage du composant.
    useEffect(() => {
        function initGoogle() {
            if (window.google && googleBtnRef.current) {
                window.google.accounts.id.initialize({
                    client_id: GOOGLE_CLIENT_ID,
                    callback: handleGoogleCredential,
                });
                window.google.accounts.id.renderButton(googleBtnRef.current, {
                    theme: 'outline',
                    size: 'large',
                    width: '100%',
                    text: 'signin_with',
                    shape: 'rectangular',
                    logo_alignment: 'left',
                });
            }
        }

        const existingScript = document.getElementById('google-identity-script');
        if (existingScript) {
            // Script deja charge — on initialise juste le bouton
            initGoogle();
        } else {
            const script = document.createElement('script');
            script.id = 'google-identity-script';
            script.src = 'https://accounts.google.com/gsi/client';
            script.async = true;
            script.defer = true;
            script.onload = initGoogle;
            document.body.appendChild(script);
        }

        return () => {
            if (window.google?.accounts?.id) {
                window.google.accounts.id.cancel();
            }
        };
    }, []);
    // ─────────────────────────────────────────────────────────

    const inputStyle = { width: '100%', padding: '12px 16px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, fontSize: '14px', color: P.onSurface, outline: 'none', boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif' };

    return (
        <div style={{ minHeight: '100vh', display: 'flex', fontFamily: 'Poppins, sans-serif' }}>

            <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#f9f9f9', padding: '20px' }}>
                <div style={{ width: '100%', maxWidth: '380px' }}>

                    <div style={{ width: '52px', height: '52px', backgroundColor: P.surfaceContainerLow, borderRadius: '14px', padding: '8px', marginBottom: '24px' }}>
                        <img src="/logo_glotelho.png" alt="Glotelho" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                    </div>

                    <h1 style={{ fontSize: '22px', fontWeight: 800, color: P.onSurface, margin: '0 0 6px 0' }}>Connexion</h1>
                    <p style={{ fontSize: '13px', color: P.outline, margin: '0 0 28px 0' }}>Accedez au back-office Glotelho.</p>

                    {error && <div style={{ backgroundColor: P.errorContainer, color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '16px', fontSize: '13px', fontWeight: 500 }}>{error}</div>}

                    {/* OPTION 1 — Google */}
                    <div ref={googleBtnRef} style={{ marginBottom: '20px', minHeight: '44px' }}></div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px', margin: '0 0 20px 0' }}>
                        <div style={{ flex: 1, height: '1px', backgroundColor: P.outlineVariant }}></div>
                        <span style={{ fontSize: '11px', color: P.outline, fontWeight: 500 }}>ou</span>
                        <div style={{ flex: 1, height: '1px', backgroundColor: P.outlineVariant }}></div>
                    </div>

                    {/* OPTION 2 — Nom d'utilisateur + mot de passe */}
                    <form onSubmit={handleSubmit}>
                        <div style={{ marginBottom: '16px' }}>
                            <label style={{ display: 'block', fontSize: '11px', fontWeight: 600, color: P.onSurfaceVariant, textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: '8px' }}>Nom d'utilisateur ou email</label>
                            <input type="text" value={username} onChange={e => setUsername(e.target.value)} style={inputStyle} placeholder="manager@glotelho.com" required />
                        </div>
                        <div>
                            <label style={{ display: 'block', fontSize: '11px', fontWeight: 600, color: P.onSurfaceVariant, textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: '8px' }}>Mot de passe</label>
                            <input type="password" value={password} onChange={e => setPassword(e.target.value)} style={inputStyle} placeholder="••••••••" required />
                        </div>

                        <div style={{ textAlign: 'right', marginTop: '10px' }}>
                            <Link to="/forgot-password" style={{ fontSize: '12px', color: P.primary, fontWeight: 600, textDecoration: 'none' }}>Mot de passe oublie ?</Link>
                        </div>

                        <button type="submit" disabled={loading}
                            style={{ width: '100%', marginTop: '20px', backgroundColor: loading ? P.outline : P.primary, color: '#fff', padding: '13px', borderRadius: '10px', border: 'none', fontSize: '14px', fontWeight: 600, cursor: loading ? 'not-allowed' : 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: loading ? 'none' : '0 4px 14px rgba(125,87,0,0.3)' }}>
                            {loading ? 'Connexion...' : 'Se connecter'}
                        </button>
                    </form>

                    <p style={{ textAlign: 'center', marginTop: '24px', fontSize: '13px', color: P.outline }}>
                        Pas encore de compte ? <Link to="/register" style={{ color: P.primary, fontWeight: 600, textDecoration: 'none' }}>Creer un compte manager</Link>
                    </p>
                </div>
            </div>

            <div style={{ flex: 1, backgroundColor: P.inverseS, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '40px' }}>
                <div style={{ textAlign: 'center', maxWidth: '380px' }}>
                    <div style={{ width: '90px', height: '90px', backgroundColor: P.primary, borderRadius: '24px', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 28px' }}>
                        <svg width="42" height="42" fill="none" stroke="white" viewBox="0 0 24 24" strokeWidth="1.6">
                            <path strokeLinecap="round" strokeLinejoin="round" d="M5 17H3a1 1 0 01-1-1v-4a1 1 0 011-1h12l4 3v2h-2M5 17h7"/>
                            <circle cx="7.5" cy="17.5" r="2.5"/><circle cx="17.5" cy="17.5" r="2.5"/>
                            <path strokeLinecap="round" strokeLinejoin="round" d="M5 11l2-4h8l2 4"/>
                        </svg>
                    </div>
                    <h2 style={{ fontSize: '22px', fontWeight: 700, color: P.inverseSOn, margin: '0 0 12px 0' }}>Suivi des livraisons en temps reel</h2>
                    <p style={{ fontSize: '14px', color: 'rgba(241,241,241,0.5)', lineHeight: 1.6, margin: 0 }}>
                        Gerez vos livraisons, livreurs et litiges depuis une plateforme unique a Douala.
                    </p>
                </div>
            </div>
        </div>
    );
}