// ============================================================
// CONTROLLER API — Application Mobile Livreur
// Routes : /api/mobile/livreur/*
// Auth : JWT avec role delivery_person
// ============================================================
const prisma = require('../utils/prismaClient');

// GET /api/mobile/livreur/profil
// Profil complet du livreur connecte
async function getProfil(req, res) {
    try {
        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id },
            include: { users: true, vehicules: true }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

        // Verifier si le profil est approuve
        if (livreur.status === 'Indisponible') {
            return res.status(403).json({
                message: 'Profil en attente d\'approbation. Contactez votre manager.',
                status: 'pending',
                caution_payee: livreur.caution_payee,
                caution_montant: livreur.caution_montant,
            });
        }

        if (livreur.status === 'Hors_service') {
            return res.status(403).json({
                message: 'Votre profil a ete rejete. Contactez le support Glotelho.',
                status: 'rejected',
            });
        }

        res.json({
            id: livreur.id,
            user_id: livreur.user_id,
            nom: livreur.users.last_name,
            prenom: livreur.users.first_name,
            email: livreur.users.email,
            telephone: livreur.users.phone,
            fcm_token: livreur.users.fcm_token,
            status: livreur.status,
            available: livreur.available,
            zone_affectee: livreur.zone_affectee,
            vehicule: livreur.vehicules,
            caution_payee: livreur.caution_payee,
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// GET /api/mobile/livreur/courses
// Courses assignees au livreur connecte
async function getMesCourses(req, res) {
    try {
        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

        const courses = await prisma.deliveryorders.findMany({
            where: {
                delivery_person_id: livreur.id,
                status: { in: ['Assign_', 'En_cours'] }
            },
            include: {
                customers: { include: { users: true } },
                delivery_items: true,
                managers: { include: { users: true } },
            },
            orderBy: { creation_date: 'desc' }
        });

        res.json(courses);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// GET /api/mobile/livreur/historique
// Historique des courses terminees
async function getHistorique(req, res) {
    try {
        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

        const courses = await prisma.deliveryorders.findMany({
            where: {
                delivery_person_id: livreur.id,
                status: { in: ['Livr_', 'Annul_', 'Suspendu'] }
            },
            include: {
                customers: { include: { users: true } },
                delivery_items: true,
            },
            orderBy: { creation_date: 'desc' },
            take: 50
        });

        res.json(courses);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// POST /api/mobile/livreur/disponibilite
// body: { available: true/false }
async function setDisponibilite(req, res) {
    try {
        const { available } = req.body;
        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

        // Ne pas modifier si en cours de livraison
        if (livreur.status === 'En_livraison') {
            return res.status(400).json({ message: 'Impossible de changer de disponibilite pendant une livraison.' });
        }

        const updated = await prisma.delivery_persons.update({
            where: { user_id: req.user.id },
            data: {
                available: !!available,
                status: available ? 'Disponible' : 'Indisponible'
            }
        });

        res.json({ message: available ? 'Vous etes maintenant disponible.' : 'Vous etes maintenant indisponible.', livreur: updated });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// POST /api/mobile/livreur/courses/:id/accepter
// Accepter une course assignee
async function accepterCourse(req, res) {
    try {
        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

        const course = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) }
        });
        if (!course) return res.status(404).json({ message: 'Course introuvable.' });
        if (course.delivery_person_id !== livreur.id) {
            return res.status(403).json({ message: 'Cette course ne vous est pas assignee.' });
        }
        if (course.status !== 'Assign_') {
            return res.status(400).json({ message: 'Cette course ne peut pas etre acceptee.' });
        }

        // Statut livreur -> En_livraison
        await prisma.delivery_persons.update({
            where: { id: livreur.id },
            data: { status: 'En_livraison', available: false }
        });

        res.json({ message: 'Course acceptee. Bonne livraison !', course });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// POST /api/mobile/livreur/courses/:id/refuser
// body: { motif: string }
// Refuser une course -> retour En_attente
async function refuserCourse(req, res) {
    try {
        const { motif } = req.body;
        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

        const course = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) }
        });
        if (!course) return res.status(404).json({ message: 'Course introuvable.' });
        if (course.delivery_person_id !== livreur.id) {
            return res.status(403).json({ message: 'Cette course ne vous est pas assignee.' });
        }

        // Retour En_attente pour reassignation
        const updated = await prisma.deliveryorders.update({
            where: { id: parseInt(req.params.id) },
            data: {
                status: 'En_attente',
                delivery_person_id: null,
            }
        });

        // Livreur redevient disponible
        await prisma.delivery_persons.update({
            where: { id: livreur.id },
            data: { status: 'Disponible', available: true }
        });

        // TODO: FCM -> manager notifie du refus
        res.json({ message: 'Course refusee. Le manager sera notifie.', course: updated });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// POST /api/mobile/livreur/courses/:id/demarrer
// Demarrer la course -> statut En_cours + activation tracking GPS
async function demarrerCourse(req, res) {
    try {
        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

        const course = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) }
        });
        if (!course) return res.status(404).json({ message: 'Course introuvable.' });
        if (course.delivery_person_id !== livreur.id) {
            return res.status(403).json({ message: 'Cette course ne vous est pas assignee.' });
        }
        if (course.status !== 'Assign_') {
            return res.status(400).json({ message: 'La course doit etre en statut Assigne pour demarrer.' });
        }

        const updated = await prisma.deliveryorders.update({
            where: { id: parseInt(req.params.id) },
            data: { status: 'En_cours' }
        });

        // TODO: Firebase -> activer tracking positions/{livreur.id}
        // TODO: FCM -> notifier client que le livreur est en route
        res.json({
            message: 'Course demarree. Activez le partage de position GPS.',
            course: updated,
            firebase_path: 'positions/' + livreur.id,
            tracking_instructions: 'Ecrivez votre position GPS dans Firebase Realtime Database toutes les 5 secondes : positions/' + livreur.id + ' = { lat, lng, vitesse, timestamp }'
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// POST /api/mobile/livreur/courses/:id/position
// body: { latitude, longitude, vitesse }
// Enregistrer position GPS (backup BDD + Firebase)
async function enregistrerPosition(req, res) {
    try {
        const { latitude, longitude, vitesse } = req.body;
        if (!latitude || !longitude) {
            return res.status(400).json({ message: 'Latitude et longitude requises.' });
        }

        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

        const course = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) }
        });
        if (!course || course.tracking_blocked) {
            return res.status(400).json({ message: 'Tracking bloque ou course introuvable.' });
        }

        // Historique GPS en BDD
        await prisma.position_tracking.create({
            data: {
                delivery_person_id: livreur.id,
                latitude: parseFloat(latitude),
                longitude: parseFloat(longitude),
                speed: vitesse ? parseFloat(vitesse) : null,
                timestamp: new Date(),
            }
        });

        // TODO: En production -> ecrire aussi dans Firebase
        // admin.database().ref('positions/' + livreur.id).set({ lat: latitude, lng: longitude, vitesse, timestamp: Date.now() })

        res.json({
            message: 'Position enregistree.',
            firebase_path: 'positions/' + livreur.id,
            position: { latitude, longitude, vitesse, timestamp: new Date() }
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// POST /api/mobile/livreur/courses/:id/arrivee
// Signaler arrivee a destination -> notif push client
async function signalerArrivee(req, res) {
    try {
        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id },
            include: { users: true }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

        const course = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) },
            include: { customers: { include: { users: true } } }
        });
        if (!course) return res.status(404).json({ message: 'Course introuvable.' });

        // TODO: FCM -> notifier client "Votre livreur est arrive !"
        // await sendFCM(course.customers.users.fcm_token, 'Livreur arrive', livreur.users.first_name + ' est arrive a votre adresse.')

        res.json({
            message: 'Arrivee signalee. Notification envoyee au client.',
            client: course.customers ? .users ? .first_name,
            // Code OTP simule (en prod: generer et stocker en BDD)
            otp_code: Math.floor(100000 + Math.random() * 900000).toString(),
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// POST /api/mobile/livreur/courses/:id/cloturer
// body: { otp_code, montant_collecte, observations }
// Cloturer la course -> statut Livr_
async function cloturerCourse(req, res) {
    try {
        const { otp_code, montant_collecte, observations } = req.body;
        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

        const course = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) }
        });
        if (!course) return res.status(404).json({ message: 'Course introuvable.' });
        if (course.delivery_person_id !== livreur.id) {
            return res.status(403).json({ message: 'Cette course ne vous est pas assignee.' });
        }
        if (course.status !== 'En_cours') {
            return res.status(400).json({ message: 'La course doit etre En_cours pour etre cloturee.' });
        }

        // TODO: Valider OTP ici

        // Cloturer la course
        const updated = await prisma.deliveryorders.update({
            where: { id: parseInt(req.params.id) },
            data: {
                status: 'Livr_',
                collected_amount: montant_collecte ? parseFloat(montant_collecte) : course.amount_to_collect,
                delivery_date: new Date(),
                tracking_blocked: true,
            }
        });

        // Creer rapport de livraison
        if (observations) {
            await prisma.rapports.create({
                data: {
                    deliveryorder_id: parseInt(req.params.id),
                    type: 'livraison',
                    contenu: observations,
                    auteur: 'livreur_' + livreur.id,
                    dateCreation: new Date(),
                }
            });
        }

        // Livreur redevient disponible
        await prisma.delivery_persons.update({
            where: { id: livreur.id },
            data: { status: 'Disponible', available: true }
        });

        // TODO: Firebase -> effacer positions/{livreur.id}
        // TODO: FCM -> notifier manager + client que la livraison est faite

        res.json({
            message: 'Livraison cloturee avec succes. Vous etes maintenant disponible.',
            course: updated,
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// POST /api/mobile/livreur/courses/:id/incident
// body: { type: 'panne'|'perte_colis'|'colis_casse', description }
// Signaler un incident -> suspension + dette si perte/casse
async function signalerIncident(req, res) {
    try {
        const { type, description } = req.body;
        if (!type) return res.status(400).json({ message: 'Type d\'incident requis.' });

        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

        const course = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) },
            include: { orders: true }
        });
        if (!course) return res.status(404).json({ message: 'Course introuvable.' });

        // Suspendre la course
        const motifMap = {
            'panne': 'Panne vehicule — L2 recupere au point GPS d\'arret',
            'perte_colis': 'Colis perdu — DetteFinanciere creee — L2 repart du depot',
            'colis_casse': 'Colis casse — DetteFinanciere + course retour debris',
        };

        await prisma.deliveryorders.update({
            where: { id: parseInt(req.params.id) },
            data: {
                status: 'Suspendu',
                suspension_reason: motifMap[type] || description || type,
            }
        });

        // Creer dette financiere si perte ou casse
        if (['perte_colis', 'colis_casse'].includes(type)) {
            const montantDette = course.amount_to_collect || (course.orders ? .total_amount) || 0;
            await prisma.recouvrement.create({
                data: {
                    deliveryorder_id: parseInt(req.params.id),
                    delivery_person_id: livreur.id,
                    amount_to_collect: parseFloat(montantDette),
                    amount_collected: 0,
                    motif: type === 'perte_colis' ? 'perte_colis' : 'colis_casse',
                }
            });
        }

        // TODO: FCM -> notifier manager de l'incident

        res.json({
            message: 'Incident signale. Le manager a ete notifie.',
            type,
            dette_creee: ['perte_colis', 'colis_casse'].includes(type),
            instructions: motifMap[type] || 'Attendez les instructions du manager.',
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// POST /api/mobile/livreur/fcm-token
// body: { token }
// Enregistrer/MAJ le token Firebase FCM
async function updateFcmToken(req, res) {
    try {
        const { token } = req.body;
        if (!token) return res.status(400).json({ message: 'Token FCM requis.' });
        await prisma.users.update({
            where: { id: req.user.id },
            data: { fcm_token: token }
        });
        res.json({ message: 'Token FCM mis a jour.' });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

module.exports = {
    getProfil,
    getMesCourses,
    getHistorique,
    setDisponibilite,
    accepterCourse,
    refuserCourse,
    demarrerCourse,
    enregistrerPosition,
    signalerArrivee,
    cloturerCourse,
    signalerIncident,
    updateFcmToken,
};