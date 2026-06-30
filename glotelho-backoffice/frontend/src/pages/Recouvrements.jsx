import { useState, useEffect } from 'react';
import api from '../services/api';
import { IconAlert, IconCheck, IconUser, IconSearch } from '../components/Icons';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    primaryFixed: '#ffdea9', onPrimaryContainer: '#483100',
    error: '#ba1a1a', errorContainer: '#ffdad6', onErrorContainer: '#93000a',
    surface: '#ffffff', background: '#f9f9f9',
    surfaceContainerLow: '#f3f3f3', surfaceContainerHigh: '#e8e8e8',
    inverseS: '#2f3131', inverseSOn: '#f1f1f1',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
};

function KpiCard({ icon: Icon, label, value, iconColor, iconBg }) {
    return (
        <div style={{ backgroundColor: P.inverseS, borderRadius: '12px', padding: '16px', display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '9px', backgroundColor: iconBg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Icon style={{ width: '17px', height: '17px', color: iconColor }} />
            </div>
            <div>
                <p style={{ margin: 0, fontSize: '20px', fontWeight: 800, color: P.inverseSOn, lineHeight: 1 }}>{value}</p>
                <p style={{ margin: '4px 0 0 0', fontSize: '11px', color: 'rgba(241,241,241,0.4)', fontWeight: 500 }}>{label}</p>
            </div>
        </div>
    );
}

export default function Recouvrements() {
    const [recouvrements, setRecouvrements] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [search, setSearch] = useState('');
    const [successMsg, setSuccessMsg] = useState('');

    useEffect(() => {
        api.get('/recouvrements')
            .then(res => setRecouvrements(res.data))
            .catch(() => setError('Impossible de charger les recouvrements.'))
            .finally(() => setLoading(false));
    }, []);

    async function handleMarquerPaye(id) {
        const montant = window.prompt('Montant effectivement recouvre (FCFA) :');
        if (!montant) return;
        try {
            await api.post('/recouvrements/' + id + '/payer', { amount_collected: parseFloat(montant) });
            setSuccessMsg('Recouvrement mis a jour.');
            api.get('/recouvrements').then(res => setRecouvrements(res.data));
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur.');
        }
    }

    const filtered = recouvrements.filter(r =>
        !search || [
            r.delivery_persons?.users?.first_name,
            r.delivery_persons?.users?.last_name,
            r.motif,
            '#' + r.id,
        ].some(v => v?.toLowerCase().includes(search.toLowerCase()))
    );

    const totalDu = recouvrements.reduce((s, r) => s + Number(r.amount_to_collect || 0), 0);
    const totalRecouvre = recouvrements.reduce((s, r) => s + Number(r.amount_collected || 0), 0);
    const totalRestant = totalDu - totalRecouvre;
    const enCours = recouvrements.filter(r => Number(r.amount_collected || 0) < Number(r.amount_to_collect || 0)).length;

    const thStyle = { padding: '9px 14px', textAlign: 'left', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em', borderBottom: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, whiteSpace: 'nowrap' };
    const tdStyle = { padding: '12px 14px', fontSize: '13px', color: P.onSurface, borderBottom: '1px solid ' + P.surfaceContainerLow };

    const motifLabels = { perte_colis: 'Perte colis', colis_casse: 'Colis casse' };

    return (
        <div style={{ fontFamily: 'Poppins, sans-serif' }}>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '10px', marginBottom: '18px' }}>
                <KpiCard icon={IconAlert} label="Total dettes" value={recouvrements.length} iconColor={P.primaryContainer} iconBg="rgba(201,149,46,0.15)" />
                <KpiCard icon={IconUser} label="En cours" value={enCours} iconColor="#ef9a9a" iconBg="rgba(239,154,154,0.15)" />
                <KpiCard icon={IconAlert} label="Montant total du" value={totalDu.toLocaleString('fr-FR') + ' F'} iconColor="#ef9a9a" iconBg="rgba(239,154,154,0.15)" />
                <KpiCard icon={IconCheck} label="Deja recouvre" value={totalRecouvre.toLocaleString('fr-FR') + ' F'} iconColor="#81c784" iconBg="rgba(129,199,132,0.15)" />
            </div>

            {/* Alerte montant restant */}
            {totalRestant > 0 && (
                <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', borderRadius: '10px', padding: '11px 16px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <IconAlert style={{ width: '15px', height: '15px', color: P.error, flexShrink: 0 }} />
                    <p style={{ margin: 0, fontSize: '13px', color: P.onErrorContainer, fontWeight: 500 }}>
                        <strong>{totalRestant.toLocaleString('fr-FR')} FCFA</strong> restent a recouvrer aupres des livreurs.
                    </p>
                </div>
            )}

            {successMsg && <div style={{ backgroundColor: '#c8e6c9', border: '1px solid #a5d6a7', color: '#1b5e20', padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>{successMsg}</div>}
            {error && <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>{error}</div>}

            <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>
                <div style={{ padding: '13px 16px', borderBottom: '1px solid ' + P.surfaceContainerLow, display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <div style={{ position: 'relative', flex: 1 }}>
                        <IconSearch style={{ position: 'absolute', left: '9px', top: '50%', transform: 'translateY(-50%)', width: '13px', height: '13px', color: P.outline }} />
                        <input type="text" placeholder="Rechercher par livreur, motif..." value={search} onChange={e => setSearch(e.target.value)}
                            style={{ width: '100%', padding: '8px 12px 8px 28px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', backgroundColor: P.surfaceContainerLow, boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none' }} />
                    </div>
                </div>

                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead><tr>
                        {['ID', 'Livreur', 'Livraison', 'Motif', 'Montant du', 'Recouvre', 'Restant', 'Action'].map(h => <th key={h} style={thStyle}>{h}</th>)}
                    </tr></thead>
                    <tbody>
                        {loading ? (
                            <tr><td colSpan={8} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>Chargement...</td></tr>
                        ) : filtered.length === 0 ? (
                            <tr><td colSpan={8} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>Aucune dette financiere enregistree.</td></tr>
                        ) : filtered.map(r => {
                            const du = Number(r.amount_to_collect || 0);
                            const recouvre = Number(r.amount_collected || 0);
                            const restant = du - recouvre;
                            const solde = restant <= 0;
                            return (
                                <tr key={r.id} onMouseEnter={e => e.currentTarget.style.backgroundColor = P.surfaceContainerLow} onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'} style={{ transition: 'background 0.1s' }}>
                                    <td style={{ ...tdStyle, fontWeight: 700, color: P.primary }}>#{r.id}</td>
                                    <td style={tdStyle}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                            <div style={{ width: '26px', height: '26px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '10px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>
                                                {r.delivery_persons?.users?.first_name?.[0]}
                                            </div>
                                            <div>
                                                <p style={{ margin: 0, fontSize: '13px', fontWeight: 500 }}>{r.delivery_persons?.users?.first_name} {r.delivery_persons?.users?.last_name}</p>
                                                <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>{r.delivery_persons?.users?.phone}</p>
                                            </div>
                                        </div>
                                    </td>
                                    <td style={{ ...tdStyle, color: P.primary, fontWeight: 600 }}>
                                        {r.deliveryorder_id ? <a href={'/livraisons/' + r.deliveryorder_id} style={{ color: P.primary, textDecoration: 'none' }}>#{String(r.deliveryorder_id).padStart(5,'0')}</a> : '—'}
                                    </td>
                                    <td style={tdStyle}>
                                        <span style={{ backgroundColor: r.motif === 'perte_colis' ? P.errorContainer : P.primaryFixed, color: r.motif === 'perte_colis' ? P.onErrorContainer : P.onPrimaryContainer, padding: '2px 8px', borderRadius: '4px', fontSize: '11px', fontWeight: 600 }}>
                                            {motifLabels[r.motif] || r.motif}
                                        </span>
                                    </td>
                                    <td style={{ ...tdStyle, fontWeight: 700, color: P.error }}>{du.toLocaleString('fr-FR')} FCFA</td>
                                    <td style={{ ...tdStyle, fontWeight: 700, color: '#1b5e20' }}>{recouvre.toLocaleString('fr-FR')} FCFA</td>
                                    <td style={{ ...tdStyle, fontWeight: 700, color: solde ? '#1b5e20' : P.error }}>
                                        {solde ? '0 FCFA' : restant.toLocaleString('fr-FR') + ' FCFA'}
                                    </td>
                                    <td style={tdStyle}>
                                        {!solde ? (
                                            <button onClick={() => handleMarquerPaye(r.id)}
                                                style={{ padding: '4px 10px', borderRadius: '6px', backgroundColor: '#c8e6c9', color: '#1b5e20', fontSize: '11px', fontWeight: 600, border: 'none', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                                Encaisser
                                            </button>
                                        ) : (
                                            <span style={{ fontSize: '11px', fontWeight: 600, color: '#1b5e20' }}>Solde</span>
                                        )}
                                    </td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>
                <div style={{ padding: '11px 16px', borderTop: '1px solid ' + P.surfaceContainerLow }}>
                    <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>{filtered.length} enregistrement{filtered.length > 1 ? 's' : ''}</p>
                </div>
            </div>
        </div>
    );
}