import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import api from '../services/api';
import { IconPackage, IconSearch, IconCheck, IconClock, IconAlert, IconUser, IconX } from '../components/Icons';

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

const statusOrder = {
    'En_cours':   { bg: P.tertiaryContainer,   color: P.onTertiaryContainer, label: 'En cours' },
    'Payee':      { bg: '#c8e6c9',              color: '#1b5e20',             label: 'Payee' },
    'Livree':     { bg: P.primaryFixed,         color: P.onPrimaryContainer,  label: 'Livree' },
    'Annulee':    { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant,    label: 'Annulee' },
    'En_attente': { bg: P.primaryFixed,         color: P.onPrimaryContainer,  label: 'En attente' },
};

const statusItem = {
    'Disponible':     { bg: '#c8e6c9', color: '#1b5e20', label: 'Disponible' },
    'Non_disponible': { bg: P.errorContainer, color: P.onErrorContainer, label: 'Non disponible' },
};

function getProductImage(name) {
    if (!name) return 'https://placehold.co/80x80/eeeeee/817564?text=Prod.';
    const n = name.toLowerCase();
    if (n.includes('tv') || n.includes('television')) return 'https://placehold.co/80x80/1a1c1c/f9f9f9?text=TV';
    if (n.includes('clim') || n.includes('climatiseur')) return 'https://placehold.co/80x80/475e8b/ffffff?text=AC';
    if (n.includes('machine') || n.includes('laver')) return 'https://placehold.co/80x80/20619e/ffffff?text=ML';
    if (n.includes('frigo') || n.includes('refriger')) return 'https://placehold.co/80x80/2f3131/f1f1f1?text=RF';
    if (n.includes('tel') || n.includes('phone') || n.includes('iphone') || n.includes('samsung')) return 'https://placehold.co/80x80/7d5700/ffffff?text=TEL';
    if (n.includes('ordi') || n.includes('laptop') || n.includes('pc')) return 'https://placehold.co/80x80/475e8b/ffffff?text=PC';
    return 'https://placehold.co/80x80/eeeeee/817564?text=Prod.';
}

