const prisma = require('../utils/prismaClient');
const crypto = require('crypto');
const bcrypt = require('bcrypt');

function genererOTP() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

// Envoie SMS via Africa's Talking + lien WhatsApp pre-rempli
async function envoyerNotificationClient(livraisonId, clientNom, clientTel, clientWa, otp, trackingUrl) {
    var message = 'Bonjour ' + clientNom + ' !\n\n' +
        'Votre commande Glotelho est en cours de livraison.\n' +
        'Numero : ' + String(livraisonId).padStart(5, '0') + '\n\n' +
        'Suivez votre livreur en temps reel :\n' + trackingUrl + '\n\n' +
        'Code a donner au livreur a la reception :\n' +
        '*' + otp + '*\n\n' +
        'Ne partagez pas ce code.';

    // Lien WhatsApp avec message pre-rempli
    var waTel = (clientWa || clientTel).replace(/\s/g, '').replace(/\+/g, '');
    if (!waTel.startsWith('237')) {
        waTel = '237' + waTel;
    }
    var waLink = 'https://wa.me/' + waTel + '?text=' + encodeURIComponent(message);

    console.log('=== NOTIFICATION CLIENT ===');
    console.log('WhatsApp link :', waLink);
    console.log('SMS vers :', clientTel);
    console.log(message);
    console.log('===========================');

    // Envoi SMS via Africa's Talking
    try {
        var AfricasTalking = require('africastalking');
        var at = AfricasTalking({
            username: process.env.AT_USERNAME || 'sandbox',
            apiKey: process.env.AT_API_KEY,
        });

        var smsTel = clientTel.replace(/\s/g, '');
        if (!smsTel.startsWith('+')) {
            smsTel = '+' + smsTel.replace(/\+/g, '');
        }

        await at.SMS.send({
            to: [smsTel],
            message: message,
        });
        console.log('[SMS] Envoye avec succes a', smsTel);
    } catch (smsErr) {
        console.warn('[SMS] Echec envoi :', smsErr.message);
    }

    return { message: message, waLink: waLink };
}

