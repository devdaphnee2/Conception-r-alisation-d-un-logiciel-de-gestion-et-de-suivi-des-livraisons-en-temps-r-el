import { useState, useEffect } from 'react';
import api from '../services/api';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e', primaryDark: '#4e3600',
    primaryFixed: '#ffdea9', onPrimaryContainer: '#483100',
    error: '#ba1a1a', errorContainer: '#ffdad6',
    green: '#1b5e20', greenBg: '#e8f5e9',
    blue: '#20619e', blueBg: '#e3f2fd',
    surface: '#ffffff', surfaceContainerLow: '#f6f4f0', surfaceContainerHigh: '#eee9e0',
    inverseS: '#2f3131', inverseSOn: '#f1f1f1',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#e3dccc',
};

function KpiCard({ label, value, sub, icon, gradient }) {
    return (
        <div style={{
            borderRadius: '16px', padding: '18px 20px', position: 'relative', overflow: 'hidden',
            background: gradient || 'linear-gradient(135deg, #ffffff, #fafafa)',
            border: gradient ? 'none' : '1px solid ' + P.outlineVariant,
            boxShadow: gradient ? '0 8px 20px rgba(0,0,0,0.08)' : '0 1px 3px rgba(0,0,0,0.04)',
        }}>
            <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
                <div>
                    <p style={{ margin: 0, fontSize: '10.5px', fontWeight: 700, color: gradient ? 'rgba(255,255,255,0.75)' : P.outline, textTransform: 'uppercase', letterSpacing: '0.07em' }}>{label}</p>
                    <p style={{ margin: '8px 0 0', fontSize: '26px', fontWeight: 900, color: gradient ? '#fff' : P.onSurface, lineHeight: 1 }}>{value}</p>
                    {sub && <p style={{ margin: '5px 0 0', fontSize: '11px', color: gradient ? 'rgba(255,255,255,0.65)' : P.outline }}>{sub}</p>}
                </div>
                {icon && (
                    <div style={{
                        width: '38px', height: '38px', borderRadius: '11px', flexShrink: 0,
                        backgroundColor: gradient ? 'rgba(255,255,255,0.18)' : P.surfaceContainerLow,
                        display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '18px',
                    }}>{icon}</div>
                )}
            </div>
        </div>
    );
}

function Section({ title, icon, children, right }) {
    return (
        <div style={{ backgroundColor: P.surface, borderRadius: '18px', border: '1px solid ' + P.outlineVariant, marginBottom: '16px', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.03)' }}>
            <div style={{ padding: '15px 22px', borderBottom: '1px solid ' + P.surfaceContainerLow, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '9px' }}>
                    <span style={{ fontSize: '15px' }}>{icon}</span>
                    <p style={{ margin: 0, fontSize: '13.5px', fontWeight: 700, color: P.onSurface }}>{title}</p>
                </div>
                {right}
            </div>
            <div style={{ padding: '22px' }}>{children}</div>
        </div>
    );
}

function BarRow({ rank, label, value, max, color, suffix, sub }) {
    var pct = max > 0 ? Math.max(Math.round((value / max) * 100), 4) : 0;
    return (
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '14px' }}>
            <div style={{
                width: '24px', height: '24px', borderRadius: '7px', flexShrink: 0,
                backgroundColor: rank <= 3 ? P.primaryFixed : P.surfaceContainerLow,
                color: rank <= 3 ? P.onPrimaryContainer : P.outline,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: '10.5px', fontWeight: 800,
            }}>{rank}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '5px', gap: '8px' }}>
                    <span style={{ fontSize: '12.5px', color: P.onSurface, fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{label}</span>
                    <span style={{ fontSize: '11.5px', color: P.outline, fontWeight: 700, flexShrink: 0 }}>{value}{suffix || ''}</span>
                </div>
                <div style={{ height: '7px', borderRadius: '4px', backgroundColor: P.surfaceContainerLow, overflow: 'hidden' }}>
                    <div style={{ height: '100%', width: pct + '%', background: color || 'linear-gradient(90deg,' + P.primaryContainer + ',' + P.primary + ')', borderRadius: '4px', transition: 'width 0.5s ease' }}></div>
                </div>
                {sub && <p style={{ margin: '4px 0 0', fontSize: '10px', color: P.outline }}>{sub}</p>}
            </div>
        </div>
    );
}

