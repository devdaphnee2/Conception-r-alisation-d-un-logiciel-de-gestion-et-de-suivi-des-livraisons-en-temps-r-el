import { useState, useEffect } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';

const statusLabels = {
    'En_attente': 'En attente',
    'Assign_': 'Assigne',
    'En_cours': 'En cours',
    'Livr_': 'Livre',
    'Suspendu': 'Suspendu',
    'Annul_': 'Annule',
};

const statusStyles = {
    'En_attente': { background: '#FFF9C4', color: '#B45309' },
    'Assign_':    { background: '#EFF6FF', color: '#1D4ED8' },
    'En_cours':   { background: '#FFF1E8', color: '#E8580A' },
    'Livr_':      { background: '#F0FDF4', color: '#15803D' },
    'Suspendu':   { background: '#FEF2F2', color: '#DC2626' },
    'Annul_':     { background: '#F3F4F6', color: '#6B7280' },
};

export default function LivraisonShow() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [livraison, setLivraison] = useState(null);
    const [livreurs, setLivreurs] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [actionLoading, setActionLoading] = useState(false);
    const [showSuspendForm, setShowSuspendForm] = useState(false);
    const [showAssignForm, setShowAssignForm] = useState(false);
    const [suspensionReason, setSuspensionReason] = useState('');
    const [selectedLivreur, setSelectedLivreur] = useState('');
    const [successMsg, setSuccessMsg] = useState('');

    useEffect(() => {
        api.get('/livraisons/' + id)
            .then(res => setLivraison(res.data))
            .catch(() => setError('Livraison introuvable.'))
            .finally(() => setLoading(false));
        api.get('/livreurs').then(res => setLivreurs(res.data)).catch(() => {});
    }, [id]);

    async function handleAction(action, data = {}) {
        setActionLoading(true);
        setError('');
        setSuccessMsg('');
        try {
            const res = await api.post('/livraisons/' + id + '/' + action, data);
            setLivraison(prev => ({ ...prev, ...res.data.livraison }));
            setSuccessMsg(res.data.message);
            setShowSuspendForm(false);
            setShowAssignForm(false);
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur lors de l\'action.');
        } finally {
            setActionLoading(false);
        }
    }

    async function handleAnnuler() {
        if (!window.confirm('Confirmer l\'annulation de cette livraison ?')) return;
        handleAction('annuler');
    }

    async function handleBordereau() {
        try {
            const res = await api.get('/bordereaux/livraison/' + id, { responseType: 'blob' });
            const url = window.URL.createObjectURL(new Blob([res.data]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', 'bordereau_' + id + '.pdf');
            document.body.appendChild(link);
            link.click();
            link.remove();
        } catch (err) {
            setError('Erreur lors du telechargement du bordereau.');
        }
    }

    if (loading) return <p style={{ color: '#8A8AA3', textAlign: 'center', marginTop: '60px' }}>Chargement...</p>;
    if (error && !livraison) return <p style={{ color: '#DC2626', textAlign: 'center', marginTop: '60px' }}>{error}</p>;

    const statusStyle = statusStyles[livraison?.status] || { background: '#F3F4F6', color: '#6B7280' };

    const cardStyle = {
        backgroundColor: 'white', borderRadius: '20px',
        border: '1px solid #ECECF2', padding: '28px',
        boxShadow: '0 1px 3px rgba(0,0,0,0.04)', marginBottom: '20px',
    };
    const labelStyle = { fontSize: '11px', fontWeight: 600, color: '#8A8AA3', textTransform: 'uppercase', letterSpacing: '0.08em', margin: 0 };
    const valueStyle = { fontSize: '15px', color: '#1C1C2E', fontWeight: 500, margin: '4px 0 0 0' };
    const inputStyle = { width: '100%', padding: '12px 16px', borderRadius: '12px', border: '1px solid #ECECF2', backgroundColor: '#FAFAFC', fontSize: '14px', color: '#1C1C2E', outline: 'none', boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif', marginTop: '8px' };
    const btnPrimary = { padding: '10px 20px', borderRadius: '12px', border: 'none', background: 'linear-gradient(to right, #E8580A, #FF7A33)', color: 'white', fontSize: '14px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' };
    const btnSecondary = { padding: '10px 20px', borderRadius: '12px', border: '1px solid #ECECF2', backgroundColor: '#FAFAFC', color: '#1C1C2E', fontSize: '14px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' };
    const btnDanger = { padding: '10px 20px', borderRadius: '12px', border: '1px solid #FECACA', backgroundColor: '#FEF2F2', color: '#DC2626', fontSize: '14px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' };

    return (
        <div style={{ maxWidth: '780px' }}>

            <BackButton to="/livraisons" />

            <div style={{ marginBottom: '24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                    <Link to="/livraisons" style={{ color: '#8A8AA3', textDecoration: 'none', fontSize: '14px' }}>Livraisons</Link>
                    <span style={{ color: '#8A8AA3', margin: '0 8px' }}>/</span>
                    <span style={{ color: '#1C1C2E', fontSize: '14px', fontWeight: 500 }}>Livraison #{id}</span>
                </div>
                <span style={{ ...statusStyle, padding: '6px 14px', borderRadius: '999px', fontSize: '13px', fontWeight: 600 }}>
                    {statusLabels[livraison?.status] || livraison?.status}
                </span>
            </div>

            {successMsg && (
                <div style={{ backgroundColor: '#F0FDF4', border: '1px solid #BBF7D0', color: '#15803D', padding: '12px 16px', borderRadius: '12px', marginBottom: '20px', fontSize: '14px' }}>
                    {successMsg}
                </div>
            )}
            {error && (
                <div style={{ backgroundColor: '#FEF2F2', border: '1px solid #FECACA', color: '#DC2626', padding: '12px 16px', borderRadius: '12px', marginBottom: '20px', fontSize: '14px' }}>
                    {error}
                </div>
            )}

            <div style={cardStyle}>
                <p style={{ fontSize: '16px', fontWeight: 700, color: '#1C1C2E', margin: '0 0 20px 0' }}>Informations de livraison</p>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                    <div><p style={labelStyle}>Adresse</p><p style={valueStyle}>{livraison?.delivery_address}</p></div>
                    <div><p style={labelStyle}>Zone / Bloc</p><p style={valueStyle}>{livraison?.zone_bloc || '—'}</p></div>
                    <div><p style={labelStyle}>Montant a recouvrer</p><p style={valueStyle}>{livraison?.amount_to_collect ? livraison.amount_to_collect + ' FCFA' : '—'}</p></div>
                    <div><p style={labelStyle}>Montant collecte</p><p style={valueStyle}>{livraison?.collected_amount ? livraison.collected_amount + ' FCFA' : '—'}</p></div>
                    <div><p style={labelStyle}>Date de livraison</p><p style={valueStyle}>{livraison?.delivery_date ? new Date(livraison.delivery_date).toLocaleString('fr-FR') : '—'}</p></div>
                    <div><p style={labelStyle}>Date de creation</p><p style={valueStyle}>{livraison?.creation_date ? new Date(livraison.creation_date).toLocaleString('fr-FR') : '—'}</p></div>
                    {livraison?.suspension_reason && (
                        <div style={{ gridColumn: '1 / -1' }}><p style={labelStyle}>Raison de suspension</p><p style={{ ...valueStyle, color: '#DC2626' }}>{livraison.suspension_reason}</p></div>
                    )}
                </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', marginBottom: '20px' }}>
                <div style={{ ...cardStyle, marginBottom: 0 }}>
                    <p style={{ fontSize: '14px', fontWeight: 700, color: '#1C1C2E', margin: '0 0 16px 0' }}>Client</p>
                    {livraison?.customers ? (
                        <>
                            <p style={valueStyle}>{livraison.customers.users?.first_name} {livraison.customers.users?.last_name}</p>
                            <p style={{ fontSize: '13px', color: '#8A8AA3', marginTop: '4px' }}>{livraison.customers.users?.phone}</p>
                            <p style={{ fontSize: '13px', color: '#8A8AA3' }}>{livraison.customers.address || '—'}</p>
                        </>
                    ) : <p style={{ color: '#8A8AA3', fontSize: '14px' }}>—</p>}
                </div>
                <div style={{ ...cardStyle, marginBottom: 0 }}>
                    <p style={{ fontSize: '14px', fontWeight: 700, color: '#1C1C2E', margin: '0 0 16px 0' }}>Livreur</p>
                    {livraison?.delivery_persons ? (
                        <>
                            <p style={valueStyle}>{livraison.delivery_persons.users?.first_name} {livraison.delivery_persons.users?.last_name}</p>
                            <p style={{ fontSize: '13px', color: '#8A8AA3', marginTop: '4px' }}>{livraison.delivery_persons.users?.phone}</p>
                            <p style={{ fontSize: '13px', color: '#8A8AA3' }}>Zone : {livraison.delivery_persons.zone_affectee || '—'}</p>
                        </>
                    ) : <p style={{ color: '#8A8AA3', fontSize: '14px' }}>Non assigne</p>}
                </div>
            </div>

            <div style={{ ...cardStyle, marginBottom: 0 }}>
                <p style={{ fontSize: '16px', fontWeight: 700, color: '#1C1C2E', margin: '0 0 20px 0' }}>Actions</p>

                <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>

                    {!['Livr_', 'Annul_'].includes(livraison?.status) && (
                        <Link to={'/livraisons/' + id + '/edit'} style={{ ...btnSecondary, textDecoration: 'none', display: 'inline-flex', alignItems: 'center' }}>
                            Modifier
                        </Link>
                    )}

                    {['En_attente', 'Suspendu'].includes(livraison?.status) && (
                        <button onClick={() => { setShowAssignForm(!showAssignForm); setShowSuspendForm(false); }} style={btnPrimary}>
                            {livraison?.delivery_persons ? 'Reassigner' : 'Assigner un livreur'}
                        </button>
                    )}

                    {['Assign_', 'En_cours'].includes(livraison?.status) && (
                        <button onClick={() => { setShowSuspendForm(!showSuspendForm); setShowAssignForm(false); }} style={btnSecondary}>
                            Suspendre
                        </button>
                    )}

                    {['En_attente', 'Suspendu'].includes(livraison?.status) && (
                        <button onClick={handleAnnuler} disabled={actionLoading} style={btnDanger}>
                            Annuler la livraison
                        </button>
                    )}

                    <button onClick={handleBordereau} style={btnSecondary}>
                        Telecharger le bordereau
                    </button>

                </div>

                {showAssignForm && (
                    <div style={{ marginTop: '20px', padding: '20px', backgroundColor: '#FAFAFC', borderRadius: '16px', border: '1px solid #ECECF2' }}>
                        <p style={{ fontSize: '14px', fontWeight: 600, color: '#1C1C2E', marginBottom: '12px' }}>Choisir un livreur</p>
                        <select value={selectedLivreur} onChange={e => setSelectedLivreur(e.target.value)} style={inputStyle}>
                            <option value="">-- Selectionner --</option>
                            {livreurs.map(l => (
                                <option key={l.id} value={l.id}>{l.users?.first_name} {l.users?.last_name}</option>
                            ))}
                        </select>
                        <div style={{ display: 'flex', gap: '10px', marginTop: '12px' }}>
                            <button onClick={() => handleAction('assigner', { delivery_person_id: selectedLivreur })} disabled={!selectedLivreur || actionLoading} style={{ ...btnPrimary, opacity: !selectedLivreur ? 0.6 : 1 }}>
                                {actionLoading ? 'En cours...' : 'Confirmer'}
                            </button>
                            <button onClick={() => setShowAssignForm(false)} style={btnSecondary}>Annuler</button>
                        </div>
                    </div>
                )}

                {showSuspendForm && (
                    <div style={{ marginTop: '20px', padding: '20px', backgroundColor: '#FAFAFC', borderRadius: '16px', border: '1px solid #ECECF2' }}>
                        <p style={{ fontSize: '14px', fontWeight: 600, color: '#1C1C2E', marginBottom: '12px' }}>Raison de la suspension</p>
                        <textarea value={suspensionReason} onChange={e => setSuspensionReason(e.target.value)} placeholder="Decrivez la raison..." rows={3} style={{ ...inputStyle, resize: 'vertical' }} />
                        <div style={{ display: 'flex', gap: '10px', marginTop: '12px' }}>
                            <button onClick={() => handleAction('suspendre', { suspension_reason: suspensionReason })} disabled={!suspensionReason || actionLoading} style={{ ...btnDanger, border: 'none', backgroundColor: '#DC2626', color: 'white', opacity: !suspensionReason ? 0.6 : 1 }}>
                                {actionLoading ? 'En cours...' : 'Confirmer la suspension'}
                            </button>
                            <button onClick={() => setShowSuspendForm(false)} style={btnSecondary}>Annuler</button>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}