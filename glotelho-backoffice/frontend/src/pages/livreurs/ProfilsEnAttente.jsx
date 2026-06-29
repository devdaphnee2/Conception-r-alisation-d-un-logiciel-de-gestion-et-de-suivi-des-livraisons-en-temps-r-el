import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import api from '../../services/api';
import { IconUser, IconCheck, IconX, IconSearch, IconAlert } from '../../components/Icons';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    primaryFixed: '#ffdea9', onPrimaryContainer: '#483100',
    error: '#ba1a1a', errorContainer: '#ffdad6', onErrorContainer: '#93000a',
    surface: '#ffffff', background: '#f9f9f9',
    surfaceContainerLow: '#f3f3f3', surfaceContainerHigh: '#e8e8e8',
    inverseS: '#2f3131', inverseSOn: '#f1f1f1',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
    secondary: '#475e8b', secondaryContainer: '#b5ccff', onSecondaryContainer: '#3e5682',
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

export default function ProfilsEnAttente() {
    const [livreurs, setLivreurs] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [successMsg, setSuccessMsg] = useState('');
    const [search, setSearch] = useState('');
    const [actionLoading, setActionLoading] = useState(false);

    function charger() {
        api.get('/profils/en-attente')
            .then(res => setLivreurs(res.data))
            .catch(() => setError('Impossible de charger les profils en attente.'))
            .finally(() => setLoading(false));
    }

    useEffect(() => { charger(); }, []);

    async function handleApprouver(id, nom) {
        if (!window.confirm('Approuver le profil de ' + nom + ' ?')) return;
        setActionLoading(true);
        try {
            const res = await api.post('/profils/' + id + '/approuver');
            setSuccessMsg(res.data.message);
            charger();
        } catch (err) { setError(err.response?.data?.message || 'Erreur.'); }
        finally { setActionLoading(false); }
    }

    async function handleRejeter(id, nom) {
        const motif = window.prompt('Motif du rejet pour ' + nom + ' :');
        if (!motif) return;
        setActionLoading(true);
        try {
            const res = await api.post('/profils/' + id + '/rejeter', { motif });
            setSuccessMsg(res.data.message);
            charger();
        } catch (err) { setError(err.response?.data?.message || 'Erreur.'); }
        finally { setActionLoading(false); }
    }

    const filtered = livreurs.filter(l =>
        !search || [l.users?.first_name, l.users?.last_name, l.users?.phone, l.zone_affectee]
            .some(v => v?.toLowerCase().includes(search.toLowerCase()))
    );

    const stats = {
        total: livreurs.length,
        cautionOk: livreurs.filter(l => l.caution_payee).length,
        cautionKo: livreurs.filter(l => !l.caution_payee).length,
    };

    function getDossierStatus(l) {
        const manquants = [];
        if (!l.cni_photo_avant) manquants.push('CNI recto');
        if (!l.cni_photo_arriere) manquants.push('CNI verso');
        if (!l.permis_photo) manquants.push('Permis');
        return manquants;
    }

    const thStyle = {
        padding: '9px 14px', textAlign: 'left', fontSize: '10px',
        fontWeight: 600, color: P.outline, textTransform: 'uppercase',
        letterSpacing: '0.08em', borderBottom: '1px solid ' + P.outlineVariant,
        backgroundColor: P.surfaceContainerLow, whiteSpace: 'nowrap'
    };
    const tdStyle = {
        padding: '12px 14px', fontSize: '13px', color: P.onSurface,
        borderBottom: '1px solid ' + P.surfaceContainerLow
    };

    return (
        <div style={{ fontFamily: 'Poppins, sans-serif' }}>

            {/* KPIs */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '10px', marginBottom: '18px' }}>
                <KpiCard icon={IconUser}  label="Profils en attente"  value={stats.total}     iconColor={P.primaryContainer} iconBg="rgba(201,149,46,0.15)" />
                <KpiCard icon={IconCheck} label="Caution reglee"      value={stats.cautionOk} iconColor="#81c784"            iconBg="rgba(129,199,132,0.15)" />
                <KpiCard icon={IconAlert} label="Caution en attente"  value={stats.cautionKo} iconColor="#ef9a9a"            iconBg="rgba(239,154,154,0.15)" />
            </div>

            {/* Bandeau info */}
            {livreurs.length > 0 && (
                <div style={{ backgroundColor: P.primaryFixed, border: '1px solid ' + P.primaryContainer, borderRadius: '10px', padding: '11px 16px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <IconAlert style={{ width: '15px', height: '15px', color: P.primary, flexShrink: 0 }} />
                    <p style={{ margin: 0, fontSize: '13px', color: P.onPrimaryContainer, fontWeight: 500 }}>
                        <strong>{livreurs.length} profil{livreurs.length > 1 ? 's' : ''}</strong> en attente. Ces livreurs ne peuvent pas recevoir de courses ni apparaitre dans la liste principale tant que leur profil n'est pas approuve et leur caution reglee.
                    </p>
                </div>
            )}

            {successMsg && (
                <div style={{ backgroundColor: '#c8e6c9', border: '1px solid #a5d6a7', color: '#1b5e20', padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>
                    {successMsg}
                </div>
            )}
            {error && (
                <div style={{ backgroundColor: P.errorContainer, border: '1px solid rgba(186,26,26,0.2)', color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 500 }}>
                    {error}
                </div>
            )}

            {/* TABLE */}
            <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>

                {/* Barre recherche */}
                <div style={{ padding: '13px 16px', borderBottom: '1px solid ' + P.surfaceContainerLow, display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <div style={{ position: 'relative', flex: 1 }}>
                        <IconSearch style={{ position: 'absolute', left: '9px', top: '50%', transform: 'translateY(-50%)', width: '13px', height: '13px', color: P.outline }} />
                        <input
                            type="text"
                            placeholder="Rechercher par nom, telephone, zone..."
                            value={search}
                            onChange={e => setSearch(e.target.value)}
                            style={{ width: '100%', padding: '8px 12px 8px 28px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', backgroundColor: P.surfaceContainerLow, boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif', color: P.onSurface, outline: 'none' }}
                        />
                    </div>
                </div>

                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead>
                        <tr>
                            {['Candidat', 'Contact', 'Zone / Vehicule', 'Caution', 'Documents', 'Actions'].map(h => (
                                <th key={h} style={thStyle}>{h}</th>
                            ))}
                        </tr>
                    </thead>
                    <tbody>
                        {loading ? (
                            <tr><td colSpan={6} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>Chargement...</td></tr>
                        ) : filtered.length === 0 ? (
                            <tr><td colSpan={6} style={{ ...tdStyle, textAlign: 'center', color: P.outline, padding: '40px' }}>Aucun profil en attente.</td></tr>
                        ) : filtered.map(l => {
                            const nom = l.users?.first_name + ' ' + l.users?.last_name;
                            const cautionOk = l.caution_payee;
                            const docsManquants = getDossierStatus(l);
                            const dossierOk = docsManquants.length === 0;

                            return (
                                <tr key={l.id}
                                    onMouseEnter={e => e.currentTarget.style.backgroundColor = P.surfaceContainerLow}
                                    onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}
                                    style={{ transition: 'background 0.1s' }}
                                >
                                    {/* Candidat */}
                                    <td style={tdStyle}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                            <div style={{ width: '34px', height: '34px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 700, color: '#fff', flexShrink: 0 }}>
                                                {l.users?.first_name?.[0]}
                                            </div>
                                            <div>
                                                <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onSurface }}>{nom}</p>
                                                <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>
                                                    #{String(l.id).padStart(3,'0')} — {l.date_candidature ? new Date(l.date_candidature).toLocaleDateString('fr-FR') : '—'}
                                                </p>
                                            </div>
                                        </div>
                                    </td>

                                    {/* Contact */}
                                    <td style={tdStyle}>
                                        <p style={{ margin: 0, fontSize: '13px', fontWeight: 500 }}>{l.users?.phone}</p>
                                        <p style={{ margin: '2px 0 0 0', fontSize: '11px', color: P.outline }}>{l.users?.email}</p>
                                    </td>

                                    {/* Zone / Vehicule */}
                                    <td style={tdStyle}>
                                        <p style={{ margin: 0, fontSize: '13px', fontWeight: 500 }}>{l.zone_affectee || '—'}</p>
                                        <p style={{ margin: '2px 0 0 0', fontSize: '11px', color: P.outline }}>
                                            {l.vehicules?.brand} {l.vehicules?.type} — {l.vehicules?.plate_number}
                                        </p>
                                    </td>

                                    {/* Caution */}
                                    <td style={tdStyle}>
                                        <p style={{ margin: '0 0 4px 0', fontSize: '13px', fontWeight: 700, color: cautionOk ? '#1b5e20' : P.error }}>
                                            {Number(l.caution_montant || 50000).toLocaleString('fr-FR')} FCFA
                                        </p>
                                        <span style={{ fontSize: '10px', fontWeight: 600, padding: '2px 7px', borderRadius: '4px', backgroundColor: cautionOk ? '#c8e6c9' : P.errorContainer, color: cautionOk ? '#1b5e20' : P.onErrorContainer }}>
                                            {cautionOk ? 'PAYEE' : 'NON PAYEE'}
                                        </span>
                                    </td>

                                    {/* Documents */}
                                    <td style={tdStyle}>
                                        {dossierOk ? (
                                            <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                                                <IconCheck style={{ width: '13px', height: '13px', color: '#1b5e20' }} />
                                                <span style={{ fontSize: '11px', color: '#1b5e20', fontWeight: 600 }}>Complet</span>
                                            </div>
                                        ) : (
                                            <div>
                                                <div style={{ display: 'flex', alignItems: 'center', gap: '4px', marginBottom: '3px' }}>
                                                    <IconX style={{ width: '12px', height: '12px', color: P.error }} />
                                                    <span style={{ fontSize: '11px', color: P.error, fontWeight: 600 }}>{docsManquants.length} manquant{docsManquants.length > 1 ? 's' : ''}</span>
                                                </div>
                                                {docsManquants.map((d, i) => (
                                                    <p key={i} style={{ margin: 0, fontSize: '10px', color: P.outline }}>• {d}</p>
                                                ))}
                                            </div>
                                        )}
                                    </td>

                                    {/* Actions — bouton Voir pointe vers /livreurs/profils/:id */}
                                    <td style={tdStyle}>
                                        <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                                            <Link
                                                to={'/livreurs/profils/' + l.id}
                                                style={{ padding: '5px 10px', borderRadius: '7px', backgroundColor: P.secondaryContainer, color: P.onSecondaryContainer, fontSize: '11px', fontWeight: 600, textDecoration: 'none' }}
                                            >
                                                Voir dossier
                                            </Link>
                                            <button
                                                onClick={() => handleApprouver(l.id, nom)}
                                                disabled={actionLoading}
                                                style={{ padding: '5px 10px', borderRadius: '7px', backgroundColor: '#c8e6c9', color: '#1b5e20', fontSize: '11px', fontWeight: 600, border: 'none', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}
                                            >
                                                Approuver
                                            </button>
                                            <button
                                                onClick={() => handleRejeter(l.id, nom)}
                                                disabled={actionLoading}
                                                style={{ padding: '5px 10px', borderRadius: '7px', backgroundColor: P.errorContainer, color: P.onErrorContainer, fontSize: '11px', fontWeight: 600, border: 'none', cursor: 'pointer', fontFamily: 'Poppins, sans-serif' }}
                                            >
                                                Rejeter
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>

                <div style={{ padding: '11px 16px', borderTop: '1px solid ' + P.surfaceContainerLow }}>
                    <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>
                        {filtered.length} profil{filtered.length > 1 ? 's' : ''} affiche{filtered.length > 1 ? 's' : ''}
                    </p>
                </div>
            </div>
        </div>
    );
}