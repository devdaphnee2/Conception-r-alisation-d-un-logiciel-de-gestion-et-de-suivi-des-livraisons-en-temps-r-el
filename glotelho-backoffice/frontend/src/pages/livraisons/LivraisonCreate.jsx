import { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';


<BackButton to="/livraisons" />
export default function LivraisonCreate() {
    const [form, setForm] = useState({
        delivery_address: '',
        customer_id: '',
        delivery_person_id: '',
        order_id: '',
        amount_to_collect: '',
        collected_amount: '0',
        zone_bloc: '',
        delivery_date: '',
        delivery_instructions: '',
    });
    const [customers, setCustomers] = useState([]);
    const [livreurs, setLivreurs] = useState([]);
    const [orders, setOrders] = useState([]);
    const [selectedOrder, setSelectedOrder] = useState(null);
    const [selectedCustomer, setSelectedCustomer] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const navigate = useNavigate();

    useEffect(() => {
        api.get('/customers').then(res => setCustomers(res.data)).catch(() => {});
        api.get('/livreurs').then(res => setLivreurs(res.data)).catch(() => {});
    }, []);

    async function handleCustomerChange(e) {
        const customerId = e.target.value;
        const customer = customers.find(c => String(c.id) === String(customerId));
        setSelectedCustomer(customer || null);
        setSelectedOrder(null);
        setOrders([]);
        setForm(prev => ({
            ...prev,
            customer_id: customerId,
            order_id: '',
            amount_to_collect: '',
            collected_amount: '0',
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

    const itemsMaintenant = selectedOrder?.delivery_items?.filter(i => i.route_info === 'A livrer maintenant') || [];
    const itemsPlusTard = selectedOrder?.delivery_items?.filter(i => i.route_info === 'A programmer pour une prochaine livraison') || [];

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
        width: '100%', padding: '11px 14px', borderRadius: '12px',
        border: '1px solid #ECECF2', backgroundColor: '#FAFAFC',
        fontSize: '14px', color: '#1C1C2E', outline: 'none',
        boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif',
    };

    const labelStyle = {
        display: 'block', fontSize: '11px', fontWeight: 600,
        color: '#8A8AA3', textTransform: 'uppercase',
        letterSpacing: '0.08em', marginBottom: '8px',
    };

    const sectionTitle = (title) => (
        <p style={{ fontSize: '13px', fontWeight: 700, color: '#1C1C2E', margin: '0 0 16px 0', paddingBottom: '8px', borderBottom: '2px solid #E8580A', display: 'inline-block' }}>
            {title}
        </p>
    );

    const infoCard = (label, value, color) => (
        <div style={{ padding: '12px 16px', borderRadius: '12px', backgroundColor: color === 'orange' ? '#FFF1E8' : color === 'green' ? '#F0FDF4' : '#FEF2F2', border: '1px solid ' + (color === 'orange' ? '#FFD4B3' : color === 'green' ? '#BBF7D0' : '#FECACA') }}>
            <div style={{ fontSize: '10px', fontWeight: 600, color: '#8A8AA3', textTransform: 'uppercase', marginBottom: '4px' }}>{label}</div>
            <div style={{ fontSize: '15px', fontWeight: 700, color: color === 'orange' ? '#E8580A' : color === 'green' ? '#15803D' : '#DC2626' }}>{value}</div>
        </div>
    );

    return (
        <div style={{ maxWidth: '760px' }}>

            <div style={{ marginBottom: '24px' }}>
                <Link to="/livraisons" style={{ color: '#8A8AA3', textDecoration: 'none', fontSize: '14px' }}>Livraisons</Link>
                <span style={{ color: '#8A8AA3', margin: '0 8px' }}>/</span>
                <span style={{ color: '#1C1C2E', fontSize: '14px', fontWeight: 500 }}>Nouvelle livraison</span>
            </div>

            <div style={{ backgroundColor: 'white', borderRadius: '24px', border: '1px solid #ECECF2', padding: '32px', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>

                {error && (
                    <div style={{ backgroundColor: '#FEF2F2', border: '1px solid #FECACA', color: '#DC2626', padding: '12px 16px', borderRadius: '12px', marginBottom: '24px', fontSize: '14px' }}>
                        {error}
                    </div>
                )}

                <form onSubmit={handleSubmit}>
                    <div style={{ display: 'grid', gap: '24px' }}>

                        {/* CLIENT */}
                        <div>{sectionTitle('Client')}</div>

                        <div>
                            <label style={labelStyle}>Selectionner le client *</label>
                            <select name="customer_id" value={form.customer_id} onChange={handleCustomerChange} style={inputStyle} required>
                                <option value="">-- Selectionner un client --</option>
                                {customers.map(c => (
                                    <option key={c.id} value={c.id}>
                                        {c.users?.first_name} {c.users?.last_name} — {c.users?.phone}
                                    </option>
                                ))}
                            </select>
                        </div>

                        {selectedCustomer && (
                            <div style={{ padding: '16px', backgroundColor: '#FAFAFC', borderRadius: '16px', border: '1px solid #ECECF2' }}>
                                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px', fontSize: '13px' }}>
                                    <div>
                                        <div style={{ color: '#8A8AA3', fontSize: '11px', marginBottom: '4px', textTransform: 'uppercase', fontWeight: 600 }}>Nom complet</div>
                                        <div style={{ color: '#1C1C2E', fontWeight: 600 }}>{selectedCustomer.users?.first_name} {selectedCustomer.users?.last_name}</div>
                                    </div>
                                    <div>
                                        <div style={{ color: '#8A8AA3', fontSize: '11px', marginBottom: '4px', textTransform: 'uppercase', fontWeight: 600 }}>Telephone</div>
                                        <div style={{ color: '#1C1C2E', fontWeight: 600 }}>{selectedCustomer.users?.phone}</div>
                                    </div>
                                    <div>
                                        <div style={{ color: '#8A8AA3', fontSize: '11px', marginBottom: '4px', textTransform: 'uppercase', fontWeight: 600 }}>Adresse</div>
                                        <div style={{ color: '#1C1C2E', fontWeight: 600 }}>{selectedCustomer.address || '—'}</div>
                                    </div>
                                </div>
                            </div>
                        )}

                        {/* COMMANDE */}
                        {form.customer_id && (
                            <>
                                <div>{sectionTitle('Commande')}</div>

                                <div>
                                    <label style={labelStyle}>Selectionner la commande</label>
                                    <select name="order_id" value={form.order_id} onChange={handleOrderChange} style={inputStyle}>
                                        <option value="">-- Selectionner une commande --</option>
                                        {orders.length === 0
                                            ? <option disabled>Aucune commande disponible</option>
                                            : orders.map(o => (
                                                <option key={o.id} value={o.id}>
                                                    Commande #{o.id} — {Number(o.total_amount).toLocaleString('fr-FR')} FCFA — {o.status}
                                                </option>
                                            ))
                                        }
                                    </select>
                                </div>

                                {selectedOrder && (
                                    <>
                                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px' }}>
                                            {infoCard('Montant total commande', Number(selectedOrder.total_amount).toLocaleString('fr-FR') + ' FCFA', 'orange')}
                                            <div>
                                                <label style={labelStyle}>Montant deja paye (FCFA)</label>
                                                <input type="number" name="collected_amount" value={form.collected_amount} onChange={handleChange} style={inputStyle} min="0" max={selectedOrder.total_amount} placeholder="0" />
                                            </div>
                                            {infoCard('Reste a payer', Number(resteAPayer).toLocaleString('fr-FR') + ' FCFA', resteAPayer > 0 ? 'red' : 'green')}
                                        </div>

                                        {itemsMaintenant.length > 0 && (
                                            <div>
                                                <div style={{ fontSize: '12px', fontWeight: 700, color: '#15803D', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                                                    Articles a livrer maintenant ({itemsMaintenant.length})
                                                </div>
                                                <div style={{ display: 'grid', gap: '8px' }}>
                                                    {itemsMaintenant.map((item, i) => (
                                                        <div key={i} style={{ padding: '12px 16px', borderRadius: '12px', backgroundColor: '#F0FDF4', border: '1px solid #BBF7D0', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                                                            <div>
                                                                <div style={{ fontSize: '13px', fontWeight: 600, color: '#1C1C2E' }}>{item.product_name}</div>
                                                                {item.delivery_instructions && (
                                                                    <div style={{ fontSize: '11px', color: '#8A8AA3', marginTop: '3px' }}>{item.delivery_instructions}</div>
                                                                )}
                                                            </div>
                                                            <span style={{ fontSize: '11px', fontWeight: 600, color: '#15803D', backgroundColor: '#DCFCE7', padding: '3px 10px', borderRadius: '999px', whiteSpace: 'nowrap', marginLeft: '12px' }}>
                                                                Maintenant
                                                            </span>
                                                        </div>
                                                    ))}
                                                </div>
                                            </div>
                                        )}

                                        {itemsPlusTard.length > 0 && (
                                            <div>
                                                <div style={{ fontSize: '12px', fontWeight: 700, color: '#B45309', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                                                    Articles a livrer plus tard ({itemsPlusTard.length})
                                                </div>
                                                <div style={{ display: 'grid', gap: '8px' }}>
                                                    {itemsPlusTard.map((item, i) => (
                                                        <div key={i} style={{ padding: '12px 16px', borderRadius: '12px', backgroundColor: '#FFF9C4', border: '1px solid #FDE68A', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                                                            <div>
                                                                <div style={{ fontSize: '13px', fontWeight: 600, color: '#1C1C2E' }}>{item.product_name}</div>
                                                                {item.delivery_instructions && (
                                                                    <div style={{ fontSize: '11px', color: '#8A8AA3', marginTop: '3px' }}>{item.delivery_instructions}</div>
                                                                )}
                                                            </div>
                                                            <span style={{ fontSize: '11px', fontWeight: 600, color: '#B45309', backgroundColor: '#FEF3C7', padding: '3px 10px', borderRadius: '999px', whiteSpace: 'nowrap', marginLeft: '12px' }}>
                                                                Plus tard
                                                            </span>
                                                        </div>
                                                    ))}
                                                </div>
                                            </div>
                                        )}
                                    </>
                                )}
                            </>
                        )}

                        {/* LIVRAISON */}
                        <div>{sectionTitle('Informations de livraison')}</div>

                        <div>
                            <label style={labelStyle}>Adresse de livraison *</label>
                            <input type="text" name="delivery_address" value={form.delivery_address} onChange={handleChange} style={inputStyle} placeholder="Ex: Bonamoussadi, Rue des Manguiers, Douala" required />
                        </div>

                        <div>
                            <label style={labelStyle}>Description du lieu <span style={{ textTransform: 'none', fontWeight: 400 }}>(facultatif — ex: 3eme maison apres le marche, portail bleu)</span></label>
                            <input type="text" name="zone_bloc" value={form.zone_bloc} onChange={handleChange} style={inputStyle} placeholder="Ex: Apres le carrefour Shell, portail rouge, 2eme etage" />
                        </div>

                        <div>
                            <label style={labelStyle}>Instructions de livraison <span style={{ textTransform: 'none', fontWeight: 400 }}>(conditions de transport, fragile, etc.)</span></label>
                            <textarea name="delivery_instructions" value={form.delivery_instructions} onChange={handleChange} rows={3} style={{ ...inputStyle, resize: 'vertical' }} placeholder="Ex: Colis fragile, ne pas empiler, maintenir a la verticale..." />
                        </div>

                        <div>
                            <label style={labelStyle}>Date de livraison souhaitee</label>
                            <input type="datetime-local" name="delivery_date" value={form.delivery_date} onChange={handleChange} style={inputStyle} />
                        </div>

                        {/* ASSIGNATION */}
                        <div>{sectionTitle('Assignation')}</div>

                        <div>
                            <label style={labelStyle}>Livreur <span style={{ textTransform: 'none', fontWeight: 400 }}>(optionnel — peut etre assigne plus tard)</span></label>
                            <select name="delivery_person_id" value={form.delivery_person_id} onChange={handleChange} style={inputStyle}>
                                <option value="">-- Assigner plus tard --</option>
                                {livreurs.map(l => (
                                    <option key={l.id} value={l.id}>
                                        {l.users?.first_name} {l.users?.last_name} — {l.zone_affectee || 'Sans zone'}
                                    </option>
                                ))}
                            </select>
                        </div>

                        <div style={{ display: 'flex', gap: '12px', marginTop: '8px' }}>
                            <button type="submit" disabled={loading} style={{ background: 'linear-gradient(to right, #E8580A, #FF7A33)', color: 'white', padding: '12px 28px', borderRadius: '12px', border: 'none', fontSize: '14px', fontWeight: 600, cursor: loading ? 'not-allowed' : 'pointer', opacity: loading ? 0.7 : 1, boxShadow: '0 4px 12px rgba(232,88,10,0.25)', fontFamily: 'Poppins, sans-serif' }}>
                                {loading ? 'Creation...' : 'Creer la livraison'}
                            </button>
                            <Link to="/livraisons" style={{ padding: '12px 24px', borderRadius: '12px', border: '1px solid #ECECF2', backgroundColor: '#FAFAFC', color: '#1C1C2E', fontSize: '14px', fontWeight: 500, textDecoration: 'none', display: 'inline-flex', alignItems: 'center' }}>
                                Annuler
                            </Link>
                        </div>

                    </div>
                </form>
            </div>
        </div>
    );
}