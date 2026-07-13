const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middlewares/authMiddleware');
const managerOnly = require('../../middlewares/managerOnly');
const { index, show, store, prendreEnCharge, resoudre, rejeter, cloturer } = require('./litigeController');

router.use(authMiddleware, managerOnly);

router.get('/', index);
router.post('/', store);
router.get('/:id', show);
router.post('/:id/prendre-en-charge', prendreEnCharge);
router.post('/:id/resoudre', resoudre);
router.post('/:id/rejeter', rejeter);
router.post('/:id/cloturer', cloturer);

module.exports = router;