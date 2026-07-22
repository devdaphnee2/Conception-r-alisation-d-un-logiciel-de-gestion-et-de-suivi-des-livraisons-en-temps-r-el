const express = require('express');
const router = express.Router();
const prisma = require('../../utils/prismaClient');
const axios = require('axios');

const CAMPAY_BASE_URL = process.env.CAMPAY_BASE_URL || 'https://demo.campay.net/api';
const CAMPAY_TOKEN    = process.env.CAMPAY_TOKEN;

// ── GET /api/paiement/:id — Infos livraison pour la page facture ──────────
router.get('/:id', async (req, res) => {
    try {
        const livraison = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) },
            include: {
                delivery_items: true,
                delivery_persons: { include: { vehicules: true } },
                confirmations: true,
            }
        });
        if (!livraison) return res.status(404).json({ message: 'Livraison introuvable.' });

        // Vérifier si déjà payée
        if (livraison.payment_status === 'paid') {
            return res.json({ ...livraison, already_paid: true });
        }

        res.json({ ...livraison, already_paid: false });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
});

// ── POST /api/paiement/:id/initier — Initier le paiement CamPay ──────────
router.post('/:id/initier', async (req, res) => {
    try {
        const { telephone } = req.body;
        if (!telephone) return res.status(400).json({ message: 'Numéro de téléphone requis.' });

        const livraison = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) },
            include: { delivery_items: true }
        });
        if (!livraison) return res.status(404).json({ message: 'Livraison introuvable.' });
        if (livraison.payment_status === 'paid') {
            return res.status(400).json({ message: 'Cette livraison a déjà été payée.' });
        }

        const montant = Math.round(Number(livraison.amount_to_collect || 0));
        if (montant <= 0) return res.status(400).json({ message: 'Montant invalide.' });

        // Formater le numéro (doit commencer par 237)
        let tel = telephone.replace(/\s/g, '').replace(/\+/g, '');
        if (!tel.startsWith('237')) tel = '237' + tel;

        // Appel CamPay /collect/
        const campayRes = await axios.post(
            CAMPAY_BASE_URL + '/collect/',
            {
                amount      : String(montant),
                from        : tel,
                description : 'Paiement commande Glotelho #' + String(livraison.id).padStart(5, '0'),
                external_reference: String(livraison.id),
            },
            {
                headers: {
                    Authorization : 'Token ' + CAMPAY_TOKEN,
                    'Content-Type': 'application/json',
                }
            }
        );

        const reference = campayRes.data.reference;
        if (!reference) return res.status(500).json({ message: 'Erreur CamPay : pas de référence.' });

        // Sauvegarder la référence de paiement
        await prisma.deliveryorders.update({
            where: { id: livraison.id },
            data: { payment_reference: reference, payment_status: 'pending' }
        });

        res.json({
            message  : 'Paiement initié. Confirmez sur votre téléphone.',
            reference: reference,
            montant  : montant,
        });
    } catch (err) {
        const campayMsg = err.response?.data?.detail || err.response?.data?.message || err.message;
        res.status(500).json({ message: 'Erreur paiement : ' + campayMsg });
    }
});

// ── GET /api/paiement/:id/verifier?reference=xxx — Vérifier le statut ────
router.get('/:id/verifier', async (req, res) => {
    try {
        const { reference } = req.query;
        if (!reference) return res.status(400).json({ message: 'Référence requise.' });

        // Vérifier le statut chez CamPay
        const campayRes = await axios.get(
            CAMPAY_BASE_URL + '/transaction/' + reference + '/',
            {
                headers: {
                    Authorization: 'Token ' + CAMPAY_TOKEN,
                }
            }
        );

        const status = campayRes.data.status; // SUCCESSFUL, FAILED, PENDING

        if (status === 'SUCCESSFUL') {
            // Marquer la livraison comme payée
            await prisma.deliveryorders.update({
                where: { id: parseInt(req.params.id) },
                data: {
                    payment_status: 'paid',
                    payment_reference: reference,
                }
            });
            return res.json({ status: 'SUCCESSFUL', message: 'Paiement confirmé !' });
        }

        if (status === 'FAILED') {
            await prisma.deliveryorders.update({
                where: { id: parseInt(req.params.id) },
                data: { payment_status: 'failed' }
            });
            return res.json({ status: 'FAILED', message: 'Paiement échoué.' });
        }

        res.json({ status: 'PENDING', message: 'En attente de confirmation...' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur vérification : ' + err.message });
    }
});

module.exports = router;