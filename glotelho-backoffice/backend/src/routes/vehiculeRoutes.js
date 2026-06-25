const express = require('express');
const router = express.Router();
const authMiddleware = require('../middlewares/authMiddleware');
const managerOnly = require('../middlewares/managerOnly');
const prisma = require('../utils/prismaClient');

router.use(authMiddleware, managerOnly);

router.get('/', async(req, res) => {
    try {
        const vehicules = await prisma.vehicules.findMany({
            where: { status: 'Disponible' }
        });
        res.json(vehicules);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

module.exports = router;