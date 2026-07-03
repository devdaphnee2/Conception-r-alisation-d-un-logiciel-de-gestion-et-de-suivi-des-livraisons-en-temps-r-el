// src/models/orderModel.js
const pool = require('../config/db');
const crypto = require('crypto');

// Générer une référence unique type GE-902341
const generateReference = () => {
  const num = Math.floor(100000 + Math.random() * 900000);
  return `GE-${num}`;
};

// ── 1. Créer une commande ────────────────────────────────────────
const createOrder = async (customerId, data) => {
  const {
    items, delivery_address, delivery_type,
    payment_method, shipping_fee, total_amount
  } = data;

  const reference = generateReference();

  const [orderResult] = await pool.query(
    `INSERT INTO orders
     (customer_id, delivery_address, delivery_type, payment_method,
      shipping_fee, total_amount, reference, status)
     VALUES (?, ?, ?, ?, ?, ?, ?, 'En_cours')`,
    [customerId, delivery_address, delivery_type,
     payment_method, shipping_fee || 0, total_amount, reference]
  );

  const orderId = orderResult.insertId;

  // Insérer les articles
  for (const item of items) {
    await pool.query(
      `INSERT INTO delivery_items
       (order_id, deliveryorder_id, product_name, quantity, price)
       VALUES (?, 0, ?, ?, ?)`,
      [orderId, item.name, item.quantity || 1, item.price || 0]
    );
  }

  return { orderId, reference };
};

// ── 2. Historique des commandes du client ────────────────────────
const getOrdersByCustomerId = async (customerId) => {
  const [orders] = await pool.query(
    `SELECT o.id, o.reference, o.status, o.delivery_address,
            o.delivery_type, o.payment_method, o.shipping_fee,
            o.total_amount, o.cancellation_reason,
            o.created_at, o.updated_at
     FROM orders o
     WHERE o.customer_id = ?
     ORDER BY o.created_at DESC`,
    [customerId]
  );

  // Récupérer les articles pour chaque commande
  for (const order of orders) {
    const [items] = await pool.query(
      `SELECT product_name, quantity, price
       FROM delivery_items
       WHERE order_id = ?`,
      [order.id]
    );
    order.items = items;
  }

  return orders;
};

// ── 3. Détails d'une commande ────────────────────────────────────
const getOrderById = async (orderId, customerId) => {
  const [rows] = await pool.query(
    `SELECT o.id, o.reference, o.status, o.delivery_address,
            o.delivery_type, o.payment_method, o.shipping_fee,
            o.total_amount, o.cancellation_reason,
            o.created_at, o.updated_at
     FROM orders o
     WHERE o.id = ? AND o.customer_id = ?`,
    [orderId, customerId]
  );

  if (!rows[0]) return null;

  const order = rows[0];
  const [items] = await pool.query(
    `SELECT product_name, quantity, price
     FROM delivery_items WHERE order_id = ?`,
    [orderId]
  );
  order.items = items;

  return order;
};

// ── 4. Frais de livraison ────────────────────────────────────────
const getShippingFees = () => {
  return [
    { type: 'pickup', label: 'Point de retrait', fee: 0 },
    { type: 'home',   label: 'Livraison à domicile', fee: 3000 },
  ];
};

module.exports = { createOrder, getOrdersByCustomerId, getOrderById, getShippingFees };