const express = require('express');
const router = express.Router();
const authMiddleware = require('../middlewares/authMiddleware');
const managerOnly = require('../middlewares/managerOnly');
const { index, store, show, update, suspendre, reactiver } = require('../controllers/livreurController');

router.use(authMiddleware, managerOnly);

router.get('/', index);
router.post('/', store);
router.get('/:id', show);
router.put('/:id', update);
router.post('/:id/suspendre', suspendre);
router.post('/:id/reactiver', reactiver);

module.exports = router;
