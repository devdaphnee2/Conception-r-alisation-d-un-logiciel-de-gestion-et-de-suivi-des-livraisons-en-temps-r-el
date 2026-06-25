const prisma = require('../utils/prismaClient');

async function index(req, res) {
    try {
        const litiges = await prisma.remises_compensations.findMany({
            include: {
                orders: {
                    include: {
                        customers: { include: { users: true } }
                    }
                },
                managers: { include: { users: true } },
            },
            orderBy: { created_at: 'desc' },
        });
        res.json(litiges);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

async function show(req, res) {
    try {
        const litige = await prisma.remises_compensations.findUnique({
            where: { id: parseInt(req.params.id) },
            include: {
                orders: {
                    include: {
                        customers: { include: { users: true } },
                        delivery_items: true,
                    }
                },
                managers: { include: { users: true } },
            }
        });

        if (!litige) return res.status(404).json({ message: 'Litige introuvable.' });
        res.json(litige);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

async function store(req, res) {
    try {
        const { order_id, type, reason, amount } = req.body;

        if (!order_id || !type || !reason) {
            return res.status(400).json({ message: 'Commande, type et raison sont requis.' });
        }

        const manager = await prisma.managers.findUnique({
            where: { user_id: req.user.id }
        });

        const litige = await prisma.remises_compensations.create({
            data: {
                order_id: parseInt(order_id),
                type,
                reason,
                amount: amount ? parseFloat(amount) : null,
                approved_by_manager_id: manager.id,
                status: 'En_attente',
            }
        });

        res.status(201).json({ message: 'Litige cree.', litige });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

async function prendreEnCharge(req, res) {
    try {
        const manager = await prisma.managers.findUnique({ where: { user_id: req.user.id } });

        const litige = await prisma.remises_compensations.update({
            where: { id: parseInt(req.params.id) },
            data: {
                status: 'En_attente',
                approved_by_manager_id: manager.id,
            }
        });

        res.json({ message: 'Litige pris en charge.', litige });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

async function resoudre(req, res) {
    try {
        const { decision, amount } = req.body;

        if (!decision) {
            return res.status(400).json({ message: 'La decision est requise.' });
        }

        const litige = await prisma.remises_compensations.update({
            where: { id: parseInt(req.params.id) },
            data: {
                status: 'Approuvee',
                type: decision,
                amount: amount ? parseFloat(amount) : null,
            }
        });

        res.json({ message: 'Litige resolu.', litige });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

async function rejeter(req, res) {
    try {
        const litige = await prisma.remises_compensations.update({
            where: { id: parseInt(req.params.id) },
            data: { status: 'Rejetee' }
        });

        res.json({ message: 'Litige rejete.', litige });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

module.exports = { index, show, store, prendreEnCharge, resoudre, rejeter };
