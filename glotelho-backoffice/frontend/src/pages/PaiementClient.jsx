import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';

const API_URL = import.meta.env.VITE_API_URL || 'http://192.168.1.145:5000/api';

const P = {
    navy   : '#0D1B2A',
    gold   : '#C9952E',
    goldDark: '#7d5700',
    white  : '#FFFFFF',
    gray   : '#F2F4F7',
    dgray  : '#3D3D3D',
    lgray  : '#817564',
    green  : '#1b5e20',
    greenBg: '#f0fdf4',
    red    : '#ba1a1a',
    redBg  : '#ffdad6',
};

export default function PaiementClient() {
    const { id } = useParams();
    const navigate = useNavigate();

    const [livraison, setLivraison]   = useState(null);
    const [loading, setLoading]       = useState(true);
    const [error, setError]           = useState('');
    const [telephone, setTelephone]   = useState('');
    const [step, setStep]             = useState('facture'); // facture | paiement | verification | succes | echec
    const [reference, setReference]   = useState('');
    const [payLoading, setPayLoading] = useState(false);
    const [payError, setPayError]     = useState('');
    const [countdown, setCountdown]   = useState(30);

    // Charger la livraison
    useEffect(() => {
        fetch(API_URL + '/paiement/' + id)
            .then(r => r.json())
            .then(data => {
                if (data.message && !data.id) { setError(data.message); return; }
                setLivraison(data);
                if (data.already_paid) {
                    // Déjà payé — rediriger directement vers le tracking, sans repasser par la facture
                    navigate('/suivi/' + id, { replace: true });
                }
            })
            .catch(() => setError('Impossible de charger la commande.'))
            .finally(() => setLoading(false));
    }, [id]);

    // Countdown de vérification
    useEffect(() => {
        if (step !== 'verification') return;
        if (countdown <= 0) { verifierPaiement(); return; }
        const timer = setTimeout(() => setCountdown(c => c - 1), 1000);
        return () => clearTimeout(timer);
    }, [step, countdown]);

    async function initierPaiement() {
        if (!telephone.trim()) { setPayError('Entrez votre numéro de téléphone.'); return; }
        setPayLoading(true);
        setPayError('');
        try {
            const res = await fetch(API_URL + '/paiement/' + id + '/initier', {
                method : 'POST',
                headers: { 'Content-Type': 'application/json' },
                body   : JSON.stringify({ telephone: telephone.trim() }),
            });
            const data = await res.json();
            if (!res.ok) { setPayError(data.message || 'Erreur lors du paiement.'); return; }
            setReference(data.reference);
            setStep('verification');
            setCountdown(30);
        } catch {
            setPayError('Erreur réseau. Vérifiez votre connexion.');
        } finally {
            setPayLoading(false);
        }
    }

    async function verifierPaiement() {
        try {
            const res = await fetch(API_URL + '/paiement/' + id + '/verifier?reference=' + reference);
            const data = await res.json();
            if (data.status === 'SUCCESSFUL') { setStep('succes'); return; }
            if (data.status === 'FAILED')     { setStep('echec');  return; }
            // Toujours PENDING — relancer dans 5s
            setTimeout(() => verifierPaiement(), 5000);
        } catch {
            setTimeout(() => verifierPaiement(), 5000);
        }
    }

    const montant  = livraison ? Number(livraison.amount_to_collect || 0) : 0;
    const articles = livraison?.delivery_items || [];
    const numRef   = id ? String(id).padStart(5, '0') : '00000';

    if (loading) return (
        <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: P.navy, fontFamily: 'Poppins, sans-serif' }}>
            <div style={{ textAlign: 'center' }}>
                <p style={{ fontSize: '40px', margin: '0 0 12px' }}>⏳</p>
                <p style={{ color: 'rgba(255,255,255,0.5)', fontSize: '14px' }}>Chargement...</p>
            </div>
        </div>
    );

    if (error) return (
        <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Poppins, sans-serif', backgroundColor: P.gray }}>
            <div style={{ textAlign: 'center', backgroundColor: P.white, borderRadius: '20px', padding: '40px 32px', maxWidth: '400px', boxShadow: '0 8px 32px rgba(0,0,0,0.1)' }}>
                <p style={{ fontSize: '48px', margin: '0 0 16px' }}>🔍</p>
                <p style={{ fontSize: '18px', fontWeight: 800, color: P.navy, margin: '0 0 10px' }}>Commande introuvable</p>
                <p style={{ fontSize: '13px', color: P.lgray, margin: 0 }}>{error}</p>
            </div>
        </div>
    );

    return (
        <div style={{ minHeight: '100vh', backgroundColor: P.gray, fontFamily: 'Poppins, sans-serif' }}>
            <style>{`* { box-sizing: border-box; } body { margin: 0; }`}</style>

            {/* Header */}
            <div style={{ background: P.navy, padding: '20px 24px', display: 'flex', alignItems: 'center', gap: '12px' }}>
                <div style={{ width: '36px', height: '36px', backgroundColor: P.gold, borderRadius: '9px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '18px' }}>📦</div>
                <div>
                    <p style={{ margin: 0, fontSize: '16px', fontWeight: 800, color: P.white }}>Glotelho</p>
                    <p style={{ margin: 0, fontSize: '10px', color: 'rgba(255,255,255,0.4)', textTransform: 'uppercase', letterSpacing: '0.1em' }}>Paiement sécurisé</p>
                </div>
            </div>

            <div style={{ maxWidth: '520px', margin: '0 auto', padding: '24px 16px' }}>

                {/* ── ÉTAPE 1 : FACTURE ── */}
                {step === 'facture' && (
                    <>
                        <div style={{ backgroundColor: P.white, borderRadius: '16px', padding: '20px', marginBottom: '16px', boxShadow: '0 2px 12px rgba(0,0,0,0.06)' }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                                <div>
                                    <p style={{ margin: 0, fontSize: '10px', fontWeight: 700, color: P.lgray, textTransform: 'uppercase', letterSpacing: '0.1em' }}>Commande</p>
                                    <p style={{ margin: 0, fontSize: '22px', fontWeight: 900, color: P.gold, letterSpacing: '0.05em', fontFamily: 'monospace' }}>#{numRef}</p>
                                </div>
                                <div style={{ textAlign: 'right' }}>
                                    <p style={{ margin: 0, fontSize: '10px', color: P.lgray }}>Client</p>
                                    <p style={{ margin: 0, fontSize: '14px', fontWeight: 700, color: P.navy }}>{livraison?.client_nom || '—'}</p>
                                </div>
                            </div>

                            <div style={{ borderTop: '1px solid #f3f3f3', paddingTop: '14px', marginBottom: '14px' }}>
                                <p style={{ margin: '0 0 10px', fontSize: '11px', fontWeight: 700, color: P.lgray, textTransform: 'uppercase' }}>Articles commandés</p>
                                {articles.length > 0 ? articles.map((a, i) => (
                                    <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 0', borderBottom: i < articles.length - 1 ? '1px solid #f9f9f9' : 'none' }}>
                                        <div>
                                            <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.navy }}>{a.product_name}</p>
                                            <p style={{ margin: 0, fontSize: '11px', color: P.lgray }}>Quantité : {a.quantity || 1}</p>
                                        </div>
                                        <p style={{ margin: 0, fontSize: '13px', fontWeight: 700, color: P.goldDark }}>
                                            {a.price ? (Number(a.price) * (a.quantity || 1)).toLocaleString('fr-FR') + ' F' : '—'}
                                        </p>
                                    </div>
                                )) : (
                                    <p style={{ fontSize: '13px', color: P.lgray, margin: 0 }}>Aucun article détaillé.</p>
                                )}
                            </div>

                            {/* Adresse */}
                            <div style={{ backgroundColor: P.gray, borderRadius: '10px', padding: '12px', marginBottom: '14px' }}>
                                <p style={{ margin: '0 0 4px', fontSize: '10px', fontWeight: 700, color: P.lgray, textTransform: 'uppercase' }}>Adresse de livraison</p>
                                <p style={{ margin: 0, fontSize: '13px', color: P.navy, fontWeight: 600 }}>{livraison?.delivery_address || '—'}</p>
                                {livraison?.zone_bloc && <p style={{ margin: '2px 0 0', fontSize: '11px', color: P.lgray }}>{livraison.zone_bloc}</p>}
                            </div>

                            {/* Frais de livraison — montant exact, informatif */}
                            {livraison?.frais_livraison > 0 && (
                                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', backgroundColor: '#fff8e1', border: '1px solid #ffe082', borderRadius: '10px', padding: '10px 14px', marginBottom: '14px' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                        <span style={{ fontSize: '16px' }}>🛵</span>
                                        <div>
                                            <p style={{ margin: 0, fontSize: '12px', color: '#7d5700', fontWeight: 700 }}>Frais de livraison</p>
                                            <p style={{ margin: 0, fontSize: '10px', color: '#a17d00' }}>À remettre en cash au livreur à la réception</p>
                                        </div>
                                    </div>
                                    <p style={{ margin: 0, fontSize: '16px', fontWeight: 900, color: '#7d5700' }}>
                                        {Number(livraison.frais_livraison).toLocaleString('fr-FR')} F
                                    </p>
                                </div>
                            )}

                            {/* Total */}
                            <div style={{ background: P.navy, borderRadius: '12px', padding: '16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                <div>
                                    <p style={{ margin: 0, fontSize: '10px', color: 'rgba(255,255,255,0.5)', textTransform: 'uppercase' }}>Montant à payer maintenant</p>
                                    <p style={{ margin: '2px 0 0', fontSize: '11px', color: 'rgba(255,255,255,0.4)' }}>Marchandise uniquement — via Mobile Money</p>
                                </div>
                                <p style={{ margin: 0, fontSize: '26px', fontWeight: 900, color: P.gold }}>{montant.toLocaleString('fr-FR')} <span style={{ fontSize: '14px' }}>FCFA</span></p>
                            </div>
                        </div>

                        <button onClick={() => setStep('paiement')}
                            style={{ width: '100%', padding: '18px', borderRadius: '14px', border: 'none', background: `linear-gradient(135deg, ${P.goldDark}, ${P.gold})`, color: P.white, fontSize: '16px', fontWeight: 700, cursor: 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: '0 6px 20px rgba(125,87,0,0.35)' }}>
                            Valider ma commande →
                        </button>
                    </>
                )}

                {/* ── ÉTAPE 2 : PAIEMENT ── */}
                {step === 'paiement' && (
                    <div style={{ backgroundColor: P.white, borderRadius: '16px', padding: '24px', boxShadow: '0 2px 12px rgba(0,0,0,0.06)' }}>
                        <p style={{ margin: '0 0 6px', fontSize: '20px', fontWeight: 800, color: P.navy, textAlign: 'center' }}>💳 Paiement Mobile Money</p>
                        <p style={{ margin: '0 0 24px', fontSize: '13px', color: P.lgray, textAlign: 'center' }}>MTN MoMo ou Orange Money</p>

                        <div style={{ background: P.navy, borderRadius: '12px', padding: '16px', marginBottom: '24px', textAlign: 'center' }}>
                            <p style={{ margin: 0, fontSize: '11px', color: 'rgba(255,255,255,0.5)' }}>Montant</p>
                            <p style={{ margin: '4px 0 0', fontSize: '32px', fontWeight: 900, color: P.gold }}>{montant.toLocaleString('fr-FR')} <span style={{ fontSize: '16px' }}>FCFA</span></p>
                        </div>

                        <p style={{ margin: '0 0 8px', fontSize: '12px', fontWeight: 700, color: P.lgray, textTransform: 'uppercase' }}>Votre numéro Mobile Money</p>
                        <input
                            type="tel"
                            value={telephone}
                            onChange={e => setTelephone(e.target.value)}
                            placeholder="Ex: 677 777 777"
                            style={{ width: '100%', padding: '16px', borderRadius: '12px', border: '2px solid #d3c4b0', fontSize: '18px', fontFamily: 'Poppins, sans-serif', color: P.navy, outline: 'none', textAlign: 'center', letterSpacing: '0.1em', fontWeight: 600, marginBottom: '8px' }}
                            onFocus={e => e.target.style.borderColor = P.gold}
                            onBlur={e => e.target.style.borderColor = '#d3c4b0'}
                        />
                        <p style={{ margin: '0 0 20px', fontSize: '11px', color: P.lgray, textAlign: 'center' }}>Une notification apparaîtra sur votre téléphone pour confirmer</p>

                        {payError && <p style={{ margin: '0 0 14px', fontSize: '13px', color: P.red, textAlign: 'center', backgroundColor: P.redBg, padding: '10px', borderRadius: '8px' }}>{payError}</p>}

                        <button onClick={initierPaiement} disabled={payLoading}
                            style={{ width: '100%', padding: '18px', borderRadius: '14px', border: 'none', background: payLoading ? '#ccc' : `linear-gradient(135deg, ${P.goldDark}, ${P.gold})`, color: P.white, fontSize: '16px', fontWeight: 700, cursor: payLoading ? 'not-allowed' : 'pointer', fontFamily: 'Poppins, sans-serif', marginBottom: '12px' }}>
                            {payLoading ? '⏳ Traitement...' : '📱 Effectuer le paiement'}
                        </button>

                        <button onClick={() => setStep('facture')}
                            style={{ width: '100%', padding: '12px', borderRadius: '14px', border: '1px solid #d3c4b0', background: 'transparent', color: P.lgray, fontSize: '14px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                            ← Retour
                        </button>
                    </div>
                )}

                {/* ── ÉTAPE 3 : VÉRIFICATION ── */}
                {step === 'verification' && (
                    <div style={{ backgroundColor: P.white, borderRadius: '16px', padding: '40px 24px', boxShadow: '0 2px 12px rgba(0,0,0,0.06)', textAlign: 'center' }}>
                        <p style={{ fontSize: '52px', margin: '0 0 16px' }}>📱</p>
                        <p style={{ fontSize: '20px', fontWeight: 800, color: P.navy, margin: '0 0 10px' }}>Confirmez sur votre téléphone</p>
                        <p style={{ fontSize: '13px', color: P.lgray, margin: '0 0 24px', lineHeight: 1.6 }}>
                            Une notification a été envoyée sur votre téléphone.<br/>
                            Entrez votre PIN Mobile Money pour confirmer.
                        </p>
                        <div style={{ width: '70px', height: '70px', borderRadius: '50%', border: `4px solid ${P.gold}`, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 16px', fontSize: '24px', fontWeight: 900, color: P.gold }}>
                            {countdown}
                        </div>
                        <p style={{ fontSize: '12px', color: P.lgray }}>Vérification automatique dans {countdown}s...</p>

                        <button onClick={verifierPaiement}
                            style={{ marginTop: '20px', padding: '14px 28px', borderRadius: '12px', border: 'none', backgroundColor: P.navy, color: P.white, fontSize: '14px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                            Vérifier maintenant
                        </button>
                    </div>
                )}

                {/* ── ÉTAPE 4 : SUCCÈS ── */}
                {step === 'succes' && (
                    <div style={{ backgroundColor: P.white, borderRadius: '16px', padding: '40px 24px', boxShadow: '0 2px 12px rgba(0,0,0,0.06)', textAlign: 'center' }}>
                        <p style={{ fontSize: '64px', margin: '0 0 16px' }}>✅</p>
                        <p style={{ fontSize: '22px', fontWeight: 900, color: P.green, margin: '0 0 10px' }}>Paiement confirmé !</p>
                        <p style={{ fontSize: '13px', color: P.lgray, margin: '0 0 8px', lineHeight: 1.6 }}>
                            Votre paiement de <strong>{montant.toLocaleString('fr-FR')} FCFA</strong> a bien été effectué.
                        </p>
                        <p style={{ fontSize: '13px', color: P.lgray, margin: '0 0 28px' }}>
                            Un livreur va être assigné à votre commande.
                        </p>
                        <button onClick={() => navigate('/suivi/' + id)}
                            style={{ width: '100%', padding: '18px', borderRadius: '14px', border: 'none', background: `linear-gradient(135deg, ${P.goldDark}, ${P.gold})`, color: P.white, fontSize: '16px', fontWeight: 700, cursor: 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: '0 6px 20px rgba(125,87,0,0.35)' }}>
                            📍 Suivre ma livraison
                        </button>
                    </div>
                )}

                {/* ── ÉTAPE 5 : ÉCHEC ── */}
                {step === 'echec' && (
                    <div style={{ backgroundColor: P.white, borderRadius: '16px', padding: '40px 24px', boxShadow: '0 2px 12px rgba(0,0,0,0.06)', textAlign: 'center' }}>
                        <p style={{ fontSize: '64px', margin: '0 0 16px' }}>❌</p>
                        <p style={{ fontSize: '22px', fontWeight: 900, color: P.red, margin: '0 0 10px' }}>Paiement échoué</p>
                        <p style={{ fontSize: '13px', color: P.lgray, margin: '0 0 28px', lineHeight: 1.6 }}>
                            Le paiement n'a pas pu être effectué.<br/>Vérifiez votre solde et réessayez.
                        </p>
                        <button onClick={() => { setStep('paiement'); setPayError(''); }}
                            style={{ width: '100%', padding: '18px', borderRadius: '14px', border: 'none', background: `linear-gradient(135deg, ${P.goldDark}, ${P.gold})`, color: P.white, fontSize: '16px', fontWeight: 700, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                            Réessayer
                        </button>
                    </div>
                )}
            </div>
        </div>
    );
}