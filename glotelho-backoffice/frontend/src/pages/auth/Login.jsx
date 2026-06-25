import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { IconEye, IconEyeOff } from '../../components/Icons';

export default function Login() {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const { login } = useAuth();
    const navigate = useNavigate();

    async function handleSubmit(e) {
        e.preventDefault();
        setError('');
        setLoading(true);
        try {
            await login(email, password);
            navigate('/dashboard');
        } catch (err) {
            setError(err.response?.data?.message || 'Identifiants incorrects.');
        } finally {
            setLoading(false);
        }
    }

    const P = {
        primary: '#7d5700',
        primaryContainer: '#c9952e',
        primaryFixed: '#ffdea9',
        primaryFixedDim: '#f6bd53',
        secondary: '#475e8b',
        tertiary: '#20619e',
        background: '#f9f9f9',
        surface: '#ffffff',
        surfaceContainerLow: '#f3f3f3',
        surfaceContainer: '#eeeeee',
        inverseS: '#2f3131',
        inverseSOn: '#f1f1f1',
        onSurface: '#1a1c1c',
        onSurfaceVariant: '#4f4536',
        outline: '#817564',
        outlineVariant: '#d3c4b0',
        error: '#ba1a1a',
        errorContainer: '#ffdad6',
    };

    return (
        <div style={{ minHeight: '100vh', display: 'flex', fontFamily: 'Poppins, sans-serif', backgroundColor: P.background }}>

            {/* LEFT PANEL */}
            <div style={{ width: '44%', backgroundColor: P.inverseS, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', padding: '44px', position: 'relative', overflow: 'hidden' }}>

                <div style={{ position: 'absolute', top: '-60px', right: '-60px', width: '280px', height: '280px', borderRadius: '50%', backgroundColor: 'rgba(201,149,46,0.1)' }}></div>
                <div style={{ position: 'absolute', bottom: '80px', left: '-40px', width: '180px', height: '180px', borderRadius: '50%', backgroundColor: 'rgba(201,149,46,0.06)' }}></div>
                <div style={{ position: 'absolute', top: '45%', right: '10%', width: '80px', height: '80px', borderRadius: '50%', border: '1px solid rgba(246,189,83,0.15)' }}></div>

                {/* Logo */}
                <div style={{ position: 'relative', zIndex: 1, display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <div style={{ width: '40px', height: '40px', backgroundColor: P.surface, borderRadius: '10px', padding: '5px', flexShrink: 0 }}>
                        <img src="/logo_glotelho.png" alt="Glotelho" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                    </div>
                    <span style={{ fontSize: '20px', fontWeight: 700, color: P.inverseSOn, letterSpacing: '-0.01em' }}>Glotelho</span>
                </div>

                {/* Hero text */}
                <div style={{ position: 'relative', zIndex: 1 }}>
                    <div style={{ display: 'inline-flex', alignItems: 'center', gap: '7px', backgroundColor: 'rgba(246,189,83,0.12)', border: '1px solid rgba(246,189,83,0.25)', borderRadius: '999px', padding: '5px 13px', marginBottom: '24px' }}>
                        <div style={{ width: '5px', height: '5px', borderRadius: '50%', backgroundColor: P.primaryFixedDim }}></div>
                        <span style={{ fontSize: '11px', fontWeight: 500, color: P.primaryFixedDim }}>Plateforme logistique — Douala, Cameroun</span>
                    </div>
                    <h1 style={{ fontSize: '32px', fontWeight: 800, color: P.inverseSOn, lineHeight: '1.2', letterSpacing: '-0.02em', margin: '0 0 14px 0' }}>
                        Suivi des livraisons<br/>
                        <span style={{ color: P.primaryContainer }}>en temps reel</span>
                    </h1>
                    <p style={{ fontSize: '14px', color: 'rgba(241,241,241,0.5)', lineHeight: '1.7', margin: 0, maxWidth: '340px' }}>
                        Supervisez chaque livraison, coordonnez vos livreurs et gerez les incidents depuis un seul back-office operationnel.
                    </p>

                    <div style={{ display: 'flex', gap: '32px', marginTop: '36px' }}>
                        {[
                            { value: '3', label: 'Modules' },
                            { value: '100%', label: 'Temps reel' },
                            { value: '24/7', label: 'Disponible' },
                        ].map((s, i) => (
                            <div key={i}>
                                <p style={{ margin: 0, fontSize: '22px', fontWeight: 800, color: P.inverseSOn, letterSpacing: '-0.02em' }}>{s.value}</p>
                                <p style={{ margin: '3px 0 0 0', fontSize: '11px', color: 'rgba(241,241,241,0.35)', fontWeight: 500, textTransform: 'uppercase', letterSpacing: '0.06em' }}>{s.label}</p>
                            </div>
                        ))}
                    </div>
                </div>

                <p style={{ position: 'relative', zIndex: 1, margin: 0, fontSize: '11px', color: 'rgba(241,241,241,0.25)' }}>
                    Glotelho Back-office © 2026
                </p>
            </div>

            {/* RIGHT FORM */}
            <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '48px' }}>
                <div style={{ width: '100%', maxWidth: '380px' }}>

                    <div style={{ marginBottom: '32px' }}>
                        <h2 style={{ margin: '0 0 6px 0', fontSize: '24px', fontWeight: 700, color: P.onSurface, letterSpacing: '-0.02em' }}>Connexion</h2>
                        <p style={{ margin: 0, fontSize: '13px', color: P.outline }}>Acces reserve aux managers Glotelho</p>
                    </div>

                    {error && (
                        <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', color: P.error, padding: '11px 14px', borderRadius: '10px', marginBottom: '20px', fontSize: '13px', fontWeight: 500 }}>
                            {error}
                        </div>
                    )}

                    <form onSubmit={handleSubmit}>
                        <div style={{ display: 'grid', gap: '16px' }}>

                            <div>
                                <label style={{ display: 'block', fontSize: '11px', fontWeight: 600, color: P.onSurfaceVariant, marginBottom: '7px', textTransform: 'uppercase', letterSpacing: '0.07em' }}>Email</label>
                                <input type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="manager@glotelho.com" required autoFocus
                                    style={{ width: '100%', padding: '11px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, fontSize: '13px', color: P.onSurface, backgroundColor: P.surface, fontFamily: 'Poppins, sans-serif', transition: 'all 0.15s' }} />
                            </div>

                            <div>
                                <label style={{ display: 'block', fontSize: '11px', fontWeight: 600, color: P.onSurfaceVariant, marginBottom: '7px', textTransform: 'uppercase', letterSpacing: '0.07em' }}>Mot de passe</label>
                                <div style={{ position: 'relative' }}>
                                    <input type={showPassword ? 'text' : 'password'} value={password} onChange={e => setPassword(e.target.value)} placeholder="••••••••" required
                                        style={{ width: '100%', padding: '11px 42px 11px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, fontSize: '13px', color: P.onSurface, backgroundColor: P.surface, fontFamily: 'Poppins, sans-serif', boxSizing: 'border-box', transition: 'all 0.15s' }} />
                                    <button type="button" onClick={() => setShowPassword(!showPassword)}
                                        style={{ position: 'absolute', right: '11px', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: P.outline, display: 'flex', padding: '4px' }}>
                                        {showPassword ? <IconEyeOff style={{ width: '17px', height: '17px' }} /> : <IconEye style={{ width: '17px', height: '17px' }} />}
                                    </button>
                                </div>
                            </div>

                            <button type="submit" disabled={loading}
                                style={{ width: '100%', padding: '12px 24px', backgroundColor: loading ? P.outline : P.primary, color: '#fff', border: 'none', borderRadius: '10px', fontSize: '14px', fontWeight: 600, cursor: loading ? 'not-allowed' : 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: loading ? 'none' : '0 4px 14px rgba(125,87,0,0.3)', transition: 'all 0.2s', marginTop: '4px' }}
                                onMouseEnter={e => { if (!loading) e.currentTarget.style.backgroundColor = '#6b4900'; }}
                                onMouseLeave={e => { if (!loading) e.currentTarget.style.backgroundColor = P.primary; }}
                            >
                                {loading ? 'Connexion...' : 'Se connecter'}
                            </button>

                        </div>
                    </form>

                    <div style={{ marginTop: '28px', padding: '14px 16px', backgroundColor: P.surfaceContainerLow, borderRadius: '10px', border: '1px solid ' + P.outlineVariant }}>
                        <p style={{ margin: '0 0 5px 0', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.07em' }}>Compte demo</p>
                        <p style={{ margin: 0, fontSize: '12px', color: P.onSurface }}>manager@glotelho.com</p>
                        <p style={{ margin: '2px 0 0 0', fontSize: '12px', color: P.onSurface }}>password123</p>
                    </div>
                </div>
            </div>
        </div>
    );
}
