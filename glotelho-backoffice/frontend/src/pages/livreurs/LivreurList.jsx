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

// ── STATUT PROFIL (administratif) ────────────────────────────
const statutProfil = {
    'Disponible':   { bg: '#e8f5e9', color: '#2e7d32', label: 'Approuvé',    dot: '#4caf50' },
    'En_livraison': { bg: '#e8f5e9', color: '#2e7d32', label: 'Approuvé',    dot: '#4caf50' },
    'Indisponible': { bg: '#fff8e1', color: '#f57f17', label: 'En attente',  dot: '#ffc107' },
    'Hors_service': { bg: P.errorContainer, color: P.error, label: 'Rejeté', dot: P.error },
    'Suspendu':     { bg: P.errorContainer, color: P.error, label: 'Suspendu',dot: P.error },
};

// ── STATUT LIVRAISON (opérationnel) ──────────────────────────
const statutLivraison = {
    'Disponible':   { bg: '#e3f2fd', color: '#1565c0', label: 'Disponible',    dot: '#42a5f5' },
    'En_livraison': { bg: P.primaryFixed, color: P.onPrimaryContainer, label: 'En livraison', dot: P.primaryContainer },
    'Indisponible': { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, label: '—', dot: P.outline },
    'Hors_service': { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, label: '—', dot: P.outline },
    'Suspendu':     { bg: P.errorContainer, color: P.error, label: 'Suspendu', dot: P.error },
};

function KpiCard({ icon: Icon, label, value, iconColor, iconBg }) {
    return (
        <div style={{ backgroundColor: P.inverseS, borderRadius: '12px', padding: '16px', display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '9px', backgroundColor: iconBg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Icon style={{ width: '17px', height: '17px', color: iconColor }} />
            </div>
            <div>
                <p style={{ margin: 0, fontSize: '22px', fontWeight: 800, color: P.inverseSOn, lineHeight: 1 }}>{value}</p>
                <p style={{ margin: '4px 0 0', fontSize: '11px', color: 'rgba(241,241,241,0.4)', fontWeight: 500 }}>{label}</p>
            </div>
        </div>
    );
}

function Badge({ config }) {
    if (!config) return <span style={{ color: P.outline, fontSize: '11px' }}>—</span>;
    return (
        <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
            <div style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: config.dot, flexShrink: 0 }}></div>
            <span style={{ backgroundColor: config.bg, color: config.color, padding: '2px 8px', borderRadius: '4px', fontSize: '10px', fontWeight: 700 }}>
                {config.label}
            </span>
        </div>
    );
}

