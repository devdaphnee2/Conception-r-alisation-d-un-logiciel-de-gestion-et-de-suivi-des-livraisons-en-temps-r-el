const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middlewares/authMiddleware');
const managerOnly = require('../../middlewares/managerOnly');
const { index, create, show, update, assigner, annuler } = require('./livraisonController');

router.use(authMiddleware, managerOnly);
router.get('/', index);
router.post('/', create);
router.get('/:id', show);
router.put('/:id', update);
router.post('/:id/assigner', assigner);
router.post('/:id/annuler', annuler);

module.exports = router;