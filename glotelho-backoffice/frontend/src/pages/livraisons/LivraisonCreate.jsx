import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import api from '../../services/api';
import BackButton from '../../components/BackButton';

const P = {
    primary: '#7d5700', primaryContainer: '#c9952e',
    primaryFixed: '#ffdea9', onPrimaryContainer: '#483100',
    error: '#ba1a1a', errorContainer: '#ffdad6', onErrorContainer: '#93000a',
    surface: '#ffffff', surfaceContainerLow: '#f3f3f3',
    onSurface: '#1a1c1c', onSurfaceVariant: '#4f4536',
    outline: '#817564', outlineVariant: '#d3c4b0',
};

const ARTICLE_VIDE = { nom: '', quantite: 1, prix_unitaire: '' };

export default function LivraisonCreate() {
    const navigate = useNavigate();

    const [client, setClient] = useState({
        nom: '', telephone: '', whatsapp: '', adresse_livraison: '', zone_bloc: '', instructions: ''
    });

    const [articles, setArticles] = useState([{ ...ARTICLE_VIDE }]);

    const [livraison, setLivraison] = useState({
        montant_livraison: '500', date_souhaitee: '', livreur_id: ''
    });

    const [livreurs, setLivreurs] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        api.get('/livreurs').then(res => setLivreurs(res.data || [])).catch(() => {});
    }, []);

    function handleClientChange(e) {
        setClient({ ...client, [e.target.name]: e.target.value });
    }

    function handleLivraisonChange(e) {
        setLivraison({ ...livraison, [e.target.name]: e.target.value });
    }

    function handleArticleChange(index, field, value) {
        const updated = articles.map((a, i) => i === index ? { ...a, [field]: value } : a);
        setArticles(updated);
    }

    function addArticle() {
        setArticles([...articles, { ...ARTICLE_VIDE }]);
    }

    function removeArticle(index) {
        if (articles.length === 1) return;
        setArticles(articles.filter((_, i) => i !== index));
    }

    const totalArticles = articles.reduce((sum, a) => {
        const qty = parseInt(a.quantite) || 0;
        const prix = parseFloat(a.prix_unitaire) || 0;
        return sum + qty * prix;
    }, 0);

    const fraisLivraison = parseFloat(livraison.montant_livraison) || 0;
    const totalGeneral = totalArticles + fraisLivraison;

    async function handleSubmit(e) {
        e.preventDefault();
        setError('');

        const articlesValides = articles.filter(a => a.nom.trim());
        if (articlesValides.length === 0) {
            setError('Ajoutez au moins un article.');
            return;
        }

        setLoading(true);
        try {
            const payload = {
                client_nom: client.nom,
                client_telephone: client.telephone,
                client_whatsapp: client.whatsapp || client.telephone,
                delivery_address: client.adresse_livraison,
                zone_bloc: client.zone_bloc,
                delivery_instructions: client.instructions,
                amount_to_collect: totalGeneral,
                collected_amount: 0,
                montant_livraison: fraisLivraison,
                articles: articlesValides,
                delivery_person_id: livraison.livreur_id || null,
                delivery_date: livraison.date_souhaitee || null,
            };

            await api.post('/livraisons', payload);
            navigate('/livraisons');
        } catch (err) {
            setError(
                (err.response && err.response.data && err.response.data.message)
                    ? err.response.data.message
                    : 'Erreur lors de la creation.'
            );
        } finally {
            setLoading(false);
        }
    }

    const inputStyle = {
        width: '100%', padding: '11px 14px', borderRadius: '10px',
        border: '1.5px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow,
        fontSize: '13px', color: P.onSurface, outline: 'none',
        boxSizing: 'border-box', fontFamily: 'Poppins, sans-serif'
    };

    const labelStyle = {
        display: 'block', fontSize: '11px', fontWeight: 600,
        color: P.onSurfaceVariant, textTransform: 'uppercase',
        letterSpacing: '0.07em', marginBottom: '7px'
    };

    function SectionTitle({ children }) {
        return (
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', margin: '8px 0 16px' }}>
                <p style={{ margin: 0, fontSize: '13px', fontWeight: 700, color: P.onSurface, whiteSpace: 'nowrap' }}>{children}</p>
                <div style={{ flex: 1, height: '1px', backgroundColor: P.outlineVariant }}></div>
            </div>
        );
    }

    return (
        <div style={{ maxWidth: '800px', fontFamily: 'Poppins, sans-serif' }}>
            <BackButton to="/livraisons" />
            <div style={{ marginBottom: '20px' }}>
                <Link to="/livraisons" style={{ color: P.outline, textDecoration: 'none', fontSize: '13px' }}>Livraisons</Link>
                <span style={{ color: P.outlineVariant, margin: '0 6px' }}>/</span>
                <span style={{ color: P.onSurface, fontSize: '13px', fontWeight: 500 }}>Nouvelle livraison</span>
            </div>

            <div style={{ backgroundColor: P.surface, borderRadius: '14px', border: '1px solid ' + P.outlineVariant, padding: '28px', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>

                {error && (
                    <div style={{ backgroundColor: P.errorContainer, color: P.error, padding: '10px 14px', borderRadius: '8px', marginBottom: '20px', fontSize: '13px', fontWeight: 500 }}>
                        {error}
                    </div>
                )}

                <form onSubmit={handleSubmit}>

                    {/* INFORMATIONS CLIENT */}
                    <SectionTitle>Informations client</SectionTitle>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px', marginBottom: '14px' }}>
                        <div>
                            <label style={labelStyle}>Nom complet du client *</label>
                            <input type="text" name="nom" value={client.nom} onChange={handleClientChange}
                                style={inputStyle} placeholder="Ex: Marie Ngono" required />
                        </div>
                        <div>
                            <label style={labelStyle}>Telephone *</label>
                            <input type="text" name="telephone" value={client.telephone} onChange={handleClientChange}
                                style={inputStyle} placeholder="655 112 233" required />
                        </div>
                        <div>
                            <label style={labelStyle}>
                                Numero WhatsApp
                                <span style={{ fontWeight: 400, textTransform: 'none', marginLeft: '4px' }}>(si different)</span>
                            </label>
                            <input type="text" name="whatsapp" value={client.whatsapp} onChange={handleClientChange}
                                style={inputStyle} placeholder="655 112 233" />
                        </div>
                    </div>

                    {/* ADRESSE LIVRAISON */}
                    <SectionTitle>Adresse de livraison</SectionTitle>
                    <div style={{ marginBottom: '14px' }}>
                        <label style={labelStyle}>Adresse complete *</label>
                        <input type="text" name="adresse_livraison" value={client.adresse_livraison} onChange={handleClientChange}
                            style={inputStyle} placeholder="Ex: Bonamoussadi, Rue des Manguiers" required />
                    </div>
                    <div style={{ marginBottom: '14px' }}>
                        <label style={labelStyle}>Description du lieu / Repere</label>
                        <input type="text" name="zone_bloc" value={client.zone_bloc} onChange={handleClientChange}
                            style={inputStyle} placeholder="Ex: Apres le carrefour Shell, portail rouge" />
                    </div>
                    <div style={{ marginBottom: '20px' }}>
                        <label style={labelStyle}>Instructions speciales</label>
                        <textarea name="instructions" value={client.instructions} onChange={handleClientChange}
                            rows={2} style={{ ...inputStyle, resize: 'vertical' }}
                            placeholder="Ex: Colis fragile, appeler avant d'arriver..." />
                    </div>

                    {/* ARTICLES */}
                    <SectionTitle>Articles de la commande</SectionTitle>

                    {articles.map((article, i) => (
                        <div key={i} style={{ padding: '14px', backgroundColor: P.surfaceContainerLow, borderRadius: '10px', border: '1px solid ' + P.outlineVariant, marginBottom: '10px' }}>
                            <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr 1fr auto', gap: '10px', alignItems: 'end' }}>
                                <div>
                                    <label style={{ ...labelStyle, marginBottom: '5px' }}>Designation *</label>
                                    <input type="text" value={article.nom}
                                        onChange={e => handleArticleChange(i, 'nom', e.target.value)}
                                        style={inputStyle} placeholder="Ex: Creme Balea 125ml" />
                                </div>
                                <div>
                                    <label style={{ ...labelStyle, marginBottom: '5px' }}>Quantite</label>
                                    <input type="number" value={article.quantite}
                                        onChange={e => handleArticleChange(i, 'quantite', e.target.value)}
                                        style={inputStyle} min="1" />
                                </div>
                                <div>
                                    <label style={{ ...labelStyle, marginBottom: '5px' }}>Prix unitaire (FCFA)</label>
                                    <input type="number" value={article.prix_unitaire}
                                        onChange={e => handleArticleChange(i, 'prix_unitaire', e.target.value)}
                                        style={inputStyle} min="0" placeholder="0" />
                                </div>
                                <button type="button" onClick={() => removeArticle(i)}
                                    disabled={articles.length === 1}
                                    style={{
                                        padding: '11px 14px', borderRadius: '8px',
                                        border: '1px solid ' + P.outlineVariant,
                                        backgroundColor: articles.length === 1 ? P.surfaceContainerLow : P.errorContainer,
                                        color: articles.length === 1 ? P.outline : P.error,
                                        cursor: articles.length === 1 ? 'not-allowed' : 'pointer',
                                        fontFamily: 'Poppins, sans-serif', fontSize: '16px'
                                    }}>
                                    ×
                                </button>
                            </div>
                            {article.nom && article.prix_unitaire && (
                                <p style={{ margin: '8px 0 0', fontSize: '11px', color: P.outline, textAlign: 'right' }}>
                                    Sous-total : <strong style={{ color: P.primary }}>
                                        {((parseInt(article.quantite) || 1) * (parseFloat(article.prix_unitaire) || 0)).toLocaleString('fr-FR')} FCFA
                                    </strong>
                                </p>
                            )}
                        </div>
                    ))}

                    <button type="button" onClick={addArticle}
                        style={{ width: '100%', padding: '10px', borderRadius: '10px', border: '1.5px dashed ' + P.outlineVariant, backgroundColor: 'transparent', color: P.primary, fontSize: '13px', fontWeight: 600, cursor: 'pointer', fontFamily: 'Poppins, sans-serif', marginBottom: '20px' }}>
                        + Ajouter un article
                    </button>

                    {/* RECAPITULATIF MONTANTS */}
                    <div style={{ backgroundColor: P.surfaceContainerLow, borderRadius: '10px', padding: '14px 16px', border: '1px solid ' + P.outlineVariant, marginBottom: '20px' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                            <span style={{ fontSize: '12px', color: P.outline }}>Sous-total articles</span>
                            <span style={{ fontSize: '12px', fontWeight: 600, color: P.onSurface }}>{totalArticles.toLocaleString('fr-FR')} FCFA</span>
                        </div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
                            <span style={{ fontSize: '12px', color: P.outline }}>Frais de livraison</span>
                            <input type="number" name="montant_livraison" value={livraison.montant_livraison}
                                onChange={handleLivraisonChange}
                                style={{ width: '130px', padding: '6px 10px', borderRadius: '8px', border: '1px solid ' + P.outlineVariant, fontSize: '12px', fontFamily: 'Poppins, sans-serif', textAlign: 'right', outline: 'none', backgroundColor: P.surface }} />
                        </div>
                        <div style={{ borderTop: '1px solid ' + P.outlineVariant, paddingTop: '10px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <span style={{ fontSize: '14px', fontWeight: 700, color: P.onSurface }}>Total a collecter</span>
                            <span style={{ fontSize: '20px', fontWeight: 800, color: P.primary }}>{totalGeneral.toLocaleString('fr-FR')} FCFA</span>
                        </div>
                    </div>

                    {/* ASSIGNATION */}
                    <SectionTitle>Assignation livreur</SectionTitle>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px', marginBottom: '24px' }}>
                        <div>
                            <label style={labelStyle}>
                                Livreur
                                <span style={{ fontWeight: 400, textTransform: 'none', marginLeft: '4px' }}>(optionnel)</span>
                            </label>
                            <select name="livreur_id" value={livraison.livreur_id} onChange={handleLivraisonChange} style={inputStyle}>
                                <option value="">-- Assigner plus tard --</option>
                                {livreurs.map(l => (
                                    <option key={l.id} value={l.id}>
                                        {l.users && l.users.first_name} {l.users && l.users.last_name} — {l.zone_affectee || 'Sans zone'}
                                    </option>
                                ))}
                            </select>
                        </div>
                        <div>
                            <label style={labelStyle}>Date souhaitee</label>
                            <input type="datetime-local" name="date_souhaitee" value={livraison.date_souhaitee}
                                onChange={handleLivraisonChange} style={inputStyle} />
                        </div>
                    </div>

                    {/* BOUTONS */}
                    <div style={{ display: 'flex', gap: '12px', paddingTop: '8px', borderTop: '1px solid ' + P.outlineVariant }}>
                        <button type="submit" disabled={loading}
                            style={{
                                backgroundColor: loading ? P.outline : P.primary,
                                color: '#fff', padding: '12px 28px', borderRadius: '10px',
                                border: 'none', fontSize: '13px', fontWeight: 600,
                                cursor: loading ? 'not-allowed' : 'pointer',
                                fontFamily: 'Poppins, sans-serif',
                                boxShadow: loading ? 'none' : '0 4px 12px rgba(125,87,0,0.28)'
                            }}>
                            {loading ? 'Creation en cours...' : 'Creer la livraison'}
                        </button>
                        <Link to="/livraisons"
                            style={{ padding: '12px 24px', borderRadius: '10px', border: '1px solid ' + P.outlineVariant, backgroundColor: P.surfaceContainerLow, color: P.onSurface, fontSize: '13px', fontWeight: 500, textDecoration: 'none', display: 'inline-flex', alignItems: 'center' }}>
                            Annuler
                        </Link>
                    </div>

                </form>
            </div>
        </div>
    );
}