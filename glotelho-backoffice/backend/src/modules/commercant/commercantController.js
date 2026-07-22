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
        var livraison = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) },
            include: {
                delivery_persons: { include: { users: true, vehicules: true } },
                delivery_items: true,
                confirmations: true
            }
        });
        if (!livraison) return res.status(404).json({ message: 'Livraison introuvable.' });
        res.json(livraison);
    } catch (err) {
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

        // ── Calcul des montants ────────────────────────────────────────
        // amount_to_collect = UNIQUEMENT le prix de la marchandise (payé en ligne par le client via OM/MoMo)
        // frais_livraison   = payé en cash au livreur à la remise du colis
        var totalArticles = 0;
        if (body.articles && body.articles.length > 0) {
            body.articles.forEach(function(a) {
                totalArticles += (parseFloat(a.prix_unitaire) || 0) * (parseInt(a.quantite) || 1);
            });
        }
        var fraisLivraison = parseFloat(body.montant_livraison || body.frais_livraison) || 0;

        var livraison = await prisma.deliveryorders.create({
            data: {
                manager_id: manager.id,
                customer_id: customer.id,
                delivery_person_id: null,
                pickup_address: body.pickup_address || null,
                delivery_address: body.delivery_address,
                zone_bloc: body.zone_bloc || null,
                delivery_instructions: body.delivery_instructions || null,
                amount_to_collect: totalArticles, // ← uniquement la marchandise
                frais_livraison: fraisLivraison, // ← payé cash au livreur
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

        res.status(201).json({ message: 'Commande enregistrée.', livraison });
    } catch (err) {
        console.error('[creerLivraison]', err.message);
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function commanderCourse(req, res) {
    try {
        var id = parseInt(req.params.id);
        var livraison = await prisma.deliveryorders.findUnique({
            where: { id },
            include: { managers: { include: { users: true } } }
        });
        if (!livraison) return res.status(404).json({ message: 'Commande introuvable.' });
        if (livraison.status !== 'Commande') return res.status(400).json({ message: 'Déjà envoyée.' });

        await prisma.deliveryorders.update({ where: { id }, data: { status: 'En_attente' } });

        var commercantUser = null;
        if (livraison.manager_id) {
            var commercantRecord = await prisma.managers.findFirst({
                where: { id: livraison.manager_id },
                include: { users: true }
            });
            commercantUser = commercantRecord ? commercantRecord.users : null;
        }
        var commercantNom = commercantUser ?
            commercantUser.first_name + ' ' + commercantUser.last_name :
            'Un commerçant';

        try {
            var admins = await prisma.users.findMany({ where: { role: 'manager' } });
            for (var admin of admins) {
                await prisma.notifications.create({
                    data: {
                        recipient_id: admin.id,
                        message: '🛒 Nouvelle commande #' + String(id).padStart(5, '0') +
                            ' reçue de ' + commercantNom +
                            (livraison.delivery_address ? ' · ' + livraison.delivery_address : '') +
                            '. En attente d\'assignation.',
                        type: 'Interne',
                        is_read: false,
                    }
                });
            }
        } catch (e) { console.warn('[NOTIF COMMANDER COURSE] Echec:', e.message); }

        var managerUser = livraison.managers ? livraison.managers.users : null;
        if (managerUser && managerUser.fcm_token) {
            try {
                var { getFirebaseDB } = require('../../config/firebaseAdmin');
                var db = getFirebaseDB();
                if (db) {
                    await db.ref('notifications/' + Date.now()).set({
                        token: managerUser.fcm_token,
                        titre: '🛒 Nouvelle commande reçue',
                        corps: 'Commande #' + String(id).padStart(5, '0') + ' de ' + commercantNom,
                        lu: false,
                        createdAt: Date.now()
                    });
                }
            } catch (e) { console.warn('[FCM COMMANDER COURSE] Echec:', e.message); }
        }

        res.json({ message: "Course commandée ! L'admin va assigner un livreur." });
    } catch (err) {
        console.error('[COMMANDER COURSE] Erreur:', err.message);
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function supprimerCommande(req, res) {
    try {
        var id = parseInt(req.params.id);
        var livraison = await prisma.deliveryorders.findUnique({ where: { id } });
        if (!livraison) return res.status(404).json({ message: 'Commande introuvable.' });
        if (!['Commande', 'En_attente'].includes(livraison.status)) return res.status(400).json({ message: 'Cette commande ne peut plus être annulée.' });
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