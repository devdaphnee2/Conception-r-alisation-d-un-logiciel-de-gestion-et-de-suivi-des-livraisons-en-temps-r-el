const express = require('express');
const router = express.Router();
const authMiddleware = require('../middlewares/authMiddleware');
const managerOnly = require('../middlewares/managerOnly');
const { index, store, show, update, assigner, suspendre, annuler } = require('../controllers/livraisonController');

router.use(authMiddleware, managerOnly);

router.get('/', index);
router.post('/', store);
router.get('/:id', show);
router.put('/:id', update);
router.post('/:id/assigner', assigner);
router.post('/:id/suspendre', suspendre);
router.post('/:id/annuler', annuler);

module.exports = router;