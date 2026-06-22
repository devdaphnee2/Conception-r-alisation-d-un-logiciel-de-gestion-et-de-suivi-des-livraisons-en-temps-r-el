const express = require('express');
const router = express.Router();
const authMiddleware = require('../middlewares/authMiddleware');
const managerOnly = require('../middlewares/managerOnly');
const prisma = require('../utils/prismaClient');

router.use(authMiddleware, managerOnly);

router.get('/', async(req, res) => {
    try {
        const customers = await prisma.customers.findMany({
            include: { users: true },
        });
        res.json(customers);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

router.get('/:id/orders', async(req, res) => {
    try {
        const orders = await prisma.orders.findMany({
            where: { customer_id: parseInt(req.params.id) },
            include: { delivery_items: true },
            orderBy: { created_at: 'desc' },
        });
        res.json(orders);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

module.exports = router;