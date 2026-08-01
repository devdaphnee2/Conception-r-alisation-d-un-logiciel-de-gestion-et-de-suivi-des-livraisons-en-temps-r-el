import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import api from '../../services/api';
import { IconPackage, IconSearch, IconCheck, IconClock, IconAlert, IconTruck } from '../../components/Icons';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    primaryFixed: '#ffdea9', onPrimaryContainer: '#483100',
    secondary: '#475e8b', secondaryContainer: '#b5ccff', onSecondaryContainer: '#3e5682',
    tertiary: '#20619e', tertiaryContainer: '#6aa1e3', onTertiaryContainer: '#003762',
    error: '#ba1a1a', errorContainer: '#ffdad6', onErrorContainer: '#93000a',
    surface: '#ffffff', surfaceContainerLow: '#f3f3f3', surfaceContainerHigh: '#e8e8e8',
    inverseS: '#2f3131', inverseSOn: '#f1f1f1',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
};

const statusConfig = {
    'En_attente': { bg: P.primaryFixed,        color: P.onPrimaryContainer,   label: 'En attente' },
    'Assign_':    { bg: P.secondaryContainer,   color: P.onSecondaryContainer, label: 'Assigne' },
    'Valide_':    { bg: '#c8e6c9',              color: '#1b5e20',              label: 'Validee' },
    'En_cours':   { bg: P.tertiaryContainer,    color: P.onTertiaryContainer,  label: 'En cours' },
    'Livr_':      { bg: '#c8e6c9',              color: '#1b5e20',              label: 'Livre' },
    'Suspendu':   { bg: P.errorContainer,       color: P.onErrorContainer,     label: 'Suspendu' },
    'Annul_':     { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant,     label: 'Annule' },
};

const acceptConfig = {
    'accepte':    { bg: '#c8e6c9', color: '#1b5e20', label: 'Accepté',    dot: '#4caf50' },
    'refuse':     { bg: P.errorContainer, color: P.error, label: 'Refusé', dot: P.error },
    'en_attente': { bg: P.primaryFixed, color: P.onPrimaryContainer, label: 'En attente', dot: P.primaryContainer },
    'non_assigne':{ bg: P.surfaceContainerHigh, color: P.outline, label: '—', dot: P.outline },
};

function getAcceptStatus(livraison) {
    if (!livraison.delivery_person_id) return 'non_assigne';
    if (['Valide_', 'En_cours', 'Livr_'].includes(livraison.status)) return 'accepte';
    if (livraison.status === 'Annul_') return 'refuse';
    if (livraison.status === 'Assign_') return 'en_attente';
    if (livraison.status === 'En_attente') return 'non_assigne';
    return 'en_attente';
}

// Récupère le nom du livreur, quelle que soit la forme retournée par l'API
// (users peut être un objet OU un tableau selon la route/l'inclusion Prisma)
function getLivreurNom(l) {
    if (!l.delivery_persons) return '';
    var dp = l.delivery_persons;
    var u = null;
    if (Array.isArray(dp.users)) {
        u = dp.users.find(function(x) { return x.id === dp.user_id; }) || dp.users[0] || null;
    } else if (dp.users && typeof dp.users === 'object') {
        u = dp.users;
    } else if (dp.user) {
        u = dp.user;
    }
    return u ? (u.first_name + ' ' + u.last_name) : '';
}

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

