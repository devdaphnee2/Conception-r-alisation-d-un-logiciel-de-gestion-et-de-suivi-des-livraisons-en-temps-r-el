import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import api from '../../services/api';

const statusStyles = {
    'En_attente': { background: '#FFF9C4', color: '#B45309' },
    'Assign_':    { background: '#EFF6FF', color: '#1D4ED8' },
    'En_cours':   { background: '#FFF1E8', color: '#E8580A' },
    'Livr_':      { background: '#F0FDF4', color: '#15803D' },
    'Suspendu':   { background: '#FEF2F2', color: '#DC2626' },
    'Annul_':     { background: '#F3F4F6', color: '#6B7280' },
};

const statusLabels = {
    'En_attente': 'En attente',
    'Assign_': 'Assigne',
    'En_cours': 'En cours',
    'Livr_': 'Livre',
    'Suspendu': 'Suspendu',
    'Annul_': 'Annule',
};

export default function LivraisonList() {
    const [livraisons, setLivraisons] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [actionMsg, setActionMsg] = useState('');
    const navigate = useNavigate();

    function charger() {
        api.get('/livraisons')
            .then(res => setLivraisons(res.data))
            .catch(() => setError('Impossible de charger les livraisons.'))
            .finally(() => setLoading(false));
    }

    useEffect(() => { charger(); }, []);

    async function handleSuspendre(id) {
        const reason = window.prompt('Raison de la suspension :');
        if (!reason) return;
        try {
            await api.post('/livraisons/' + id + '/suspendre', { suspension_reason: reason });
            setActionMsg('Livraison suspendue.');
            charger();
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur.');
        }
    }

    async function handleAnnuler(id) {
        if (!window.confirm('Confirmer l\'annulation de cette livraison ?')) return;
        try {
            await api.post('/livraisons/' + id + '/annuler');
            setActionMsg('Livraison annulee.');
            charger();
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur.');
        }
    }

    if (loading) return <p style={{ color: '#8A8AA3', textAlign: 'center', marginTop: '60px' }}>Chargement...</p>;

    return (
        <div>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px' }}>
                <p style={{ color: '#8A8AA3', fontSize: '14px', margin: 0 }}>
                    {livraisons.length} livraison{livraisons.length !== 1 ? 's' : ''} au total
                </p>
                <Link to="/livraisons/create" style={{ background: 'linear-gradient(to right, #E8580A, #FF7A33)', color: 'white', padding: '10px 20px', borderRadius: '12px', textDecoration: 'none', fontSize: '14px', fontWeight: 600, boxShadow: '0 4px 12px rgba(232,88,10,0.25)' }}>
                    + Nouvelle livraison
                </Link>
            </div>

            {actionMsg && (
                <div style={{ backgroundColor: '#F0FDF4', border: '1px solid #BBF7D0', color: '#15803D', padding: '12px 16px', borderRadius: '12px', marginBottom: '16px', fontSize: '14px' }}>
                    {actionMsg}
                </div>
            )}

            {error && (
                <div style={{ backgroundColor: '#FEF2F2', border: '1px solid #FECACA', color: '#DC2626', padding: '12px 16px', borderRadius: '12px', marginBottom: '16px', fontSize: '14px' }}>
                    {error}
                </div>
            )}

            <div style={{ backgroundColor: 'white', borderRadius: '20px', border: '1px solid #ECECF2', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
                    <thead>
                        <tr style={{ backgroundColor: '#FAFAFC', borderBottom: '1px solid #ECECF2' }}>
                            {['ID', 'Adresse', 'Client', 'Livreur', 'Statut', 'Date', 'Actions'].map(h => (
                                <th key={h} style={{ padding: '12px 16px', textAlign: 'left', fontSize: '11px', fontWeight: 600, color: '#8A8AA3', textTransform: 'uppercase', letterSpacing: '0.08em' }}>
                                    {h}
                                </th>
                            ))}
                        </tr>
                    </thead>
                    <tbody>
                        {livraisons.length === 0 ? (
                            <tr>
                                <td colSpan={7} style={{ padding: '60px', textAlign: 'center', color: '#8A8AA3' }}>
                                    Aucune livraison.{' '}
                                    <Link to="/livraisons/create" style={{ color: '#E8580A', fontWeight: 600 }}>Creer la premiere</Link>
                                </td>
                            </tr>
                        ) : (
                            livraisons.map((l, i) => {
                                const style = statusStyles[l.status] || { background: '#F3F4F6', color: '#6B7280' };
                                const peutSuspendre = ['Assign_', 'En_cours'].includes(l.status);
                                const peutAnnuler = ['En_attente', 'Suspendu'].includes(l.status);
                                const peutModifier = !['Livr_', 'Annul_'].includes(l.status);

                                return (
                                    <tr key={l.id}
                                        style={{ borderBottom: i < livraisons.length - 1 ? '1px solid #ECECF2' : 'none', transition: 'background 0.15s' }}
                                        onMouseEnter={e => e.currentTarget.style.backgroundColor = '#FAFAFC'}
                                        onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}
                                    >
                                        <td style={{ padding: '14px 16px', fontWeight: 700, color: '#1C1C2E' }}>#{l.id}</td>
                                        <td style={{ padding: '14px 16px', color: '#1C1C2E', maxWidth: '160px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{l.delivery_address}</td>
                                        <td style={{ padding: '14px 16px', color: '#8A8AA3' }}>
                                            {l.customers?.users?.first_name ?? '—'}
                                        </td>
                                        <td style={{ padding: '14px 16px', color: '#8A8AA3' }}>
                                            {l.delivery_persons?.users?.first_name ?? 'Non assigne'}
                                        </td>
                                        <td style={{ padding: '14px 16px' }}>
                                            <span style={{ ...style, padding: '3px 10px', borderRadius: '999px', fontSize: '11px', fontWeight: 600 }}>
                                                {statusLabels[l.status] || l.status}
                                            </span>
                                        </td>
                                        <td style={{ padding: '14px 16px', color: '#8A8AA3' }}>
                                            {l.creation_date ? new Date(l.creation_date).toLocaleDateString('fr-FR') : '—'}
                                        </td>
                                        <td style={{ padding: '14px 16px' }}>
                                            <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                                                <Link to={'/livraisons/' + l.id}
                                                    style={{ padding: '5px 10px', borderRadius: '8px', backgroundColor: '#F5F5FF', color: '#4F46E5', fontSize: '12px', fontWeight: 600, textDecoration: 'none' }}>
                                                    Voir
                                                </Link>
                                                {peutModifier && (
                                                    <Link to={'/livraisons/' + l.id + '/edit'}
                                                        style={{ padding: '5px 10px', borderRadius: '8px', backgroundColor: '#FAFAFC', color: '#1C1C2E', fontSize: '12px', fontWeight: 600, textDecoration: 'none', border: '1px solid #ECECF2' }}>
                                                        Modifier
                                                    </Link>
                                                )}
                                                {peutSuspendre && (
                                                    <button onClick={() => handleSuspendre(l.id)}
                                                        style={{ padding: '5px 10px', borderRadius: '8px', backgroundColor: '#FFF9C4', color: '#B45309', fontSize: '12px', fontWeight: 600, border: 'none', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                                        Suspendre
                                                    </button>
                                                )}
                                                {peutAnnuler && (
                                                    <button onClick={() => handleAnnuler(l.id)}
                                                        style={{ padding: '5px 10px', borderRadius: '8px', backgroundColor: '#FEF2F2', color: '#DC2626', fontSize: '12px', fontWeight: 600, border: 'none', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                                        Annuler
                                                    </button>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                );
                            })
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
}