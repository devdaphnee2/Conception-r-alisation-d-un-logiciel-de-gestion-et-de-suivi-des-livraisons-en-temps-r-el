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
  getDeliveryPersonStatus,
  createLitige
} = require('../models/clientModel');
const pool = require('../config/db');

// Récupérer le customer_id à partir de req.user.id (table customers liée à users)
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
      return res.status(400).json({ message: 'Le motif d\'annulation est requis.' });
    }

    const customerId = await getCustomerId(req.user.id);
    const livraison = await getDeliveryOrderForCustomer(id, customerId);
    if (!livraison) {
      return res.status(404).json({ message: 'Livraison introuvable.' });
    }

    if (['Livré', 'Annulé'].includes(livraison.status)) {
      return res.status(400).json({ message: `Impossible d'annuler une livraison au statut "${livraison.status}".` });
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
// ──────────────────────────────────────────────
async function declarerLitige(req, res) {
  try {
    const { deliveryorder_id, description } = req.body;

    if (!deliveryorder_id || !description) {
      return res.status(400).json({ message: 'ID de livraison et description requis.' });
    }

    const customerId = await getCustomerId(req.user.id);
    const livraison = await getDeliveryOrderForCustomer(deliveryorder_id, customerId);
    if (!livraison) {
      return res.status(404).json({ message: 'Livraison introuvable.' });
    }

    // Un litige ne peut être déclaré que sur une livraison ayant eu un livreur
    // validé par le manager (statut Disponible au moment de l'assignation).
    if (!livraison.delivery_person_id) {
      return res.status(400).json({
        message: 'Impossible de déclarer un litige : aucun livreur validé n\'a été assigné à cette livraison.'
      });
    }

    // Snapshot du statut actuel du livreur (traçabilité, sans bloquer le litige)
    const livreurStatut = await getDeliveryPersonStatus(livraison.delivery_person_id);

    const litigeId = await createLitige({
      deliveryorder_id,
      customer_id: customerId,
      delivery_person_id: livraison.delivery_person_id,
      description,
      livreur_statut: livreurStatut
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