export default function LivraisonList() {
    const [livraisons, setLivraisons] = useState([]);
    const [loading, setLoading]       = useState(true);
    const [search, setSearch]         = useState('');
    const [filterStatus, setFilterStatus]   = useState('');
    const [filterAccept, setFilterAccept]   = useState('');
    const [error, setError]           = useState('');
    const [vue, setVue]               = useState('actives');

    useEffect(function() {
        function charger() {
            api.get('/livraisons')
                .then(function(res) { setLivraisons(res.data); })
                .catch(function() { setError('Impossible de charger les livraisons.'); })
                .finally(function() { setLoading(false); });
        }
        charger();
        // Rafraîchit automatiquement toutes les 8s pour refléter les
        // changements faits côté livreur (acceptation, démarrage, etc.)
        // sans que le manager ait besoin de recharger la page manuellement.
        var interval = setInterval(charger, 8000);
        return function() { clearInterval(interval); };
    }, []);

    var STATUTS_ARCHIVES = ['Livr_', 'Annul_'];

    var livraisonsVue = livraisons.filter(function(l) {
        return vue === 'archivees'
            ? STATUTS_ARCHIVES.includes(l.status)
            : !STATUTS_ARCHIVES.includes(l.status);
    });

    var searchLower = search.trim().toLowerCase();

    var filtered = livraisonsVue.filter(function(l) {
        var matchStatus = !filterStatus || l.status === filterStatus;
        var matchAccept = !filterAccept || getAcceptStatus(l) === filterAccept;

        if (!searchLower) return matchStatus && matchAccept;

        var clientNom = l.client_nom || ((l.customers && l.customers.users) ? l.customers.users.first_name + ' ' + l.customers.users.last_name : '');
        var livreurNom = getLivreurNom(l);

        var champs = [
            clientNom,
            livreurNom,
            l.delivery_address,
            l.client_telephone,
            '#' + String(l.id).padStart(5, '0'),
            String(l.id),
        ];

        var matchSearch = champs.some(function(v) {
            return v && String(v).toLowerCase().includes(searchLower);
        });

        return matchStatus && matchAccept && matchSearch;
    });

    var stats = {
        total      : livraisons.length,
        en_attente : livraisons.filter(function(l) { return l.status === 'En_attente'; }).length,
        en_cours   : livraisons.filter(function(l) { return l.status === 'En_cours'; }).length,
        livrees    : livraisons.filter(function(l) { return l.status === 'Livr_'; }).length,
        suspendues : livraisons.filter(function(l) { return l.status === 'Suspendu'; }).length,
    };

    var thStyle = { padding: '9px 14px', textAlign: 'left', fontSize: '10px', fontWeight: 600, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.08em', borderBottom: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, whiteSpace: 'nowrap' };
    var tdStyle = { padding: '12px 14px', fontSize: '13px', color: P.onSurface, borderBottom: '1px solid ' + P.surfaceContainerLow };

    return (
        <div style={{ fontFamily: 'Poppins, sans-serif' }}>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: '10px', marginBottom: '18px' }}>
                <KpiCard icon={IconPackage} label="Total"      value={stats.total}      iconColor={P.primaryContainer} iconBg="rgba(201,149,46,0.15)" />
                <KpiCard icon={IconClock}   label="En attente" value={stats.en_attente} iconColor={P.primaryContainer} iconBg="rgba(201,149,46,0.1)" />
                <KpiCard icon={IconTruck}   label="En cours"   value={stats.en_cours}   iconColor="#6aa1e3"            iconBg="rgba(106,161,227,0.15)" />
                <KpiCard icon={IconCheck}   label="Livrees"    value={stats.livrees}    iconColor="#81c784"            iconBg="rgba(129,199,132,0.15)" />
                <KpiCard icon={IconAlert}   label="Suspendues" value={stats.suspendues} iconColor="#ef9a9a"            iconBg="rgba(239,154,154,0.15)" />
            </div>

            {error && <div style={{ backgroundColor: P.errorContainer, color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px' }}>{error}</div>}

            <div style={{ display: 'flex', gap: '8px', marginBottom: '14px' }}>
                <button onClick={function() { setVue('actives'); }}
                    style={{
                        padding: '8px 18px', borderRadius: '8px', border: 'none', cursor: 'pointer',
                        fontSize: '12px', fontWeight: 700, fontFamily: 'Poppins, sans-serif',
                        backgroundColor: vue === 'actives' ? P.primary : P.surfaceContainerLow,
                        color: vue === 'actives' ? '#fff' : P.outline,
                    }}>
                    📦 Livraisons actives ({livraisons.filter(function(l) { return !['Livr_','Annul_'].includes(l.status); }).length})
                </button>
                <button onClick={function() { setVue('archivees'); }}
                    style={{
                        padding: '8px 18px', borderRadius: '8px', border: 'none', cursor: 'pointer',
                        fontSize: '12px', fontWeight: 700, fontFamily: 'Poppins, sans-serif',
                        backgroundColor: vue === 'archivees' ? P.primary : P.surfaceContainerLow,
                        color: vue === 'archivees' ? '#fff' : P.outline,
                    }}>
                    🗄️ Archivées ({livraisons.filter(function(l) { return ['Livr_','Annul_'].includes(l.status); }).length})
                </button>
            </div>

            <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>

                <div style={{ padding: '13px 16px', borderBottom: '1px solid ' + P.surfaceContainerLow, display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
                    <div style={{ position: 'relative', flex: 1, minWidth: '200px' }}>
                        <IconSearch style={{ position: 'absolute', left: '9px', top: '50%', transform: 'translateY(-50%)', width: '13px', height: '13px', color: P.outline }} />
                        <input type="text" placeholder="Rechercher client, livreur, adresse, numero..." value={search}
                            onChange={function(e) { setSearch(e.target.value); }}
                            style={{ width: '100%', padding: '8px 12px 8px 28px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', backgroundColor: P.surfaceContainerLow, boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none' }} />
                    </div>
                    <select value={filterStatus} onChange={function(e) { setFilterStatus(e.target.value); }}
                        style={{ padding: '8px 12px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, backgroundColor: P.surface, outline: 'none' }}>
                        <option value="">Tous statuts</option>
                        <option value="En_attente">En attente</option>
                        <option value="Assign_">Assigne</option>
                        <option value="Valide_">Validee</option>
                        <option value="En_cours">En cours</option>
                        <option value="Livr_">Livre</option>
                        <option value="Suspendu">Suspendu</option>
                        <option value="Annul_">Annule</option>
                    </select>
                    <select value={filterAccept} onChange={function(e) { setFilterAccept(e.target.value); }}
                        style={{ padding: '8px 12px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', fontFamily: 'Poppins, sans-serif', color: P.onSurface, backgroundColor: P.surface, outline: 'none' }}>
                        <option value="">Réponse livreur</option>
                        <option value="accepte">Accepté</option>
                        <option value="en_attente">En attente réponse</option>
                        <option value="refuse">Refusé</option>
                        <option value="non_assigne">Non assigné</option>
                    </select>
                    <Link to="/livraisons/create"
                        style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '8px 16px', backgroundColor: P.primary, color: '#fff', borderRadius: '8px', textDecoration: 'none', fontSize: '12px', fontWeight: 600, whiteSpace: 'nowrap', boxShadow: '0 2px 8px rgba(125,87,0,0.2)' }}>
                        <IconPackage style={{ width: '13px', height: '13px' }} />
                        Nouvelle livraison
                    </Link>
                </div>

                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead>
                        <tr>
                            <th style={thStyle}>ID</th>
                            <th style={thStyle}>Client</th>
                            <th style={thStyle}>Livreur</th>
                            <th style={thStyle}>Adresse</th>
                            <th style={thStyle}>Montant</th>
                            <th style={thStyle}>Statut livraison</th>
                            <th style={{ ...thStyle, borderLeft: '2px solid ' + P.primaryFixed }}>
                                Réponse livreur
                                <div style={{ fontSize: '9px', fontWeight: 400, color: P.outlineVariant, textTransform: 'none', marginTop: '1px' }}>Acceptation de la course</div>
                            </th>
                            <th style={thStyle}>Date</th>
                            <th style={thStyle}></th>
                        </tr>
                    </thead>
                    <tbody>
                        {loading ? (
                            <tr><td colSpan={9} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>Chargement...</td></tr>
                        ) : filtered.length === 0 ? (
                            <tr><td colSpan={9} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>Aucune livraison trouvee.</td></tr>
                        ) : filtered.map(function(l) {
                            var sc = statusConfig[l.status] || { bg: P.surfaceContainerHigh, color: P.onSurfaceVariant, label: l.status };
                            var acceptKey = getAcceptStatus(l);
                            var ac = acceptConfig[acceptKey];
                            var clientNom = l.client_nom || ((l.customers && l.customers.users) ? l.customers.users.first_name + ' ' + l.customers.users.last_name : '—');
                            var clientTel = l.client_telephone || ((l.customers && l.customers.users) ? l.customers.users.phone : '');
                            var clientInit = clientNom[0] || '?';
                            var livreurNom   = getLivreurNom(l) || null;
                            var livreurPhoto = l.delivery_persons ? l.delivery_persons.photo_profil_url : null;

                            return (
                                <tr key={l.id}
                                    onMouseEnter={function(e) { e.currentTarget.style.backgroundColor = P.surfaceContainerLow; }}
                                    onMouseLeave={function(e) { e.currentTarget.style.backgroundColor = 'transparent'; }}
                                    style={{ transition: 'background 0.1s', cursor: 'pointer' }}
                                    onClick={function() { window.location.href = '/livraisons/' + l.id; }}
                                >
                                    <td style={{ ...tdStyle, fontWeight: 700, color: P.primary }}>
                                        #{String(l.id).padStart(5,'0')}
                                    </td>

                                    <td style={tdStyle}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                            <div style={{ width: '26px', height: '26px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '10px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>
                                                {clientInit}
                                            </div>
                                            <div>
                                                <p style={{ margin: 0, fontSize: '12px', fontWeight: 500 }}>{clientNom}</p>
                                                <p style={{ margin: 0, fontSize: '10px', color: P.outline }}>{clientTel}</p>
                                            </div>
                                        </div>
                                    </td>

                                    <td style={tdStyle}>
                                        {livreurNom ? (
                                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                                <div style={{ width: '26px', height: '26px', borderRadius: '50%', overflow: 'hidden', flexShrink: 0, backgroundColor: P.primary }}>
                                                    {livreurPhoto
                                                        ? <img src={livreurPhoto} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                                                        : <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '10px', fontWeight: 700, color: '#fff' }}>{livreurNom[0]}</div>
                                                    }
                                                </div>
                                                <span style={{ fontSize: '12px' }}>{livreurNom}</span>
                                            </div>
                                        ) : <span style={{ color: P.outlineVariant, fontStyle: 'italic', fontSize: '12px' }}>Non assigne</span>}
                                    </td>

                                    <td style={{ ...tdStyle, color: P.onSurfaceVariant, maxWidth: '140px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', fontSize: '12px' }}>
                                        {l.delivery_address}
                                    </td>

                                    <td style={{ ...tdStyle, fontWeight: 700, color: P.primary, whiteSpace: 'nowrap', fontSize: '12px' }}>
                                        {l.amount_to_collect ? Number(l.amount_to_collect).toLocaleString('fr-FR') + ' F' : '—'}
                                    </td>

                                    <td style={tdStyle}>
                                        <span style={{ backgroundColor: sc.bg, color: sc.color, padding: '3px 8px', borderRadius: '5px', fontSize: '10px', fontWeight: 600 }}>
                                            {sc.label}
                                        </span>
                                    </td>

                                    <td style={{ ...tdStyle, borderLeft: '2px solid ' + P.primaryFixed }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                                            <div style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: ac.dot, flexShrink: 0 }}></div>
                                            <span style={{ backgroundColor: ac.bg, color: ac.color, padding: '2px 8px', borderRadius: '4px', fontSize: '10px', fontWeight: 700 }}>
                                                {ac.label}
                                            </span>
                                        </div>
                                    </td>

                                    <td style={{ ...tdStyle, color: P.outline, fontSize: '11px', whiteSpace: 'nowrap' }}>
                                        {l.creation_date ? new Date(l.creation_date).toLocaleDateString('fr-FR') : '—'}
                                    </td>

                                    <td style={tdStyle} onClick={function(e) { e.stopPropagation(); }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                            <Link to={'/livraisons/' + l.id}
                                                style={{ color: P.primary, fontWeight: 600, textDecoration: 'none', fontSize: '12px' }}>
                                                Voir
                                            </Link>
                                            {['Assign_', 'Valide_', 'En_cours'].includes(l.status) && (
                                                <Link to={'/tracking'}
                                                    style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', padding: '3px 8px', borderRadius: '5px', backgroundColor: '#2f3131', color: '#fff', textDecoration: 'none', fontSize: '10px', fontWeight: 600, whiteSpace: 'nowrap' }}>
                                                    📍 Tracking
                                                </Link>
                                            )}
                                        </div>
                                    </td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>

                <div style={{ padding: '11px 16px', borderTop: '1px solid ' + P.surfaceContainerLow, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>{filtered.length} livraison{filtered.length > 1 ? 's' : ''}</p>
                    <div style={{ display: 'flex', gap: '14px', fontSize: '10px', color: P.outline }}>
                        <span>🟡 En attente : {stats.en_attente}</span>
                        <span>🔵 En cours : {stats.en_cours}</span>
                        <span>🟢 Livrées : {stats.livrees}</span>
                        <span>🔴 Suspendues : {stats.suspendues}</span>
                    </div>
                </div>
            </div>
        </div>
    );
}