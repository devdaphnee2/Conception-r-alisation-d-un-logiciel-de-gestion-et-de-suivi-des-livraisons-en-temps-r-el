const prisma = require('../../utils/prismaClient');
const crypto = require('crypto');
const bcrypt = require('bcrypt');

function genererOTP() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

// Envoie SMS + lien WhatsApp au CLIENT — appelé UNIQUEMENT au démarrage de la course
async function envoyerNotificationClient(livraisonId, clientNom, clientTel, clientWa, otp, trackingUrl) {
    var message = 'Bonjour ' + clientNom + ' !\n\n' +
        'Votre commande Glotelho est en cours de livraison.\n' +
        'Numero : #' + String(livraisonId).padStart(5, '0') + '\n\n' +
        'Suivez votre livreur en temps reel :\n' + trackingUrl + '\n\n' +
        'Code a donner au livreur a la reception :\n*' + otp + '*\n\n' +
        'Ne partagez pas ce code.';

    var waTel = (clientWa || clientTel).replace(/\s/g, '').replace(/\+/g, '');
    if (!waTel.startsWith('237')) waTel = '237' + waTel;
    var waLink = 'https://wa.me/' + waTel + '?text=' + encodeURIComponent(message);

    console.log('[NOTIF CLIENT] WhatsApp:', waLink);

    try {
        var AfricasTalking = require('africastalking');
        var at = AfricasTalking({ username: process.env.AT_USERNAME || 'sandbox', apiKey: process.env.AT_API_KEY });
        var smsTel = clientTel.replace(/\s/g, '');
        if (!smsTel.startsWith('+')) smsTel = '+' + smsTel.replace(/\+/g, '');
        await at.SMS.send({ to: [smsTel], message: message });
        console.log('[SMS] Envoyé à', smsTel);
    } catch (smsErr) {
        console.warn('[SMS] Echec:', smsErr.message);
    }

    return { message, waLink };
}

// Notification FCM — envoyer une push notification via Firebase
async function envoyerNotificationFCM(fcmToken, titre, corps) {
    if (!fcmToken) return;
    try {
        var { getFirebaseDB } = require('../../config/firebaseAdmin');
        var db = getFirebaseDB();
        if (db) {
            await db.ref('notifications/' + Date.now()).set({
                token: fcmToken,
                titre: titre,
                corps: corps,
                lu: false,
                createdAt: Date.now()
            });
        }
        console.log('[FCM] Notification envoyée:', titre);
    } catch (e) {
        console.warn('[FCM] Echec:', e.message);
    }
}