export default function LivreurList() {
    const [livreurs, setLivreurs] = useState([]);
    const [loading, setLoading]   = useState(true);
    const [search, setSearch]     = useState('');
    const [filterProfil, setFilterProfil]       = useState('');
    const [filterLivraison, setFilterLivraison] = useState('');

    useEffect(() => {
        // Charger tous les livreurs (actifs + en attente)
        Promise.all([
            api.get('/livreurs?all=true').catch(() => ({ data: [] })),
            api.get('/profils/en-attente').catch(() => ({ data: [] })),
        ]).then(function([livrRes, profilRes]) {
            var livreurs = livrRes.data || [];
            var profils  = profilRes.data || [];

            // Fusionner — les profils en attente ne sont pas dans /livreurs
            var ids = new Set(livreurs.map(function(l) { return l.id; }));
            var profilsNouveaux = profils.filter(function(p) { return !ids.has(p.id); });
            setLivreurs([...livreurs, ...profilsNouveaux]);
        }).finally(function() { setLoading(false); });
    }, []);

    var filtered = livreurs.filter(function(l) {
        var user = l.users || l.user;
        var matchSearch = !search || [
            user?.first_name, user?.last_name, user?.prenom, user?.nom,
            user?.phone, user?.telephone, l.zone_affectee,
        ].some(function(v) { return v && v.toLowerCase().includes(search.toLowerCase()); });

        // Filtre statut profil
        var matchProfil = !filterProfil || l.status === filterProfil;

        // Filtre statut livraison
        var matchLivraison = !filterLivraison || l.status === filterLivraison;

        return matchSearch && matchProfil && matchLivraison;
    });

    var stats = {
        total       : livreurs.length,
        approuves   : livreurs.filter(function(l) { return ['Disponible','En_livraison'].includes(l.status); }).length,
        en_attente  : livreurs.filter(function(l) { return l.status === 'Indisponible'; }).length,
        en_livraison: livreurs.filter(function(l) { return l.status === 'En_livraison'; }).length,
        suspendus   : livreurs.filter(function(l) { return l.status === 'Suspendu'; }).length,
    };

    var thStyle = { padding: '9px 14px', textAlign: 'left', fontSize: '10px', fontWeight: 700, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em', borderBottom: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow };
    var tdStyle = { padding: '12px 14px', fontSize: '13px', color: P.onSurface, borderBottom: '1px solid ' + P.surfaceContainerLow };

    return (
        <div style={{ fontFamily: 'Poppins, sans-serif' }}>

            {/* KPIs */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '10px', marginBottom: '18px' }}>
                <KpiCard icon={IconUser}  label="Total livreurs"  value={stats.total}        iconColor={P.primaryContainer} iconBg="rgba(201,149,46,0.15)" />
                <KpiCard icon={IconCheck} label="Approuvés"       value={stats.approuves}    iconColor="#81c784"            iconBg="rgba(129,199,132,0.15)" />
                <KpiCard icon={IconAlert} label="En attente"      value={stats.en_attente}   iconColor="#ffc107"            iconBg="rgba(255,193,7,0.15)" />
                <KpiCard icon={IconTruck} label="En livraison"    value={stats.en_livraison} iconColor="#6aa1e3"            iconBg="rgba(106,161,227,0.15)" />
            </div>

            <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>

                {/* Barre de filtres */}
                <div style={{ padding: '13px 16px', borderBottom: '1px solid ' + P.surfaceContainerLow, display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
                    <div style={{ position: 'relative', flex: 1, minWidth: '200px' }}>
                        <IconSearch style={{ position: 'absolute', left: '9px', top: '50%', transform: 'translateY(-50%)', width: '13px', height: '13px', color: P.outline }} />
                        <input type="text" placeholder="Rechercher nom, téléphone, zone..." value={search}
                            onChange={function(e) { setSearch(e.target.value); }}
                            style={{ width: '100%', padding: '8px 12px 8px 28px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', backgroundColor: P.surfaceContainerLow, fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none', boxSizing: 'border-box' }} />
                    </div>

                    {/* Filtre statut profil */}
                    <select value={filterProfil} onChange={function(e) { setFilterProfil(e.target.value); }}
                        style={{ padding: '8px 12px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, backgroundColor: P.surface, outline: 'none' }}>
                        <option value="">Statut profil</option>
                        <option value="Disponible">Approuvé</option>
                        <option value="Indisponible">En attente</option>
                        <option value="Hors_service">Rejeté</option>
                        <option value="Suspendu">Suspendu</option>
                    </select>

                    {/* Filtre statut livraison */}
                    <select value={filterLivraison} onChange={function(e) { setFilterLivraison(e.target.value); }}
                        style={{ padding: '8px 12px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, backgroundColor: P.surface, outline: 'none' }}>
                        <option value="">Statut livraison</option>
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

                {/* Tableau */}
                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead>
                        <tr>
                            <th style={thStyle}>Livreur</th>
                            <th style={thStyle}>Contact</th>
                            <th style={thStyle}>Zone / Caution</th>
                            <th style={thStyle}>Véhicule</th>
                            <th style={{ ...thStyle, borderLeft: '2px solid ' + P.primaryFixed }}>
                                Statut Profil
                                <div style={{ fontSize: '9px', fontWeight: 400, color: P.outlineVariant, textTransform: 'none', marginTop: '1px' }}>Validation dossier</div>
                            </th>
                            <th style={{ ...thStyle, borderLeft: '1px solid ' + P.outlineVariant }}>
                                Statut Livraison
                                <div style={{ fontSize: '9px', fontWeight: 400, color: P.outlineVariant, textTransform: 'none', marginTop: '1px' }}>Disponibilité opérationnelle</div>
                            </th>
                            <th style={thStyle}></th>
                        </tr>
                    </thead>
                    <tbody>
                        {loading ? (
                            <tr><td colSpan={7} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>Chargement...</td></tr>
                        ) : filtered.length === 0 ? (
                            <tr><td colSpan={7} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>Aucun livreur trouvé.</td></tr>
                        ) : filtered.map(function(l) {
                            var user = l.users || l.user;
                            var p    = Array.isArray(l.photos) ? l.photos[0] : l.photos;
                            var photoUrl = l.photo_profil_url || l.photo_profil || (p && (p.photo_profil_url || p.photo_profil));

                            var sprofil    = statutProfil[l.status]    || { bg: P.surfaceContainerHigh, color: P.outline, label: l.status || '—', dot: P.outline };
                            var slivraison = statutLivraison[l.status] || { bg: P.surfaceContainerHigh, color: P.outline, label: '—', dot: P.outline };

                            // Lien — profils en attente → /livreurs/profils/:id, autres → /livreurs/:id
                            var lien = l.status === 'Indisponible' ? '/livreurs/profils/' + l.id : '/livreurs/' + l.id;

                            return (
                                <tr key={l.id}
                                    onMouseEnter={function(e) { e.currentTarget.style.backgroundColor = P.surfaceContainerLow; }}
                                    onMouseLeave={function(e) { e.currentTarget.style.backgroundColor = 'transparent'; }}
                                    style={{ transition: 'background 0.1s', cursor: 'pointer' }}
                                    onClick={function() { window.location.href = lien; }}
                                >
                                    {/* Livreur */}
                                    <td style={tdStyle}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                            <div style={{ width: '36px', height: '36px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 700, color: '#fff', flexShrink: 0, overflow: 'hidden' }}>
                                                {photoUrl
                                                    ? <img src={photoUrl} alt="profil" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                                                    : (user && (user.first_name || user.prenom) ? (user.first_name || user.prenom)[0] : 'L')
                                                }
                                            </div>
                                            <div>
                                                <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onSurface }}>
                                                    {(user && (user.first_name || user.prenom)) || ''} {(user && (user.last_name || user.nom)) || ''}
                                                </p>
                                                <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>#{String(l.id).padStart(3,'0')}</p>
                                            </div>
                                        </div>
                                    </td>

                                    {/* Contact */}
                                    <td style={tdStyle}>
                                        <p style={{ margin: 0, fontSize: '12px' }}>{(user && (user.phone || user.telephone)) || '—'}</p>
                                        <p style={{ margin: '2px 0 0', fontSize: '11px', color: P.outline }}>{(user && user.email) || '—'}</p>
                                    </td>

                                    {/* Zone / Caution */}
                                    <td style={{ ...tdStyle, fontSize: '12px' }}>
                                        <p style={{ margin: 0 }}>{l.zone_affectee || '—'}</p>
                                        <span style={{ display: 'inline-block', marginTop: '4px', fontSize: '10px', fontWeight: 600, padding: '2px 6px', borderRadius: '4px', backgroundColor: l.caution_payee ? '#c8e6c9' : P.errorContainer, color: l.caution_payee ? '#1b5e20' : P.error }}>
                                            {l.caution_payee ? 'Caution payée' : 'Caution due'}
                                        </span>
                                    </td>

                                    {/* Véhicule */}
                                    <td style={{ ...tdStyle, fontSize: '12px' }}>
                                        {(function() {
                                            var veh    = Array.isArray(l.vehicules) ? l.vehicules[0] : l.vehicules;
                                            var vMarque = l.vehicule_marque || (veh && (veh.brand || veh.marque)) || '';
                                            var vType   = l.vehicule_type   || (veh && veh.type) || '';
                                            var vPlaque = l.vehicule_immatriculation || (veh && (veh.plate_number || veh.immatriculation)) || '';
                                            return vMarque || vType ? (
                                                <span>
                                                    {vMarque} {vType}
                                                    <br/>
                                                    <span style={{ fontSize: '10px', color: P.outline }}>{vPlaque || '—'}</span>
                                                </span>
                                            ) : <span style={{ color: P.outline }}>—</span>;
                                        })()}
                                    </td>

                                    {/* Statut Profil */}
                                    <td style={{ ...tdStyle, borderLeft: '2px solid ' + P.primaryFixed }}>
                                        <Badge config={sprofil} />
                                    </td>

                                    {/* Statut Livraison */}
                                    <td style={{ ...tdStyle, borderLeft: '1px solid ' + P.outlineVariant }}>
                                        {['Disponible','En_livraison'].includes(l.status)
                                            ? <Badge config={slivraison} />
                                            : <span style={{ fontSize: '11px', color: P.outlineVariant, fontStyle: 'italic' }}>Non actif</span>
                                        }
                                    </td>

                                    {/* Actions */}
                                    <td style={tdStyle} onClick={function(e) { e.stopPropagation(); }}>
                                        {l.status === 'Indisponible' ? (
                                            <Link to={'/livreurs/profils/' + l.id}
                                                style={{ color: '#f57f17', fontWeight: 700, textDecoration: 'none', fontSize: '11px', backgroundColor: '#fff8e1', padding: '3px 8px', borderRadius: '4px', border: '1px solid #ffe082' }}>
                                                Valider
                                            </Link>
                                        ) : (
                                            <Link to={'/livreurs/' + l.id}
                                                style={{ color: P.primary, fontWeight: 600, textDecoration: 'none', fontSize: '12px' }}>
                                                Voir
                                            </Link>
                                        )}
                                    </td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>

                <div style={{ padding: '11px 16px', borderTop: '1px solid ' + P.surfaceContainerLow, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>{filtered.length} livreur{filtered.length > 1 ? 's' : ''}</p>
                    <div style={{ display: 'flex', gap: '16px', fontSize: '10px', color: P.outline }}>
                        <span>🟡 En attente : {stats.en_attente}</span>
                        <span>🟢 Approuvés : {stats.approuves}</span>
                        <span>🔵 En livraison : {stats.en_livraison}</span>
                        <span>🔴 Suspendus : {stats.suspendus}</span>
                    </div>
                </div>
            </div>
        </div>
    );
}