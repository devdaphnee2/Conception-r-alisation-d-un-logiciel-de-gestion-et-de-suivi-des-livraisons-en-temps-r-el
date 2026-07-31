const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middlewares/authMiddleware');
const managerOnly = require('../../middlewares/managerOnly');
const { index, create, show, update, assigner, accepter, annuler, demarrerCourse, publicShow } = require('./livraisonController');

// Route publique AVANT le middleware d'auth
router.get('/public/:id', publicShow);

// Route accessible au livreur (authentifié, mais PAS manager-only) :
// permet au livreur d'accepter une course qui lui a été proposée.
router.post('/:id/accepter', authMiddleware, accepter);

// Route accessible au livreur : démarrer la course déjà acceptée.
router.post('/:id/demarrer', authMiddleware, demarrerCourse);

// ── Le reste des routes est réservé aux managers ───────────────────────
router.use(authMiddleware, managerOnly);
router.get('/', index);
router.post('/', create);
router.get('/:id', show);
router.put('/:id', update);
router.post('/:id/assigner', assigner);
router.post('/:id/annuler', annuler);

module.exports = router;