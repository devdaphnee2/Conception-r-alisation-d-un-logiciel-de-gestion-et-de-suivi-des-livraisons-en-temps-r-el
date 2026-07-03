// src/controllers/trackingController.js
const {
  getLastPosition,
  getPositionHistory,
  getDeliveryPersonByOrderId
} = require('../models/trackingModel');
const pool = require('../config/db');

// ── 1. Dernière position d'un livreur ────────────────────────────
// GET /api/v1/tracking/livreur/:delivery_person_id
async function getLastPositionHandler(req, res) {
  try {
    const { delivery_person_id } = req.params;

    const position = await getLastPosition(delivery_person_id);
    if (!position) {
      return res.status(404).json({
        message: 'Aucune position disponible pour ce livreur.',
        position: null
      });
    }

    res.json({
      delivery_person_id: parseInt(delivery_person_id),
      position: {
        latitude:    parseFloat(position.latitude),
        longitude:   parseFloat(position.longitude),
        speed:       position.speed || 0,
        recorded_at: position.recorded_at
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ── 2. Suivi en direct d'une commande ────────────────────────────
// GET /api/v1/tracking/order/:order_id
async function trackOrder(req, res) {
  try {
    const { order_id } = req.params;

    // Récupérer le customer_id depuis le token
    const [customerRows] = await pool.query(
      'SELECT id FROM customers WHERE user_id = ?', [req.user.id]
    );
    const customerId = customerRows[0]?.id;

    // Vérifier que la commande appartient à ce client
    const [orderRows] = await pool.query(
      'SELECT id, status FROM orders WHERE id = ? AND customer_id = ?',
      [order_id, customerId]
    );
    if (!orderRows[0]) {
      return res.status(404).json({ message: 'Commande introuvable.' });
    }

    // Récupérer le livreur assigné
    const deliveryPerson = await getDeliveryPersonByOrderId(order_id);
    if (!deliveryPerson) {
      return res.status(404).json({
        message: 'Aucun livreur assigné à cette commande.',
        tracking: null
      });
    }

    // Récupérer sa dernière position
    const position = await getLastPosition(deliveryPerson.delivery_person_id);

    const fullName = [deliveryPerson.first_name, deliveryPerson.last_name]
      .filter(Boolean).join(' ').trim();

    res.json({
      order_id: parseInt(order_id),
      order_status: orderRows[0].status,
      livreur: {
        id:       deliveryPerson.delivery_person_id,
        nom:      fullName,
        phone:    deliveryPerson.phone,
        statut:   deliveryPerson.status
      },
      position: position ? {
        latitude:    parseFloat(position.latitude),
        longitude:   parseFloat(position.longitude),
        speed:       position.speed || 0,
        recorded_at: position.recorded_at
      } : null
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ── 3. Historique du trajet ───────────────────────────────────────
// GET /api/v1/tracking/livreur/:delivery_person_id/history
async function getPositionHistoryHandler(req, res) {
  try {
    const { delivery_person_id } = req.params;
    const { race_id } = req.query;

    const history = await getPositionHistory(delivery_person_id, race_id);

    res.json({
      delivery_person_id: parseInt(delivery_person_id),
      count: history.length,
      positions: history.map(p => ({
        latitude:    parseFloat(p.latitude),
        longitude:   parseFloat(p.longitude),
        speed:       p.speed || 0,
        recorded_at: p.recorded_at
      }))
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

module.exports = { getLastPositionHandler, trackOrder, getPositionHistoryHandler };