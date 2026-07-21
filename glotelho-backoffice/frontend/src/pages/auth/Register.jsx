import { useState, useEffect, useRef } from 'react';
import { Link, useNavigate } from 'react-router-dom';
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

export default function Register() {
    const [form, setForm] = useState({ first_name: '', last_name: '', email: '', phone: '', password: '', confirm_password: '' });
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const [welcomeNew, setWelcomeNew] = useState(false);
    const navigate = useNavigate();
    const googleBtnRef = useRef(null);

    function handleChange(e) { setForm({ ...form, [e.target.name]: e.target.value }); }

    // OPTION 2 — Formulaire d'inscription simple
    async function handleSubmit(e) {
        e.preventDefault();
        setError('');

        if (form.password !== form.confirm_password) {
            setError('Les mots de passe ne correspondent pas.');
            return;
        }
        if (form.password.length < 8) {
            setError('Le mot de passe doit contenir au moins 8 caracteres.');
            return;
        }

        setLoading(true);
        try {
            console.log(" Données envoyées au backend :", form);
            const res = await api.post('http://localhost:5000/api/auth/register', form);
            console.log(" Réponse du backend :", res.data);

            localStorage.setItem('token', res.data.token);
            localStorage.setItem('user', JSON.stringify(res.data.user));
            setWelcomeNew(true);
            setTimeout(() => { window.location.href = '/dashboard'; }, 1500);
        } catch (err) {
            // 🔍 Impression détaillée de l'erreur dans la console du navigateur (F12)
            console.error("❌ Exception capturée lors de l'inscription :", err);
            if (err.response) {
                console.error(" Statut HTTP :", err.response.status);
                console.error(" Données de réponse backend :", err.response.data);
            } else if (err.request) {
                console.error(" Pas de réponse du serveur (problème réseau ou CORS) :", err.request);
            } else {
                console.error(" Erreur de configuration de la requête :", err.message);
            }

            setError(err.response?.data?.message || `Erreur: ${err.message || 'Erreur lors de la creation du compte.'}`);
        } finally { setLoading(false); }
    }

    // OPTION 1 — Inscription via Google (creation automatique)
    async function handleGoogleCredential(response) {
        setError('');
        setLoading(true);
        try {
            console.log(" Credential Google reçu :", response.credential);
            const res = await api.post('/auth/google-register', { credential: response.credential });
            console.log(" Réponse du backend (Google) :", res.data);

            localStorage.setItem('token', res.data.token);
            localStorage.setItem('user', JSON.stringify(res.data.user));
            setWelcomeNew(true);
            setTimeout(() => { window.location.href = '/dashboard'; }, 1500);
        } catch (err) {
            // 🔍 Impression détaillée de l'erreur
            console.error("❌ Exception lors de l'inscription Google :", err);
            if (err.response) {
                console.error(" Statut HTTP :", err.response.status);
                console.error(" Données de réponse :", err.response.data);
            }

            setError(err.response?.data?.message || 'Inscription Google impossible.');
        } finally { setLoading(false); }
    }

    // ── Chargement du script Google Identity Services ────────
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
                    width: '380',
                    text: 'signup_with',
                    shape: 'rectangular',
                    logo_alignment: 'left',
                });
            }
        }

        const existingScript = document.getElementById('google-identity-script');
        if (existingScript) {
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

    const inputStyle = { width: '100%', padding: '11px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, fontSize: '13px', color: P.onSurface, outline: 'none', boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif' };
    const labelStyle = { display: 'block', fontSize: '11px', fontWeight: 600, color: P.onSurfaceVariant, textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: '7px' };

    if (welcomeNew) {
        return (
            <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#f9f9f9', fontFamily: 'Poppins, sans-serif', padding: '20px' }}>
                <div style={{ textAlign: 'center', maxWidth: '380px' }}>
                    <div style={{ width: '64px', height: '64px', borderRadius: '50%', backgroundColor: '#c8e6c9', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 20px' }}>
                        <svg width="28" height="28" fill="none" stroke="#1b5e20" viewBox="0 0 24 24" strokeWidth="2.5"><path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7"/></svg>
                    </div>
                    <h1 style={{ fontSize: '19px', fontWeight: 800, color: P.onSurface, margin: '0 0 8px 0' }}>Bienvenue chez Glotelho !</h1>
                    <p style={{ fontSize: '13px', color: P.outline, margin: 0 }}>Votre compte manager a ete cree. Redirection en cours...</p>
                </div>
            </div>
        );
    }

    return (
        <div style={{ minHeight: '100vh', display: 'flex', fontFamily: 'Poppins, sans-serif' }}>

            <div style={{ flex: 1, backgroundColor: P.inverseS, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '40px' }}>
                <div style={{ textAlign: 'center', maxWidth: '380px' }}>
                    <div style={{ width: '90px', height: '90px', backgroundColor: P.primary, borderRadius: '24px', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 28px' }}>
                        <svg width="42" height="42" fill="none" stroke="white" viewBox="0 0 24 24" strokeWidth="1.6">
                            <path strokeLinecap="round" strokeLinejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
                        </svg>
                    </div>
                    <h2 style={{ fontSize: '22px', fontWeight: 700, color: P.inverseSOn, margin: '0 0 12px 0' }}>Rejoignez l'equipe Glotelho</h2>
                    <p style={{ fontSize: '14px', color: 'rgba(241,241,241,0.5)', lineHeight: 1.6, margin: 0 }}>
                        Creez votre compte manager pour gerer les livraisons, livreurs et litiges.
                    </p>
                </div>
            </div>

            <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#f9f9f9', padding: '20px', overflowY: 'auto' }}>
                <div style={{ width: '100%', maxWidth: '380px', padding: '20px 0' }}>

                    <div style={{ width: '52px', height: '52px', backgroundColor: P.surfaceContainerLow, borderRadius: '14px', padding: '8px', marginBottom: '24px' }}>
                        <img src="/logo_glotelho.png" alt="Glotelho" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                    </div>

                    <h1 style={{ fontSize: '22px', fontWeight: 800, color: P.onSurface, margin: '0 0 6px 0' }}>Creer un compte manager</h1>
                    <p style={{ fontSize: '13px', color: P.outline, margin: '0 0 24px 0' }}>Inscrivez-vous avec Google ou via le formulaire.</p>

                    {error && <div style={{ backgroundColor: P.errorContainer, color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '16px', fontSize: '13px', fontWeight: 500 }}>{error}</div>}

                    {/* OPTION 1 — Inscription avec Google */}
                    <div ref={googleBtnRef} style={{ marginBottom: '20px', minHeight: '44px' }}></div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px', margin: '0 0 20px 0' }}>
                        <div style={{ flex: 1, height: '1px', backgroundColor: P.outlineVariant }}></div>
                        <span style={{ fontSize: '11px', color: P.outline, fontWeight: 500 }}>ou remplissez le formulaire</span>
                        <div style={{ flex: 1, height: '1px', backgroundColor: P.outlineVariant }}></div>
                    </div>

                    {/* OPTION 2 — Formulaire simple */}
                    <form onSubmit={handleSubmit}>
                        <div style={{ display: 'grid', gap: '14px' }}>
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
                                <div>
                                    <label style={labelStyle}>Prenom</label>
                                    <input type="text" name="first_name" value={form.first_name} onChange={handleChange} style={inputStyle} required />
                                </div>
                                <div>
                                    <label style={labelStyle}>Nom</label>
                                    <input type="text" name="last_name" value={form.last_name} onChange={handleChange} style={inputStyle} required />
                                </div>
                            </div>
                            <div>
                                <label style={labelStyle}>Email</label>
                                <input type="email" name="email" value={form.email} onChange={handleChange} style={inputStyle} placeholder="manager@glotelho.com" required />
                            </div>
                            <div>
                                <label style={labelStyle}>Numero de telephone</label>
                                <input type="text" name="phone" value={form.phone} onChange={handleChange} style={inputStyle} placeholder="655112233" required />
                            </div>
                            <div>
                                <label style={labelStyle}>Mot de passe</label>
                                <input type="password" name="password" value={form.password} onChange={handleChange} style={inputStyle} required minLength={8} />
                            </div>
                            <div>
                                <label style={labelStyle}>Confirmer le mot de passe</label>
                                <input type="password" name="confirm_password" value={form.confirm_password} onChange={handleChange} style={inputStyle} required minLength={8} />
                            </div>
                            <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>Minimum 8 caracteres.</p>

                            <button type="submit" disabled={loading}
                                style={{ width: '100%', backgroundColor: loading ? P.outline : P.primary, color: '#fff', padding: '13px', borderRadius: '10px', border: 'none', fontSize: '14px', fontWeight: 600, cursor: loading ? 'not-allowed' : 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: loading ? 'none' : '0 4px 14px rgba(125,87,0,0.3)' }}>
                                {loading ? 'Creation...' : 'Creer mon compte'}
                            </button>
                        </div>
                    </form>

                    <p style={{ textAlign: 'center', marginTop: '20px', fontSize: '13px', color: P.outline }}>
                        Deja un compte ? <Link to="/login" style={{ color: P.primary, fontWeight: 600, textDecoration: 'none' }}>Se connecter</Link>
                    </p>
                </div>
            </div>
        </div>
    );
}