// ============================================================
// CONTROLLER API — Application Mobile Livreur
// Routes : /api/mobile/livreur/*
// Auth : JWT avec role delivery_person
// Firebase : https://glotelho-livraison-default-rtdb.europe-west1.firebasedatabase.app
// ============================================================

const prisma = require('../utils/prismaClient');

// Initialisation Firebase Admin (optionnel si pas encore configure)
// Decommenter apres avoir place firebase-admin.json dans src/config/
let firebaseDb = null;
try {
    const admin = require('firebase-admin');
    if (!admin.apps.length) {
        const serviceAccount = require('../config/firebase-admin.json');
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            databaseURL: 'https://glotelho-livraison-default-rtdb.europe-west1.firebasedatabase.app',
        });
    }
    firebaseDb = admin.database();
    console.log('[Firebase] Connexion Realtime Database OK');
} catch (e) {
    console.warn('[Firebase] Admin SDK non configure — positions GPS en BDD uniquement :', e.message);
}

// Helper — ecrire position dans Firebase
async function writeFirebasePosition(livreurId, data) {
    if (!firebaseDb) return false;
    try {
        await firebaseDb.ref('positions/' + livreurId).set(data);
        return true;
    } catch (e) {
        console.error('[Firebase] Erreur ecriture position :', e.message);
        return false;
    }
}

// Helper — effacer position Firebase (fin de course)
async function clearFirebasePosition(livreurId) {
    if (!firebaseDb) return;
    try {
        await firebaseDb.ref('positions/' + livreurId).remove();
    } catch (e) {
        console.error('[Firebase] Erreur suppression position :', e.message);
    }
}

// Helper — envoyer notification FCM
async function sendFCM(fcmToken, titre, corps) {
    if (!firebaseDb || !fcmToken) return;
    try {
        const admin = require('firebase-admin');
        await admin.messaging().send({
            token: fcmToken,
            notification: { title: titre, body: corps },
        });
    } catch (e) {
        console.warn('[FCM] Notification non envoyee :', e.message);
    }
}

// ──────────────────────────────────────────────────────────
// GET /api/mobile/livreur/profil
// Profil complet du livreur connecte
// ──────────────────────────────────────────────────────────
async function getProfil(req, res) {
    try {
        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id },
            include: { users: true, vehicules: true }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

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
            firebase_database_url: 'https://glotelho-livraison-default-rtdb.europe-west1.firebasedatabase.app',
            firebase_path: 'positions/' + livreur.id,
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// ──────────────────────────────────────────────────────────
// GET /api/mobile/livreur/courses
// Courses assignees au livreur connecte
// ──────────────────────────────────────────────────────────
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

// ──────────────────────────────────────────────────────────
// GET /api/mobile/livreur/historique
// ──────────────────────────────────────────────────────────
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

// ──────────────────────────────────────────────────────────
// POST /api/mobile/livreur/disponibilite
// body: { available: true/false }
// ──────────────────────────────────────────────────────────
async function setDisponibilite(req, res) {
    try {
        const { available } = req.body;

        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

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

        res.json({
            message: available ? 'Vous etes maintenant disponible.' : 'Vous etes maintenant indisponible.',
            livreur: updated
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// ──────────────────────────────────────────────────────────
// POST /api/mobile/livreur/courses/:id/accepter
// ──────────────────────────────────────────────────────────
async function accepterCourse(req, res) {
    try {
        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id },
            include: { users: true }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

        const course = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) },
            include: { managers: { include: { users: true } } }
        });
        if (!course) return res.status(404).json({ message: 'Course introuvable.' });
        if (course.delivery_person_id !== livreur.id) {
            return res.status(403).json({ message: 'Cette course ne vous est pas assignee.' });
        }
        if (course.status !== 'Assign_') {
            return res.status(400).json({ message: 'Cette course ne peut pas etre acceptee.' });
        }

        await prisma.delivery_persons.update({
            where: { id: livreur.id },
            data: { status: 'En_livraison', available: false }
        });

        // FCM -> notifier le manager
        if (course.managers && course.managers.users && course.managers.users.fcm_token) {
            await sendFCM(
                course.managers.users.fcm_token,
                'Course acceptee',
                livreur.users.first_name + ' a accepte la course #' + course.id
            );
        }

        res.json({ message: 'Course acceptee. Bonne livraison !', course });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// ──────────────────────────────────────────────────────────
// POST /api/mobile/livreur/courses/:id/refuser
// body: { motif }
// ──────────────────────────────────────────────────────────
async function refuserCourse(req, res) {
    try {
        const { motif } = req.body;

        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id },
            include: { users: true }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

        const course = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) },
            include: { managers: { include: { users: true } } }
        });
        if (!course) return res.status(404).json({ message: 'Course introuvable.' });
        if (course.delivery_person_id !== livreur.id) {
            return res.status(403).json({ message: 'Cette course ne vous est pas assignee.' });
        }

        const updated = await prisma.deliveryorders.update({
            where: { id: parseInt(req.params.id) },
            data: {
                status: 'En_attente',
                delivery_person_id: null,
            }
        });

        await prisma.delivery_persons.update({
            where: { id: livreur.id },
            data: { status: 'Disponible', available: true }
        });

        // FCM -> notifier le manager du refus
        if (course.managers && course.managers.users && course.managers.users.fcm_token) {
            await sendFCM(
                course.managers.users.fcm_token,
                'Course refusee',
                livreur.users.first_name + ' a refuse la course #' + course.id + (motif ? ' : ' + motif : '')
            );
        }

        res.json({ message: 'Course refusee. Le manager a ete notifie.', course: updated });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// ──────────────────────────────────────────────────────────
