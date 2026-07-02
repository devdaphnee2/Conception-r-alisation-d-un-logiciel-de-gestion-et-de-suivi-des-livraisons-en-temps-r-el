// src/models/clientModel.js
// Requêtes SQL pour les fonctionnalités client (historique, confirmation, annulation, notation, litiges)

const pool = require('../config/db');

// ──────────────────────────────────────────────
// 1. Historique des commandes/livraisons du client
// ──────────────────────────────────────────────
const getDeliveryOrdersByCustomerId = async (customerId) => {
  const [rows] = await pool.query(
    `SELECT 
       d.id, d.status, d.delivery_address, d.delivery_latitude, d.delivery_longitude,
       d.amount_to_collect, d.collected_amount, d.estimated_delivery_time,
       d.creation_date, d.delivery_date,
       dp.id AS delivery_person_id,
       u.first_name AS livreur_first_name,
       u.last_name AS livreur_last_name,
       u.phone AS livreur_phone
     FROM deliveryorders d
     LEFT JOIN delivery_persons dp ON d.delivery_person_id = dp.id
     LEFT JOIN users u ON dp.user_id = u.id
     WHERE d.customer_id = ?
     ORDER BY d.creation_date DESC`,
    [customerId]
  );
  return rows;
};

// Récupérer une livraison précise appartenant à ce client (sécurité)
const getDeliveryOrderForCustomer = async (deliveryOrderId, customerId) => {
  const [rows] = await pool.query(
    `SELECT * FROM deliveryorders WHERE id = ? AND customer_id = ?`,
    [deliveryOrderId, customerId]
  );
  return rows[0];
};

// ──────────────────────────────────────────────
// 2. Confirmation de réception (OTP)
// ──────────────────────────────────────────────
const getConfirmationByDeliveryOrder = async (deliveryOrderId) => {
  const [rows] = await pool.query(
    `SELECT * FROM confirmations WHERE deliveryorder_id = ? ORDER BY id DESC LIMIT 1`,
    [deliveryOrderId]
  );
  return rows[0];
};

const validateConfirmation = async (confirmationId) => {
  await pool.query(
    `UPDATE confirmations SET confirmed_at = NOW() WHERE id = ?`,
    [confirmationId]
  );
};

const markDeliveryAsDelivered = async (deliveryOrderId) => {
  // Valeur ENUM correcte dans la base : 'Livré'
  await pool.query(
    `UPDATE deliveryorders SET status = 'Livré', delivery_date = NOW() WHERE id = ?`,
    [deliveryOrderId]
  );
};

// ──────────────────────────────────────────────
// 3. Annulation d'une livraison
// ──────────────────────────────────────────────
const cancelDeliveryOrder = async (deliveryOrderId, reason) => {
  // Valeur ENUM correcte dans la base : 'Annulé'
  await pool.query(
    `UPDATE deliveryorders 
     SET status = 'Annulé', suspension_reason = ?, tracking_blocked = 1
     WHERE id = ?`,
    [reason, deliveryOrderId]
  );
};

// ──────────────────────────────────────────────
// 4. Notation du livreur
// ──────────────────────────────────────────────
const createNotation = async (data) => {
  const { deliveryorder_id, customer_id, delivery_person_id, note, commentaire } = data;
  await pool.query(
    `INSERT INTO notations (deliveryorder_id, customer_id, delivery_person_id, note, commentaire)
     VALUES (?, ?, ?, ?, ?)`,
    [deliveryorder_id, customer_id, delivery_person_id, note, commentaire || null]
  );
};

const hasNotation = async (deliveryOrderId) => {
  const [rows] = await pool.query(
    `SELECT id FROM notations WHERE deliveryorder_id = ?`,
    [deliveryOrderId]
  );
  return rows.length > 0;
};

// ──────────────────────────────────────────────
// 5. Litiges — stockés dans remises_compensations
// Cohérence avec le backend manager (litigeController.js utilise remises_compensations)
// ──────────────────────────────────────────────

// Récupérer l'order_id lié à une livraison (via delivery_items)
const getOrderIdByDeliveryOrder = async (deliveryOrderId) => {
  const [rows] = await pool.query(
    `SELECT order_id FROM delivery_items WHERE deliveryorder_id = ? LIMIT 1`,
    [deliveryOrderId]
  );
  return rows[0]?.order_id || null;
};

// Récupérer le premier manager disponible
const getFirstManagerId = async () => {
  const [rows] = await pool.query(`SELECT id FROM managers LIMIT 1`);
  return rows[0]?.id || null;
};

// Créer un litige dans remises_compensations
const createLitige = async (data) => {
  const { order_id, type, reason, amount, manager_id } = data;
  const [result] = await pool.query(
    `INSERT INTO remises_compensations (order_id, type, reason, amount, approved_by_manager_id, status)
     VALUES (?, ?, ?, ?, ?, 'En_attente')`,
    [order_id, type, reason, amount || null, manager_id]
  );
  return result.insertId;
};

module.exports = {
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
};