import { useState, useEffect } from 'react';
import api from '../services/api';
import { useAuth } from '../context/AuthContext';
import { IconUser, IconBell, IconCheck, IconAlert, IconX } from '../components/Icons';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    primaryFixed: '#ffdea9', onPrimaryContainer: '#483100',
    error: '#ba1a1a', errorContainer: '#ffdad6', onErrorContainer: '#93000a',
    surface: '#ffffff', surfaceContainerLow: '#f3f3f3', surfaceContainerHigh: '#e8e8e8',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
};

function Section({ title, children }) {
    return (
        <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, marginBottom: '16px', overflow: 'hidden', boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}>
            <div style={{ padding: '13px 20px', borderBottom: '1px solid ' + P.surfaceContainerLow, backgroundColor: P.surfaceContainerLow }}>
                <p style={{ margin: 0, fontSize: '13px', fontWeight: 700, color: P.onSurface }}>{title}</p>
            </div>
            <div style={{ padding: '20px' }}>{children}</div>
        </div>
    );
}

function Toggle({ checked, onChange }) {
    return (
        <button onClick={onChange} type="button"
            style={{ width: '42px', height: '24px', borderRadius: '999px', border: 'none', cursor: 'pointer', backgroundColor: checked ? P.primary : P.outlineVariant, position: 'relative', transition: 'background 0.2s', padding: 0, flexShrink: 0 }}>
            <div style={{ width: '18px', height: '18px', borderRadius: '50%', backgroundColor: '#fff', position: 'absolute', top: '3px', left: checked ? '21px' : '3px', transition: 'left 0.2s', boxShadow: '0 1px 3px rgba(0,0,0,0.2)' }}></div>
        </button>
    );
}

