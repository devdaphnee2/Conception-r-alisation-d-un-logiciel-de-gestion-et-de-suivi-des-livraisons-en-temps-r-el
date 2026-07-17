const prisma = require('../../utils/prismaClient');
const crypto = require('crypto');
const bcrypt = require('bcrypt');

function genererOTP() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

async function enrichirLivreur(livraison) {
    if (livraison && livraison.delivery_persons && livraison.delivery_persons.user_id) {
        var u = await prisma.users.findUnique({
            where: { id: livraison.delivery_persons.user_id },
            select: { id: true, first_name: true, last_name: true, phone: true, email: true }
        });
        livraison.delivery_persons.user = u;
        livraison.delivery_persons.users = u;
    }
    return livraison;
}

async function enrichirLivraisons(livraisons) {
    for (var i = 0; i < livraisons.length; i++) { await enrichirLivreur(livraisons[i]); }
    return livraisons;
}

async function envoyerNotificationClient(livraisonId, clientNom, clientTel, clientWa, otp, trackingUrl) {
    var message = 'Bonjour ' + clientNom + ' !\n\nVotre commande Glotelho est en cours de livraison.\nNumero : #' + String(livraisonId).padStart(5, '0') + '\n\nSuivez votre livreur :\n' + trackingUrl + '\n\nCode a donner au livreur :\n*' + otp + '*\n\nNe partagez pas ce code.';
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
    } catch (smsErr) { console.warn('[SMS] Echec:', smsErr.message); }
    return { message, waLink };
}

async function envoyerNotificationFCM(fcmToken, titre, corps) {
    if (!fcmToken) return;
    try {
        var { getFirebaseDB } = require('../../config/firebaseAdmin');
        var db = getFirebaseDB();
        if (db) await db.ref('notifications/' + Date.now()).set({ token: fcmToken, titre, corps, lu: false, createdAt: Date.now() });
    } catch (e) { console.warn('[FCM] Echec:', e.message); }
}

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
            include: { customers: { include: { users: true } }, delivery_persons: { include: { vehicules: true } }, delivery_items: true },
            orderBy: { creation_date: 'desc' }
        });
        await enrichirLivraisons(livraisons);
        res.json(livraisons);
    } catch (error) {
        console.error('ERREUR INDEX:', error.message);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

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
            var articlesData = body.articles.filter(function(a) { return a.nom && a.nom.trim(); }).map(function(a) {
                return { deliveryorder_id: livraison.id, product_name: a.nom, quantity: parseInt(a.quantite) || 1, price: parseFloat(a.prix_unitaire) || 0, status: 'Disponible' };
            });
            if (articlesData.length > 0) await prisma.delivery_items.createMany({ data: articlesData });
        }

        // Créer confirmation avec livreur si assigné, sinon sans
        if (livreurId) {
            await prisma.confirmations.create({
                data: { deliveryorder_id: livraison.id, customer_id: customer.id, delivery_person_id: livreurId, otp_code: otp, methode: 'OTP' }
            });
        }

        var trackingUrl = (process.env.FRONTEND_URL || 'http://localhost:5173') + '/suivi/' + livraison.id;
        res.status(201).json({ message: 'Livraison créée.', livraison, otp, tracking_url: trackingUrl });
    } catch (error) {
        console.error('ERREUR CREATE:', error.message);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

async function show(req, res) {
    try {
        var livraison = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) },
            include: { customers: { include: { users: true } }, delivery_persons: { include: { vehicules: true } }, managers: { include: { users: true } }, delivery_items: true, rapports: true, confirmations: true }
        });
        if (!livraison) return res.status(404).json({ message: 'Livraison introuvable.' });
        await enrichirLivreur(livraison);
        res.json(livraison);
    } catch (error) { res.status(500).json({ message: 'Erreur serveur', error: error.message }); }
}

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
    } catch (error) { res.status(500).json({ message: 'Erreur serveur', error: error.message }); }
}