function DonutChart({ segments, size, thickness }) {
    var total = segments.reduce(function(s, seg) { return s + seg.value; }, 0);
    var r = (size - thickness) / 2;
    var circumference = 2 * Math.PI * r;
    var offset = 0;
    return (
        <div style={{ position: 'relative', width: size, height: size, flexShrink: 0 }}>
            <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
                <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={P.surfaceContainerLow} strokeWidth={thickness} />
                {total > 0 && segments.map(function(seg, i) {
                    var frac = seg.value / total;
                    var dash = frac * circumference;
                    var el = (
                        <circle key={i} cx={size/2} cy={size/2} r={r} fill="none" stroke={seg.color}
                            strokeWidth={thickness} strokeDasharray={dash + ' ' + (circumference - dash)}
                            strokeDashoffset={-offset} strokeLinecap="butt" />
                    );
                    offset += dash;
                    return el;
                })}
            </svg>
            <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
                <span style={{ fontSize: '22px', fontWeight: 900, color: P.onSurface, lineHeight: 1 }}>{total}</span>
                <span style={{ fontSize: '9px', color: P.outline, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em', marginTop: '2px' }}>Total</span>
            </div>
        </div>
    );
}

export default function Statistiques() {
    const [livraisons, setLivraisons] = useState([]);
    const [livreurs, setLivreurs]     = useState([]);
    const [loading, setLoading]       = useState(true);
    const [periode, setPeriode]       = useState('tout');

    useEffect(function() {
        Promise.all([
            api.get('/livraisons').catch(function() { return { data: [] }; }),
            api.get('/livreurs?all=true').catch(function() { return { data: [] }; }),
        ]).then(function([lRes, drRes]) {
            setLivraisons(lRes.data || []);
            setLivreurs(drRes.data || []);
        }).finally(function() { setLoading(false); });
    }, []);

    var maintenant = new Date();
    var seuilJours = periode === '7j' ? 7 : periode === '30j' ? 30 : null;

    var livraisonsFiltrees = livraisons.filter(function(l) {
        if (!seuilJours) return true;
        var d = new Date(l.creation_date);
        var diffJours = (maintenant - d) / (1000 * 60 * 60 * 24);
        return diffJours <= seuilJours;
    });

    var totalLivraisons = livraisonsFiltrees.length;
    var livrees   = livraisonsFiltrees.filter(function(l) { return l.status === 'Livr_'; });
    var annulees  = livraisonsFiltrees.filter(function(l) { return l.status === 'Annul_'; });
    var enCours   = livraisonsFiltrees.filter(function(l) { return ['Assign_','Valide_','En_cours'].includes(l.status); });
    var enAttente = livraisonsFiltrees.filter(function(l) { return ['Commande','En_attente'].includes(l.status); });
    var tauxReussite = totalLivraisons > 0 ? Math.round((livrees.length / totalLivraisons) * 100) : 0;

    var caTotal = livrees.reduce(function(sum, l) { return sum + (Number(l.amount_to_collect) || 0); }, 0);
    var fraisTotal = livrees.reduce(function(sum, l) { return sum + (Number(l.frais_livraison) || 0); }, 0);

    var zonesCount = {};
    livraisonsFiltrees.forEach(function(l) {
        var adresse = (l.delivery_address || '').split(',')[0].trim();
        if (!adresse) return;
        zonesCount[adresse] = (zonesCount[adresse] || 0) + 1;
    });
    var zonesTriees = Object.entries(zonesCount).sort(function(a, b) { return b[1] - a[1]; }).slice(0, 7);
    var zoneMax = zonesTriees.length > 0 ? zonesTriees[0][1] : 1;

    var livreurStats = {};
    livraisonsFiltrees.forEach(function(l) {
        if (!l.delivery_person_id) return;
        if (!livreurStats[l.delivery_person_id]) livreurStats[l.delivery_person_id] = { total: 0, livrees: 0 };
        livreurStats[l.delivery_person_id].total++;
        if (l.status === 'Livr_') livreurStats[l.delivery_person_id].livrees++;
    });

    var livreursAvecStats = livreurs.map(function(lv) {
        var u = Array.isArray(lv.users) ? (lv.users.find(function(x) { return x.id === lv.user_id; }) || lv.users[0]) : lv.users;
        var s = livreurStats[lv.id] || { total: 0, livrees: 0 };
        return {
            id: lv.id,
            nom: u ? u.first_name + ' ' + u.last_name : 'Livreur #' + lv.id,
            total: s.total,
            livrees: s.livrees,
        };
    }).filter(function(l) { return l.total > 0; })
      .sort(function(a, b) { return b.livrees - a.livrees; })
      .slice(0, 7);

    var livreurMax = livreursAvecStats.length > 0 ? livreursAvecStats[0].livrees : 1;

    var repartition = [
        { label: 'Livrées',    value: livrees.length,    color: P.green },
        { label: 'En cours',   value: enCours.length,    color: P.blue },
        { label: 'En attente', value: enAttente.length,  color: P.primaryContainer },
        { label: 'Annulées',   value: annulees.length,   color: P.error },
    ];

    if (loading) return (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '50vh', fontFamily: 'Poppins, sans-serif' }}>
            <div style={{ textAlign: 'center' }}>
                <div style={{ width: '32px', height: '32px', border: '3px solid ' + P.surfaceContainerLow, borderTopColor: P.primaryContainer, borderRadius: '50%', margin: '0 auto 12px', animation: 'spin 0.8s linear infinite' }}></div>
                <p style={{ color: P.outline, fontSize: '13px', margin: 0 }}>Chargement des statistiques...</p>
            </div>
            <style>{'@keyframes spin { to { transform: rotate(360deg); } }'}</style>
        </div>
    );

    return (
        <div style={{ fontFamily: 'Poppins, sans-serif' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '22px', flexWrap: 'wrap', gap: '12px' }}>
                <div>
                    <h1 style={{ fontSize: '21px', fontWeight: 900, color: P.onSurface, margin: '0 0 3px 0' }}>📊 Statistiques</h1>
                    <p style={{ fontSize: '12.5px', color: P.outline, margin: 0 }}>Vue d'ensemble des livreurs, commandes et zones de livraison.</p>
                </div>
                <div style={{ display: 'flex', gap: '4px', backgroundColor: P.surfaceContainerLow, borderRadius: '10px', padding: '4px' }}>
                    {[
                        { key: 'tout', label: 'Tout' },
                        { key: '30j', label: '30 jours' },
                        { key: '7j', label: '7 jours' },
                    ].map(function(p) {
                        var active = periode === p.key;
                        return (
                            <button key={p.key} onClick={function() { setPeriode(p.key); }}
                                style={{
                                    padding: '7px 16px', borderRadius: '8px', border: 'none', cursor: 'pointer',
                                    fontSize: '12px', fontWeight: 700, fontFamily: 'Poppins, sans-serif',
                                    backgroundColor: active ? P.surface : 'transparent',
                                    color: active ? P.primary : P.outline,
                                    boxShadow: active ? '0 2px 6px rgba(0,0,0,0.08)' : 'none',
                                    transition: 'all 0.15s',
                                }}>
                                {p.label}
                            </button>
                        );
                    })}
                </div>
            </div>

            {/* KPIs principaux */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px', marginBottom: '14px' }}>
                <KpiCard label="Total commandes" value={totalLivraisons} icon=""
                    gradient={'linear-gradient(135deg, ' + P.inverseS + ', #1a1c1c)'} />
                <KpiCard label="Livrées" value={livrees.length} sub={tauxReussite + '% de réussite'} icon="" />
                <KpiCard label="En cours" value={enCours.length} icon="" />
                <KpiCard label="Annulées" value={annulees.length} icon="" />
            </div>

            {/* KPIs financiers */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '20px' }}>
                <KpiCard label="Chiffre d'affaires marchandise" value={caTotal.toLocaleString('fr-FR') + ' FCFA'}
                    sub="Sur commandes livrées" icon=""
                    gradient={'linear-gradient(135deg, ' + P.primary + ', ' + P.primaryContainer + ')'} />
                <KpiCard label="Frais de livraison collectés" value={fraisTotal.toLocaleString('fr-FR') + ' FCFA'}
                    sub="Sur commandes livrées" icon=""
                    gradient={'linear-gradient(135deg, ' + P.blue + ', #4a90d9)'} />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '280px 1fr', gap: '16px', marginBottom: '4px' }}>
                {/* Répartition en donut */}
                <Section title="Répartition des statuts" icon="">
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '18px' }}>
                        <DonutChart segments={repartition} size={140} thickness={20} />
                        <div style={{ width: '100%', display: 'grid', gap: '8px' }}>
                            {repartition.map(function(r, i) {
                                var pct = totalLivraisons > 0 ? Math.round((r.value / totalLivraisons) * 100) : 0;
                                return (
                                    <div key={i} style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                        <div style={{ width: '9px', height: '9px', borderRadius: '3px', backgroundColor: r.color, flexShrink: 0 }}></div>
                                        <span style={{ fontSize: '11.5px', color: P.onSurface, fontWeight: 500, flex: 1 }}>{r.label}</span>
                                        <span style={{ fontSize: '11.5px', color: P.outline, fontWeight: 700 }}>{r.value} · {pct}%</span>
                                    </div>
                                );
                            })}
                        </div>
                    </div>
                </Section>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                    {/* Zones */}
                    <Section title="Zones les plus livrées" icon="">
                        {zonesTriees.length === 0 ? (
                            <p style={{ fontSize: '12px', color: P.outline, fontStyle: 'italic', margin: 0, textAlign: 'center', padding: '20px 0' }}>Aucune donnée pour cette période.</p>
                        ) : (
                            zonesTriees.map(function([zone, count], i) {
                                return <BarRow key={i} rank={i+1} label={zone} value={count} max={zoneMax}
                                    color={'linear-gradient(90deg, ' + P.primaryContainer + ', ' + P.primary + ')'} />;
                            })
                        )}
                    </Section>

                    {/* Livreurs */}
                    <Section title="Livreurs les plus actifs" icon="">
                        {livreursAvecStats.length === 0 ? (
                            <p style={{ fontSize: '12px', color: P.outline, fontStyle: 'italic', margin: 0, textAlign: 'center', padding: '20px 0' }}>Aucune donnée pour cette période.</p>
                        ) : (
                            livreursAvecStats.map(function(l, i) {
                                var tauxLivreur = l.total > 0 ? Math.round((l.livrees / l.total) * 100) : 0;
                                return (
                                    <BarRow key={l.id} rank={i+1} label={l.nom} value={l.livrees} max={livreurMax}
                                        suffix={' / ' + l.total} sub={tauxLivreur + '% de réussite'}
                                        color={'linear-gradient(90deg, ' + P.blue + ', #4a90d9)'} />
                                );
                            })
                        )}
                    </Section>
                </div>
            </div>
        </div>
    );
}