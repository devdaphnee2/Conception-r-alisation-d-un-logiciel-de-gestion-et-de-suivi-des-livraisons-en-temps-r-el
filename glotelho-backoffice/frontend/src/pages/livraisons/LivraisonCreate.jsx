import { useState, useEffect } from 'react';
import { useNavigate, useSearchParams, Link } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    primaryFixed: '#ffdea9', onPrimaryContainer: '#483100',
    secondary: '#475e8b', secondaryContainer: '#b5ccff', onSecondaryContainer: '#3e5682',
    tertiary: '#20619e', tertiaryContainer: '#6aa1e3', onTertiaryContainer: '#003762',
    error: '#ba1a1a', errorContainer: '#ffdad6', onErrorContainer: '#93000a',
    surface: '#ffffff', background: '#f9f9f9',
    surfaceContainerLow: '#f3f3f3', surfaceContainerHigh: '#e8e8e8',
    inverseS: '#2f3131', inverseSOn: '#f1f1f1',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
};

export default function LivraisonCreate() {
    // ── Lecture des params URL (venant de CommandeList) ──────
    // Ex: /livraisons/create?order_id=3&customer_id=2
    const [searchParams] = useSearchParams();
    const urlOrderId    = searchParams.get('order_id');
    const urlCustomerId = searchParams.get('customer_id');
    // ─────────────────────────────────────────────────────────

    const [form, setForm] = useState({
        delivery_address: '', customer_id: urlCustomerId || '',
        delivery_person_id: '', order_id: urlOrderId || '',
        amount_to_collect: '', collected_amount: '0',
        zone_bloc: '', delivery_date: '', delivery_instructions: '',
    });

    const [customers, setCustomers]           = useState([]);
    const [livreurs, setLivreurs]             = useState([]);
    const [orders, setOrders]                 = useState([]);
    const [selectedOrder, setSelectedOrder]   = useState(null);
    const [selectedCustomer, setSelectedCustomer] = useState(null);
    const [loading, setLoading]               = useState(false);
    const [initLoading, setInitLoading]       = useState(!!urlCustomerId);
    const [error, setError]                   = useState('');
    const navigate = useNavigate();

    // ── Chargement initial des données de base ───────────────
    useEffect(() => {
        Promise.all([
            api.get('/customers').catch(() => ({ data: [] })),
            api.get('/livreurs').catch(() => ({ data: [] })),
        ]).then(([custRes, livRes]) => {
            setCustomers(custRes.data);
            setLivreurs(livRes.data);
        });
    }, []);

    // ── Pré-remplissage automatique si order_id dans l'URL ──
    useEffect(() => {
        if (!urlCustomerId || customers.length === 0) return;

        const customer = customers.find(c => String(c.id) === String(urlCustomerId));
        if (!customer) return;

        setSelectedCustomer(customer);
        setForm(prev => ({
            ...prev,
            customer_id: String(urlCustomerId),
            delivery_address: customer.address || '',
        }));

        // Charger les commandes du client
        api.get('/customers/' + urlCustomerId + '/orders')
            .then(res => {
                const customerOrders = res.data;
                setOrders(customerOrders);

                // Si order_id aussi dans l'URL, pre-selectionner la commande
                if (urlOrderId) {
                    const order = customerOrders.find(o => String(o.id) === String(urlOrderId));
                    if (order) {
                        setSelectedOrder(order);
                        setForm(prev => ({
                            ...prev,
                            order_id: String(urlOrderId),
                            amount_to_collect: String(order.total_amount),
                            collected_amount: '0',
                        }));
                    }
                }
            })
            .finally(() => setInitLoading(false));
    }, [customers, urlCustomerId, urlOrderId]);
    // ─────────────────────────────────────────────────────────

    async function handleCustomerChange(e) {
        const customerId = e.target.value;
        const customer = customers.find(c => String(c.id) === String(customerId));
        setSelectedCustomer(customer || null);
        setSelectedOrder(null);
        setOrders([]);
        setForm(prev => ({
            ...prev,
            customer_id: customerId, order_id: '',
            amount_to_collect: '', collected_amount: '0',
            delivery_address: customer?.address || '',
        }));
        if (customerId) {
            try {
                const res = await api.get('/customers/' + customerId + '/orders');
                setOrders(res.data);
            } catch (err) {}
        }
    }

    function handleOrderChange(e) {
        const orderId = e.target.value;
        const order = orders.find(o => String(o.id) === String(orderId));
        setSelectedOrder(order || null);
        setForm(prev => ({
            ...prev,
            order_id: orderId,
            amount_to_collect: order ? String(order.total_amount) : '',
            collected_amount: '0',
        }));
    }

    function handleChange(e) {
        setForm({ ...form, [e.target.name]: e.target.value });
    }

    const resteAPayer = selectedOrder
        ? Math.max(0, parseFloat(selectedOrder.total_amount) - parseFloat(form.collected_amount || 0))
        : null;
    const itemsMaintenant = selectedOrder?.delivery_items?.filter(i => i.status === 'Disponible') || [];
    const itemsPlusTard   = selectedOrder?.delivery_items?.filter(i => i.status !== 'Disponible') || [];

    async function handleSubmit(e) {
        e.preventDefault();
        setError('');
        setLoading(true);
        try {
            await api.post('/livraisons', form);
            navigate('/livraisons');
        } catch (err) {
            setError(err.response?.data?.message || 'Erreur lors de la creation.');
        } finally {
            setLoading(false);
        }
    }

    const inputStyle = {
        width: '100%', padding: '11px 14px', borderRadius: '10px',
        border: '1.5px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow,
        fontSize: '13px', color: P.onSurface, outline: 'none',
        boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif',
        transition: 'border-color 0.15s',
    };
    const labelStyle = {
        display: 'block', fontSize: '11px', fontWeight: 600,
        color: P.onSurfaceVariant, textTransform: 'uppercase',
        letterSpacing: '0.07em', marginBottom: '7px',
    };

    function SectionTitle({ children }) {
        return (
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '4px' }}>
                <p style={{ margin: 0, fontSize: '13px', fontWeight: 700, color: P.onSurface }}>{children}</p>
                <div style={{ flex: 1, height: '1px', backgroundColor: P.outlineVariant }}></div>
            </div>
        );
    }

    if (initLoading) {
        return (
            <div style={{ fontFamily: 'Poppins, sans-serif', maxWidth: '760px' }}>
                <BackButton to="/commandes" />
                <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, padding: '48px', textAlign: 'center', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>
                    <p style={{ margin: 0, color: P.outline, fontSize: '14px' }}>Chargement de la commande...</p>
                </div>
            </div>
        );
    }

    return (
        <div style={{ maxWidth: '760px', fontFamily: 'Poppins, sans-serif' }}>
            <BackButton to={urlOrderId ? '/commandes' : '/livraisons'} />

            <div style={{ marginBottom: '20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                    <Link to="/livraisons" style={{ color: P.outline, textDecoration: 'none', fontSize: '13px' }}>Livraisons</Link>
                    <span style={{ color: P.outlineVariant, margin: '0 6px' }}>/</span>
                    <span style={{ color: P.onSurface, fontSize: '13px', fontWeight: 500 }}>Nouvelle livraison</span>
                </div>

                {/* Badge pre-rempli depuis commande */}
                {urlOrderId && (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', backgroundColor: P.primaryFixed, border: '1px solid ' + P.primaryContainer, borderRadius: '20px', padding: '5px 12px' }}>
                        <div style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: P.primaryContainer }}></div>
                        <span style={{ fontSize: '11px', fontWeight: 600, color: P.onPrimaryContainer }}>
                            Pre-rempli depuis Commande #{urlOrderId}
                        </span>
                    </div>
                )}
            </div>

            <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, padding: '28px', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>

                {error && (
                    <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', color: P.error, padding: '11px 14px', borderRadius: '10px', marginBottom: '20px', fontSize: '13px', fontWeight: 500 }}>
                        {error}
                    </div>
                )}

                <form onSubmit={handleSubmit}>
                    <div style={{ display: 'grid', gap: '20px' }}>

                        {/* ── CLIENT ────────────────────────────── */}
                        <SectionTitle>Client</SectionTitle>

                        <div>
                            <label style={labelStyle}>Selectionner le client *</label>
                            <select
                                name="customer_id"
                                value={form.customer_id}
                                onChange={handleCustomerChange}
                                style={inputStyle}
                                required
                                disabled={!!urlCustomerId}
                            >
                                <option value="">-- Selectionner un client --</option>
                                {customers.map(c => (
                                    <option key={c.id} value={c.id}>
                                        {c.users?.first_name} {c.users?.last_name} — {c.users?.phone}
                                    </option>
                                ))}
                            </select>
                            {urlCustomerId && (
                                <p style={{ margin: '5px 0 0 0', fontSize: '11px', color: P.outline }}>
                                    Client pre-selectionne depuis la commande.
                                    <button type="button" onClick={() => { setForm(f => ({ ...f, customer_id: '', order_id: '' })); setSelectedCustomer(null); setSelectedOrder(null); window.history.replaceState({}, '', '/livraisons/create'); }}
                                        style={{ background: 'none', border: 'none', color: P.primary, fontSize: '11px', cursor: 'pointer', fontFamily: 'Poppins, sans-serif', fontWeight: 600, marginLeft: '6px' }}>
                                        Changer
                                    </button>
                                </p>
                            )}
                        </div>

                        {/* Infos client */}
                        {selectedCustomer && (
                            <div style={{ padding: '14px 16px', backgroundColor: P.primaryFixed, borderRadius: '10px', border: '1px solid ' + P.primaryContainer + '60' }}>
                                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px', fontSize: '13px' }}>
                                    <div>
                                        <p style={{ ...labelStyle, marginBottom: '3px' }}>Nom complet</p>
                                        <p style={{ margin: 0, fontWeight: 600, color: P.onSurface }}>{selectedCustomer.users?.first_name} {selectedCustomer.users?.last_name}</p>
                                    </div>
                                    <div>
                                        <p style={{ ...labelStyle, marginBottom: '3px' }}>Telephone</p>
                                        <p style={{ margin: 0, fontWeight: 600, color: P.onSurface }}>{selectedCustomer.users?.phone}</p>
                                    </div>
                                    {selectedCustomer.address && (
                                        <div>
                                            <p style={{ ...labelStyle, marginBottom: '3px' }}>Adresse enregistree</p>
                                            <p style={{ margin: 0, fontWeight: 600, color: P.onSurface }}>{selectedCustomer.address}</p>
                                        </div>
                                    )}
                                </div>
                            </div>
                        )}

                        {/* ── COMMANDE ──────────────────────────── */}
                        {form.customer_id && (
                            <>
                                <SectionTitle>Commande</SectionTitle>

                                <div>
                                    <label style={labelStyle}>Selectionner la commande</label>
                                    <select
                                        name="order_id"
                                        value={form.order_id}
                                        onChange={handleOrderChange}
                                        style={inputStyle}
                                        disabled={!!urlOrderId && !!selectedOrder}
                                    >
                                        <option value="">-- Selectionner une commande --</option>
                                        {orders.length === 0
                                            ? <option disabled>Aucune commande disponible</option>
                                            : orders.map(o => (
                                                <option key={o.id} value={o.id}>
                                                    Commande #{o.id} — {Number(o.total_amount).toLocaleString('fr-FR')} FCFA — {o.statut || o.status}
                                                </option>
                                            ))
                                        }
                                    </select>
                                </div>

                                {selectedOrder && (
                                    <>
                                        {/* Montants */}
                                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px' }}>
                                            <div style={{ padding: '14px', borderRadius: '10px', backgroundColor: P.inverseS, textAlign: 'center' }}>
                                                <p style={{ margin: '0 0 4px 0', fontSize: '10px', color: 'rgba(241,241,241,0.5)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em' }}>Montant total</p>
                                                <p style={{ margin: 0, fontSize: '16px', fontWeight: 800, color: P.primaryContainer }}>
                                                    {Number(selectedOrder.total_amount).toLocaleString('fr-FR')} FCFA
                                                </p>
                                            </div>
                                            <div>
                                                <label style={labelStyle}>Montant deja paye (FCFA)</label>
                                                <input
                                                    type="number" name="collected_amount"
                                                    value={form.collected_amount} onChange={handleChange}
                                                    style={inputStyle} min="0" max={selectedOrder.total_amount} placeholder="0"
                                                />
                                            </div>
                                            <div style={{ padding: '14px', borderRadius: '10px', backgroundColor: resteAPayer > 0 ? P.errorContainer : '#c8e6c9', border: '1px solid ' + (resteAPayer > 0 ? 'rgba(186,26,26,0.2)' : '#a5d6a7'), textAlign: 'center' }}>
                                                <p style={{ margin: '0 0 4px 0', fontSize: '10px', color: resteAPayer > 0 ? P.error : '#1b5e20', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em' }}>Reste a payer</p>
                                                <p style={{ margin: 0, fontSize: '16px', fontWeight: 800, color: resteAPayer > 0 ? P.error : '#1b5e20' }}>
                                                    {Number(resteAPayer).toLocaleString('fr-FR')} FCFA
                                                </p>
                                            </div>
                                        </div>

                                        {/* Articles disponibles */}
                                        {itemsMaintenant.length > 0 && (
                                            <div>
                                                <p style={{ margin: '0 0 10px 0', fontSize: '11px', fontWeight: 700, color: '#1b5e20', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                                                    Articles a livrer maintenant ({itemsMaintenant.length})
                                                </p>
                                                <div style={{ display: 'grid', gap: '7px' }}>
                                                    {itemsMaintenant.map((item, i) => (
                                                        <div key={i} style={{ padding: '11px 14px', borderRadius: '9px', backgroundColor: '#f0fdf4', border: '1px solid #a5d6a7', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                                            <p style={{ margin: 0, fontSize: '13px', fontWeight: 500, color: P.onSurface }}>{item.product_name}</p>
                                                            <span style={{ fontSize: '10px', fontWeight: 600, color: '#1b5e20', backgroundColor: '#c8e6c9', padding: '2px 8px', borderRadius: '4px', flexShrink: 0, marginLeft: '10px' }}>Disponible</span>
                                                        </div>
                                                    ))}
                                                </div>
                                            </div>
                                        )}

                                        {/* Articles non disponibles */}
                                        {itemsPlusTard.length > 0 && (
                                            <div>
                                                <p style={{ margin: '0 0 10px 0', fontSize: '11px', fontWeight: 700, color: P.onPrimaryContainer, textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                                                    Articles a livrer plus tard ({itemsPlusTard.length})
                                                </p>
                                                <div style={{ display: 'grid', gap: '7px' }}>
                                                    {itemsPlusTard.map((item, i) => (
                                                        <div key={i} style={{ padding: '11px 14px', borderRadius: '9px', backgroundColor: P.primaryFixed, border: '1px solid ' + P.primaryContainer + '50', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                                            <p style={{ margin: 0, fontSize: '13px', fontWeight: 500, color: P.onSurface }}>{item.product_name}</p>
                                                            <span style={{ fontSize: '10px', fontWeight: 600, color: P.onPrimaryContainer, backgroundColor: P.primaryFixed, padding: '2px 8px', borderRadius: '4px', flexShrink: 0, marginLeft: '10px', border: '1px solid ' + P.primaryContainer + '40' }}>Non disponible</span>
                                                        </div>
                                                    ))}
                                                </div>
                                            </div>
                                        )}
                                    </>
                                )}
                            </>
                        )}

                        {/* ── INFORMATIONS LIVRAISON ────────────── */}
                        <SectionTitle>Informations de livraison</SectionTitle>

                        <div>
                            <label style={labelStyle}>Adresse de livraison *</label>
                            <input
                                type="text" name="delivery_address"
                                value={form.delivery_address} onChange={handleChange}
                                style={inputStyle}
                                placeholder="Ex: Bonamoussadi, Rue des Manguiers, Douala"
                                required
                            />
                        </div>

                        <div>
                            <label style={labelStyle}>
                                Description du lieu
                                <span style={{ textTransform: 'none', fontWeight: 400, marginLeft: '4px' }}>(facultatif)</span>
                            </label>
                            <input
                                type="text" name="zone_bloc"
                                value={form.zone_bloc} onChange={handleChange}
                                style={inputStyle}
                                placeholder="Ex: Apres le carrefour Shell, portail rouge, 2eme etage"
                            />
                        </div>

                        <div>
                            <label style={labelStyle}>Instructions de livraison</label>
                            <textarea
                                name="delivery_instructions"
                                value={form.delivery_instructions} onChange={handleChange}
                                rows={3}
                                style={{ ...inputStyle, resize: 'vertical' }}
                                placeholder="Ex: Colis fragile, ne pas empiler, maintenir a la verticale..."
                            />
                        </div>

                        <div>
                            <label style={labelStyle}>Date de livraison souhaitee</label>
                            <input
                                type="datetime-local" name="delivery_date"
                                value={form.delivery_date} onChange={handleChange}
                                style={inputStyle}
                            />
                        </div>

                        {/* ── ASSIGNATION ───────────────────────── */}
                        <SectionTitle>Assignation livreur</SectionTitle>

                        <div>
                            <label style={labelStyle}>
                                Livreur
                                <span style={{ textTransform: 'none', fontWeight: 400, marginLeft: '4px' }}>(optionnel — assignable apres creation)</span>
                            </label>
                            <select
                                name="delivery_person_id"
                                value={form.delivery_person_id}
                                onChange={handleChange}
                                style={inputStyle}
                            >
                                <option value="">-- Assigner plus tard --</option>
                                {livreurs.map(l => (
                                    <option key={l.id} value={l.id}>
                                        {l.users?.first_name} {l.users?.last_name} — {l.zone_affectee || 'Sans zone'} — {l.vehicules?.type || 'Vehicule inconnu'}
                                    </option>
                                ))}
                            </select>
                        </div>

                        {/* ── BOUTONS ───────────────────────────── */}
                        <div style={{ display: 'flex', gap: '12px', paddingTop: '8px', borderTop: '1px solid ' + P.outlineVariant, marginTop: '4px' }}>
                            <button
                                type="submit"
                                disabled={loading}
                                style={{ backgroundColor: loading ? P.outline : P.primary, color: '#fff', padding: '12px 28px', borderRadius: '10px', border: 'none', fontSize: '13px', fontWeight: 600, cursor: loading ? 'not-allowed' : 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: loading ? 'none' : '0 4px 12px rgba(125,87,0,0.28)', transition: 'all 0.2s' }}
                                onMouseEnter={e => { if (!loading) e.currentTarget.style.backgroundColor = '#6b4900'; }}
                                onMouseLeave={e => { if (!loading) e.currentTarget.style.backgroundColor = P.primary; }}
                            >
                                {loading ? 'Creation en cours...' : 'Creer la livraison'}
                            </button>
                            <Link
                                to={urlOrderId ? '/commandes' : '/livraisons'}
                                style={{ padding: '12px 24px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, color: P.onSurface, fontSize: '13px', fontWeight: 500, textDecoration: 'none', display: 'inline-flex', alignItems: 'center' }}
                            >
                                Annuler
                            </Link>
                        </div>

                    </div>
                </form>
            </div>
        </div>
    );
}