const express = require('express');
const router = express.Router();
const authMiddleware = require('../middlewares/authMiddleware');
const managerOnly = require('../middlewares/managerOnly');
const { index, payer } = require('../controllers/recouvrementController');

router.use(authMiddleware, managerOnly);
router.get('/', index);
router.post('/:id/payer', payer);

module.exports = router;