// POST /api/mobile/livreur/courses/:id/demarrer
// ──────────────────────────────────────────────────────────
async function demarrerCourse(req, res) {
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

        // FCM -> notifier le client que le livreur est en route
        if (course.customers && course.customers.users && course.customers.users.fcm_token) {
            await sendFCM(
                course.customers.users.fcm_token,
                'Votre livreur est en route',
                livreur.users.first_name + ' est en chemin vers votre adresse.'
            );
        }

        res.json({
            message: 'Course demarree. Activez le partage de position GPS.',
            course: updated,
            firebase_database_url: 'https://glotelho-livraison-default-rtdb.europe-west1.firebasedatabase.app',
            firebase_path: 'positions/' + livreur.id,
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// ──────────────────────────────────────────────────────────
// POST /api/mobile/livreur/courses/:id/position
// body: { latitude, longitude, vitesse }
// Appele toutes les 5 secondes par l'app mobile
// ──────────────────────────────────────────────────────────
async function enregistrerPosition(req, res) {
    try {
        const { latitude, longitude, vitesse } = req.body;

        if (!latitude || !longitude) {
            return res.status(400).json({ message: 'Latitude et longitude requises.' });
        }

        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id },
            include: { users: true }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

        const course = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) }
        });
        if (!course || course.tracking_blocked) {
            return res.status(400).json({ message: 'Tracking bloque ou course introuvable.' });
        }

        // Ecriture Firebase Realtime Database — lu en temps reel par le front
        const firebaseData = {
            lat: parseFloat(latitude),
            lng: parseFloat(longitude),
            vitesse: vitesse ? parseFloat(vitesse) : 0,
            timestamp: Date.now(),
            nom: livreur.users.first_name,
            vehicule: livreur.vehicules ? livreur.vehicules.type : 'moto',
            course_id: course.id,
        };

        const firebaseOk = await writeFirebasePosition(livreur.id, firebaseData);

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

        res.json({
            message: 'Position enregistree.',
            firebase: firebaseOk ? 'OK' : 'Non connecte — BDD uniquement',
            firebase_path: 'positions/' + livreur.id,
            position: { latitude, longitude, vitesse, timestamp: new Date() }
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// ──────────────────────────────────────────────────────────
// POST /api/mobile/livreur/courses/:id/arrivee
// Signaler arrivee a destination
// ──────────────────────────────────────────────────────────
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

        // Generer OTP 6 chiffres
        const otpCode = Math.floor(100000 + Math.random() * 900000).toString();

        // Stocker OTP en base pour validation
        await prisma.confirmations.create({
            data: {
                deliveryorder_id: parseInt(req.params.id),
                type: 'otp',
                value: otpCode,
                confirmed_at: null,
            }
        });

        // FCM -> notifier le client avec le code OTP
        if (course.customers && course.customers.users && course.customers.users.fcm_token) {
            await sendFCM(
                course.customers.users.fcm_token,
                'Votre livreur est arrive !',
                livreur.users.first_name + ' est arrive. Code de confirmation : ' + otpCode
            );
        }

        res.json({
            message: 'Arrivee signalee. Code OTP envoye au client.',
            otp_code: otpCode,
            client_nom: course.customers ? course.customers.users.first_name : null,
            client_telephone: course.customers ? course.customers.users.phone : null,
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// ──────────────────────────────────────────────────────────
// POST /api/mobile/livreur/courses/:id/cloturer
// body: { otp_code, montant_collecte, observations }
// ──────────────────────────────────────────────────────────
async function cloturerCourse(req, res) {
    try {
        const { otp_code, montant_collecte, observations } = req.body;

        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id },
            include: { users: true }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

        const course = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) },
            include: {
                customers: { include: { users: true } },
                managers: { include: { users: true } }
            }
        });
        if (!course) return res.status(404).json({ message: 'Course introuvable.' });
        if (course.delivery_person_id !== livreur.id) {
            return res.status(403).json({ message: 'Cette course ne vous est pas assignee.' });
        }
        if (course.status !== 'En_cours') {
            return res.status(400).json({ message: 'La course doit etre En_cours pour etre cloturee.' });
        }

        // Valider OTP si fourni
        if (otp_code) {
            const confirmation = await prisma.confirmations.findFirst({
                where: {
                    deliveryorder_id: parseInt(req.params.id),
                    type: 'otp',
                    value: otp_code,
                    confirmed_at: null,
                }
            });
            if (!confirmation) {
                return res.status(400).json({ message: 'Code OTP invalide ou deja utilise.' });
            }
            // Marquer OTP comme utilise
            await prisma.confirmations.update({
                where: { id: confirmation.id },
                data: { confirmed_at: new Date() }
            });
        }

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

        // Rapport de livraison
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

        // Effacer position Firebase — tracking stoppe
        await clearFirebasePosition(livreur.id);

        // FCM -> notifier manager
        if (course.managers && course.managers.users && course.managers.users.fcm_token) {
            await sendFCM(
                course.managers.users.fcm_token,
                'Livraison effectuee',
                'La course #' + course.id + ' a ete livree par ' + livreur.users.first_name
            );
        }

        // FCM -> notifier client
        if (course.customers && course.customers.users && course.customers.users.fcm_token) {
            await sendFCM(
                course.customers.users.fcm_token,
                'Livraison confirmee',
                'Votre commande a ete livree avec succes. Merci de votre confiance !'
            );
        }

        res.json({
            message: 'Livraison cloturee avec succes. Vous etes maintenant disponible.',
            course: updated,
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// ──────────────────────────────────────────────────────────
// POST /api/mobile/livreur/courses/:id/incident
// body: { type: 'panne'|'perte_colis'|'colis_casse', description }
// ──────────────────────────────────────────────────────────
async function signalerIncident(req, res) {
    try {
        const { type, description } = req.body;
        if (!type) return res.status(400).json({ message: 'Type d\'incident requis.' });

        const livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id },
            include: { users: true }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

        const course = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) },
            include: {
                managers: { include: { users: true } },
                orders: true
            }
        });
        if (!course) return res.status(404).json({ message: 'Course introuvable.' });

        const motifMap = {
            'panne': 'Panne vehicule — L2 recupere au point GPS arret',
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
            const montantDette = course.amount_to_collect || 0;
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

        // FCM -> notifier le manager de l'incident
        if (course.managers && course.managers.users && course.managers.users.fcm_token) {
            await sendFCM(
                course.managers.users.fcm_token,
                'Incident signale — Course #' + course.id,
                livreur.users.first_name + ' : ' + (motifMap[type] || description)
            );
        }

        res.json({
            message: 'Incident signale. Le manager a ete notifie.',
            type,
            motif: motifMap[type] || description,
            dette_creee: ['perte_colis', 'colis_casse'].includes(type),
            instructions: motifMap[type] || 'Attendez les instructions du manager.',
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// ──────────────────────────────────────────────────────────
// POST /api/mobile/livreur/fcm-token
// body: { token }
// ──────────────────────────────────────────────────────────
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