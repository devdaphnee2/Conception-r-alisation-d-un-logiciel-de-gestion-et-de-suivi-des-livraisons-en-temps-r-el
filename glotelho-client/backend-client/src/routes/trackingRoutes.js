// src/routes/trackingRoutes.js
const express = require('express');
const router = express.Router();
const {
  getLastPositionHandler,
  trackOrder,
  getPositionHistoryHandler
} = require('../controllers/trackingController');
const { authMiddleware, requireCustomer } = require('../middlewares/authMiddleware');

// Position d'un livreur
router.get('/livreur/:delivery_person_id',
  authMiddleware, requireCustomer, getLastPositionHandler);

// Suivi en direct d'une commande
router.get('/order/:order_id',
  authMiddleware, requireCustomer, trackOrder);

// Historique du trajet
router.get('/livreur/:delivery_person_id/history',
  authMiddleware, requireCustomer, getPositionHistoryHandler);

module.exports = router;