import { Outlet, NavLink } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { IconDashboard, IconPackage, IconMap, IconTruck, IconAlert, IconLogout } from '../components/Icons';

export default function DashboardLayout() {
    const { user, logout } = useAuth();

    const links = [
        { to: '/dashboard', label: 'Tableau de bord', icon: IconDashboard },
        { to: '/livraisons', label: 'Livraisons', icon: IconPackage },
        { to: '/tracking', label: 'Tracking', icon: IconMap },
        { to: '/livreurs', label: 'Livreurs', icon: IconTruck },
        { to: '/litiges', label: 'Litiges', icon: IconAlert },
    ];

    return (
        <div style={{ display: 'flex', minHeight: '100vh', backgroundColor: '#FAFAFC' }}>

            <aside style={{
                position: 'fixed',
                left: 0,
                top: 0,
                zIndex: 20,
                display: 'flex',
                flexDirection: 'column',
                height: '100vh',
                width: '288px',
                overflow: 'hidden',
                backgroundColor: '#0F0F1A',
                color: 'white',
            }}>

                <div style={{
                    pointerEvents: 'none',
                    position: 'absolute',
                    left: '50%',
                    top: '-20%',
                    transform: 'translateX(-50%)',
                    width: '260px',
                    height: '260px',
                    backgroundColor: '#E8580A',
                    opacity: 0.12,
                    borderRadius: '50%',
                    filter: 'blur(80px)',
                }}></div>

                <div style={{
                    position: 'relative',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '12px',
                    padding: '28px',
                    borderBottom: '1px solid rgba(255,255,255,0.06)',
                }}>
                    <div style={{
                        width: '44px',
                        height: '44px',
                        borderRadius: '16px',
                        backgroundColor: 'white',
                        padding: '6px',
                    }}>
                        <img src="/logo_glotelho.png" alt="Glotelho" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                    </div>
                    <div>
                        <p style={{ fontWeight: 700, fontSize: '18px', lineHeight: 1, margin: 0 }}>Glotelho</p>
                        <p style={{ fontSize: '11px', color: '#8A8AA3', marginTop: '4px', letterSpacing: '0.1em' }}>BACK-OFFICE</p>
                    </div>
                </div>

                <nav style={{ position: 'relative', flex: 1, padding: '24px 16px 0', display: 'flex', flexDirection: 'column', gap: '4px' }}>
                    <p style={{ fontSize: '10px', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.15em', color: '#8A8AA3', padding: '0 16px', marginBottom: '12px' }}>
                        Navigation
                    </p>
                    {links.map((link) => {
                        const Icon = link.icon;
                        return (
                            <NavLink
                                key={link.to}
                                to={link.to}
                                style={({ isActive }) => ({
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: '12px',
                                    padding: '12px 16px',
                                    borderRadius: '16px',
                                    fontSize: '14px',
                                    fontWeight: 500,
                                    textDecoration: 'none',
                                    transition: 'all 0.2s',
                                    background: isActive ? 'linear-gradient(to right, #E8580A, #FF7A33)' : 'transparent',
                                    color: isActive ? 'white' : '#8A8AA3',
                                    boxShadow: isActive ? '0 8px 24px rgba(232,88,10,0.2)' : 'none',
                                })}
                            >
                                <Icon style={{ width: '18px', height: '18px', flexShrink: 0 }} />
                                {link.label}
                            </NavLink>
                        );
                    })}
                </nav>

                <div style={{ position: 'relative', borderTop: '1px solid rgba(255,255,255,0.06)', padding: '16px' }}>
                    <div style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '12px',
                        padding: '10px 12px',
                        marginBottom: '8px',
                        borderRadius: '16px',
                        backgroundColor: 'rgba(255,255,255,0.03)',
                    }}>
                        <div style={{
                            width: '40px',
                            height: '40px',
                            borderRadius: '50%',
                            background: 'linear-gradient(135deg, #E8580A, #FF8A4C)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontSize: '14px',
                            fontWeight: 700,
                            flexShrink: 0,
                        }}>
                            {user?.first_name?.[0]}
                        </div>
                        <div style={{ flex: 1, minWidth: 0 }}>
                            <p style={{ fontSize: '14px', fontWeight: 500, margin: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                                {user?.first_name} {user?.last_name}
                            </p>
                            <p style={{ fontSize: '12px', color: '#8A8AA3', margin: 0 }}>Manager</p>
                        </div>
                    </div>
                    <button
                        onClick={logout}
                        style={{
                            width: '100%',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '12px',
                            padding: '10px 16px',
                            borderRadius: '16px',
                            fontSize: '14px',
                            fontWeight: 500,
                            color: '#8A8AA3',
                            background: 'none',
                            border: 'none',
                            cursor: 'pointer',
                            transition: 'all 0.2s',
                        }}
                        onMouseEnter={e => { e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.05)'; e.currentTarget.style.color = 'white'; }}
                        onMouseLeave={e => { e.currentTarget.style.backgroundColor = 'transparent'; e.currentTarget.style.color = '#8A8AA3'; }}
                    >
                        <IconLogout style={{ width: '18px', height: '18px' }} />
                        Deconnexion
                    </button>
                </div>
            </aside>

            <div style={{ marginLeft: '288px', width: 'calc(100% - 288px)', display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
                <header style={{
                    position: 'sticky',
                    top: 0,
                    zIndex: 10,
                    borderBottom: '1px solid #ECECF2',
                    backgroundColor: 'rgba(255,255,255,0.8)',
                    backdropFilter: 'blur(20px)',
                    padding: '24px 32px',
                }}>
                    <h1 style={{ fontSize: '26px', fontWeight: 700, color: '#1C1C2E', margin: 0 }}>Tableau de bord</h1>
                    <p style={{ fontSize: '14px', color: '#8A8AA3', marginTop: '4px', marginBottom: 0 }}>Vue d'ensemble de l'activite Glotelho</p>
                </header>

                <main style={{ flex: 1, padding: '32px' }}>
                    <Outlet />
                </main>
            </div>

        </div>
    );
}