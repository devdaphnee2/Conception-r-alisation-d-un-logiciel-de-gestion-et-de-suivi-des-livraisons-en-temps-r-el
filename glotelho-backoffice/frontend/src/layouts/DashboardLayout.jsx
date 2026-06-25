import { useState } from 'react';
import { Outlet, NavLink, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { IconDashboard, IconPackage, IconMap, IconTruck, IconAlert, IconLogout, IconBell, IconSearch } from '../components/Icons';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e', primaryFixedDim: '#f6bd53',
    secondary: '#475e8b', tertiary: '#20619e',
    surface: '#ffffff', background: '#f9f9f9',
    surfaceContainerLow: '#f3f3f3', surfaceContainer: '#eeeeee',
    inverseS: '#2f3131', inverseSOn: '#f1f1f1',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
};

const pageTitles = {
    '/dashboard': 'Tableau de bord',
    '/livraisons': 'Livraisons',
    '/livreurs': 'Livreurs',
    '/litiges': 'Litiges',
    '/tracking': 'Tracking',
};

export default function DashboardLayout() {
    const { user, logout } = useAuth();
    const location = useLocation();
    const [search, setSearch] = useState('');

    const pageTitle = Object.entries(pageTitles).find(([path]) =>
        location.pathname === path || (path !== '/dashboard' && location.pathname.startsWith(path))
    )?.[1] || 'Glotelho';

    const links = [
        { to: '/dashboard', label: 'Dashboard', icon: IconDashboard },
        { to: '/livraisons', label: 'Livraisons', icon: IconPackage },
        { to: '/tracking', label: 'Tracking', icon: IconMap },
        { to: '/livreurs', label: 'Livreurs', icon: IconTruck },
        { to: '/litiges', label: 'Litiges', icon: IconAlert },
    ];

    return (
        <div style={{ display: 'flex', minHeight: '100vh', backgroundColor: P.background, fontFamily: 'Poppins, sans-serif' }}>

            <aside style={{ position: 'fixed', left: 0, top: 0, zIndex: 20, display: 'flex', flexDirection: 'column', height: '100vh', width: '220px', backgroundColor: P.inverseS, color: P.inverseSOn }}>

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

                <nav style={{ flex: 1, padding: '14px 10px', display: 'flex', flexDirection: 'column', gap: '2px' }}>
                    <p style={{ fontSize: '9px', fontWeight: 600, color: 'rgba(241,241,241,0.25)', textTransform: 'uppercase', letterSpacing: '0.12em', padding: '0 8px', marginBottom: '8px' }}>Menu</p>
                    {links.map(({ to, label, icon: Icon }) => {
                        const isActive = location.pathname === to || (to !== '/dashboard' && location.pathname.startsWith(to));
                        return (
                            <NavLink key={to} to={to} style={{
                                display: 'flex', alignItems: 'center', gap: '9px',
                                padding: '9px 10px', borderRadius: '8px',
                                fontSize: '13px', fontWeight: isActive ? 600 : 400,
                                textDecoration: 'none',
                                backgroundColor: isActive ? 'rgba(201,149,46,0.16)' : 'transparent',
                                color: isActive ? P.primaryContainer : 'rgba(241,241,241,0.5)',
                                borderLeft: isActive ? '3px solid ' + P.primaryContainer : '3px solid transparent',
                                transition: 'all 0.15s',
                            }}
                            onMouseEnter={e => { if (!isActive) { e.currentTarget.style.backgroundColor = 'rgba(241,241,241,0.06)'; e.currentTarget.style.color = P.inverseSOn; }}}
                            onMouseLeave={e => { if (!isActive) { e.currentTarget.style.backgroundColor = 'transparent'; e.currentTarget.style.color = 'rgba(241,241,241,0.5)'; }}}
                            >
                                <Icon style={{ width: '15px', height: '15px', flexShrink: 0 }} />
                                {label}
                            </NavLink>
                        );
                    })}
                </nav>

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
                            <IconBell style={{ width: '14px', height: '14px', color: P.onSurfaceVariant }} />
                            <span style={{ position: 'absolute', top: '7px', right: '7px', width: '6px', height: '6px', backgroundColor: P.primaryContainer, borderRadius: '50%', border: '1.5px solid white' }}></span>
                        </button>
                        <div style={{ width: '32px', height: '32px', borderRadius: '8px', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 700, color: '#fff', cursor: 'pointer' }}>
                            {user?.first_name?.[0]}
                        </div>
                    </div>
                </header>
                <main style={{ flex: 1, padding: '24px' }}>
                    <Outlet />
                </main>
            </div>
        </div>
    );
}
