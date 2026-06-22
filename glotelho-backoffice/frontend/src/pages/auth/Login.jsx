import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

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
            setError(err.response?.data?.message || 'Erreur de connexion.');
        } finally {
            setLoading(false);
        }
    }

    return (
        <div className="min-h-screen flex items-center justify-center relative overflow-hidden bg-[#14141F]">

            <div className="absolute top-[-10%] left-[-10%] w-[500px] h-[500px] bg-[#E8580A] opacity-20 rounded-full blur-[120px]"></div>
            <div className="absolute bottom-[-10%] right-[-10%] w-[400px] h-[400px] bg-[#FFB088] opacity-10 rounded-full blur-[120px]"></div>

            <div className="relative z-10 w-full max-w-md mx-4">

                <div className="text-center mb-8">
                    <div className="inline-flex items-center justify-center w-20 h-20 rounded-2xl bg-white mb-4 shadow-lg shadow-orange-500/20 p-3">
                        <img src="/logo_glotelho.png" alt="Glotelho" className="w-full h-full object-contain" />
                    </div>
                    <h1 className="font-display font-extrabold text-3xl text-white tracking-tight">Glotelho</h1>
                    <p className="text-[#8A8AA3] text-sm mt-1 font-medium">Back-office Manager</p>
                </div>

                <div className="bg-white/[0.04] backdrop-blur-xl border border-white/10 rounded-3xl shadow-2xl p-8">

                    {error && (
                        <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-sm rounded-xl px-4 py-3 mb-5">
                            {error}
                        </div>
                    )}

                    <form onSubmit={handleSubmit} className="space-y-5">

                        <div>
                            <label className="block text-xs font-semibold text-[#8A8AA3] uppercase tracking-wider mb-2">
                                Email
                            </label>
                            <input
                                type="email"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                className="w-full bg-white border border-white/10 rounded-xl px-4 py-3 text-[#1A1A2E] placeholder-[#8A8AA3] focus:outline-none focus:ring-2 focus:ring-[#E8580A] focus:border-transparent transition-all"
                                placeholder="manager@glotelho.com"
                                required
                                autoFocus
                            />
                        </div>

                        <div>
                            <label className="block text-xs font-semibold text-[#8A8AA3] uppercase tracking-wider mb-2">
                                Mot de passe
                            </label>
                            <div className="relative">
                                <input
                                    type={showPassword ? 'text' : 'password'}
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    className="w-full bg-white border border-white/10 rounded-xl px-4 py-3 pr-12 text-[#1A1A2E] placeholder-[#8A8AA3] focus:outline-none focus:ring-2 focus:ring-[#E8580A] focus:border-transparent transition-all"
                                    placeholder="********"
                                    required
                                />
                                <button
                                    type="button"
                                    onClick={() => setShowPassword(!showPassword)}
                                    className="absolute right-3 top-1/2 -translate-y-1/2 text-[#8A8AA3] hover:text-[#1A1A2E] transition-colors"
                                >
                                    {showPassword ? (
                                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.542-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.542 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                                        </svg>
                                    ) : (
                                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                        </svg>
                                    )}
                                </button>
                            </div>
                        </div>

                        <button
                            type="submit"
                            disabled={loading}
                            className="w-full bg-gradient-to-r from-[#E8580A] to-[#FF7A33] text-white font-semibold py-3.5 rounded-xl hover:shadow-lg hover:shadow-orange-500/30 hover:scale-[1.01] active:scale-[0.99] transition-all duration-200 disabled:opacity-60"
                        >
                            {loading ? 'Connexion...' : 'Se connecter'}
                        </button>

                    </form>
                </div>

                <p className="text-center text-[#8A8AA3]/60 text-xs mt-6">Glotelho - 2026 - Plateforme de livraison</p>

            </div>
        </div>
    );
}