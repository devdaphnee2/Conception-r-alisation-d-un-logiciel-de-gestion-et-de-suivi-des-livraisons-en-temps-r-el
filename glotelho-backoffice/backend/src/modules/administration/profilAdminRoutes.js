const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middlewares/authMiddleware');
const managerOnly = require('../../middlewares/managerOnly');
const {
    listeEnAttente,
    detailProfil,
    envoyerNotificationCaution,
    marquerCautionPayee,
    approuver,
    rejeter
} = require('./profilController');

router.use(authMiddleware, managerOnly);

router.get('/en-attente', listeEnAttente);
router.get('/:id', detailProfil);
router.post('/:id/notifier-caution', envoyerNotificationCaution);
router.post('/:id/caution-payee', marquerCautionPayee);
router.post('/:id/approuver', approuver);
router.post('/:id/rejeter', rejeter);

module.exports = router;