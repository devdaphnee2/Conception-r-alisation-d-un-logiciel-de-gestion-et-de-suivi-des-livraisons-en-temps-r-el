import { useAuth } from '../context/AuthContext';
import { IconPackage, IconMap, IconTruck, IconAlert } from '../components/Icons';

export default function Dashboard() {
    const { user } = useAuth();

    const stats = [
        { label: "Livraisons aujourd'hui", value: '0', icon: IconPackage, accent: '#E8580A', soft: '#FFF1E8' },
        { label: 'En cours', value: '0', icon: IconMap, accent: '#3B82F6', soft: '#EFF6FF' },
        { label: 'Livreurs actifs', value: '0', icon: IconTruck, accent: '#A855F7', soft: '#FAF5FF' },
        { label: 'Litiges ouverts', value: '0', icon: IconAlert, accent: '#EF4444', soft: '#FEF2F2' },
    ];

    return (
        <div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '20px', marginBottom: '32px' }}>
                {stats.map((stat, i) => {
                    const Icon = stat.icon;
                    return (
                        <div key={i} style={{
                            backgroundColor: 'white',
                            borderRadius: '24px',
                            border: '1px solid #ECECF2',
                            padding: '24px',
                            boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
                            transition: 'all 0.2s',
                            cursor: 'default',
                        }}
                        onMouseEnter={e => { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = '0 8px 24px rgba(0,0,0,0.06)'; }}
                        onMouseLeave={e => { e.currentTarget.style.transform = 'translateY(0)'; e.currentTarget.style.boxShadow = '0 1px 3px rgba(0,0,0,0.04)'; }}
                        >
                            <div style={{
                                width: '44px',
                                height: '44px',
                                borderRadius: '16px',
                                backgroundColor: stat.soft,
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                marginBottom: '20px',
                            }}>
                                <Icon style={{ width: '20px', height: '20px', color: stat.accent }} />
                            </div>
                            <p style={{ fontSize: '34px', fontWeight: 800, color: '#1C1C2E', margin: 0, lineHeight: 1 }}>{stat.value}</p>
                            <p style={{ fontSize: '14px', color: '#8A8AA3', marginTop: '8px', fontWeight: 500 }}>{stat.label}</p>
                        </div>
                    );
                })}
            </div>

            <div style={{
                borderRadius: '24px',
                background: 'linear-gradient(135deg, #0F0F1A, #1C1C2E)',
                padding: '32px',
                position: 'relative',
                overflow: 'hidden',
            }}>
                <div style={{
                    position: 'absolute',
                    right: '-5%',
                    top: '-30%',
                    width: '300px',
                    height: '300px',
                    borderRadius: '50%',
                    backgroundColor: '#E8580A',
                    opacity: 0.15,
                    filter: 'blur(100px)',
                }}></div>
                <div style={{ position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <div>
                        <p style={{ fontSize: '24px', fontWeight: 700, color: 'white', margin: '0 0 8px 0' }}>
                            Bienvenue, {user?.first_name}
                        </p>
                        <p style={{ fontSize: '14px', color: '#8A8AA3', margin: 0, maxWidth: '400px' }}>
                            Voici un apercu de l'activite Glotelho aujourd'hui.
                        </p>
                    </div>
                    <div style={{ width: '64px', height: '64px', borderRadius: '16px', backgroundColor: 'white', padding: '10px' }}>
                        <img src="/logo_glotelho.png" alt="Glotelho" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                    </div>
                </div>
            </div>
        </div>
    );
}