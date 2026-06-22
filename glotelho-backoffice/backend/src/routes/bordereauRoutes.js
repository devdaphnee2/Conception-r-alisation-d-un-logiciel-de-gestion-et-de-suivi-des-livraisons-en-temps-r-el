const express = require('express');
const router = express.Router();
const authMiddleware = require('../middlewares/authMiddleware');
const managerOnly = require('../middlewares/managerOnly');
const { generer } = require('../controllers/bordereauController');

router.use(authMiddleware, managerOnly);

router.get('/livraison/:id', generer);

module.exports = router;