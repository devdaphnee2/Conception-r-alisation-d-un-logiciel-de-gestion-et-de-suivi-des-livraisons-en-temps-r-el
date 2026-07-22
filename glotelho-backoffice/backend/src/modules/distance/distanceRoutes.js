const express = require('express');
const router = express.Router();
const axios = require('axios');

const MAPBOX_TOKEN = 'pk.eyJ1IjoiYW1hbmRpbmVraWx5IiwiYSI6ImNtcjRyZzd2NzBjc3UzMHIwdHkxZmdnZWIifQ.CrM5ELxBNEXlP4rQzxsxow';

// Formule : Prix = F_base + (D x T_km) + Σ Surcharges
const FRAIS_BASE = 500; // F_base — prise en charge
const TARIF_PAR_KM = 200; // T_km — tarif au kilomètre
const SURCHARGE_COLIS_GROS = 700; // colis volumineux
const SURCHARGE_EXPRESS = 700; // livraison express

// ── POST /api/distance/calculer-frais ──────────────────────────
// body: { adresse_depart, adresse_arrivee, format_colis, express }
router.post('/calculer-frais', async(req, res) => {
    try {
        const {
            adresse_depart,
            adresse_arrivee,
            format_colis,
            express,
            lat_depart,
            lng_depart,
            lat_arrivee,
            lng_arrivee
        } = req.body;
        if (!adresse_depart || !adresse_arrivee) {
            return res.status(400).json({ message: 'Les deux adresses sont requises.' });
        }

        async function geocoder(adresse) {
            const url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/' +
                encodeURIComponent(adresse + ', Douala, Cameroun') +
                '.json?access_token=' + MAPBOX_TOKEN + '&limit=1';
            const res = await axios.get(url);
            if (!res.data.features || res.data.features.length === 0) return null;
            return res.data.features[0].center; // [lng, lat]
        }

        // Utiliser les coordonnées GPS déjà connues (AdresseInput) si fournies —
        // évite un nouveau géocodage textuel qui peut renvoyer 2 points identiques
        let depart = (lng_depart != null && lat_depart != null) ? [lng_depart, lat_depart] : null;
        let arrivee = (lng_arrivee != null && lat_arrivee != null) ? [lng_arrivee, lat_arrivee] : null;

        if (!depart) depart = await geocoder(adresse_depart);
        if (!arrivee) arrivee = await geocoder(adresse_arrivee);

        if (!depart || !arrivee) {
            return res.status(404).json({ message: 'Adresse introuvable. Précisez le quartier.' });
        }

        // Calcul de la distance routière réelle via Mapbox Directions
        const dirUrl = 'https://api.mapbox.com/directions/v5/mapbox/driving/' +
            depart[0] + ',' + depart[1] + ';' + arrivee[0] + ',' + arrivee[1] +
            '?access_token=' + MAPBOX_TOKEN;
        const dirRes = await axios.get(dirUrl);

        if (!dirRes.data.routes || dirRes.data.routes.length === 0) {
            return res.status(404).json({ message: 'Itinéraire introuvable.' });
        }

        const distanceMetres = dirRes.data.routes[0].distance;
        const distanceKm = distanceMetres / 1000;

        // ── Surcharges ──────────────────────────────────────────
        let surcharges = 0;
        const details = [];
        if (format_colis === 'Gros') {
            surcharges += SURCHARGE_COLIS_GROS;
            details.push({ label: 'Colis volumineux', montant: SURCHARGE_COLIS_GROS });
        }
        if (express === true) {
            surcharges += SURCHARGE_EXPRESS;
            details.push({ label: 'Livraison express', montant: SURCHARGE_EXPRESS });
        }

        // ── Formule : Prix = F_base + (D x T_km) + Σ Surcharges ──
        const coutDistance = distanceKm * TARIF_PAR_KM;
        let frais = FRAIS_BASE + coutDistance + surcharges;
        frais = Math.round(frais / 50) * 50; // arrondi à 50 XAF près

        res.json({
            distance_km: Math.round(distanceKm * 10) / 10,
            frais_base: FRAIS_BASE,
            cout_distance: Math.round(coutDistance),
            surcharges: surcharges,
            surcharges_details: details,
            frais_livraison: frais,
            depart_coords: depart,
            arrivee_coords: arrivee,
        });
    } catch (err) {
        res.status(500).json({ message: 'Erreur calcul distance', error: err.message });
    }
});

module.exports = router;