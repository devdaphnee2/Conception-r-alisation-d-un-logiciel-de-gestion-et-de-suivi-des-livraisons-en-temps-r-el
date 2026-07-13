const prisma = require('../../utils/prismaClient');

async function index(req, res) {
    try {
        const recouvrements = await prisma.recouvrement.findMany({
            include: {
                delivery_persons: { include: { users: true } },
                deliveryorders: { include: { customers: { include: { users: true } } } },
            },
            orderBy: { id: 'desc' },
        });
        res.json(recouvrements);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

async function payer(req, res) {
    try {
        const { amount_collected } = req.body;
        if (!amount_collected) return res.status(400).json({ message: 'Montant requis.' });
        const rec = await prisma.recouvrement.findUnique({ where: { id: parseInt(req.params.id) } });
        if (!rec) return res.status(404).json({ message: 'Recouvrement introuvable.' });
        const newTotal = Number(rec.amount_collected || 0) + Number(amount_collected);
        const updated = await prisma.recouvrement.update({
            where: { id: parseInt(req.params.id) },
            data: { amount_collected: newTotal }
        });
        res.json({ message: 'Paiement enregistre.', recouvrement: updated });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

module.exports = { index, payer };