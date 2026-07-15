import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import api from '../../services/api';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    primaryFixed: '#ffdea9', onPrimaryContainer: '#483100',
    error: '#ba1a1a', errorContainer: '#ffdad6', onErrorContainer: '#93000a',
    surface: '#ffffff', surfaceContainerLow: '#f3f3f3', surfaceContainerHigh: '#e8e8e8',
    inverseS: '#2f3131', inverseSOn: '#f1f1f1',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
    secondary: '#475e8b', secondaryContainer: '#b5ccff',
};

export default function CommandesList() {
    const navigate    = useNavigate();
    const [commandes, setCommandes] = useState([]);
    const [livreurs,  setLivreurs]  = useState([]);
    const [loading,   setLoading]   = useState(true);
    const [assignForm, setAssignForm] = useState({ livreurId: '', commandeId: null });
    const [actionLoading, setActionLoading] = useState(false);
    const [successMsg, setSuccessMsg] = useState('');
    const [error, setError] = useState('');

    function charger() {
        setLoading(true);
        setError('');

        api.get('/livraisons?status=En_attente')
            .then(function(res) { setCommandes(res.data || []); })
            .catch(function(err) {
                setError('Erreur chargement commandes : ' + (err.response && err.response.data ? err.response.data.message : err.message));
            });

        api.get('/livreurs')
            .then(function(res) { setLivreurs(res.data || []); })
            .catch(function() {})
            .finally(function() { setLoading(false); });
    }

    useEffect(function() { charger(); }, []);

    async function handleAssigner(commandeId) {
        if (!assignForm.livreurId) { setError('Sélectionnez un livreur.'); return; }
        setActionLoading(true);
        setError('');
        try {
            var res = await api.post('/livraisons/' + commandeId + '/assigner', {
                delivery_person_id: assignForm.livreurId
            });
            setSuccessMsg('Livreur assigné avec succès !');
            if (res.data && res.data.whatsapp_link) {
                window.open(res.data.whatsapp_link, '_blank');
            }
            setAssignForm({ livreurId: '', commandeId: null });
            charger();
        } catch (err) {
            setError(err.response && err.response.data && err.response.data.message ? err.response.data.message : 'Erreur.');
        } finally {
            setActionLoading(false);
        }
    }

    var inputStyle = { width: '100%', padding: '10px 12px', borderRadius: '8px', border: '1.5px solid ' + P.outlineVariant, fontSize: '12px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none', boxSizing: 'border-box', backgroundColor: P.surface };

    return (
        <div style={{ fontFamily: 'Poppins, sans-serif', maxWidth: '1100px' }}>

            <div style={{ marginBottom: '20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                    <h2 style={{ margin: '0 0 4px', fontSize: '20px', fontWeight: 800, color: P.onSurface }}>Commandes en attente</h2>
                    <p style={{ margin: 0, fontSize: '13px', color: P.outline }}>
                        Commandes reçues des commerçants — assignez un livreur pour créer la course.
                    </p>
                </div>
                <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
                    <span style={{ backgroundColor: P.primaryFixed, color: P.onPrimaryContainer, padding: '5px 14px', borderRadius: '20px', fontSize: '12px', fontWeight: 700 }}>
                        {commandes.length} en attente
                    </span>
                    <Link to="/livraisons" style={{ padding: '8px 16px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, color: P.onSurface, textDecoration: 'none', fontSize: '12px', fontWeight: 500 }}>
                        Voir toutes les livraisons
                    </Link>
                </div>
            </div>

            {successMsg && (
                <div style={{ backgroundColor: '#c8e6c9', color: '#1b5e20', padding: '10px 16px', borderRadius: '10px', marginBottom: '16px', fontSize: '13px', fontWeight: 500 }}>
                    ✅ {successMsg}
                </div>
            )}
            {error && (
                <div style={{ backgroundColor: P.errorContainer, color: P.error, padding: '10px 16px', borderRadius: '10px', marginBottom: '16px', fontSize: '13px' }}>
                    {error}
                </div>
            )}

            {loading ? (
                <div style={{ textAlign: 'center', padding: '60px', color: P.outline }}>Chargement...</div>
            ) : commandes.length === 0 ? (
                <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, padding: '60px', textAlign: 'center' }}>
                    <p style={{ fontSize: '40px', margin: '0 0 12px' }}>📭</p>
                    <p style={{ fontSize: '16px', fontWeight: 700, color: P.onSurface, margin: '0 0 6px' }}>Aucune commande en attente</p>
                    <p style={{ fontSize: '13px', color: P.outline, margin: 0 }}>Les commandes des commerçants apparaîtront ici dès leur réception.</p>
                </div>
            ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                    {commandes.map(function(cmd) {
                        var clientNom = cmd.client_nom || (cmd.customers && cmd.customers.users ? cmd.customers.users.first_name + ' ' + cmd.customers.users.last_name : '—');
                        var clientTel = cmd.client_telephone || (cmd.customers && cmd.customers.users ? cmd.customers.users.phone : '');
                        var numFormate = '#' + String(cmd.id).padStart(5, '0');
                        var isAssigning = assignForm.commandeId === cmd.id;

                        return (
                            <div key={cmd.id} style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, overflow: 'hidden', boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>

                                <div style={{ padding: '14px 18px', borderBottom: '1px solid ' + P.surfaceContainerLow, display: 'flex', alignItems: 'center', justifyContent: 'space-between', backgroundColor: P.surfaceContainerLow }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                        <span style={{ fontSize: '20px', fontWeight: 900, color: P.primary }}>{numFormate}</span>
                                        <span style={{ fontSize: '11px', color: P.outline }}>
                                            {cmd.creation_date ? new Date(cmd.creation_date).toLocaleString('fr-FR') : '—'}
                                        </span>
                                    </div>
                                    <span style={{ backgroundColor: P.primaryFixed, color: P.onPrimaryContainer, padding: '3px 10px', borderRadius: '20px', fontSize: '10px', fontWeight: 700 }}>
                                        ⏳ En attente d'assignation
                                    </span>
                                </div>

                                <div style={{ padding: '16px 18px', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '16px' }}>

                                    {/* Client */}
                                    <div>
                                        <p style={{ margin: '0 0 8px', fontSize: '10px', fontWeight: 700, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Client</p>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                            <div style={{ width: '32px', height: '32px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>
                                                {clientNom[0] || '?'}
                                            </div>
                                            <div>
                                                <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onSurface }}>{clientNom}</p>
                                                <p style={{ margin: '2px 0 0', fontSize: '11px', color: P.outline }}>{clientTel}</p>
                                            </div>
                                        </div>
                                        <div style={{ marginTop: '8px' }}>
                                            <p style={{ margin: '0 0 2px', fontSize: '10px', color: P.outline }}>📍 {cmd.delivery_address}</p>
                                            {cmd.zone_bloc && <p style={{ margin: 0, fontSize: '10px', color: P.outline }}>{cmd.zone_bloc}</p>}
                                        </div>
                                    </div>

                                    {/* Articles */}
                                    <div>
                                        <p style={{ margin: '0 0 8px', fontSize: '10px', fontWeight: 700, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em' }}>
                                            Articles ({cmd.delivery_items ? cmd.delivery_items.length : 0})
                                        </p>
                                        <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                                            {cmd.delivery_items && cmd.delivery_items.slice(0, 3).map(function(item, i) {
                                                return (
                                                    <div key={i} style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px' }}>
                                                        <span style={{ color: P.onSurface }}>{item.product_name} x{item.quantity || 1}</span>
                                                        <span style={{ color: P.primary, fontWeight: 600 }}>
                                                            {item.price ? (Number(item.price) * (item.quantity || 1)).toLocaleString('fr-FR') + ' F' : ''}
                                                        </span>
                                                    </div>
                                                );
                                            })}
                                            {cmd.delivery_items && cmd.delivery_items.length > 3 && (
                                                <p style={{ margin: 0, fontSize: '10px', color: P.outline }}>+ {cmd.delivery_items.length - 3} autre(s) article(s)</p>
                                            )}
                                        </div>
                                        <div style={{ marginTop: '8px', paddingTop: '8px', borderTop: '1px solid ' + P.outlineVariant, display: 'flex', justifyContent: 'space-between' }}>
                                            <span style={{ fontSize: '11px', color: P.outline }}>Total à collecter</span>
                                            <span style={{ fontSize: '14px', fontWeight: 800, color: P.primary }}>
                                                {Number(cmd.amount_to_collect || 0).toLocaleString('fr-FR')} FCFA
                                            </span>
                                        </div>
                                    </div>

                                    {/* Assignation */}
                                    <div>
                                        <p style={{ margin: '0 0 8px', fontSize: '10px', fontWeight: 700, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Assigner un livreur</p>
                                        {isAssigning ? (
                                            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                                                <select value={assignForm.livreurId}
                                                    onChange={function(e) { setAssignForm({ livreurId: e.target.value, commandeId: cmd.id }); }}
                                                    style={inputStyle}>
                                                    <option value="">-- Sélectionner --</option>
                                                    {livreurs.filter(function(l) { return l.status === 'Disponible' && l.caution_payee; }).map(function(l) {
                                                        var u = Array.isArray(l.users)
                                                            ? l.users.find(function(u) { return u.id === l.user_id; })
                                                            : l.users;
                                                        return (
                                                            <option key={l.id} value={l.id} disabled={!l.caution_payee}>
                                                                {u && u.first_name} {u && u.last_name} — {l.zone_affectee || 'Sans zone'}
                                                            </option>
                                                        );
                                                    })}
                                                </select>
                                                <div style={{ display: 'flex', gap: '8px' }}>
                                                    <button onClick={function() { handleAssigner(cmd.id); }} disabled={actionLoading}
                                                        style={{ flex: 1, padding: '9px', borderRadius: '8px', border: 'none', backgroundColor: P.primary, color: '#fff', fontSize: '12px', fontWeight: 700, cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                                        {actionLoading ? '...' : '✅ Confirmer'}
                                                    </button>
                                                    <button onClick={function() { setAssignForm({ livreurId: '', commandeId: null }); }}
                                                        style={{ padding: '9px 12px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, color: P.onSurface, fontSize: '12px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                                        ✕
                                                    </button>
                                                </div>
                                            </div>
                                        ) : (
                                            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                                                <button onClick={function() { setAssignForm({ livreurId: '', commandeId: cmd.id }); }}
                                                    style={{ width: '100%', padding: '10px', borderRadius: '8px', border: 'none', backgroundColor: P.primary, color: '#fff', fontSize: '12px', fontWeight: 700, cursor: 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: '0 2px 8px rgba(125,87,0,0.25)' }}>
                                                    🛵 Assigner un livreur
                                                </button>
                                                <Link to={'/livraisons/' + cmd.id}
                                                    style={{ textAlign: 'center', display: 'block', padding: '8px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, color: P.onSurface, textDecoration: 'none', fontSize: '12px', fontWeight: 500 }}>
                                                    Voir détails
                                                </Link>
                                            </div>
                                        )}
                                    </div>
                                </div>

                                {cmd.delivery_instructions && (
                                    <div style={{ padding: '10px 18px', borderTop: '1px solid ' + P.surfaceContainerLow, backgroundColor: P.primaryFixed }}>
                                        <p style={{ margin: 0, fontSize: '11px', color: P.onPrimaryContainer }}>
                                            📝 <strong>Instructions :</strong> {cmd.delivery_instructions}
                                        </p>
                                    </div>
                                )}
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
}