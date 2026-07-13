const express        = require('express');
const router         = express.Router();
const authMiddleware = require('../../middlewares/authMiddleware');
const ctrl           = require('./commercantController');

router.use(authMiddleware);

router.get  ('/livraisons',                  ctrl.mesLivraisons);
router.get  ('/livraisons/:id',              ctrl.detailLivraison);
router.post ('/livraisons',                  ctrl.creerLivraison);
router.get  ('/livreurs-disponibles',        ctrl.livreursDisponibles);
router.post ('/livraisons/:id/litige',       ctrl.declarerLitige);

module.exports = router;