function KpiCard({ icon: Icon, label, value, iconColor, iconBg }) {
    return (
        <div style={{ backgroundColor: P.inverseS, borderRadius: '12px', padding: '16px', display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '9px', backgroundColor: iconBg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Icon style={{ width: '17px', height: '17px', color: iconColor }} />
            </div>
            <div>
                <p style={{ margin: 0, fontSize: '22px', fontWeight: 800, color: P.inverseSOn, lineHeight: 1 }}>{value}</p>
                <p style={{ margin: '4px 0 0 0', fontSize: '11px', color: 'rgba(241,241,241,0.4)', fontWeight: 500 }}>{label}</p>
            </div>
        </div>
    );
}

// MODALE DETAIL COMMANDE — style panier e-commerce
function CommandeModal({ commande, onClose }) {
    const navigate = useNavigate();
    const items = commande.delivery_items || [];
    const disponibles = items.filter(i => i.status === 'Disponible');
    const sc = statusOrder[commande.statut] || { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, label: commande.statut };

    function handleCreerLivraison() {
        onClose();
        navigate('/livraisons/create?order_id=' + commande.id + '&customer_id=' + commande.customers?.id);
    }

    // Fermer en cliquant sur le fond
    function handleBackdropClick(e) {
        if (e.target === e.currentTarget) onClose();
    }

    return (
        <div onClick={handleBackdropClick} style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', zIndex: 200, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }}>
            <div style={{ backgroundColor: P.surface, borderRadius: '16px', width: '100%', maxWidth: '900px', maxHeight: '90vh', overflow: 'hidden', display: 'flex', flexDirection: 'column', boxShadow: '0 24px 64px rgba(0,0,0,0.25)' }}>

                {/* HEADER MODALE */}
                <div style={{ padding: '16px 24px', borderBottom: '1px solid ' + P.outlineVariant, display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexShrink: 0 }}>
                    <div>
                        <p style={{ margin: 0, fontSize: '16px', fontWeight: 700, color: P.onSurface }}>
                            Commande #{String(commande.id).padStart(5,'0')}
                        </p>
                        <p style={{ margin: '3px 0 0 0', fontSize: '12px', color: P.outline }}>
                            {commande.created_at ? new Date(commande.created_at).toLocaleDateString('fr-FR', { day: '2-digit', month: 'long', year: 'numeric' }) : '—'}
                            {' · '}
                            <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '1px 7px', borderRadius: '4px', fontSize: '11px', fontWeight: 600 }}>{sc.label}</span>
                        </p>
                    </div>
                    <button onClick={onClose} style={{ width: '32px', height: '32px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <IconX style={{ width: '16px', height: '16px', color: P.onSurfaceVariant }} />
                    </button>
                </div>

                {/* CORPS EN 2 COLONNES */}
                <div style={{ display: 'flex', flex: 1, overflow: 'hidden' }}>

                    {/* COLONNE GAUCHE — Articles */}
                    <div style={{ flex: 1, overflowY: 'auto', padding: '20px 24px' }}>

                        {/* Info client */}
                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '12px 16px', backgroundColor: P.surfaceContainerLow, borderRadius: '10px', marginBottom: '20px', border: '1px solid ' + P.outlineVariant }}>
                            <div style={{ width: '38px', height: '38px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '14px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>
                                {commande.customers?.users?.first_name?.[0]}
                            </div>
                            <div>
                                <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onSurface }}>
                                    {commande.customers?.users?.first_name} {commande.customers?.users?.last_name}
                                </p>
                                <p style={{ margin: '2px 0 0 0', fontSize: '12px', color: P.outline }}>
                                    {commande.customers?.users?.phone}
                                    {commande.customers?.address ? ' · ' + commande.customers.address : ''}
                                </p>
                            </div>
                        </div>

                        {/* Liste articles */}
                        <p style={{ margin: '0 0 12px 0', fontSize: '11px', fontWeight: 700, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em' }}>
                            {items.length} article{items.length > 1 ? 's' : ''} dans cette commande
                        </p>

                        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                            {items.map((item, i) => {
                                const si = statusItem[item.status] || { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, label: item.status };
                                const unitPrice = item.unit_price ? Number(item.unit_price) : null;
                                const qty = item.quantity || 1;

                                return (
                                    <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: '14px', padding: '16px', borderRadius: '12px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>

                                        {/* Image produit */}
                                        <div style={{ width: '80px', height: '80px', borderRadius: '10px', overflow: 'hidden', flexShrink: 0, border: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow }}>
                                            <img
                                                src={getProductImage(item.product_name)}
                                                alt={item.product_name}
                                                style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                                            />
                                        </div>

                                        {/* Infos article */}
                                        <div style={{ flex: 1, minWidth: 0 }}>
                                            <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: '12px', marginBottom: '6px' }}>
                                                <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onSurface, lineHeight: 1.4 }}>
                                                    {item.product_name}
                                                </p>
                                                {unitPrice && (
                                                    <p style={{ margin: 0, fontSize: '13px', fontWeight: 700, color: P.onSurfaceVariant, whiteSpace: 'nowrap' }}>
                                                        {qty} x {unitPrice.toLocaleString('fr-FR')} FCFA
                                                    </p>
                                                )}
                                            </div>

                                            {/* Description / specs si disponibles */}
                                            {item.description && (
                                                <p style={{ margin: '0 0 8px 0', fontSize: '12px', color: P.outline, lineHeight: 1.5 }}>
                                                    {item.description}
                                                </p>
                                            )}

                                            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '8px' }}>
                                                <span style={{ backgroundColor: si.bg, color: si.color, padding: '3px 10px', borderRadius: '5px', fontSize: '11px', fontWeight: 600 }}>
                                                    {si.label}
                                                </span>
                                                {unitPrice && (
                                                    <p style={{ margin: 0, fontSize: '15px', fontWeight: 800, color: P.primary }}>
                                                        {(unitPrice * qty).toLocaleString('fr-FR')} FCFA
                                                    </p>
                                                )}
                                            </div>
                                        </div>
                                    </div>
                                );
                            })}
                        </div>

                        {/* Résumé articles */}
                        <div style={{ marginTop: '16px', padding: '12px 16px', backgroundColor: P.surfaceContainerLow, borderRadius: '10px', border: '1px solid ' + P.outlineVariant }}>
                            <p style={{ margin: 0, fontSize: '12px', color: P.outline }}>
                                <span style={{ color: '#1b5e20', fontWeight: 600 }}>{disponibles.length} article{disponibles.length > 1 ? 's' : ''} disponible{disponibles.length > 1 ? 's' : ''}</span>
                                {items.length - disponibles.length > 0 && (
                                    <span style={{ color: P.error }}> · {items.length - disponibles.length} non disponible{items.length - disponibles.length > 1 ? 's' : ''} (livraison differee)</span>
                                )}
                            </p>
                        </div>
                    </div>

                    {/* COLONNE DROITE — Récapitulatif */}
                    <div style={{ width: '280px', flexShrink: 0, borderLeft: '1px solid ' + P.outlineVariant, padding: '20px', display: 'flex', flexDirection: 'column', gap: '0' }}>

                        <p style={{ margin: '0 0 16px 0', fontSize: '18px', fontWeight: 800, color: P.onSurface }}>
                            Total : <span style={{ color: P.primary }}>{Number(commande.total_amount || 0).toLocaleString('fr-FR')} FCFA</span>
                        </p>

                        {/* Détail récapitulatif */}
                        <div style={{ borderTop: '1px solid ' + P.outlineVariant, borderBottom: '1px solid ' + P.outlineVariant, padding: '14px 0', marginBottom: '16px', display: 'flex', flexDirection: 'column', gap: '10px' }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                                <p style={{ margin: 0, fontSize: '13px', color: P.onSurfaceVariant }}>Sous-total</p>
                                <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onSurface }}>{Number(commande.total_amount || 0).toLocaleString('fr-FR')} FCFA</p>
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                                <p style={{ margin: 0, fontSize: '13px', color: P.onSurfaceVariant }}>Livraison</p>
                                <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: '#1b5e20' }}>0 FCFA</p>
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                                <p style={{ margin: 0, fontSize: '13px', color: P.onSurfaceVariant }}>Articles dispo.</p>
                                <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onSurface }}>{disponibles.length} / {items.length}</p>
                            </div>
                        </div>

                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '24px' }}>
                            <p style={{ margin: 0, fontSize: '15px', fontWeight: 700, color: P.onSurface }}>Total</p>
                            <p style={{ margin: 0, fontSize: '15px', fontWeight: 800, color: P.primary }}>{Number(commande.total_amount || 0).toLocaleString('fr-FR')} FCFA</p>
                        </div>

                        {/* Statut commande */}
                        <div style={{ padding: '10px 14px', borderRadius: '10px', backgroundColor: P.surfaceContainerLow, border: '1px solid ' + P.outlineVariant, marginBottom: '16px' }}>
                            <p style={{ margin: '0 0 4px 0', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.07em' }}>Statut commande</p>
                            <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '3px 10px', borderRadius: '5px', fontSize: '12px', fontWeight: 600 }}>{sc.label}</span>
                        </div>

                        {/* BOUTON PRINCIPAL */}
                        <button
                            onClick={handleCreerLivraison}
                            style={{ width: '100%', padding: '14px', borderRadius: '10px', border: 'none', backgroundColor: P.primaryContainer, color: '#fff', fontSize: '13px', fontWeight: 700, cursor: 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: '0 4px 14px rgba(201,149,46,0.35)', textTransform: 'uppercase', letterSpacing: '0.04em', lineHeight: 1.4, marginBottom: '10px' }}
                            onMouseEnter={e => e.currentTarget.style.backgroundColor = P.primary}
                            onMouseLeave={e => e.currentTarget.style.backgroundColor = P.primaryContainer}
                        >
                            Creer une livraison<br/>pour cette commande
                        </button>

                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px' }}>
                            <svg width="12" height="12" fill="none" stroke={P.outline} viewBox="0 0 24 24" strokeWidth="2">
                                <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                                <path d="M7 11V7a5 5 0 0110 0v4"/>
                            </svg>
                            <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>Paiement securise</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}

