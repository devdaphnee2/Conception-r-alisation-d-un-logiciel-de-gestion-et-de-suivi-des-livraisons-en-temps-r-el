import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { IconEye, IconEyeOff } from '../../components/Icons';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    surface: '#ffffff', surfaceContainerLow: '#f3f3f3',
    inverseS: '#2f3131', inverseSOn: '#f1f1f1',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
    error: '#ba1a1a', errorContainer: '#ffdad6',
};

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

    return (
        <div style={{ minHeight: '100vh', display: 'flex', fontFamily: 'Poppins, sans-serif', backgroundColor: P.surface }}>

            {/* LEFT — formulaire uniquement */}
            <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '48px' }}>
                <div style={{ width: '100%', maxWidth: '400px' }}>

                    {/* Logo + titre */}
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '40px' }}>
                        <div style={{ width: '42px', height: '42px', backgroundColor: P.inverseS, borderRadius: '10px', padding: '6px', flexShrink: 0 }}>
                            <img src="/logo_glotelho.png" alt="Glotelho" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                        </div>
                        <div>
                            <p style={{ margin: 0, fontSize: '18px', fontWeight: 700, color: P.onSurface }}>Glotelho</p>
                            <p style={{ margin: 0, fontSize: '11px', color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Back-office</p>
                        </div>
                    </div>

                    <div style={{ marginBottom: '32px' }}>
                        <h1 style={{ margin: '0 0 6px 0', fontSize: '26px', fontWeight: 700, color: P.onSurface, letterSpacing: '-0.02em' }}>
                            Connexion
                        </h1>
                        <p style={{ margin: 0, fontSize: '13px', color: P.outline }}>
                            Acces reserve aux managers Glotelho
                        </p>
                    </div>

                    {error && (
                        <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', color: P.error, padding: '11px 14px', borderRadius: '10px', marginBottom: '20px', fontSize: '13px', fontWeight: 500 }}>
                            {error}
                        </div>
                    )}

                    <form onSubmit={handleSubmit}>
                        <div style={{ display: 'grid', gap: '16px' }}>

                            <div>
                                <label style={{ display: 'block', fontSize: '11px', fontWeight: 600, color: P.onSurfaceVariant, marginBottom: '7px', textTransform: 'uppercase', letterSpacing: '0.07em' }}>
                                    Email
                                </label>
                                <input
                                    type="email"
                                    value={email}
                                    onChange={e => setEmail(e.target.value)}
                                    placeholder="manager@glotelho.com"
                                    required
                                    autoFocus
                                    style={{ width: '100%', padding: '12px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, fontSize: '13px', color: P.onSurface, backgroundColor: P.surface, fontFamily: 'Poppins, sans-serif', boxSizing: 'border-box', transition: 'all 0.15s' }}
                                />
                            </div>

                            <div>
                                <label style={{ display: 'block', fontSize: '11px', fontWeight: 600, color: P.onSurfaceVariant, marginBottom: '7px', textTransform: 'uppercase', letterSpacing: '0.07em' }}>
                                    Mot de passe
                                </label>
                                <div style={{ position: 'relative' }}>
                                    <input
                                        type={showPassword ? 'text' : 'password'}
                                        value={password}
                                        onChange={e => setPassword(e.target.value)}
                                        placeholder="••••••••"
                                        required
                                        style={{ width: '100%', padding: '12px 42px 12px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, fontSize: '13px', color: P.onSurface, backgroundColor: P.surface, fontFamily: 'Poppins, sans-serif', boxSizing: 'border-box', transition: 'all 0.15s' }}
                                    />
                                    <button
                                        type="button"
                                        onClick={() => setShowPassword(!showPassword)}
                                        style={{ position: 'absolute', right: '11px', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: P.outline, display: 'flex', padding: '4px' }}
                                    >
                                        {showPassword ? <IconEyeOff style={{ width: '17px', height: '17px' }} /> : <IconEye style={{ width: '17px', height: '17px' }} />}
                                    </button>
                                </div>
                            </div>

                            <button
                                type="submit"
                                disabled={loading}
                                style={{ width: '100%', padding: '12px 24px', backgroundColor: loading ? P.outline : P.primary, color: '#fff', border: 'none', borderRadius: '10px', fontSize: '14px', fontWeight: 600, cursor: loading ? 'not-allowed' : 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: loading ? 'none' : '0 4px 14px rgba(125,87,0,0.3)', transition: 'all 0.2s', marginTop: '4px' }}
                                onMouseEnter={e => { if (!loading) e.currentTarget.style.backgroundColor = '#6b4900'; }}
                                onMouseLeave={e => { if (!loading) e.currentTarget.style.backgroundColor = P.primary; }}
                            >
                                {loading ? 'Connexion...' : 'Se connecter'}
                            </button>

                        </div>
                    </form>

                </div>
            </div>

            {/* RIGHT — illustration sobre */}
            <div style={{ width: '45%', backgroundColor: P.inverseS, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', padding: '48px', position: 'relative', overflow: 'hidden' }}>

                <div style={{ position: 'absolute', top: '-80px', right: '-80px', width: '320px', height: '320px', borderRadius: '50%', backgroundColor: 'rgba(201,149,46,0.08)' }}></div>
                <div style={{ position: 'absolute', bottom: '-60px', left: '-60px', width: '240px', height: '240px', borderRadius: '50%', backgroundColor: 'rgba(201,149,46,0.05)' }}></div>

                <div style={{ position: 'relative', zIndex: 1, textAlign: 'center', maxWidth: '340px' }}>
                    <div style={{ width: '72px', height: '72px', backgroundColor: 'rgba(255,255,255,0.06)', borderRadius: '20px', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 28px' }}>
                        <img src="/logo_glotelho.png" alt="Glotelho" style={{ width: '48px', height: '48px', objectFit: 'contain' }} />
                    </div>
                    <h2 style={{ margin: '0 0 14px 0', fontSize: '26px', fontWeight: 800, color: P.inverseSOn, letterSpacing: '-0.02em', lineHeight: 1.2 }}>
                        Gestion des livraisons<br/>
                        <span style={{ color: P.primaryContainer }}>en temps reel</span>
                    </h2>
                    <p style={{ margin: 0, fontSize: '14px', color: 'rgba(241,241,241,0.45)', lineHeight: 1.7 }}>
                        Supervisez vos livreurs, suivez chaque colis et gerez les incidents depuis un seul tableau de bord operationnel.
                    </p>
                </div>

            </div>

        </div>
    );
}
