import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import api from '../../services/api';
import { IconUser, IconSearch, IconCheck, IconAlert, IconTruck } from '../../components/Icons';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    primaryFixed: '#ffdea9', onPrimaryContainer: '#483100',
    error: '#ba1a1a', errorContainer: '#ffdad6', onErrorContainer: '#93000a',
    surface: '#ffffff', surfaceContainerLow: '#f3f3f3', surfaceContainerHigh: '#e8e8e8',
    inverseS: '#2f3131', inverseSOn: '#f1f1f1',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
};

const statusConfig = {
    'Disponible':   { bg: '#c8e6c9', color: '#1b5e20', dot: '#4caf50', label: 'Disponible' },
    'En_livraison': { bg: P.primaryFixed, color: P.onPrimaryContainer, dot: P.primaryContainer, label: 'En livraison' },
    'Suspendu':     { bg: P.errorContainer, color: P.onErrorContainer, dot: P.error, label: 'Suspendu' },
};

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

export default function LivreurList() {
    const [livreurs, setLivreurs] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [filterStatus, setFilterStatus] = useState('');

    useEffect(() => {
        api.get('/livreurs?all=true')
            .then(res => setLivreurs(res.data))
            .finally(() => setLoading(false));
    }, []);

    const filtered = livreurs.filter(l => {
        const matchStatus = !filterStatus || l.status === filterStatus;
        const user = l.users || l.user; // Sécurité
        const matchSearch = !search || [
            user?.first_name, user?.last_name, user?.phone, l.zone_affectee,
        ].some(v => v?.toLowerCase().includes(search.toLowerCase()));
        return matchStatus && matchSearch;
    });

    const stats = {
        total: livreurs.length,
        disponibles: livreurs.filter(l => l.status === 'Disponible').length,
        en_livraison: livreurs.filter(l => l.status === 'En_livraison').length,
        suspendus: livreurs.filter(l => l.status === 'Suspendu').length,
    };

    const thStyle = { padding: '9px 14px', textAlign: 'left', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em', borderBottom: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow };
    const tdStyle = { padding: '12px 14px', fontSize: '13px', color: P.onSurface, borderBottom: '1px solid ' + P.surfaceContainerLow };

    return (
        <div style={{ fontFamily: 'Poppins, sans-serif' }}>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '10px', marginBottom: '18px' }}>
                <KpiCard icon={IconUser}  label="Total livreurs"  value={stats.total}        iconColor={P.primaryContainer} iconBg="rgba(201,149,46,0.15)" />
                <KpiCard icon={IconCheck} label="Disponibles"     value={stats.disponibles}  iconColor="#81c784"            iconBg="rgba(129,199,132,0.15)" />
                <KpiCard icon={IconTruck} label="En livraison"    value={stats.en_livraison} iconColor="#6aa1e3"            iconBg="rgba(106,161,227,0.15)" />
                <KpiCard icon={IconAlert} label="Suspendus"       value={stats.suspendus}    iconColor="#ef9a9a"            iconBg="rgba(239,154,154,0.15)" />
            </div>

            <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>
                <div style={{ padding: '13px 16px', borderBottom: '1px solid ' + P.surfaceContainerLow, display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
                    <div style={{ position: 'relative', flex: 1 }}>
                        <IconSearch style={{ position: 'absolute', left: '9px', top: '50%', transform: 'translateY(-50%)', width: '13px', height: '13px', color: P.outline }} />
                        <input type="text" placeholder="Rechercher par nom, téléphone, zone..." value={search} onChange={e => setSearch(e.target.value)}
                            style={{ width: '100%', padding: '8px 12px 8px 28px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', backgroundColor: P.surfaceContainerLow, boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none' }} />
                    </div>
                    <select value={filterStatus} onChange={e => setFilterStatus(e.target.value)}
                        style={{ padding: '8px 12px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, backgroundColor: P.surface, outline: 'none' }}>
                        <option value="">Tous les statuts</option>
                        <option value="Disponible">Disponible</option>
                        <option value="En_livraison">En livraison</option>
                        <option value="Suspendu">Suspendu</option>
                    </select>
                    <Link to="/livreurs/create"
                        style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '8px 16px', backgroundColor: P.primary, color: '#fff', borderRadius: '8px', textDecoration: 'none', fontSize: '12px', fontWeight: 600, whiteSpace: 'nowrap', boxShadow: '0 2px 8px rgba(125,87,0,0.2)' }}>
                        <IconUser style={{ width: '13px', height: '13px' }} />
                        Nouveau livreur
                    </Link>
                </div>

                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead><tr>
                        {['Livreur', 'Contact / CNI', 'Zone / Caution', 'Véhicule', 'Statut', ''].map(h => (
                            <th key={h} style={thStyle}>{h}</th>
                        ))}
                    </tr></thead>
                    <tbody>
                        {loading ? (
                            <tr><td colSpan={6} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>Chargement...</td></tr>
                        ) : filtered.length === 0 ? (
                            <tr><td colSpan={6} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>Aucun livreur trouvé.</td></tr>
                        ) : filtered.map(l => {
                            const sc = statusConfig[l.status] || { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, dot: P.outline, label: l.status };
                            const user = l.users || l.user; // Sécurité pour récupérer le user
                            
                            return (
                                <tr key={l.id}
                                    onMouseEnter={e => e.currentTarget.style.backgroundColor = P.surfaceContainerLow}
                                    onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}
                                    style={{ transition: 'background 0.1s', cursor: 'pointer' }}
                                    onClick={() => window.location.href = '/livreurs/' + l.id}
                                >
                                    <td style={tdStyle}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                            {/* 👇 On affiche la vraie photo si elle existe */}
                                            <div style={{ width: '36px', height: '36px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 700, color: '#fff', flexShrink: 0, overflow: 'hidden' }}>
                                                {l.photo_profil_url ? (
                                                    <img src={l.photo_profil_url} alt="profil" style={{width: '100%', height: '100%', objectFit: 'cover'}} />
                                                ) : (
                                                    user?.first_name?.[0]
                                                )}
                                            </div>
                                            <div>
                                                <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onSurface }}>{user?.first_name} {user?.last_name}</p>
                                                <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>#{String(l.id).padStart(3,'0')}</p>
                                            </div>
                                        </div>
                                    </td>
                                    <td style={tdStyle}>
                                        <p style={{ margin: 0, fontSize: '12px' }}>{user?.phone}</p>
                                        <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>{user?.email}</p>
                                        <p style={{ margin: '2px 0 0', fontSize: '11px', color: P.outlineVariant, fontWeight: 600 }}>
                                            CNI: {l.cni_numero || 'Non renseigné'}
                                        </p>
                                    </td>
                                    <td style={{ ...tdStyle, fontSize: '12px' }}>
                                        <p style={{ margin: 0 }}>{l.zone_affectee || '—'}</p>
                                        <span style={{ 
                                            display: 'inline-block', marginTop: '4px', fontSize: '10px', fontWeight: 600, 
                                            padding: '2px 6px', borderRadius: '4px',
                                            backgroundColor: l.caution_payee ? '#c8e6c9' : P.errorContainer, 
                                            color: l.caution_payee ? '#1b5e20' : P.error 
                                        }}>
                                            {l.caution_payee ? 'Caution Payée' : 'Caution Non Payée'}
                                        </span>
                                    </td>
                                    
                                    {/* 👇 On utilise les nouveaux champs véhicule directs */}
                                    <td style={{ ...tdStyle, fontSize: '12px' }}>
                                        {l.vehicule_marque || l.vehicule_type ? (
                                            <span>
                                                {l.vehicule_marque} {l.vehicule_type}
                                                <br/>
                                                <span style={{ fontSize: '10px', color: P.outline }}>{l.vehicule_immatriculation || 'Pas de plaque'}</span>
                                            </span>
                                        ) : '—'}
                                    </td>
                                    
                                    <td style={tdStyle}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                            <div style={{ width: '7px', height: '7px', borderRadius: '50%', backgroundColor: sc.dot }}></div>
                                            <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '2px 8px', borderRadius: '4px', fontSize: '10px', fontWeight: 600 }}>{sc.label}</span>
                                        </div>
                                    </td>
                                    <td style={tdStyle} onClick={e => e.stopPropagation()}>
                                        <Link to={'/livreurs/' + l.id} style={{ color: P.primary, fontWeight: 600, textDecoration: 'none', fontSize: '12px' }}>Voir</Link>
                                    </td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>
                <div style={{ padding: '11px 16px', borderTop: '1px solid ' + P.surfaceContainerLow }}>
                    <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>{filtered.length} livreur{filtered.length > 1 ? 's' : ''}</p>
                </div>
            </div>
        </div>
    );
}