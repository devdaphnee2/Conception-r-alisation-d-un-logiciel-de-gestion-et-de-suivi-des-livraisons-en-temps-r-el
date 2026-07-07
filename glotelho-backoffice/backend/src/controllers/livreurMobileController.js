const prisma = require('../utils/prismaClient');
const { getFirebaseDB } = require('../config/firebaseAdmin');

async function getProfil(req, res) {
    try {
        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id },
            include: { users: true, vehicules: true }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });
        res.json(livreur);
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function updateFcmToken(req, res) {
    try {
        const { fcm_token } = req.body;
        await prisma.users.update({ where: { id: req.user.id }, data: { fcm_token } });
        res.json({ message: 'Token FCM mis a jour.' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function toggleDisponibilite(req, res) {
    try {
        const { available } = req.body;
        const livreur = await prisma.delivery_persons.findUnique({ where: { user_id: req.user.id } });
        if (!livreur) return res.status(404).json({ message: 'Livreur introuvable.' });
        const newStatus = available ? 'Disponible' : 'Indisponible';
        await prisma.delivery_persons.update({
            where: { id: livreur.id },
            data: { available: !!available, status: newStatus }
        });
        res.json({ message: 'Disponibilite mise a jour.', status: newStatus });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function getCourses(req, res) {
    try {
        const livreur = await prisma.delivery_persons.findUnique({ where: { user_id: req.user.id } });
        if (!livreur) return res.status(404).json({ message: 'Livreur introuvable.' });
        const courses = await prisma.deliveryorders.findMany({
            where: { delivery_person_id: livreur.id, status: { in: ['Assign_', 'En_cours'] } },
            include: { customers: { include: { users: true } }, delivery_items: true },
            orderBy: { creation_date: 'desc' }
        });
        res.json(courses);
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function getHistorique(req, res) {
    try {
        const livreur = await prisma.delivery_persons.findUnique({ where: { user_id: req.user.id } });
        if (!livreur) return res.status(404).json({ message: 'Livreur introuvable.' });
        const courses = await prisma.deliveryorders.findMany({
            where: { delivery_person_id: livreur.id, status: { in: ['Livr_', 'Annul_'] } },
            include: { customers: { include: { users: true } } },
            orderBy: { creation_date: 'desc' },
            take: 50
        });
        res.json(courses);
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function accepterCourse(req, res) {
    try {
        const livreur = await prisma.delivery_persons.findUnique({ where: { user_id: req.user.id } });
        const course = await prisma.deliveryorders.findUnique({ where: { id: parseInt(req.params.id) } });
        if (!course) return res.status(404).json({ message: 'Course introuvable.' });
        if (course.delivery_person_id !== livreur.id) return res.status(403).json({ message: 'Non autorise.' });
        await prisma.deliveryorders.update({ where: { id: course.id }, data: { status: 'Assign_' } });
        res.json({ message: 'Course acceptee.' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function refuserCourse(req, res) {
    try {
        const course = await prisma.deliveryorders.findUnique({ where: { id: parseInt(req.params.id) } });
        if (!course) return res.status(404).json({ message: 'Course introuvable.' });
        await prisma.deliveryorders.update({ where: { id: course.id }, data: { status: 'En_attente', delivery_person_id: null } });
        res.json({ message: 'Course refusee.' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function demarrerCourse(req, res) {
    try {
        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id },
            include: { users: true }
        });
        const courseId = parseInt(req.params.id);
        const course = await prisma.deliveryorders.findUnique({
            where: { id: courseId },
            include: { confirmations: true }
        });
        if (!course) return res.status(404).json({ message: 'Course introuvable.' });

        await prisma.deliveryorders.update({
            where: { id: courseId },
            data: { status: 'En_cours' }
        });
        await prisma.delivery_persons.update({
            where: { id: livreur.id },
            data: { status: 'En_livraison', available: false }
        });

        // Recuperer OTP
        var otp = '';
        if (course.confirmations && course.confirmations.length > 0) {
            otp = course.confirmations[0].otp_code || '';
        }

        // Generer lien tracking public
        var frontendUrl = process.env.FRONTEND_URL || 'http://localhost:5173';
        var trackingUrl = frontendUrl + '/tracking/' + courseId;

        // Nom client
        var clientNom = course.client_nom || 'Client';
        var clientWa = course.client_whatsapp || course.client_telephone || '';

        // Construire message WhatsApp
        var message = 'Bonjour ' + clientNom + ' !\n\n' +
            'Votre livreur ' + (livreur.users ? livreur.users.first_name + ' ' + livreur.users.last_name : '') + ' vient de demarrer la course.\n\n' +
            'Suivez votre livraison en temps reel :\n' + trackingUrl + '\n\n' +
            'Code a donner au livreur a la reception :\n' +
            '*' + otp + '*\n\n' +
            'Ne partagez pas ce code.';

        // Lien WhatsApp pre-rempli
        var waTel = clientWa.replace(/\s/g, '').replace(/\+/g, '');
        if (waTel && !waTel.startsWith('237')) {
            waTel = '237' + waTel;
        }
        var waLink = waTel ? 'https://wa.me/' + waTel + '?text=' + encodeURIComponent(message) : null;

        console.log('=== NOTIFICATION DEMARRAGE COURSE ===');
        console.log('WhatsApp :', clientWa);
        console.log('Lien :', waLink);
        console.log(message);
        console.log('=====================================');

        res.json({
            message: 'Course demarree.',
            whatsapp_link: waLink,
            tracking_url: trackingUrl,
            otp: otp
        });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

// ── POST /api/mobile/livreur/courses/:id/position ───────────
// Ecrit uniquement dans Firebase — BDD desactivee (races requis par schema)
async function updatePosition(req, res) {
    try {
        const { latitude, longitude, speed } = req.body;
        if (!latitude || !longitude) {
            return res.status(400).json({ message: 'Latitude et longitude requises.' });
        }

        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id },
            include: { users: true, vehicules: true }
        });
        if (!livreur) return res.status(404).json({ message: 'Livreur introuvable.' });

        const courseId = parseInt(req.params.id);

        // Ecrire dans Firebase Realtime Database
        const firebaseDb = getFirebaseDB();
        if (firebaseDb) {
            await firebaseDb.ref('positions/' + livreur.id).set({
                latitude: parseFloat(latitude),
                longitude: parseFloat(longitude),
                speed: speed ? parseFloat(speed) : 0,
                livraison_id: courseId,
                livreur_nom: livreur.users ? (livreur.users.first_name + ' ' + livreur.users.last_name) : 'Livreur',
                vehicule: livreur.vehicules ? livreur.vehicules.type : 'moto',
                timestamp: Date.now(),
                status: 'En_livraison',
            });
            console.log('[Firebase] Position mise a jour : livreur ' + livreur.id + ' -> ' + latitude + ', ' + longitude);
        } else {
            console.warn('[Firebase] Non disponible — position non enregistree');
        }

        res.json({ message: 'Position mise a jour.', latitude, longitude });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function signalerArrivee(req, res) {
    try {
        const courseId = parseInt(req.params.id);
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        await prisma.confirmations.create({ data: { deliveryorder_id: courseId, type: 'otp', value: otp } });
        res.json({ message: 'Arrivee signalee. OTP genere.', otp });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function cloturerCourse(req, res) {
    try {
        const { rapport } = req.body;
        const courseId = parseInt(req.params.id);
        const livreur = await prisma.delivery_persons.findUnique({ where: { user_id: req.user.id } });

        await prisma.deliveryorders.update({ where: { id: courseId }, data: { status: 'Livr_', tracking_blocked: true } });
        await prisma.delivery_persons.update({ where: { id: livreur.id }, data: { status: 'Disponible', available: true } });

        if (rapport) {
            await prisma.rapports.create({ data: { deliveryorder_id: courseId, type: 'livraison', contenu: rapport, auteur: 'Livreur' } });
        }

        const firebaseDb = getFirebaseDB();
        if (firebaseDb) {
            await firebaseDb.ref('positions/' + livreur.id).remove();
        }

        res.json({ message: 'Course cloturee avec succes.' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function signalerIncident(req, res) {
    try {
        const { type_incident, description } = req.body;
        const courseId = parseInt(req.params.id);
        const livreur = await prisma.delivery_persons.findUnique({ where: { user_id: req.user.id } });

        await prisma.deliveryorders.update({
            where: { id: courseId },
            data: { status: 'Suspendu', suspension_reason: type_incident + ' : ' + (description || '') }
        });

        if (type_incident === 'perte_colis' || type_incident === 'colis_casse') {
            const course = await prisma.deliveryorders.findUnique({ where: { id: courseId } });
            await prisma.recouvrement.create({
                data: {
                    deliveryorder_id: courseId,
                    delivery_person_id: livreur.id,
                    motif: type_incident,
                    amount_to_collect: course.amount_to_collect || 0,
                    amount_collected: 0,
                }
            });
        }

        res.json({ message: 'Incident signale.' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

module.exports = {
    getProfil,
    updateFcmToken,
    toggleDisponibilite,
    getCourses,
    getHistorique,
    accepterCourse,
    refuserCourse,
    demarrerCourse,
    updatePosition,
    signalerArrivee,
    cloturerCourse,
    signalerIncident
};