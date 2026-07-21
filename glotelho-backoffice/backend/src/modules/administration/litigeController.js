const prisma = require('../../utils/prismaClient');

async function index(req, res) {
    try {
        const litiges = await prisma.remises_compensations.findMany({
            include: {
                orders: { include: { customers: { include: { users: true } }, delivery_items: true } },
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
                orders: { include: { customers: { include: { users: true } }, delivery_items: true } },
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
        const manager = await prisma.managers.findUnique({ where: { user_id: req.user.id } });
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
        res.status(201).json({ message: 'Litige declare.', litige });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Etape 7-8 du diagramme : Prendre en charge -> UPDATE statut=en_cours, manager_id
async function prendreEnCharge(req, res) {
    try {
        const manager = await prisma.managers.findUnique({ where: { user_id: req.user.id } });
        const litige = await prisma.remises_compensations.update({
            where: { id: parseInt(req.params.id) },
            data: { approved_by_manager_id: manager.id }
        });
        res.json({ message: 'Litige pris en charge. Statut en attente de resolution.', litige });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Etape 9-10 : Resoudre -> UPDATE statut=resolu, decision, motif + notif livreur/client
async function resoudre(req, res) {
    try {
        const { decision, amount } = req.body;
        if (!decision) return res.status(400).json({ message: 'La decision est requise.' });
        const litige = await prisma.remises_compensations.update({
            where: { id: parseInt(req.params.id) },
            data: {
                status: 'Approuvee',
                type: decision,
                amount: amount ? parseFloat(amount) : null,
            }
        });
        // TODO: Etape 11-12 — FCM notification livreur + client
        res.json({ message: 'Litige resolu. Decision enregistree. (FCM: notification livreur + client a connecter)', litige });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Rejeter
async function rejeter(req, res) {
    try {
        const litige = await prisma.remises_compensations.update({
            where: { id: parseInt(req.params.id) },
            data: { status: 'Rejetee' }
        });
        // TODO: FCM notification demandeur
        res.json({ message: 'Litige rejete. (FCM: notification demandeur a connecter)', litige });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Etape 13-14 : Cloturer -> UPDATE statut=cloture, date_cloture
async function cloturer(req, res) {
    try {
        const litige = await prisma.remises_compensations.findUnique({
            where: { id: parseInt(req.params.id) }
        });
        if (!litige) return res.status(404).json({ message: 'Litige introuvable.' });
        if (!['Approuvee', 'Rejetee'].includes(litige.status)) {
            return res.status(400).json({ message: 'Le litige doit etre resolu ou rejete avant de le cloturer.' });
        }
        const updated = await prisma.remises_compensations.update({
            where: { id: parseInt(req.params.id) },
            data: { status: 'Approuvee' } // En production: ajouter un champ date_cloture
        });
        res.json({ message: 'Litige cloture avec succes. Date de cloture enregistree.', litige: updated });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

module.exports = { index, show, store, prendreEnCharge, resoudre, rejeter, cloturer };
