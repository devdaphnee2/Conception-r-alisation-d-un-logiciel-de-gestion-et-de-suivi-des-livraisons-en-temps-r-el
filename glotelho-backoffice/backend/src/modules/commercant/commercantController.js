const prisma = require('../../utils/prismaClient');

// ── GET /api/v1/commercant/livraisons ────────────────────────
async function mesLivraisons(req, res) {
    try {
        var manager = await prisma.managers.findFirst({ where: { user_id: req.user.id } });
        if (!manager) return res.status(403).json({ message: 'Compte commercant introuvable.' });

        var livraisons = await prisma.deliveryorders.findMany({
            where: { manager_id: manager.id },
            include: {
                delivery_persons: { include: { users: true } },
                delivery_items: true,
                confirmations: { take: 1 },
            },
            orderBy: { creation_date: 'desc' }
        });
        res.json(livraisons);
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

// ── GET /api/v1/commercant/livraisons/:id ────────────────────
async function detailLivraison(req, res) {
    try {
        var livraison = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) },
            include: {
                delivery_persons: { include: { users: true, vehicules: true } },
                delivery_items: true,
                confirmations: true,
                litiges: true,
            }
        });
        if (!livraison) return res.status(404).json({ message: 'Livraison introuvable.' });
        res.json(livraison);
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

// ── POST /api/v1/commercant/livraisons ───────────────────────
async function creerLivraison(req, res) {
    try {
        var manager = await prisma.managers.findFirst({ where: { user_id: req.user.id } });
        if (!manager) return res.status(403).json({ message: 'Compte commercant introuvable.' });

        var body = req.body;
        if (!body.client_nom || !body.client_telephone || !body.delivery_address) {
            return res.status(400).json({ message: 'Nom client, telephone et adresse requis.' });
        }

        var bcrypt = require('bcrypt');
        var crypto = require('crypto');
        var telClean = body.client_telephone.replace(/\s/g, '').replace(/\+/g, '');

        var customer = null;
        var existingUser = await prisma.users.findFirst({ where: { phone: body.client_telephone } });
        if (existingUser) {
            customer = await prisma.customers.findFirst({ where: { user_id: existingUser.id } });
            if (!customer) customer = await prisma.customers.create({ data: { user_id: existingUser.id } });
        } else {
            var parts = (body.client_nom || '').trim().split(' ');
            var newUser = await prisma.users.create({
                data: {
                    first_name: parts[0] || body.client_nom,
                    last_name: parts.slice(1).join(' ') || '-',
                    email: telClean + '@glotelho.cm',
                    password: await bcrypt.hash(crypto.randomBytes(16).toString('hex'), 10),
                    phone: body.client_telephone,
                    role: 'customer',
                }
            });
            customer = await prisma.customers.create({ data: { user_id: newUser.id } });
        }

        var otp = Math.floor(100000 + Math.random() * 900000).toString();

        var livraison = await prisma.deliveryorders.create({
            data: {
                manager_id: manager.id,
                customer_id: customer.id,
                delivery_person_id: null,
                delivery_address: body.delivery_address,
                zone_bloc: body.zone_bloc || null,
                delivery_instructions: body.delivery_instructions || null,
                amount_to_collect: parseFloat(body.amount_to_collect) || 0,
                collected_amount: 0,
                status: 'Commande',
                delivery_date: body.delivery_date ? new Date(body.delivery_date) : null,
                client_nom: body.client_nom,
                client_telephone: body.client_telephone,
                client_whatsapp: body.client_whatsapp || body.client_telephone,
            }
        });

        if (body.articles && body.articles.length > 0) {
            var articlesData = body.articles.filter(function(a) { return a.nom; }).map(function(a) {
                return {
                    deliveryorder_id: livraison.id,
                    order_id: null,
                    product_name: a.nom,
                    quantity: parseInt(a.quantite) || 1,
                    unit_price: parseFloat(a.prix_unitaire) || 0,
                    status: 'Disponible',
                };
            });
            if (articlesData.length > 0) await prisma.delivery_items.createMany({ data: articlesData });
        }

        await prisma.confirmations.create({
            data: { deliveryorder_id: livraison.id, otp_code: otp, methode: 'OTP' }
        });

        res.status(201).json({
            message: 'Commande enregistrée. Cliquez sur "Commander une course" quand vous êtes prêt.',
            livraison: livraison,
            otp: otp,
        });
    } catch (err) {
        console.error('[creerLivraison]', err.message);
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

// ── POST /api/v1/commercant/livraisons/:id/commander-course ──
async function commanderCourse(req, res) {
    try {
        var id = parseInt(req.params.id);
        var livraison = await prisma.deliveryorders.findUnique({ where: { id: id } });
        if (!livraison) return res.status(404).json({ message: 'Commande introuvable.' });
        if (livraison.status !== 'Commande') {
            return res.status(400).json({ message: 'Cette commande a déjà été envoyée à l\'admin.' });
        }
        await prisma.deliveryorders.update({
            where: { id: id },
            data: { status: 'En_attente' }
        });
        console.log('[CommanderCourse] Commande #' + id + ' envoyée à l\'admin');
        res.json({ message: 'Course commandée ! L\'admin va assigner un livreur.' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

// ── DELETE /api/v1/commercant/livraisons/:id ─────────────────
// Supprime une commande en brouillon (statut 'Commande' uniquement)
async function supprimerCommande(req, res) {
    try {
        var id = parseInt(req.params.id);
        var livraison = await prisma.deliveryorders.findUnique({ where: { id: id } });
        if (!livraison) return res.status(404).json({ message: 'Commande introuvable.' });
        if (livraison.status !== 'Commande') {
            return res.status(400).json({ message: 'Seules les commandes non envoyées peuvent être supprimées.' });
        }
        // Supprimer les données liées avant la commande
        await prisma.delivery_items.deleteMany({ where: { deliveryorder_id: id } });
        await prisma.confirmations.deleteMany({ where: { deliveryorder_id: id } });
        await prisma.deliveryorders.delete({ where: { id: id } });
        console.log('[SupprimerCommande] Commande #' + id + ' supprimée');
        res.json({ message: 'Commande supprimée.' });
    } catch (err) {
        console.error('[supprimerCommande]', err.message);
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

// ── GET /api/v1/commercant/livreurs-disponibles ──────────────
async function livreursDisponibles(req, res) {
    try {
        var livreurs = await prisma.delivery_persons.findMany({
            where: { status: 'Disponible' },
            include: { users: true, vehicules: true },
        });
        res.json(livreurs);
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

// ── POST /api/v1/commercant/livraisons/:id/litige ────────────
async function declarerLitige(req, res) {
    try {
        var manager = await prisma.managers.findFirst({ where: { user_id: req.user.id } });
        var courseId = parseInt(req.params.id);
        var litige = await prisma.litiges.create({
            data: {
                deliveryorder_id: courseId,
                manager_id: manager ? manager.id : null,
                statut: 'Ouvert',
                description: req.body.description || 'Litige declare par le commercant',
                motif: req.body.motif || null,
            }
        });
        res.status(201).json({ message: 'Litige declare.', litige: litige });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

module.exports = {
    mesLivraisons,
    detailLivraison,
    creerLivraison,
    commanderCourse,
    supprimerCommande,
    livreursDisponibles,
    declarerLitige,
};