// GET /api/livraisons
async function index(req, res) {
    try {
        var where = {};
        if (req.query.status) where.status = req.query.status;

        var livraisons = await prisma.deliveryorders.findMany({
            where: where,
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

// POST /api/livraisons — saisie manuelle
async function create(req, res) {
    console.log('CREATE LIVRAISON appele', req.body);
    try {
        var client_nom = req.body.client_nom || '';
        var client_telephone = req.body.client_telephone || '';
        var client_whatsapp = req.body.client_whatsapp || '';
        var delivery_address = req.body.delivery_address || '';
        var zone_bloc = req.body.zone_bloc || null;
        var delivery_instructions = req.body.delivery_instructions || null;
        var amount_to_collect = req.body.amount_to_collect || 0;
        var articles = req.body.articles || [];
        var delivery_person_id = req.body.delivery_person_id || null;
        var delivery_date = req.body.delivery_date || null;

        if (!client_nom || !client_telephone || !delivery_address) {
            return res.status(400).json({ message: 'Nom client, telephone et adresse requis.' });
        }

        var manager = await prisma.managers.findFirst({ where: { user_id: req.user.id } });
        if (!manager) return res.status(403).json({ message: 'Manager introuvable.' });

        var telClean = client_telephone.replace(/\s/g, '').replace(/\+/g, '');

        // Trouver ou creer le customer
        var customer = null;
        var existingUser = await prisma.users.findFirst({ where: { phone: client_telephone } });

        if (existingUser) {
            customer = await prisma.customers.findFirst({ where: { user_id: existingUser.id } });
            if (!customer) {
                customer = await prisma.customers.create({ data: { user_id: existingUser.id } });
            }
        } else {
            var parts = client_nom.trim().split(' ');
            var firstName = parts[0] || client_nom;
            var lastName = parts.slice(1).join(' ') || '-';

            var newUser = await prisma.users.create({
                data: {
                    first_name: firstName,
                    last_name: lastName,
                    email: telClean + '@glotelho.cm',
                    password: await bcrypt.hash(crypto.randomBytes(16).toString('hex'), 10),
                    phone: client_telephone,
                    role: 'customer',
                }
            });
            customer = await prisma.customers.create({ data: { user_id: newUser.id } });
        }

        var otp = genererOTP();
        var livreurId = delivery_person_id ? parseInt(delivery_person_id) : null;
        var statut = livreurId ? 'Assign_' : 'En_attente';

        var livraison = await prisma.deliveryorders.create({
            data: {
                manager_id: manager.id,
                customer_id: customer.id,
                delivery_person_id: livreurId,
                delivery_address: delivery_address,
                zone_bloc: zone_bloc,
                delivery_instructions: delivery_instructions,
                amount_to_collect: parseFloat(amount_to_collect) || 0,
                collected_amount: 0,
                status: statut,
                delivery_date: delivery_date ? new Date(delivery_date) : null,
                client_nom: client_nom,
                client_telephone: client_telephone,
                client_whatsapp: client_whatsapp || client_telephone,
            }
        });

        // Creer les articles
        if (articles && articles.length > 0) {
            var articlesData = [];
            for (var i = 0; i < articles.length; i++) {
                var a = articles[i];
                if (a.nom && a.nom.trim()) {
                    articlesData.push({
                        deliveryorder_id: livraison.id,
                        order_id: null,
                        product_name: a.nom,
                        quantity: parseInt(a.quantite) || 1,
                        unit_price: parseFloat(a.prix_unitaire) || 0,
                        status: 'Disponible',
                    });
                }
            }
            if (articlesData.length > 0) {
                await prisma.delivery_items.createMany({ data: articlesData });
            }
        }

        // Enregistrer OTP
        await prisma.confirmations.create({
            data: {
                deliveryorder_id: livraison.id,
                otp_code: otp,
                methode: 'OTP',
            }
        });

        var frontendUrl = process.env.FRONTEND_URL || 'http://localhost:5173';
        var trackingUrl = frontendUrl + '/suivi/' + livraison.id;

        // Envoyer SMS + generer lien WhatsApp
        var notif = await envoyerNotificationClient(
            livraison.id, client_nom, client_telephone,
            client_whatsapp, otp, trackingUrl
        );

        res.status(201).json({
            message: 'Livraison creee avec succes.',
            livraison: livraison,
            otp: otp,
            tracking_url: trackingUrl,
            whatsapp_link: notif.waLink,
        });
    } catch (error) {
        console.error('ERREUR CREATE:', error.message);
        console.error(error);
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
                delivery_persons: { include: { users: true, vehicules: true } },
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

        var updated = await prisma.deliveryorders.update({
            where: { id: parseInt(req.params.id) },
            data: data
        });
        res.json({ message: 'Livraison mise a jour.', livraison: updated });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// POST /api/livraisons/:id/assigner
async function assigner(req, res) {
    try {
        var delivery_person_id = req.body.delivery_person_id;
        if (!delivery_person_id) return res.status(400).json({ message: 'Livreur requis.' });

        var livraison = await prisma.deliveryorders.update({
            where: { id: parseInt(req.params.id) },
            data: { delivery_person_id: parseInt(delivery_person_id), status: 'Assign_' },
            include: {
                customers: { include: { users: true } },
                delivery_items: true,
                confirmations: true,
            }
        });

        var otp = genererOTP();
        if (livraison.confirmations && livraison.confirmations.length > 0) {
            otp = livraison.confirmations[0].otp_code || otp;
        }

        var trackingUrl = (process.env.FRONTEND_URL || 'http://localhost:5173') + '/tracking/' + livraison.id;
        var clientNom = livraison.client_nom || '';
        var clientTel = livraison.client_telephone || '';
        var clientWa = livraison.client_whatsapp || clientTel;

        if (!clientNom && livraison.customers && livraison.customers.users) {
            clientNom = livraison.customers.users.first_name + ' ' + livraison.customers.users.last_name;
            clientTel = livraison.customers.users.phone || '';
            clientWa = clientTel;
        }

        var notif = await envoyerNotificationClient(
            livraison.id, clientNom, clientTel, clientWa, otp, trackingUrl
        );

        res.json({
            message: 'Livreur assigne. SMS envoye et lien WhatsApp genere.',
            livraison: livraison,
            tracking_url: trackingUrl,
            whatsapp_link: notif.waLink,
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
        res.json({ message: 'Livraison annulee.', livraison: livraison });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

module.exports = { index, create, show, update, assigner, annuler };