// src/routes/orderRoutes.js
const express = require('express');
const router = express.Router();
const {
  shippingFees,
  createOrderHandler,
  getOrders,
  getOrderDetails
} = require('../controllers/orderController');
const { authMiddleware, requireCustomer } = require('../middlewares/authMiddleware');

// Frais de livraison (public)
router.get('/shipping-fees', shippingFees);

// Commandes (protégées)
router.post('/orders', authMiddleware, requireCustomer, createOrderHandler);
router.get('/orders', authMiddleware, requireCustomer, getOrders);
router.get('/orders/:id', authMiddleware, requireCustomer, getOrderDetails);

module.exports = router;