export default function Parametres() {
    const { user, login } = useAuth();
    const [profil, setProfil] = useState({ first_name: '', last_name: '', email: '', phone: '' });
    const [loadingProfil, setLoadingProfil] = useState(false);
    const [successProfil, setSuccessProfil] = useState('');
    const [errorProfil, setErrorProfil] = useState('');

    const [pwdForm, setPwdForm] = useState({ current_password: '', new_password: '', confirm_password: '' });
    const [loadingPwd, setLoadingPwd] = useState(false);
    const [successPwd, setSuccessPwd] = useState('');
    const [errorPwd, setErrorPwd] = useState('');

    const [notifPrefs, setNotifPrefs] = useState({
        litiges: true, profils: true, incidents: true, recouvrements: true, push: true, email: false,
    });

    useEffect(() => {
        if (user) {
            setProfil({ first_name: user.first_name || '', last_name: user.last_name || '', email: user.email || '', phone: user.phone || '' });
        }
        // Charger preferences notifications depuis localStorage (a remplacer par API si besoin)
        const saved = localStorage.getItem('notif_prefs');
        if (saved) setNotifPrefs(JSON.parse(saved));
    }, [user]);

    function handleProfilChange(e) { setProfil({ ...profil, [e.target.name]: e.target.value }); }
    function handlePwdChange(e) { setPwdForm({ ...pwdForm, [e.target.name]: e.target.value }); }

    function toggleNotif(key) {
        const updated = { ...notifPrefs, [key]: !notifPrefs[key] };
        setNotifPrefs(updated);
        localStorage.setItem('notif_prefs', JSON.stringify(updated));
    }

    async function handleSubmitProfil(e) {
        e.preventDefault();
        setErrorProfil(''); setSuccessProfil('');
        setLoadingProfil(true);
        try {
            const res = await api.put('/auth/me', profil);
            setSuccessProfil('Profil mis a jour avec succes.');
        } catch (err) {
            setErrorProfil(err.response?.data?.message || 'Erreur lors de la mise a jour.');
        } finally { setLoadingProfil(false); }
    }

    async function handleSubmitPwd(e) {
        e.preventDefault();
        setErrorPwd(''); setSuccessPwd('');
        if (pwdForm.new_password !== pwdForm.confirm_password) {
            setErrorPwd('Les nouveaux mots de passe ne correspondent pas.');
            return;
        }
        if (pwdForm.new_password.length < 8) {
            setErrorPwd('Le mot de passe doit contenir au moins 8 caracteres.');
            return;
        }
        setLoadingPwd(true);
        try {
            await api.post('/auth/change-password', {
                current_password: pwdForm.current_password,
                new_password: pwdForm.new_password,
            });
            setSuccessPwd('Mot de passe modifie avec succes.');
            setPwdForm({ current_password: '', new_password: '', confirm_password: '' });
        } catch (err) {
            setErrorPwd(err.response?.data?.message || 'Mot de passe actuel incorrect.');
        } finally { setLoadingPwd(false); }
    }

    const inputStyle = { width: '100%', padding: '11px 14px', borderRadius: '10px', border: '1.5px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, fontSize: '13px', color: P.onSurface, outline: 'none', boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif' };
    const labelStyle = { display: 'block', fontSize: '11px', fontWeight: 600, color: P.onSurfaceVariant, textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: '7px' };
    const btnPrimary = { backgroundColor: P.primary, color: '#fff', padding: '11px 24px', borderRadius: '10px', border: 'none', fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif', boxShadow: '0 3px 10px rgba(125,87,0,0.25)' };

    const notifLabels = [
        { key: 'litiges', label: 'Nouveaux litiges', desc: 'Notification a chaque declaration de litige' },
        { key: 'profils', label: 'Profils livreur en attente', desc: 'Notification a chaque nouvelle candidature' },
        { key: 'incidents', label: 'Incidents livraison', desc: 'Panne, colis perdu, colis casse' },
        { key: 'recouvrements', label: 'Dettes financieres', desc: 'Nouvelle dette livreur a recouvrer' },
    ];

    return (
        <div style={{ maxWidth: '720px', fontFamily: 'Poppins, sans-serif' }}>
            <h1 style={{ fontSize: '20px', fontWeight: 800, color: P.onSurface, margin: '0 0 4px 0' }}>Parametres du compte</h1>
            <p style={{ fontSize: '13px', color: P.outline, margin: '0 0 24px 0' }}>Gerez vos informations personnelles, votre securite et vos notifications.</p>

            {/* PROFIL */}
            <Section title="Informations personnelles">
                {successProfil && <div style={{ backgroundColor: '#c8e6c9', border: '1px solid #a5d6a7', color: '#1b5e20', padding: '10px 14px', borderRadius: '8px', marginBottom: '16px', fontSize: '13px', fontWeight: 500 }}>{successProfil}</div>}
                {errorProfil && <div style={{ backgroundColor: P.errorContainer, color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '16px', fontSize: '13px', fontWeight: 500 }}>{errorProfil}</div>}

                <div style={{ display: 'flex', alignItems: 'center', gap: '14px', marginBottom: '20px' }}>
                    <div style={{ width: '56px', height: '56px', borderRadius: '50%', backgroundColor: P.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '20px', fontWeight: 800, color: '#fff' }}>
                        {profil.first_name?.[0]}
                    </div>
                    <div>
                        <p style={{ margin: 0, fontSize: '15px', fontWeight: 700, color: P.onSurface }}>{profil.first_name} {profil.last_name}</p>
                        <p style={{ margin: '2px 0 0 0', fontSize: '12px', color: P.outline }}>Manager — Glotelho</p>
                    </div>
                </div>

                <form onSubmit={handleSubmitProfil}>
                    <div style={{ display: 'grid', gap: '16px' }}>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                            <div><label style={labelStyle}>Prenom</label><input type="text" name="first_name" value={profil.first_name} onChange={handleProfilChange} style={inputStyle} required /></div>
                            <div><label style={labelStyle}>Nom</label><input type="text" name="last_name" value={profil.last_name} onChange={handleProfilChange} style={inputStyle} required /></div>
                        </div>
                        <div><label style={labelStyle}>Email</label><input type="email" name="email" value={profil.email} onChange={handleProfilChange} style={inputStyle} required /></div>
                        <div><label style={labelStyle}>Telephone</label><input type="text" name="phone" value={profil.phone} onChange={handleProfilChange} style={inputStyle} required /></div>
                        <div>
                            <button type="submit" disabled={loadingProfil} style={{ ...btnPrimary, backgroundColor: loadingProfil ? P.outline : P.primary, cursor: loadingProfil ? 'not-allowed' : 'pointer' }}>
                                {loadingProfil ? 'Enregistrement...' : 'Enregistrer les modifications'}
                            </button>
                        </div>
                    </div>
                </form>
            </Section>

            {/* MOT DE PASSE */}
            <Section title="Securite — Changer le mot de passe">
                {successPwd && <div style={{ backgroundColor: '#c8e6c9', border: '1px solid #a5d6a7', color: '#1b5e20', padding: '10px 14px', borderRadius: '8px', marginBottom: '16px', fontSize: '13px', fontWeight: 500 }}>{successPwd}</div>}
                {errorPwd && <div style={{ backgroundColor: P.errorContainer, color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '16px', fontSize: '13px', fontWeight: 500 }}>{errorPwd}</div>}

                <form onSubmit={handleSubmitPwd}>
                    <div style={{ display: 'grid', gap: '16px' }}>
                        <div>
                            <label style={labelStyle}>Mot de passe actuel</label>
                            <input type="password" name="current_password" value={pwdForm.current_password} onChange={handlePwdChange} style={inputStyle} required />
                        </div>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                            <div>
                                <label style={labelStyle}>Nouveau mot de passe</label>
                                <input type="password" name="new_password" value={pwdForm.new_password} onChange={handlePwdChange} style={inputStyle} required minLength={8} />
                            </div>
                            <div>
                                <label style={labelStyle}>Confirmer le mot de passe</label>
                                <input type="password" name="confirm_password" value={pwdForm.confirm_password} onChange={handlePwdChange} style={inputStyle} required minLength={8} />
                            </div>
                        </div>
                        <p style={{ margin: 0, fontSize: '11px', color: P.outline }}>Minimum 8 caracteres.</p>
                        <div>
                            <button type="submit" disabled={loadingPwd} style={{ ...btnPrimary, backgroundColor: loadingPwd ? P.outline : P.primary, cursor: loadingPwd ? 'not-allowed' : 'pointer' }}>
                                {loadingPwd ? 'Modification...' : 'Changer le mot de passe'}
                            </button>
                        </div>
                    </div>
                </form>
            </Section>

            {/* NOTIFICATIONS */}
            <Section title="Preferences de notifications">
                <div style={{ display: 'grid', gap: '4px', marginBottom: '16px' }}>
                    {notifLabels.map(n => (
                        <div key={n.key} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 4px', borderBottom: '1px solid ' + P.surfaceContainerLow }}>
                            <div>
                                <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onSurface }}>{n.label}</p>
                                <p style={{ margin: '2px 0 0 0', fontSize: '11px', color: P.outline }}>{n.desc}</p>
                            </div>
                            <Toggle checked={notifPrefs[n.key]} onChange={() => toggleNotif(n.key)} />
                        </div>
                    ))}
                </div>

                <p style={{ margin: '0 0 10px 0', fontSize: '11px', fontWeight: 700, color: P.outline, textTransform: 'uppercase', letterSpacing: '0.07em' }}>Canaux de notification</p>
                <div style={{ display: 'grid', gap: '4px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 4px', borderBottom: '1px solid ' + P.surfaceContainerLow }}>
                        <div>
                            <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onSurface }}>Notifications push</p>
                            <p style={{ margin: '2px 0 0 0', fontSize: '11px', color: P.outline }}>Alertes dans l'interface (cloche)</p>
                        </div>
                        <Toggle checked={notifPrefs.push} onChange={() => toggleNotif('push')} />
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 4px' }}>
                        <div>
                            <p style={{ margin: 0, fontSize: '13px', fontWeight: 600, color: P.onSurface }}>Notifications email</p>
                            <p style={{ margin: '2px 0 0 0', fontSize: '11px', color: P.outline }}>Recevoir aussi un email pour les alertes critiques</p>
                        </div>
                        <Toggle checked={notifPrefs.email} onChange={() => toggleNotif('email')} />
                    </div>
                </div>
            </Section>
        </div>
    );
}