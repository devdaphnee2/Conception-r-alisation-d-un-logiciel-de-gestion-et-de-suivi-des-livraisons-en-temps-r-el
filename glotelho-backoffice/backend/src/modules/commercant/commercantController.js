const prisma = require('../../utils/prismaClient');

async function mesLivraisons(req, res) {
    try {
        var manager = await prisma.managers.findFirst({ where: { user_id: req.user.id } });
        if (!manager) return res.status(403).json({ message: 'Compte commercant introuvable.' });
        var livraisons = await prisma.deliveryorders.findMany({
            where: { manager_id: manager.id },
            include: { delivery_persons: { include: { users: true } }, delivery_items: true, confirmations: { take: 1 } },
            orderBy: { creation_date: 'desc' }
        });
        res.json(livraisons);
    } catch (err) { res.status(500).json({ message: 'Erreur serveur', error: err.message }); }
}

async function livraisonsEnCours(req, res) {
    try {
        var manager = await prisma.managers.findFirst({ where: { user_id: req.user.id } });
        if (!manager) return res.status(403).json({ message: 'Compte introuvable.' });
        var livraisons = await prisma.deliveryorders.findMany({
            where: { manager_id: manager.id, status: 'En_cours' },
            include: { delivery_persons: { include: { users: true, vehicules: true } }, delivery_items: true, confirmations: { take: 1 } },
            orderBy: { creation_date: 'desc' }
        });
        res.json(livraisons);
    } catch (err) { res.status(500).json({ message: 'Erreur serveur', error: err.message }); }
}

async function detailLivraison(req, res) {
    try {
        console.log('[DETAIL] id:', req.params.id);
        var livraison = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) },
            include: {
                delivery_persons: { include: { users: true, vehicules: true } },
                delivery_items: true,
                confirmations: true
            }
        });
        console.log('[DETAIL] livraison trouvée:', livraison ? livraison.id : 'null');
        if (!livraison) return res.status(404).json({ message: 'Livraison introuvable.' });
        res.json(livraison);
    } catch (err) {
        console.error('[DETAIL ERROR]', err.message);
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

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
                data: { first_name: parts[0] || body.client_nom, last_name: parts.slice(1).join(' ') || '-', email: telClean + '@glotelho.cm', password: await bcrypt.hash(crypto.randomBytes(16).toString('hex'), 10), phone: body.client_telephone, role: 'customer' }
            });
            customer = await prisma.customers.create({ data: { user_id: newUser.id } });
        }

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

        // Articles
        if (body.articles && body.articles.length > 0) {
            var articlesData = body.articles.filter(function(a) { return a.nom; }).map(function(a) {
                return {
                    deliveryorder_id: livraison.id,
                    product_name: a.nom,
                    quantity: parseInt(a.quantite) || 1,
                    price: parseFloat(a.prix_unitaire) || 0,
                    status: 'Disponible',
                };
            });
            if (articlesData.length > 0) await prisma.delivery_items.createMany({ data: articlesData });
        }

        // PAS de confirmation ici — elle sera créée lors de l'assignation du livreur

        res.status(201).json({ message: 'Commande enregistrée.', livraison });
    } catch (err) {
        console.error('[creerLivraison]', err.message);
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function commanderCourse(req, res) {
    try {
        var id = parseInt(req.params.id);
        var livraison = await prisma.deliveryorders.findUnique({ where: { id } });
        if (!livraison) return res.status(404).json({ message: 'Commande introuvable.' });
        if (livraison.status !== 'Commande') return res.status(400).json({ message: 'Déjà envoyée.' });
        await prisma.deliveryorders.update({ where: { id }, data: { status: 'En_attente' } });
        res.json({ message: "Course commandée ! L'admin va assigner un livreur." });
    } catch (err) { res.status(500).json({ message: 'Erreur serveur', error: err.message }); }
}

async function supprimerCommande(req, res) {
    try {
        var id = parseInt(req.params.id);
        var livraison = await prisma.deliveryorders.findUnique({ where: { id } });
        if (!livraison) return res.status(404).json({ message: 'Commande introuvable.' });
        if (livraison.status !== 'Commande') return res.status(400).json({ message: 'Seules les commandes brouillon peuvent être supprimées.' });
        await prisma.delivery_items.deleteMany({ where: { deliveryorder_id: id } });
        await prisma.confirmations.deleteMany({ where: { deliveryorder_id: id } });
        await prisma.deliveryorders.delete({ where: { id } });
        res.json({ message: 'Commande supprimée.' });
    } catch (err) { res.status(500).json({ message: 'Erreur serveur', error: err.message }); }
}

async function livreursDisponibles(req, res) {
    try {
        var livreurs = await prisma.delivery_persons.findMany({ where: { status: 'Disponible' }, include: { users: true, vehicules: true } });
        res.json(livreurs);
    } catch (err) { res.status(500).json({ message: 'Erreur serveur', error: err.message }); }
}

async function declarerLitige(req, res) {
    try {
        var manager = await prisma.managers.findFirst({ where: { user_id: req.user.id } });
        var courseId = parseInt(req.params.id);
        var litige = await prisma.litiges.create({
            data: { deliveryorder_id: courseId, manager_id: manager ? manager.id : null, statut: 'Ouvert', description: req.body.description || 'Litige declare par le commercant', motif: req.body.motif || null }
        });
        res.status(201).json({ message: 'Litige declare.', litige });
    } catch (err) { res.status(500).json({ message: 'Erreur serveur', error: err.message }); }
}

module.exports = { mesLivraisons, livraisonsEnCours, detailLivraison, creerLivraison, commanderCourse, supprimerCommande, livreursDisponibles, declarerLitige };