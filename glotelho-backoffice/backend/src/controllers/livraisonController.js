const prisma = require('../utils/prismaClient');

// Liste toutes les livraisons
async function index(req, res) {
    try {
        const livraisons = await prisma.deliveryorders.findMany({
            include: {
                delivery_persons: { include: { users: true, vehicules: true } },
                managers: {
                    include: { users: true }
                },
                customers: {
                    include: { users: true }
                },
            },
            orderBy: { creation_date: 'desc' },
        });
        res.json(livraisons);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Créer une livraison
async function store(req, res) {
    try {
        console.log('Body recu :', req.body);
        console.log('User :', req.user);

        const { delivery_address, delivery_person_id, customer_id, amount_to_collect, zone_bloc, delivery_date } = req.body;

        if (!delivery_address || !customer_id) {
            return res.status(400).json({ message: 'Adresse et client sont requis.' });
        }

        const manager = await prisma.managers.findUnique({
            where: { user_id: req.user.id }
        });

        console.log('Manager trouve :', manager);

        if (!manager) {
            return res.status(403).json({ message: 'Manager introuvable.' });
        }

        const livraison = await prisma.deliveryorders.create({
            data: {
                manager_id: manager.id,
                delivery_person_id: delivery_person_id ? parseInt(delivery_person_id) : null,
                customer_id: parseInt(customer_id),
                delivery_address,
                zone_bloc: zone_bloc || null,
                amount_to_collect: amount_to_collect ? parseFloat(amount_to_collect) : 0,
                delivery_date: delivery_date ? new Date(delivery_date) : null,
                status: delivery_person_id ? 'Assigné' : 'En_attente',
            }
        });

        console.log('Livraison creee :', livraison);
        res.status(201).json({ message: 'Livraison créée avec succès.', livraison });

    } catch (error) {
        console.error('ERREUR STORE LIVRAISON :', error);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}
async function store(req, res) {
    try {
        console.log('Body recu :', req.body);
        console.log('User :', req.user);

        const { delivery_address, delivery_person_id, customer_id, amount_to_collect, collected_amount, zone_bloc, delivery_date, delivery_instructions } = req.body;
        if (!delivery_address || !customer_id) {
            return res.status(400).json({ message: 'Adresse et client sont requis.' });
        }

        const manager = await prisma.managers.findUnique({
            where: { user_id: req.user.id }
        });

        console.log('Manager trouve :', manager);

        if (!manager) {
            return res.status(403).json({ message: 'Manager introuvable.' });
        }

        const livraison = await prisma.deliveryorders.create({
            data: {
                manager_id: manager.id,
                delivery_person_id: delivery_person_id ? parseInt(delivery_person_id) : null,
                customer_id: parseInt(customer_id),
                delivery_address,
                zone_bloc: zone_bloc || null,
                amount_to_collect: amount_to_collect ? parseFloat(amount_to_collect) : 0,
                collected_amount: collected_amount ? parseFloat(collected_amount) : 0,
                delivery_date: delivery_date ? new Date(delivery_date) : null,
                status: delivery_person_id ? 'Assign_' : 'En_attente',
            }
        });

        console.log('Livraison creee :', livraison);
        res.status(201).json({ message: 'Livraison créée avec succès.', livraison });

    } catch (error) {
        console.error('ERREUR STORE LIVRAISON :', error);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Détail d'une livraison
async function show(req, res) {
    try {
        const livraison = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) },
            include: {
                delivery_persons: { include: { users: true } },
                managers: { include: { users: true } },
                customers: { include: { users: true } },
                delivery_items: true,
                photos: true,
                bordereaux: true,
            }
        });

        if (!livraison) return res.status(404).json({ message: 'Livraison introuvable.' });

        res.json(livraison);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Modifier une livraison
async function update(req, res) {
    try {
        const { delivery_address, delivery_date, zone_bloc, amount_to_collect } = req.body;

        const livraison = await prisma.deliveryorders.update({
            where: { id: parseInt(req.params.id) },
            data: {
                delivery_address,
                delivery_date: delivery_date ? new Date(delivery_date) : null,
                zone_bloc: zone_bloc || null,
                amount_to_collect: amount_to_collect ? parseFloat(amount_to_collect) : 0,
            }
        });

        res.json({ message: 'Livraison modifiée.', livraison });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Assigner un livreur
async function assigner(req, res) {
    try {
        const { delivery_person_id } = req.body;

        const livraison = await prisma.deliveryorders.update({
            where: { id: parseInt(req.params.id) },
            data: {
                delivery_person_id: parseInt(delivery_person_id),
                status: 'Assign_',
            }
        });

        res.json({ message: 'Livraison assignée.', livraison });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Suspendre une livraison
async function suspendre(req, res) {
    try {
        const { suspension_reason } = req.body;

        const livraison = await prisma.deliveryorders.update({
            where: { id: parseInt(req.params.id) },
            data: {
                status: 'Suspendu',
                suspension_reason: suspension_reason || null,
            }
        });

        res.json({ message: 'Livraison suspendue.', livraison });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Annuler une livraison
async function annuler(req, res) {
    try {
        const livraison = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) }
        });

        if (!livraison) return res.status(404).json({ message: 'Livraison introuvable.' });

        if (['Assign_', 'En_cours', 'Livr_'].includes(livraison.status)) {
            return res.status(400).json({ message: 'Impossible d\'annuler une livraison déjà assignée, en cours ou livrée.' });
        }

        const updated = await prisma.deliveryorders.update({
            where: { id: parseInt(req.params.id) },
            data: {
                status: 'Annul_',
                tracking_blocked: true,
            }
        });

        res.json({ message: 'Livraison annulée.', livraison: updated });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

module.exports = { index, store, show, update, assigner, suspendre, annuler };