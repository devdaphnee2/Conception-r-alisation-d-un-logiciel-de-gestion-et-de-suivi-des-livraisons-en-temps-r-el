const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middlewares/authMiddleware');
const ctrl = require('./commercantController');

router.use(authMiddleware);

// IMPORTANT: routes fixes AVANT les routes avec parametres /:id
router.get('/livraisons/en-cours', ctrl.livraisonsEnCours);
router.get('/livreurs-disponibles', ctrl.livreursDisponibles);
router.get('/preferences', ctrl.getPreferences);
router.patch('/preferences', ctrl.updatePreferences);

router.get('/livraisons', ctrl.mesLivraisons);
router.post('/livraisons', ctrl.creerLivraison);
router.get('/livraisons/:id', ctrl.detailLivraison);
router.delete('/livraisons/:id', ctrl.supprimerCommande);
router.post('/livraisons/:id/litige', ctrl.declarerLitige);
router.post('/livraisons/:id/commander-course', ctrl.commanderCourse);

module.exports = router;