// GET /api/livraisons
async function index(req, res) {
    try {
        var where = {};
        var validStatuses = ['En_attente', 'Assign_', 'En_cours', 'Livr_', 'Suspendu', 'Annul_'];
        if (req.query.status && validStatuses.includes(req.query.status.trim())) {
            where.status = req.query.status.trim();
        } else {
            where.status = { in: validStatuses };
        }
        var livraisons = await prisma.deliveryorders.findMany({
            where,
            include: {
                customers: { include: { users: true } },
                delivery_persons: { include: { users: true, vehicules: true } },
                delivery_items: true,
            },
            orderBy: { creation_date: 'desc' }
        });
        res.json(livraisons);
    } catch (error) {
        console.error('ERREUR INDEX:', error.message);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// POST /api/livraisons — saisie manuelle admin
async function create(req, res) {
    try {
        var body = req.body;
        if (!body.client_nom || !body.client_telephone || !body.delivery_address) {
            return res.status(400).json({ message: 'Nom client, telephone et adresse requis.' });
        }
        var manager = await prisma.managers.findFirst({ where: { user_id: req.user.id } });
        if (!manager) return res.status(403).json({ message: 'Manager introuvable.' });

        var telClean = body.client_telephone.replace(/\s/g, '').replace(/\+/g, '');
        var customer = null;
        var existingUser = await prisma.users.findFirst({ where: { phone: body.client_telephone } });
        if (existingUser) {
            customer = await prisma.customers.findFirst({ where: { user_id: existingUser.id } });
            if (!customer) customer = await prisma.customers.create({ data: { user_id: existingUser.id } });
        } else {
            var parts = body.client_nom.trim().split(' ');
            var newUser = await prisma.users.create({
                data: { first_name: parts[0] || body.client_nom, last_name: parts.slice(1).join(' ') || '-', email: telClean + '@glotelho.cm', password: await bcrypt.hash(crypto.randomBytes(16).toString('hex'), 10), phone: body.client_telephone, role: 'customer' }
            });
            customer = await prisma.customers.create({ data: { user_id: newUser.id } });
        }

        var otp = genererOTP();
        var livreurId = body.delivery_person_id ? parseInt(body.delivery_person_id) : null;
        var statut = livreurId ? 'Assign_' : 'En_attente';

        var livraison = await prisma.deliveryorders.create({
            data: {
                manager_id: manager.id,
                customer_id: customer.id,
                delivery_person_id: livreurId,
                delivery_address: body.delivery_address,
                zone_bloc: body.zone_bloc || null,
                delivery_instructions: body.delivery_instructions || null,
                amount_to_collect: parseFloat(body.amount_to_collect) || 0,
                collected_amount: 0,
                status: statut,
                delivery_date: body.delivery_date ? new Date(body.delivery_date) : null,
                client_nom: body.client_nom,
                client_telephone: body.client_telephone,
                client_whatsapp: body.client_whatsapp || body.client_telephone,
            }
        });

        if (body.articles && body.articles.length > 0) {
            var articlesData = body.articles.filter(a => a.nom && a.nom.trim()).map(a => ({
                deliveryorder_id: livraison.id,
                order_id: null,
                product_name: a.nom,
                quantity: parseInt(a.quantite) || 1,
                unit_price: parseFloat(a.prix_unitaire) || 0,
                status: 'Disponible',
            }));
            if (articlesData.length > 0) await prisma.delivery_items.createMany({ data: articlesData });
        }

        await prisma.confirmations.create({ data: { deliveryorder_id: livraison.id, otp_code: otp, methode: 'OTP' } });

        var trackingUrl = (process.env.FRONTEND_URL || 'http://localhost:5173') + '/suivi/' + livraison.id;

        res.status(201).json({
            message: 'Livraison créée.',
            livraison,
            otp,
            tracking_url: trackingUrl,
        });
    } catch (error) {
        console.error('ERREUR CREATE:', error.message);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// GET /api/livraisons/:id
async function show(req, res) {
    try {
        var livraison = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) },
            include: {
                customers: { include: { users: true } },
                delivery_persons: {
                    include: {
                        vehicules: true,
                        users: { take: 1 }, // prendre le premier user du tableau
                    }
                },
                managers: { include: { users: true } },
                delivery_items: true,
                rapports: true,
                confirmations: true,
            }
        });
        if (!livraison) return res.status(404).json({ message: 'Livraison introuvable.' });
        res.json(livraison);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// PUT /api/livraisons/:id
async function update(req, res) {
    try {
        var data = {};
        if (req.body.delivery_address) data.delivery_address = req.body.delivery_address;
        if (req.body.zone_bloc !== undefined) data.zone_bloc = req.body.zone_bloc;
        if (req.body.delivery_instructions !== undefined) data.delivery_instructions = req.body.delivery_instructions;
        if (req.body.delivery_date) data.delivery_date = new Date(req.body.delivery_date);
        if (req.body.amount_to_collect) data.amount_to_collect = parseFloat(req.body.amount_to_collect);
        if (req.body.collected_amount !== undefined) data.collected_amount = parseFloat(req.body.collected_amount);
        var updated = await prisma.deliveryorders.update({ where: { id: parseInt(req.params.id) }, data });
        res.json({ message: 'Livraison mise à jour.', livraison: updated });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// POST /api/livraisons/:id/assigner
// — NE PAS envoyer WhatsApp ici — seulement notifier le commerçant et l'admin
async function assigner(req, res) {
    try {
        var delivery_person_id = req.body.delivery_person_id;
        if (!delivery_person_id) return res.status(400).json({ message: 'Livreur requis.' });

        var livraison = await prisma.deliveryorders.update({
            where: { id: parseInt(req.params.id) },
            data: { delivery_person_id: parseInt(delivery_person_id), status: 'Assign_' },
            include: {
                customers: { include: { users: true } },
                delivery_persons: { include: { users: true } },
                managers: { include: { users: true } },
                delivery_items: true,
                confirmations: true,
            }
        });

        var livraisonId = livraison.id;
        var clientNom = livraison.client_nom || (livraison.customers && livraison.customers.users ? livraison.customers.users.first_name + ' ' + livraison.customers.users.last_name : 'Client');
        var livreurNom = livraison.delivery_persons && livraison.delivery_persons.users ? livraison.delivery_persons.users.first_name + ' ' + livraison.delivery_persons.users.last_name : 'Livreur';
        var managerNom = livraison.managers && livraison.managers.users ? livraison.managers.users.first_name + ' ' + livraison.managers.users.last_name : 'Commerçant';

        // Notifier le commerçant (manager) via FCM
        var managerUser = livraison.managers && livraison.managers.users;
        if (managerUser && managerUser.fcm_token) {
            await envoyerNotificationFCM(
                managerUser.fcm_token,
                '✅ Commande assignée',
                'Votre commande #' + String(livraisonId).padStart(5, '0') + ' pour ' + clientNom + ' a été assignée à ' + livreurNom + '.'
            );
        }

        // Notifier l'admin (tous les managers avec role manager)
        var admins = await prisma.users.findMany({ where: { role: 'manager', fcm_token: { not: null } } });
        for (var admin of admins) {
            if (admin.id !== (managerUser && managerUser.id)) {
                await envoyerNotificationFCM(
                    admin.fcm_token,
                    '🚚 Nouvelle course : ' + managerNom,
                    'Client : ' + clientNom + ' — Livreur : ' + livreurNom
                );
            }
        }

        console.log('[ASSIGNER] Livraison #' + livraisonId + ' assignée à ' + livreurNom);

        res.json({
            message: 'Livreur assigné. Le commerçant et l\'admin ont été notifiés.',
            livraison: livraison,
        });
    } catch (error) {
        console.error('ERREUR ASSIGNER:', error.message);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// POST /api/livraisons/:id/annuler
async function annuler(req, res) {
    try {
        var livraison = await prisma.deliveryorders.update({
            where: { id: parseInt(req.params.id) },
            data: { status: 'Annul_', tracking_blocked: true }
        });
        res.json({ message: 'Livraison annulée.', livraison });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// POST /api/v1/drivers/courses/:id/demarrer — appelé depuis l'app livreur
// C'EST ICI qu'on envoie le WhatsApp au client
async function demarrerCourse(req, res) {
    try {
        var livraisonId = parseInt(req.params.id);
        var livreur = await prisma.delivery_persons.findFirst({
            where: { user_id: req.user.id },
            include: { users: true }
        });
        if (!livreur) return res.status(404).json({ message: 'Livreur introuvable.' });

        var livraison = await prisma.deliveryorders.findUnique({
            where: { id: livraisonId },
            include: { customers: { include: { users: true } }, confirmations: true, managers: { include: { users: true } } }
        });
        if (!livraison) return res.status(404).json({ message: 'Livraison introuvable.' });

        // Passer en En_cours
        await prisma.deliveryorders.update({ where: { id: livraisonId }, data: { status: 'En_cours' } });
        await prisma.delivery_persons.update({ where: { id: livreur.id }, data: { status: 'En_livraison', available: 0 } });

        // OTP
        var otp = livraison.confirmations && livraison.confirmations.length > 0 ?
            livraison.confirmations[0].otp_code : genererOTP();

        var clientNom = livraison.client_nom || (livraison.customers && livraison.customers.users ? (livraison.customers.users.first_name + ' ' + livraison.customers.users.last_name) : 'Client');
        var clientTel = livraison.client_telephone || livraison.customers && livraison.customers.users.phone || '';
        var clientWa = livraison.client_whatsapp || clientTel;
        var livreurNom = livreur.users ? (livreur.users.first_name + ' ' + livreur.users.last_name) : 'Votre livreur';

        var trackingUrl = (process.env.FRONTEND_URL || 'http://localhost:5173') + '/suivi/' + livraisonId;

        // Envoyer WhatsApp + SMS au CLIENT maintenant
        var notif = await envoyerNotificationClient(livraisonId, clientNom, clientTel, clientWa, otp, trackingUrl);

        // Notifier le commerçant que la course a démarré
        var managerUser = livraison.managers && livraison.managers.users;
        if (managerUser && managerUser.fcm_token) {
            await envoyerNotificationFCM(
                managerUser.fcm_token,
                '🛵 Course démarrée',
                livreurNom + ' est en route vers ' + clientNom + ' pour la commande #' + String(livraisonId).padStart(5, '0') + '.'
            );
        }

        res.json({
            message: 'Course démarrée. Client notifié.',
            whatsapp_link: notif.waLink,
            tracking_url: trackingUrl,
            otp: otp,
        });
    } catch (error) {
        console.error('ERREUR DEMARRER:', error.message);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

module.exports = { index, create, show, update, assigner, annuler, demarrerCourse };