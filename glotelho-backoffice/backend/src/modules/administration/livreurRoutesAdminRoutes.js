const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middlewares/authMiddleware');
const managerOnly = require('../../middlewares/managerOnly');
const { index, store, show, update, suspendre, reactiver } = require('./livreurController');

// 🎯 AJOUT 1 : Importer la fonction depuis profilController
const { marquerCautionPayee } = require('./profilController');

router.use(authMiddleware, managerOnly);

router.get('/', index);
router.post('/', store);
router.get('/:id', show);
router.put('/:id', update);
router.post('/:id/suspendre', suspendre);
router.post('/:id/reactiver', reactiver);

// 🎯 AJOUT 2 : Déclarer la route pour la caution payée
router.post('/:id/caution-payee', marquerCautionPayee);

module.exports = router;