export default function CommandeList() {
    const [commandes, setCommandes] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [search, setSearch] = useState('');
    const [filterStatut, setFilterStatut] = useState('');
    const [selectedCommande, setSelectedCommande] = useState(null);

    useEffect(() => {
        api.get('/orders')
            .then(res => setCommandes(res.data))
            .catch(() => setError('Impossible de charger les commandes.'))
            .finally(() => setLoading(false));
    }, []);

    const filtered = commandes.filter(c => {
        const matchStatut = !filterStatut || c.statut === filterStatut;
        const matchSearch = !search || [
            c.customers?.users?.first_name,
            c.customers?.users?.last_name,
            c.customers?.users?.phone,
            '#' + c.id,
        ].some(v => v?.toLowerCase().includes(search.toLowerCase()));
        return matchStatut && matchSearch;
    });

    const stats = {
        total: commandes.length,
        en_cours: commandes.filter(c => c.statut === 'En_cours').length,
        payees: commandes.filter(c => c.statut === 'Payee').length,
        livrees: commandes.filter(c => c.statut === 'Livree').length,
        montant_total: commandes.reduce((sum, c) => sum + Number(c.total_amount || 0), 0),
    };

    const thStyle = { padding: '9px 14px', textAlign: 'left', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em', borderBottom: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, whiteSpace: 'nowrap' };
    const tdStyle = { padding: '13px 14px', fontSize: '13px', color: P.onSurface, borderBottom: '1px solid ' + P.surfaceContainerLow };

    return (
        <div style={{ fontFamily: 'Poppins, sans-serif' }}>

            {/* KPIs */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: '10px', marginBottom: '18px' }}>
                <KpiCard icon={IconPackage} label="Total commandes"    value={stats.total}     iconColor={P.primaryContainer} iconBg="rgba(201,149,46,0.15)" />
                <KpiCard icon={IconClock}   label="En cours"           value={stats.en_cours}  iconColor="#6aa1e3"            iconBg="rgba(106,161,227,0.15)" />
                <KpiCard icon={IconCheck}   label="Payees"             value={stats.payees}    iconColor="#81c784"            iconBg="rgba(129,199,132,0.15)" />
                <KpiCard icon={IconAlert}   label="Livrees"            value={stats.livrees}   iconColor={P.primaryContainer} iconBg="rgba(201,149,46,0.15)" />
                <KpiCard icon={IconUser}    label="Chiffre d'affaires" value={stats.montant_total.toLocaleString('fr-FR') + ' F'} iconColor="#81c784" iconBg="rgba(129,199,132,0.15)" />
            </div>

            {error && (
                <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>
                    {error}
                </div>
            )}

            {/* TABLE */}
            <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>

                {/* Filtres */}
                <div style={{ padding: '13px 16px', borderBottom: '1px solid ' + P.surfaceContainerLow, display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
                    <div style={{ position: 'relative', flex: 1, minWidth: '200px' }}>
                        <IconSearch style={{ position: 'absolute', left: '9px', top: '50%', transform: 'translateY(-50%)', width: '13px', height: '13px', color: P.outline }} />
                        <input type="text" placeholder="Rechercher par client, telephone, #commande..." value={search} onChange={e => setSearch(e.target.value)}
                            style={{ width: '100%', padding: '8px 12px 8px 28px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', backgroundColor: P.surfaceContainerLow, boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none' }} />
                    </div>
                    <select value={filterStatut} onChange={e => setFilterStatut(e.target.value)}
                        style={{ padding: '8px 12px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, backgroundColor: P.surface, outline: 'none' }}>
                        <option value="">Tous les statuts</option>
                        <option value="En_cours">En cours</option>
                        <option value="Payee">Payee</option>
                        <option value="Livree">Livree</option>
                        <option value="Annulee">Annulee</option>
                        <option value="En_attente">En attente</option>
                    </select>
                </div>

                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead><tr>
                        {['#', 'Client', 'Articles', 'Montant', 'Statut', 'Date', 'Action'].map(h => (
                            <th key={h} style={thStyle}>{h}</th>
                        ))}
                    </tr></thead>
                    <tbody>
                        {loading ? (
                            <tr><td colSpan={7} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>Chargement...</td></tr>
                        ) : filtered.length === 0 ? (
                            <tr><td colSpan={7} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>Aucune commande.</td></tr>
                        ) : filtered.map(c => {
                            const sc = statusOrder[c.statut] || { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, label: c.statut };
                            const items = c.delivery_items || [];
                            const disponibles = items.filter(i => i.status === 'Disponible').length;

                            return (
                                <tr key={c.id}
                                    onMouseEnter={e => e.currentTarget.style.backgroundColor = P.surfaceContainerLow}
                                    onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}
                                    style={{ transition: 'background 0.1s', cursor: 'pointer' }}
                                    onClick={() => setSelectedCommande(c)}
                                >
                                    <td style={{ ...tdStyle, fontWeight: 700, color: P.primary }}>#{String(c.id).padStart(5,'0')}</td>
                                    <td style={tdStyle}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                            <div style={{ width: '28px', height: '28px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '10px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>
                                                {c.customers?.users?.first_name?.[0]}
                                            </div>
                                            <div>
                                                <p style={{ margin: 0, fontSize: '13px', fontWeight: 500 }}>{c.customers?.users?.first_name} {c.customers?.users?.last_name}</p>
                                                <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>{c.customers?.users?.phone}</p>
                                            </div>
                                        </div>
                                    </td>
                                    <td style={tdStyle}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                            <div style={{ display: 'flex', gap: '3px' }}>
                                                {items.slice(0, 3).map((item, i) => (
                                                    <img key={i} src={getProductImage(item.product_name)} alt={item.product_name}
                                                        style={{ width: '28px', height: '28px', borderRadius: '6px', objectFit: 'cover', border: '1px solid ' + P.outlineVariant }} />
                                                ))}
                                                {items.length > 3 && (
                                                    <div style={{ width: '28px', height: '28px', borderRadius: '6px', backgroundColor: P.surfaceContainerHigh, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '9px', fontWeight: 700, color: P.outline }}>
                                                        +{items.length - 3}
                                                    </div>
                                                )}
                                            </div>
                                            <div>
                                                <p style={{ margin: 0, fontSize: '12px', fontWeight: 500 }}>{items.length} art.</p>
                                                <p style={{ margin: 0, fontSize: '10px', color: '#1b5e20' }}>{disponibles} dispo.</p>
                                            </div>
                                        </div>
                                    </td>
                                    <td style={{ ...tdStyle, fontWeight: 700, color: P.primary, whiteSpace: 'nowrap' }}>
                                        {Number(c.total_amount || 0).toLocaleString('fr-FR')} FCFA
                                    </td>
                                    <td style={tdStyle}>
                                        <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '3px 8px', borderRadius: '5px', fontSize: '10px', fontWeight: 600 }}>
                                            {sc.label}
                                        </span>
                                    </td>
                                    <td style={{ ...tdStyle, color: P.outline, fontSize: '12px', whiteSpace: 'nowrap' }}>
                                        {c.created_at ? new Date(c.created_at).toLocaleDateString('fr-FR') : '—'}
                                    </td>
                                    <td style={tdStyle}>
                                        <button
                                            onClick={e => { e.stopPropagation(); setSelectedCommande(c); }}
                                            style={{ padding: '5px 12px', borderRadius: '7px', backgroundColor: P.secondaryContainer, color: P.onSecondaryContainer, fontSize: '11px', fontWeight: 600, border: 'none', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                                            Voir
                                        </button>
                                    </td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>

                <div style={{ padding: '11px 16px', borderTop: '1px solid ' + P.surfaceContainerLow }}>
                    <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>
                        {filtered.length} commande{filtered.length > 1 ? 's' : ''} affichee{filtered.length > 1 ? 's' : ''}
                    </p>
                </div>
            </div>

            {/* MODALE */}
            {selectedCommande && (
                <CommandeModal
                    commande={selectedCommande}
                    onClose={() => setSelectedCommande(null)}
                />
            )}
        </div>
    );
}