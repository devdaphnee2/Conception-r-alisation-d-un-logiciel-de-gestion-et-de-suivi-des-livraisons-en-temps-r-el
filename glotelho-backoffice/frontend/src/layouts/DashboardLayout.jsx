import { useState, useCallback, useEffect, useRef } from 'react';
import { Outlet, NavLink, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import api from '../services/api';
import {
    IconDashboard, IconPackage, IconMap, IconTruck,
    IconAlert, IconLogout, IconBell, IconSearch, IconUser, IconCheck
} from '../components/Icons';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    primaryFixed: '#ffdea9', onPrimaryContainer: '#483100',
    error: '#ba1a1a', errorContainer: '#ffdad6',
    surface: '#ffffff', surfaceContainerLow: '#f3f3f3',
    inverseS: '#2f3131', inverseSOn: '#f1f1f1',
    onSurface: '#1a1c1c', outline: '#817564', outlineVariant: '#d3c4b0',
};

function IconOrders({ style }) {
    return (
        <svg style={style} fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth="1.8">
            <path strokeLinecap="round" strokeLinejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
            <path strokeLinecap="round" strokeLinejoin="round" d="M9 12h6M9 16h4"/>
        </svg>
    );
}
function IconMoney({ style }) {
    return (
        <svg style={style} fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth="1.8">
            <path strokeLinecap="round" strokeLinejoin="round" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
        </svg>
    );
}
function IconSettings({ style }) {
    return (
        <svg style={style} fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth="1.8">
            <path strokeLinecap="round" strokeLinejoin="round" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/>
            <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
        </svg>
    );
}

const pageTitles = {
    '/dashboard':        'Tableau de bord',
    '/tracking':         'Tracking GPS temps reel',
    '/commandes':        'Commandes',
    '/recouvrements':    'Recouvrements',
    '/livraisons':       'Livraisons',
    '/livreurs':         'Livreurs',
    '/livreurs/profils': 'Validation des profils',
    '/litiges':          'Litiges',
    '/parametres':       'Parametres du compte',
};

// Mapping type d'alerte -> icone/couleur pour affichage notification
const NOTIF_STYLE = {
    litige:        { color: '#ba1a1a', label: 'Litige' },
    profil:        { color: '#c9952e', label: 'Profil livreur' },
    incident:      { color: '#ba1a1a', label: 'Incident' },
    recouvrement:  { color: '#c9952e', label: 'Recouvrement' },
    livraison:     { color: '#4caf50', label: 'Livraison' },
};