async function assigner(req, res) {
    try {
        var delivery_person_id = req.body.delivery_person_id;
        if (!delivery_person_id) return res.status(400).json({ message: 'Livreur requis.' });

        var livraison = await prisma.deliveryorders.update({
            where: { id: parseInt(req.params.id) },
            data: { delivery_person_id: parseInt(delivery_person_id), status: 'Assign_' },
            include: {
                customers: { include: { users: true } },
                delivery_persons: { include: { vehicules: true } },
                managers: { include: { users: true } },
                delivery_items: true,
                confirmations: true
            }
        });

        await enrichirLivreur(livraison);

        // Créer OTP si pas encore de confirmation
        if (!livraison.confirmations || livraison.confirmations.length === 0) {
            var otp = genererOTP();
            try {
                await prisma.confirmations.create({
                    data: {
                        deliveryorder_id: livraison.id,
                        customer_id: livraison.customer_id,
                        delivery_person_id: parseInt(delivery_person_id),
                        otp_code: otp,
                        methode: 'OTP'
                    }
                });
            } catch (e) { console.warn('[CONFIRMATION] Echec création OTP:', e.message); }
        } else {
            try {
                await prisma.confirmations.updateMany({
                    where: { deliveryorder_id: livraison.id },
                    data: { delivery_person_id: parseInt(delivery_person_id) }
                });
            } catch (e) { console.warn('[CONFIRMATION] Echec update:', e.message); }
        }

        var livraisonId = livraison.id;
        var clientNom = livraison.client_nom || 'Client';

        // Récupérer les infos du livreur via user_id
        var livreurDP = await prisma.delivery_persons.findUnique({
            where: { id: parseInt(delivery_person_id) },
            include: { users: true }
        });
        var livreurNom = livreurDP && livreurDP.users ?
            livreurDP.users.first_name + ' ' + livreurDP.users.last_name :
            'Livreur';
        var livreurTel = livreurDP && livreurDP.users ? livreurDP.users.phone : '';

        var managerUser = livraison.managers ? livraison.managers.users : null;

        // ── Notification in-app pour le manager (commerçant) ──────────────
        if (livraison.manager_id) {
            var managerRecord = await prisma.managers.findFirst({
                where: { id: livraison.manager_id },
                include: { users: true }
            });
            if (managerRecord && managerRecord.user_id) {
                try {
                    await prisma.notifications.create({
                        data: {
                            recipient_id: managerRecord.user_id,
                            message: '✅ Commande #' + String(livraisonId).padStart(5, '0') +
                                ' assignée à ' + livreurNom +
                                (livreurTel ? ' (' + livreurTel + ')' : '') +
                                ' pour le client ' + clientNom + '.',
                            type: 'Interne',
                            is_read: false,
                        }
                    });
                } catch (e) { console.warn('[NOTIF MANAGER] Echec:', e.message); }
            }
        }

        // ── Notification FCM si token disponible ───────────────────────────
        if (managerUser && managerUser.fcm_token) {
            await envoyerNotificationFCM(
                managerUser.fcm_token,
                '✅ Commande assignée',
                'Commande #' + String(livraisonId).padStart(5, '0') +
                ' assignée à ' + livreurNom + '.'
            );
        }

        console.log('[ASSIGNER] Livraison #' + livraisonId + ' assignée à ' + livreurNom);
        res.json({ message: 'Livreur assigné.', livraison });
    } catch (error) {
        console.error('ERREUR ASSIGNER:', error.message);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

async function annuler(req, res) {
    try {
        var livraison = await prisma.deliveryorders.update({ where: { id: parseInt(req.params.id) }, data: { status: 'Annul_', tracking_blocked: true } });
        res.json({ message: 'Livraison annulée.', livraison });
    } catch (error) { res.status(500).json({ message: 'Erreur serveur', error: error.message }); }
}

async function demarrerCourse(req, res) {
    try {
        var livraisonId = parseInt(req.params.id);
        var livreur = await prisma.delivery_persons.findFirst({ where: { user_id: req.user.id }, include: { users: true } });
        if (!livreur) return res.status(404).json({ message: 'Livreur introuvable.' });

        var livraison = await prisma.deliveryorders.findUnique({
            where: { id: livraisonId },
            include: { customers: { include: { users: true } }, confirmations: true, managers: { include: { users: true } } }
        });
        if (!livraison) return res.status(404).json({ message: 'Livraison introuvable.' });

        await prisma.deliveryorders.update({ where: { id: livraisonId }, data: { status: 'En_cours' } });
        await prisma.delivery_persons.update({ where: { id: livreur.id }, data: { available: 0 } });

        var otp = livraison.confirmations && livraison.confirmations.length > 0 ? livraison.confirmations[0].otp_code : genererOTP();
        var clientNom = livraison.client_nom || 'Client';
        var clientTel = livraison.client_telephone || '';
        var clientWa = livraison.client_whatsapp || clientTel;
        var livreurNom = livreur.users ? (livreur.users.first_name + ' ' + livreur.users.last_name) : 'Votre livreur';
        var trackingUrl = (process.env.FRONTEND_URL || 'http://localhost:5173') + '/suivi/' + livraisonId;

        var notif = await envoyerNotificationClient(livraisonId, clientNom, clientTel, clientWa, otp, trackingUrl);

        var managerUser = livraison.managers ? livraison.managers.users : null;
        if (managerUser && managerUser.fcm_token) {
            await envoyerNotificationFCM(managerUser.fcm_token, '🛵 Course démarrée', livreurNom + ' est en route vers ' + clientNom + '.');
        }

        res.json({ message: 'Course démarrée. Client notifié.', whatsapp_link: notif.waLink, tracking_url: trackingUrl, otp });
    } catch (error) {
        console.error('ERREUR DEMARRER:', error.message);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

module.exports = { index, create, show, update, assigner, annuler, demarrerCourse };