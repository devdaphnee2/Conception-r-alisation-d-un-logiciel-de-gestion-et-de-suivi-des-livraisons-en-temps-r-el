import { useState } from 'react';
import { Outlet, NavLink, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import {
    IconDashboard, IconPackage, IconMap, IconTruck,
    IconAlert, IconLogout, IconBell, IconSearch, IconUser
} from '../components/Icons';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
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

const pageTitles = {
    '/dashboard': 'Tableau de bord',
    '/tracking': 'Tracking temps reel',
    '/commandes': 'Commandes',
    '/livraisons': 'Livraisons',
    '/livreurs': 'Livreurs',
    '/livreurs/profils': 'Validation des profils',
    '/litiges': 'Litiges',
};

export default function DashboardLayout() {
    const { user, logout } = useAuth();
    const location = useLocation();
    const [search, setSearch] = useState('');

    const pageTitle = Object.entries(pageTitles).find(([path]) =>
        location.pathname === path || (path !== '/dashboard' && location.pathname.startsWith(path))
    )?.[1] || 'Glotelho';

    const navLinks = [
        { to: '/dashboard', label: 'Dashboard', icon: IconDashboard },
        { to: '/commandes', label: 'Commandes', icon: IconOrders },
        { to: '/livraisons', label: 'Livraisons', icon: IconPackage },
        { to: '/tracking', label: 'Tracking', icon: IconMap },
        {
            label: 'Livreurs', icon: IconTruck,
            children: [
                { to: '/livreurs', label: 'Liste livreurs' },
                { to: '/livreurs/profils', label: 'Profils en attente' },
            ]
        },
        { to: '/litiges', label: 'Litiges', icon: IconAlert },
    ];

    function isActive(link) {
        if (link.to) return location.pathname === link.to || (link.to !== '/dashboard' && location.pathname.startsWith(link.to));
        if (link.children) return link.children.some(c => location.pathname === c.to || location.pathname.startsWith(c.to + '/'));
        return false;
    }

    const linkBase = { display: 'flex', alignItems: 'center', gap: '9px', padding: '9px 10px', borderRadius: '8px', fontSize: '13px', textDecoration: 'none', transition: 'all 0.15s' };

    function linkStyle(active) {
        return {
            ...linkBase,
            fontWeight: active ? 600 : 400,
            backgroundColor: active ? 'rgba(201,149,46,0.16)' : 'transparent',
            color: active ? P.primaryContainer : 'rgba(241,241,241,0.5)',
            borderLeft: active ? '3px solid ' + P.primaryContainer : '3px solid transparent',
        };
    }

    return (
        <div style={{ display: 'flex', minHeight: '100vh', backgroundColor: '#f9f9f9', fontFamily: 'Poppins, sans-serif' }}>

            <aside style={{ position: 'fixed', left: 0, top: 0, zIndex: 20, display: 'flex', flexDirection: 'column', height: '100vh', width: '220px', backgroundColor: P.inverseS }}>

                {/* Logo */}
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

                {/* Nav */}
                <nav style={{ flex: 1, padding: '14px 10px', display: 'flex', flexDirection: 'column', gap: '2px', overflowY: 'auto' }}>
                    <p style={{ fontSize: '9px', fontWeight: 600, color: 'rgba(241,241,241,0.25)', textTransform: 'uppercase', letterSpacing: '0.12em', padding: '0 8px', marginBottom: '8px' }}>Menu</p>

                    {navLinks.map((link, i) => {
                        const active = isActive(link);
                        if (link.children) {
                            const Icon = link.icon;
                            return (
                                <div key={i}>
                                    <div style={{ ...linkBase, fontWeight: active ? 600 : 400, color: active ? P.primaryContainer : 'rgba(241,241,241,0.5)', borderLeft: active ? '3px solid ' + P.primaryContainer : '3px solid transparent' }}>
                                        <Icon style={{ width: '15px', height: '15px', flexShrink: 0 }} />
                                        {link.label}
                                    </div>
                                    {link.children.map(child => {
                                        const childActive = location.pathname === child.to || location.pathname.startsWith(child.to + '/');
                                        return (
                                            <NavLink key={child.to} to={child.to}
                                                style={{ display: 'block', padding: '7px 10px 7px 34px', borderRadius: '8px', fontSize: '12px', fontWeight: childActive ? 600 : 400, textDecoration: 'none', backgroundColor: childActive ? 'rgba(201,149,46,0.16)' : 'transparent', color: childActive ? P.primaryContainer : 'rgba(241,241,241,0.45)', borderLeft: childActive ? '3px solid ' + P.primaryContainer : '3px solid transparent', transition: 'all 0.15s' }}
                                                onMouseEnter={e => { if (!childActive) { e.currentTarget.style.backgroundColor = 'rgba(241,241,241,0.06)'; e.currentTarget.style.color = P.inverseSOn; }}}
                                                onMouseLeave={e => { if (!childActive) { e.currentTarget.style.backgroundColor = 'transparent'; e.currentTarget.style.color = 'rgba(241,241,241,0.45)'; }}}
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
                            <NavLink key={link.to} to={link.to} style={linkStyle(active)}
                                onMouseEnter={e => { if (!active) { e.currentTarget.style.backgroundColor = 'rgba(241,241,241,0.06)'; e.currentTarget.style.color = P.inverseSOn; }}}
                                onMouseLeave={e => { if (!active) { e.currentTarget.style.backgroundColor = 'transparent'; e.currentTarget.style.color = 'rgba(241,241,241,0.5)'; }}}
                            >
                                <Icon style={{ width: '15px', height: '15px', flexShrink: 0 }} />
                                {link.label}
                            </NavLink>
                        );
                    })}
                </nav>

                {/* User */}
                <div style={{ padding: '12px 10px', borderTop: '1px solid rgba(241,241,241,0.07)' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '9px', padding: '8px 10px', borderRadius: '8px', backgroundColor: 'rgba(241,241,241,0.05)', marginBottom: '6px' }}>
                        <div style={{ width: '30px', height: '30px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>
                            {user?.first_name?.[0]}
                        </div>
                        <div style={{ minWidth: 0, flex: 1 }}>
                            <p style={{ margin: 0, fontSize: '12px', fontWeight: 600, color: P.inverseSOn, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{user?.first_name} {user?.last_name}</p>
                            <p style={{ margin: 0, fontSize: '10px', color: 'rgba(241,241,241,0.3)' }}>Manager</p>
                        </div>
                    </div>
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
                            <input type="text" placeholder="Rechercher..." value={search} onChange={e => setSearch(e.target.value)}
                                style={{ padding: '7px 12px 7px 28px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', backgroundColor: P.surfaceContainerLow, outline: 'none', width: '200px', fontFamily: 'Poppins, sans-serif', color: P.onSurface }} />
                        </div>
                        <button style={{ width: '32px', height: '32px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surface, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
                            <IconBell style={{ width: '14px', height: '14px', color: P.outline }} />
                            <span style={{ position: 'absolute', top: '7px', right: '7px', width: '6px', height: '6px', backgroundColor: P.primaryContainer, borderRadius: '50%', border: '1.5px solid white' }}></span>
                        </button>
                        <div style={{ width: '32px', height: '32px', borderRadius: '8px', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 700, color: '#fff', cursor: 'pointer' }}>
                            {user?.first_name?.[0]}
                        </div>
                    </div>
                </header>
                <main style={{ flex: 1, padding: '24px' }}><Outlet /></main>
            </div>
        </div>
    );
}