// src/controllers/orderController.js
const pool = require('../config/db');
const {
  createOrder,
  getOrdersByCustomerId,
  getOrderById,
  getShippingFees
} = require('../models/orderModel');

// Récupérer le customer_id depuis req.user.id
async function getCustomerId(userId) {
  const [rows] = await pool.query(
    'SELECT id FROM customers WHERE user_id = ?', [userId]
  );
  return rows[0]?.id;
}

// ── 1. Frais de livraison (GET /shipping-fees) ───────────────────
async function shippingFees(req, res) {
  try {
    const fees = getShippingFees();
    res.json({ fees });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ── 2. Créer une commande (POST /orders) ─────────────────────────
async function createOrderHandler(req, res) {
  try {
    const { items, delivery_address, delivery_type,
            payment_method, shipping_fee, total } = req.body;

    if (!items || items.length === 0) {
      return res.status(400).json({ message: 'Le panier est vide.' });
    }
    if (!delivery_address) {
      return res.status(400).json({ message: 'Adresse de livraison requise.' });
    }
    if (!payment_method) {
      return res.status(400).json({ message: 'Mode de paiement requis.' });
    }

    const customerId = await getCustomerId(req.user.id);
    if (!customerId) {
      return res.status(404).json({ message: 'Profil client introuvable.' });
    }

    const { orderId, reference } = await createOrder(customerId, {
      items,
      delivery_address,
      delivery_type: delivery_type || 'home',
      payment_method,
      shipping_fee: shipping_fee || 0,
      total_amount: total
    });

    res.status(201).json({
      message: 'Commande créée avec succès.',
      order: {
        id: orderId,
        reference,
        status: 'En_cours',
        total_amount: total,
        delivery_address,
        delivery_type,
        payment_method,
        shipping_fee: shipping_fee || 0,
        items
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ── 3. Historique des commandes (GET /orders) ────────────────────
async function getOrders(req, res) {
  try {
    const customerId = await getCustomerId(req.user.id);
    if (!customerId) {
      return res.status(404).json({ message: 'Profil client introuvable.' });
    }

    const orders = await getOrdersByCustomerId(customerId);
    res.json({ orders });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ── 4. Détails d'une commande (GET /orders/:id) ──────────────────
async function getOrderDetails(req, res) {
  try {
    const { id } = req.params;

    const customerId = await getCustomerId(req.user.id);
    if (!customerId) {
      return res.status(404).json({ message: 'Profil client introuvable.' });
    }

    const order = await getOrderById(id, customerId);
    if (!order) {
      return res.status(404).json({ message: 'Commande introuvable.' });
    }

    res.json({ order });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

module.exports = { shippingFees, createOrderHandler, getOrders, getOrderDetails };