export default function DashboardLayout() {
    const { user, logout } = useAuth();
    const location = useLocation();
    const navigate = useNavigate();
    const [search, setSearch] = useState('');
    const [showNotifs, setShowNotifs] = useState(false);
    const [showUserMenu, setShowUserMenu] = useState(false);
    const [notifications, setNotifications] = useState([]);
    const notifRef = useRef(null);
    const userMenuRef = useRef(null);

    const pageTitle = Object.entries(pageTitles).find(([path]) =>
        location.pathname === path || (path !== '/dashboard' && location.pathname.startsWith(path))
    )?.[1] || 'Glotelho';

    // ── Chargement des alertes reelles depuis l'API ──────────
    // Construit une liste de notifications cliquables a partir des
    // donnees reelles (litiges ouverts, profils en attente, incidents...)
    useEffect(() => {
        function chargerNotifications() {
            Promise.all([
                api.get('/litiges').catch(() => ({ data: [] })),
                api.get('/profils/en-attente').catch(() => ({ data: [] })),
                api.get('/livraisons').catch(() => ({ data: [] })),
                api.get('/recouvrements').catch(() => ({ data: [] })),
            ]).then(([litiges, profils, livraisons, recouvrements]) => {
                const notifs = [];

                // Litiges non traites
                (litiges.data || []).filter(l => l.status === 'En_attente').slice(0, 5).forEach(l => {
                    notifs.push({
                        id: 'litige-' + l.id,
                        type: 'litige',
                        msg: 'Litige #' + l.id + ' non traite',
                        sub: l.orders?.customers?.users?.first_name ? 'Client : ' + l.orders.customers.users.first_name : '',
                        to: '/litiges/' + l.id,
                        date: l.created_at,
                    });
                });

                // Profils livreur en attente
                (profils.data || []).slice(0, 5).forEach(p => {
                    notifs.push({
                        id: 'profil-' + p.id,
                        type: 'profil',
                        msg: 'Nouveau profil livreur : ' + (p.users?.first_name || '') + ' ' + (p.users?.last_name || ''),
                        sub: 'En attente de validation',
                        to: '/livreurs/profils/' + p.id,
                        date: p.date_candidature,
                    });
                });

                // Livraisons suspendues (incidents)
                (livraisons.data || []).filter(l => l.status === 'Suspendu').slice(0, 5).forEach(l => {
                    notifs.push({
                        id: 'incident-' + l.id,
                        type: 'incident',
                        msg: 'Livraison #' + String(l.id).padStart(5, '0') + ' suspendue',
                        sub: l.suspension_reason || 'Incident signale',
                        to: '/livraisons/' + l.id,
                        date: l.creation_date,
                    });
                });

                // Dettes non recouvrees
                (recouvrements.data || []).filter(r => Number(r.amount_collected || 0) < Number(r.amount_to_collect || 0)).slice(0, 3).forEach(r => {
                    notifs.push({
                        id: 'recouvrement-' + r.id,
                        type: 'recouvrement',
                        msg: 'Dette livreur : ' + (r.delivery_persons?.users?.first_name || '') + ' ' + (r.delivery_persons?.users?.last_name || ''),
                        sub: (Number(r.amount_to_collect) - Number(r.amount_collected || 0)).toLocaleString('fr-FR') + ' FCFA restants',
                        to: '/recouvrements',
                        date: null,
                    });
                });

                // Tri par date recente d'abord (si disponible)
                notifs.sort((a, b) => {
                    if (!a.date) return 1;
                    if (!b.date) return -1;
                    return new Date(b.date) - new Date(a.date);
                });

                setNotifications(notifs.slice(0, 10));
            });
        }

        chargerNotifications();
        // Rafraichir toutes les 60s
        const interval = setInterval(chargerNotifications, 60000);
        return () => clearInterval(interval);
    }, []);

    // Fermer les dropdowns en cliquant ailleurs
    useEffect(() => {
        function handleClickOutside(e) {
            if (notifRef.current && !notifRef.current.contains(e.target)) setShowNotifs(false);
            if (userMenuRef.current && !userMenuRef.current.contains(e.target)) setShowUserMenu(false);
        }
        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    // Recherche globale
    const handleSearch = useCallback((e) => {
        if (e.key === 'Enter' && search.trim()) {
            const q = search.trim().toLowerCase();
            if (q.startsWith('#') || /^\d+$/.test(q)) {
                navigate('/livraisons/' + q.replace('#', ''));
            } else if (q.match(/^6\d{8}$/)) {
                navigate('/livreurs?q=' + encodeURIComponent(q));
            } else {
                navigate('/commandes?q=' + encodeURIComponent(q));
            }
            setSearch('');
        }
    }, [search, navigate]);

    // Clic sur une notification -> redirige vers l'interface correspondante
    function handleNotifClick(notif) {
        setShowNotifs(false);
        navigate(notif.to);
    }

    const navLinks = [
        { to: '/dashboard',     label: 'Dashboard',  icon: IconDashboard },
        { to: '/commandes',     label: 'Commandes',  icon: IconOrders },
        { to: '/livraisons',    label: 'Livraisons', icon: IconPackage },
        { to: '/tracking',      label: 'Tracking',   icon: IconMap },
        {
            label: 'Livreurs', icon: IconTruck,
            children: [
                { to: '/livreurs',         label: 'Liste livreurs' },
                { to: '/livreurs/profils', label: 'Profils en attente' },
            ]
        },
        { to: '/litiges',       label: 'Litiges',       icon: IconAlert },
        { to: '/recouvrements', label: 'Recouvrements', icon: IconMoney },
    ];

    function isActive(link) {
        if (link.to) return location.pathname === link.to || (link.to !== '/dashboard' && location.pathname.startsWith(link.to));
        if (link.children) return link.children.some(c => location.pathname === c.to || location.pathname.startsWith(c.to + '/'));
        return false;
    }

    function navStyle(active) {
        return {
            display: 'flex', alignItems: 'center', gap: '9px', padding: '9px 10px',
            borderRadius: '8px', fontSize: '13px', textDecoration: 'none',
            fontWeight: active ? 600 : 400,
            backgroundColor: active ? 'rgba(201,149,46,0.16)' : 'transparent',
            color: active ? P.primaryContainer : 'rgba(241,241,241,0.5)',
            borderLeft: active ? '3px solid ' + P.primaryContainer : '3px solid transparent',
            transition: 'all 0.15s',
        };
    }

    return (
        <div style={{ display: 'flex', minHeight: '100vh', backgroundColor: '#f9f9f9', fontFamily: 'Poppins, sans-serif' }}>

            {/* SIDEBAR */}
            <aside style={{ position: 'fixed', left: 0, top: 0, zIndex: 20, display: 'flex', flexDirection: 'column', height: '100vh', width: '220px', backgroundColor: P.inverseS }}>
                <div style={{ padding: '20px 16px', borderBottom: '1px solid rgba(241,241,241,0.07)' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <div style={{ width: '34px', height: '34px', backgroundColor: P.surface, borderRadius: '8px', padding: '4px', flexShrink: 0 }}>
                            <img src="/logo_glotelho.png" alt="Glotelho" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                        </div>
                        <div>
                            <p style={{ margin: 0, fontWeight: 700, fontSize: '14px', color: P.inverseSOn }}>Glotelho</p>
                            <p style={{ margin: 0, fontSize: '9px', color: 'rgba(241,241,241,0.3)', textTransform: 'uppercase', letterSpacing: '0.1em' }}>Back-office</p>
                        </div>
                    </div>
                </div>

                <nav style={{ flex: 1, padding: '14px 10px', display: 'flex', flexDirection: 'column', gap: '2px', overflowY: 'auto' }}>
                    <p style={{ fontSize: '9px', fontWeight: 600, color: 'rgba(241,241,241,0.25)', textTransform: 'uppercase', letterSpacing: '0.12em', padding: '0 8px', marginBottom: '8px' }}>Menu</p>
                    {navLinks.map((link, i) => {
                        const active = isActive(link);
                        if (link.children) {
                            const Icon = link.icon;
                            return (
                                <div key={i}>
                                    {/* Le parent ne change JAMAIS de couleur — purement decoratif/groupe */}
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '9px', padding: '9px 10px', fontSize: '13px', fontWeight: 400, color: 'rgba(241,241,241,0.5)' }}>
                                        <Icon style={{ width: '15px', height: '15px', flexShrink: 0 }} />
                                        {link.label}
                                    </div>
                                    {link.children.map(child => {
                                        const ca = location.pathname === child.to || location.pathname.startsWith(child.to + '/');
                                        return (
                                            <NavLink key={child.to} to={child.to}
                                                style={{ display: 'block', padding: '7px 10px 7px 34px', borderRadius: '8px', fontSize: '12px', fontWeight: ca ? 600 : 400, textDecoration: 'none', backgroundColor: ca ? 'rgba(201,149,46,0.16)' : 'transparent', color: ca ? P.primaryContainer : 'rgba(241,241,241,0.45)', borderLeft: ca ? '3px solid ' + P.primaryContainer : '3px solid transparent', transition: 'all 0.15s' }}
                                                onMouseEnter={e => { if (!ca) { e.currentTarget.style.backgroundColor = 'rgba(241,241,241,0.06)'; e.currentTarget.style.color = P.inverseSOn; }}}
                                                onMouseLeave={e => { if (!ca) { e.currentTarget.style.backgroundColor = 'transparent'; e.currentTarget.style.color = 'rgba(241,241,241,0.45)'; }}}
                                            >
                                                {child.label}
                                            </NavLink>
                                        );
                                    })}
                                </div>
                            );
                        }
                        const Icon = link.icon;
                        return (
                            <NavLink key={link.to} to={link.to} style={navStyle(active)}
                                onMouseEnter={e => { if (!active) { e.currentTarget.style.backgroundColor = 'rgba(241,241,241,0.06)'; e.currentTarget.style.color = P.inverseSOn; }}}
                                onMouseLeave={e => { if (!active) { e.currentTarget.style.backgroundColor = 'transparent'; e.currentTarget.style.color = 'rgba(241,241,241,0.5)'; }}}
                            >
                                <Icon style={{ width: '15px', height: '15px', flexShrink: 0 }} />
                                {link.label}
                            </NavLink>
                        );
                    })}
                </nav>

                {/* Bloc utilisateur avec menu (Parametres + Deconnexion) */}
                <div ref={userMenuRef} style={{ padding: '12px 10px', borderTop: '1px solid rgba(241,241,241,0.07)', position: 'relative' }}>
                    <button onClick={() => setShowUserMenu(!showUserMenu)}
                        style={{ width: '100%', display: 'flex', alignItems: 'center', gap: '9px', padding: '8px 10px', borderRadius: '8px', backgroundColor: 'rgba(241,241,241,0.05)', marginBottom: '6px', border: 'none', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}>
                        <div style={{ width: '30px', height: '30px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>{user?.first_name?.[0]}</div>
                        <div style={{ minWidth: 0, flex: 1, textAlign: 'left' }}>
                            <p style={{ margin: 0, fontSize: '12px', fontWeight: 600, color: P.inverseSOn, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{user?.first_name} {user?.last_name}</p>
                            <p style={{ margin: 0, fontSize: '10px', color: 'rgba(241,241,241,0.3)' }}>Manager</p>
                        </div>
                    </button>

                    {/* Menu deroulant utilisateur */}
                    {showUserMenu && (
                        <div style={{ position: 'absolute', bottom: '64px', left: '10px', right: '10px', backgroundColor: P.surface, borderRadius: '10px', boxShadow: '0 8px 24px rgba(0,0,0,0.2)', overflow: 'hidden', zIndex: 50 }}>
                            <NavLink to="/parametres" onClick={() => setShowUserMenu(false)}
                                style={{ display: 'flex', alignItems: 'center', gap: '9px', padding: '11px 14px', fontSize: '13px', color: P.onSurface, textDecoration: 'none', borderBottom: '1px solid ' + P.outlineVariant }}
                                onMouseEnter={e => e.currentTarget.style.backgroundColor = P.surfaceContainerLow}
                                onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}
                            >
                                <IconSettings style={{ width: '15px', height: '15px', color: P.outline }} />
                                Parametres du compte
                            </NavLink>
                        </div>
                    )}

                    <button onClick={logout} style={{ width: '100%', display: 'flex', alignItems: 'center', gap: '8px', padding: '8px 10px', borderRadius: '8px', fontSize: '12px', fontWeight: 500, color: 'rgba(241,241,241,0.3)', background: 'none', border: 'none', cursor: 'pointer', fontFamily: 'Poppins, sans-serif', transition: 'all 0.15s' }}
                        onMouseEnter={e => { e.currentTarget.style.backgroundColor = 'rgba(241,241,241,0.06)'; e.currentTarget.style.color = P.inverseSOn; }}
                        onMouseLeave={e => { e.currentTarget.style.backgroundColor = 'transparent'; e.currentTarget.style.color = 'rgba(241,241,241,0.3)'; }}
                    >
                        <IconLogout style={{ width: '13px', height: '13px' }} />
                        Deconnexion
                    </button>
                </div>
            </aside>

            {/* MAIN */}
            <div style={{ marginLeft: '220px', width: 'calc(100% - 220px)', display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
                <header style={{ position: 'sticky', top: 0, zIndex: 10, backgroundColor: P.surface, borderBottom: '1px solid ' + P.outlineVariant, padding: '0 24px', height: '56px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '16px' }}>
                    <h1 style={{ margin: 0, fontSize: '16px', fontWeight: 700, color: P.onSurface, letterSpacing: '-0.01em' }}>{pageTitle}</h1>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <div style={{ position: 'relative' }}>
                            <IconSearch style={{ position: 'absolute', left: '9px', top: '50%', transform: 'translateY(-50%)', width: '13px', height: '13px', color: P.outline }} />
                            <input
                                type="text" placeholder="Rechercher... (Entree)" value={search}
                                onChange={e => setSearch(e.target.value)} onKeyDown={handleSearch}
                                style={{ padding: '7px 12px 7px 28px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', backgroundColor: P.surfaceContainerLow, outline: 'none', width: '210px', fontFamily: 'Poppins, sans-serif', color: P.onSurface }}
                            />
                        </div>

                        {/* Cloche notifications — cliquable, redirige */}
                        <div ref={notifRef} style={{ position: 'relative' }}>
                            <button onClick={() => setShowNotifs(!showNotifs)}
                                style={{ width: '34px', height: '34px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative', flexShrink: 0 }}>
                                <IconBell style={{ width: '15px', height: '15px', color: P.outline }} />
                                {notifications.length > 0 && (
                                    <span style={{ position: 'absolute', top: '4px', right: '4px', minWidth: '14px', height: '14px', backgroundColor: P.error, borderRadius: '999px', border: '1.5px solid white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '8px', fontWeight: 700, color: 'white', padding: '0 3px' }}>
                                        {notifications.length}
                                    </span>
                                )}
                            </button>

                            {showNotifs && (
                                <div style={{ position: 'absolute', top: '42px', right: 0, width: '320px', backgroundColor: P.surface, borderRadius: '12px', border: '1px solid ' + P.outlineVariant, boxShadow: '0 8px 24px rgba(0,0,0,0.12)', zIndex: 50, overflow: 'hidden', maxHeight: '420px', display: 'flex', flexDirection: 'column' }}>
                                    <div style={{ padding: '12px 16px', borderBottom: '1px solid ' + P.outlineVariant, display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexShrink: 0 }}>
                                        <p style={{ margin: 0, fontSize: '13px', fontWeight: 700, color: P.onSurface }}>Notifications</p>
                                        <span style={{ fontSize: '10px', fontWeight: 600, color: P.primaryContainer, backgroundColor: P.primaryFixed, padding: '2px 7px', borderRadius: '4px' }}>{notifications.length}</span>
                                    </div>

                                    <div style={{ overflowY: 'auto', flex: 1 }}>
                                        {notifications.length === 0 ? (
                                            <p style={{ textAlign: 'center', color: P.outline, fontSize: '12px', padding: '30px 16px' }}>Aucune notification.</p>
                                        ) : notifications.map(n => {
                                            const style = NOTIF_STYLE[n.type] || { color: P.outline, label: 'Info' };
                                            return (
                                                <button key={n.id} onClick={() => handleNotifClick(n)}
                                                    style={{ width: '100%', display: 'flex', alignItems: 'flex-start', gap: '10px', padding: '12px 16px', borderBottom: '1px solid ' + P.surfaceContainerLow, textAlign: 'left', background: 'transparent', border: 'none', cursor: 'pointer', fontFamily: 'Poppins, sans-serif', transition: 'background 0.1s' }}
                                                    onMouseEnter={e => e.currentTarget.style.backgroundColor = P.surfaceContainerLow}
                                                    onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}
                                                >
                                                    <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: style.color, flexShrink: 0, marginTop: '4px' }}></div>
                                                    <div style={{ flex: 1, minWidth: 0 }}>
                                                        <p style={{ margin: 0, fontSize: '10px', fontWeight: 700, color: style.color, textTransform: 'uppercase', letterSpacing: '0.05em' }}>{style.label}</p>
                                                        <p style={{ margin: '2px 0 0 0', fontSize: '12px', color: P.onSurface, fontWeight: 500 }}>{n.msg}</p>
                                                        {n.sub && <p style={{ margin: '2px 0 0 0', fontSize: '11px', color: P.outline }}>{n.sub}</p>}
                                                    </div>
                                                </button>
                                            );
                                        })}
                                    </div>
                                </div>
                            )}
                        </div>

                        {/* Avatar + menu utilisateur header */}
                        <NavLink to="/parametres"
                            style={{ width: '32px', height: '32px', borderRadius: '8px', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 700, color: '#fff', cursor: 'pointer', flexShrink: 0, textDecoration: 'none' }}
                            title="Parametres du compte"
                        >
                            {user?.first_name?.[0]}
                        </NavLink>
                    </div>
                </header>

                <main style={{ flex: 1, padding: '24px' }}>
                    <Outlet />
                </main>
            </div>
        </div>
    );
}