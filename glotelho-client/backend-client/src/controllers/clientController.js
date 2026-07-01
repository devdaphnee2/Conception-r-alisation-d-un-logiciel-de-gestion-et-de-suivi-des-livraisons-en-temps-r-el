// src/controllers/clientController.js
// Fonctionnalités client : historique, confirmation OTP, annulation, notation, litiges

const {
  getDeliveryOrdersByCustomerId,
  getDeliveryOrderForCustomer,
  getConfirmationByDeliveryOrder,
  validateConfirmation,
  markDeliveryAsDelivered,
  cancelDeliveryOrder,
  createNotation,
  hasNotation,
  getOrderIdByDeliveryOrder,
  getFirstManagerId,
  createLitige
} = require('../models/clientModel');
const pool = require('../config/db');

// Récupérer le customer_id à partir de req.user.id
async function getCustomerId(userId) {
  const [rows] = await pool.query('SELECT id FROM customers WHERE user_id = ?', [userId]);
  return rows[0]?.id;
}

// ──────────────────────────────────────────────
// 1. HISTORIQUE DES COMMANDES (GET /commandes)
// ──────────────────────────────────────────────
async function getCommandes(req, res) {
  try {
    const customerId = await getCustomerId(req.user.id);
    if (!customerId) {
      return res.status(404).json({ message: 'Profil client introuvable.' });
    }
    const livraisons = await getDeliveryOrdersByCustomerId(customerId);
    res.json({ livraisons });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 2. CONFIRMATION DE RÉCEPTION OTP (POST /confirmer)
// ──────────────────────────────────────────────
async function confirmerReception(req, res) {
  try {
    const { deliveryorder_id, otp_code } = req.body;

    if (!deliveryorder_id || !otp_code) {
      return res.status(400).json({ message: 'ID de livraison et code OTP requis.' });
    }

    const customerId = await getCustomerId(req.user.id);
    const livraison = await getDeliveryOrderForCustomer(deliveryorder_id, customerId);
    if (!livraison) {
      return res.status(404).json({ message: 'Livraison introuvable.' });
    }

    const confirmation = await getConfirmationByDeliveryOrder(deliveryorder_id);
    if (!confirmation || confirmation.methode !== 'OTP') {
      return res.status(400).json({ message: 'Aucune confirmation OTP en attente pour cette livraison.' });
    }

    if (confirmation.otp_code !== otp_code) {
      return res.status(401).json({ message: 'Code OTP incorrect.' });
    }

    await validateConfirmation(confirmation.id);
    await markDeliveryAsDelivered(deliveryorder_id);

    res.json({ message: 'Réception confirmée avec succès. Livraison marquée comme livrée.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 3. ANNULATION D'UNE LIVRAISON (POST /livraisons/:id/annuler)
// ──────────────────────────────────────────────
async function annulerLivraison(req, res) {
  try {
    const { id } = req.params;
    const { motif } = req.body;

    if (!motif) {
      return res.status(400).json({ message: "Le motif d'annulation est requis." });
    }

    const customerId = await getCustomerId(req.user.id);
    const livraison = await getDeliveryOrderForCustomer(id, customerId);
    if (!livraison) {
      return res.status(404).json({ message: 'Livraison introuvable.' });
    }

    // Vérifier les statuts ENUM exacts de la base
    if (['Livré', 'Annulé'].includes(livraison.status)) {
      return res.status(400).json({
        message: `Impossible d'annuler une livraison au statut "${livraison.status}".`
      });
    }

    await cancelDeliveryOrder(id, motif);
    res.json({ message: 'Livraison annulée avec succès.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 4. NOTATION DU LIVREUR (POST /noter)
// ──────────────────────────────────────────────
async function noterLivreur(req, res) {
  try {
    const { deliveryorder_id, note, commentaire } = req.body;

    if (!deliveryorder_id || !note) {
      return res.status(400).json({ message: 'ID de livraison et note requis.' });
    }
    if (note < 1 || note > 5) {
      return res.status(400).json({ message: 'La note doit être comprise entre 1 et 5.' });
    }

    const customerId = await getCustomerId(req.user.id);
    const livraison = await getDeliveryOrderForCustomer(deliveryorder_id, customerId);
    if (!livraison) {
      return res.status(404).json({ message: 'Livraison introuvable.' });
    }

    // Vérifier le statut ENUM exact
    if (livraison.status !== 'Livré') {
      return res.status(400).json({ message: 'Seule une livraison livrée peut être notée.' });
    }
    if (!livraison.delivery_person_id) {
      return res.status(400).json({ message: 'Aucun livreur associé à cette livraison.' });
    }

    const alreadyNoted = await hasNotation(deliveryorder_id);
    if (alreadyNoted) {
      return res.status(400).json({ message: 'Cette livraison a déjà été notée.' });
    }

    await createNotation({
      deliveryorder_id,
      customer_id: customerId,
      delivery_person_id: livraison.delivery_person_id,
      note,
      commentaire
    });

    res.status(201).json({ message: 'Merci pour votre évaluation !' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 5. DÉCLARATION D'UN LITIGE (POST /litiges)
// Stocké dans remises_compensations — cohérence avec le backend manager
// ──────────────────────────────────────────────
async function declarerLitige(req, res) {
  try {
    const { deliveryorder_id, type, reason, amount } = req.body;

    if (!deliveryorder_id || !type || !reason) {
      return res.status(400).json({
        message: 'ID de livraison, type et raison sont requis.',
        types_acceptes: ['Retour_produit', 'Rabais', 'Livraison_gratuite', 'Autre']
      });
    }

    const typesValides = ['Retour_produit', 'Rabais', 'Livraison_gratuite', 'Autre'];
    if (!typesValides.includes(type)) {
      return res.status(400).json({
        message: `Type invalide. Valeurs acceptées : ${typesValides.join(', ')}`
      });
    }

    const customerId = await getCustomerId(req.user.id);
    const livraison = await getDeliveryOrderForCustomer(deliveryorder_id, customerId);
    if (!livraison) {
      return res.status(404).json({ message: 'Livraison introuvable.' });
    }

    // Un litige ne peut être déclaré que si un livreur validé était assigné
    if (!livraison.delivery_person_id) {
      return res.status(400).json({
        message: "Impossible de déclarer un litige : aucun livreur validé n'a été assigné à cette livraison."
      });
    }

    // Récupérer l'order_id lié à cette livraison
    const orderId = await getOrderIdByDeliveryOrder(deliveryorder_id);
    if (!orderId) {
      return res.status(400).json({ message: 'Aucune commande associée à cette livraison.' });
    }

    // Récupérer le manager qui traitera le litige
    const managerId = await getFirstManagerId();
    if (!managerId) {
      return res.status(500).json({ message: 'Aucun manager disponible pour traiter le litige.' });
    }

    const litigeId = await createLitige({
      order_id: orderId,
      type,
      reason,
      amount,
      manager_id: managerId
    });

    res.status(201).json({
      message: 'Litige déclaré avec succès. Le manager va le traiter prochainement.',
      litige_id: litigeId
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

module.exports = { getCommandes, confirmerReception, annulerLivraison, noterLivreur, declarerLitige };