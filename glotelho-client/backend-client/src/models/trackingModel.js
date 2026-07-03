// src/models/trackingModel.js
const pool = require('../config/db');

// ── Dernière position connue d'un livreur ────────────────────────
const getLastPosition = async (deliveryPersonId) => {
  const [rows] = await pool.query(
    `SELECT latitude, longitude, speed, recorded_at
     FROM position_tracking
     WHERE delivery_person_id = ?
     ORDER BY recorded_at DESC
     LIMIT 1`,
    [deliveryPersonId]
  );
  return rows[0];
};

// ── Historique des positions (pour tracer le trajet) ─────────────
const getPositionHistory = async (deliveryPersonId, raceId) => {
  const [rows] = await pool.query(
    `SELECT latitude, longitude, speed, recorded_at
     FROM position_tracking
     WHERE delivery_person_id = ?
     ${raceId ? 'AND race_id = ?' : ''}
     ORDER BY recorded_at ASC`,
    raceId ? [deliveryPersonId, raceId] : [deliveryPersonId]
  );
  return rows;
};

// ── Livreur assigné à une commande client ────────────────────────
const getDeliveryPersonByOrderId = async (orderId) => {
  const [rows] = await pool.query(
    `SELECT dp.id AS delivery_person_id,
            u.first_name, u.last_name, u.phone,
            dp.status
     FROM orders o
     JOIN deliveryorders d ON d.customer_id = o.customer_id
     JOIN delivery_persons dp ON d.delivery_person_id = dp.id
     JOIN users u ON dp.user_id = u.id
     WHERE o.id = ?
     AND d.status = 'En_cours'
     LIMIT 1`,
    [orderId]
  );
  return rows[0];
};

module.exports = { getLastPosition, getPositionHistory, getDeliveryPersonByOrderId };