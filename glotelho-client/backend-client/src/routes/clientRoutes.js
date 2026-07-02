// src/routes/clientRoutes.js
const express = require('express');
const router = express.Router();
const {
  getCommandes,
  confirmerReception,
  annulerLivraison,
  noterLivreur,
  declarerLitige
} = require('../controllers/clientController');
const { authMiddleware, requireCustomer } = require('../middlewares/authMiddleware');

// Toutes ces routes nécessitent une authentification client
router.get('/commandes', authMiddleware, requireCustomer, getCommandes);
router.post('/confirmer', authMiddleware, requireCustomer, confirmerReception);
router.post('/livraisons/:id/annuler', authMiddleware, requireCustomer, annulerLivraison);
router.post('/noter', authMiddleware, requireCustomer, noterLivreur);
router.post('/litiges', authMiddleware, requireCustomer, declarerLitige);

module.exports = router;