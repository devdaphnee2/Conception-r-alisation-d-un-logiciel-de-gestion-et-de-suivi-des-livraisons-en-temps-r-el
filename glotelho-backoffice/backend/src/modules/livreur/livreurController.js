const prisma = require('../../utils/prismaClient');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const path = require('path');
const { getFirebaseDB } = require('../../config/firebaseAdmin');
const { fileUrl } = require('../../middlewares/upload');

// Efface la position Firebase d'un livreur, avec timeout de 3s pour ne
// jamais bloquer une requête si les identifiants Firebase Admin sont invalides.
async function clearFirebasePosition(livreurId) {
    try {
        var firebaseDb = getFirebaseDB();
        if (!firebaseDb) return;
        await Promise.race([
            firebaseDb.ref('positions/' + livreurId).remove(),
            new Promise(function(_, reject) {
                setTimeout(function() { reject(new Error('Firebase timeout')); }, 3000);
            })
        ]);
    } catch (e) {
        console.warn('[CLEAR POSITION] Echec (ignoré):', e.message);
    }
}

// ── HELPER — mapper statut BDD vers Flutter ──────────────────
function mapStatus(status) {
    if (status === 'Disponible' || status === 'En_livraison') return 'approved';
    if (status === 'Hors_service') return 'rejected';
    return 'pending';
}

// ── HELPER — construire profil pour Flutter ──────────────────
function buildProfile(livreur, user, vehicule, statusOverride) {
    var status = statusOverride || mapStatus(livreur.status);
    var joursRestants = null;
    if (livreur.date_activation && !livreur.caution_payee) {
        var diff = Math.floor((new Date() - new Date(livreur.date_activation)) / (1000 * 60 * 60 * 24));
        joursRestants = Math.max(0, 14 - diff);
    }
    return {
        id: String(livreur.id),
        _id: String(livreur.id),
        nom: user ? user.last_name : '',
        prenom: user ? user.first_name : '',
        dateNaissance: livreur.date_naissance ? new Date(livreur.date_naissance).toISOString() : new Date().toISOString(),
        telephone: user ? user.phone : '',
        email: user ? user.email : '',
        photoUrl: livreur.photo_profil_url || null,
        adresseResidence: livreur.adresse_residence || '',
        cniNumero: livreur.cni_numero || '',
        cniRectoUrl: livreur.cni_recto_url || null,
        cniVersoUrl: livreur.cni_verso_url || null,
        permisUrl: livreur.permis_url || null,
        vehicule: vehicule ? {
            type: vehicule.type || livreur.vehicule_type || '',
            marque: vehicule.brand || livreur.vehicule_marque || '',
            modele: livreur.vehicule_modele || '',
            immatriculation: vehicule.plate_number || livreur.vehicule_immatriculation || '',
            photoUrl: livreur.vehicule_photo_url || livreur.photo_vehicule || null,
            assuranceNumero: livreur.assurance_numero || '',
            assuranceExpiration: livreur.assurance_expiration ? new Date(livreur.assurance_expiration).toISOString() : null,
        } : {
            type: livreur.vehicule_type || '',
            marque: livreur.vehicule_marque || '',
            modele: livreur.vehicule_modele || '',
            immatriculation: livreur.vehicule_immatriculation || '',
            photoUrl: livreur.vehicule_photo_url || null,
            assuranceNumero: livreur.assurance_numero || '',
            assuranceExpiration: livreur.assurance_expiration ? new Date(livreur.assurance_expiration).toISOString() : null,
        },
        disponibilites: livreur.disponibilite_jours ? livreur.disponibilite_jours.split(',').map(function(j) {
            var h = (livreur.disponibilite_heures || '08:00-18:00').split('-');
            return { jour: j.trim(), heureDebut: h[0] || '08:00', heureFin: h[1] || '18:00' };
        }) : [],
        mobileMoneyNumero: livreur.mobile_money_numero || '',
        mobileMoneyTitulaire: livreur.mobile_money_nom || livreur.mobile_money_titulaire || '',
        status: status,
        soldeCommission: Number(livreur.solde_commission || 0),
        emprunt: Number(livreur.emprunt || 0),
        note: Number(livreur.note || 0),
        cautionPayee: livreur.caution_payee ? true : false,
        cautionMontant: Number(livreur.caution_montant || 50000),
        dateActivation: livreur.date_activation ? new Date(livreur.date_activation).toISOString() : null,
        joursRestantsAvantSuspension: joursRestants,
    };
}

// ── POST /register ────────────────────────────────────────────
async function register(req, res) {
    var uploadFields = require('../../middlewares/upload').uploadFields;
    uploadFields(req, res, async function(err) {
        if (err) return res.status(400).json({ message: err.message });
        try {
            var body = req.body;
            if (!body.telephone) return res.status(400).json({ message: 'Telephone requis.' });

            var existingPhone = await prisma.users.findFirst({ where: { phone: body.telephone } });
            if (existingPhone) return res.status(409).json({ message: 'Ce numero est deja utilise.' });

            if (body.email && body.email.trim()) {
                var existingEmail = await prisma.users.findUnique({ where: { email: body.email } });
                if (existingEmail) return res.status(409).json({ message: 'Cet email est deja utilise.' });
            }

            var hashed = await bcrypt.hash(body.password || 'glotelho2026', 10);
            var emailFinal = body.email && body.email.trim() ? body.email : body.telephone.replace(/\s/g, '') + '@glotelho.cm';

            var user = await prisma.users.create({
                data: {
                    first_name: body.prenom || '',
                    last_name: body.nom || '',
                    email: emailFinal,
                    password: hashed,
                    phone: body.telephone,
                    role: 'delivery_person',
                }
            });

            // Vehicule
            var vehicule = null;
            if (body.vehiculeImmatriculation) {
                vehicule = await prisma.vehicules.findFirst({ where: { plate_number: body.vehiculeImmatriculation } });
                if (!vehicule) {
                    vehicule = await prisma.vehicules.create({
                        data: { type: body.vehiculeType || 'moto', brand: body.vehiculeMarque || null, plate_number: body.vehiculeImmatriculation, status: 'Disponible' }
                    });
                }
            }

            var files = req.files || {};

            function getUrl(field) {
                return files[field] && files[field][0] ? fileUrl(req, files[field][0]) : null;
            }

            var dateNaissance = body.dateNaissance ? new Date(body.dateNaissance) : null;
            var assuranceExp = body.assuranceExpiration ? new Date(body.assuranceExpiration) : null;

            // Disponibilites
            var disponibiliteJours = '';
            var disponibiliteHeures = '';
            try {
                if (body.disponibilites) {
                    var dispos = typeof body.disponibilites === 'string' ? JSON.parse(body.disponibilites) : body.disponibilites;
                    if (Array.isArray(dispos)) {
                        disponibiliteJours = dispos.map(function(d) { return d.jour || d; }).filter(Boolean).join(',');
                        if (dispos[0] && dispos[0].heureDebut) disponibiliteHeures = dispos[0].heureDebut + '-' + (dispos[0].heureFin || '18:00');
                    }
                }
            } catch (e) {}

            var livreur = await prisma.delivery_persons.create({
                data: {
                    user_id: user.id,
                    vehicle_id: vehicule ? vehicule.id : null,
                    status: 'Indisponible',
                    available: 0,
                    date_naissance: dateNaissance,
                    adresse_residence: body.adresseResidence || null,
                    cni_numero: body.cniNumero || null,
                    cni_recto_url: getUrl('cniRecto'),
                    cni_verso_url: getUrl('cniVerso'),
                    permis_url: getUrl('permis'),
                    photo_profil_url: getUrl('photoProfil'),
                    vehicule_modele: body.vehiculeModele || null,
                    vehicule_type: body.vehiculeType || null,
                    vehicule_marque: body.vehiculeMarque || null,
                    vehicule_immatriculation: body.vehiculeImmatriculation || null,
                    vehicule_photo_url: getUrl('photoVehicule'),
                    assurance_numero: body.assuranceNumero || null,
                    assurance_expiration: assuranceExp,
                    mobile_money_numero: body.mobileMoneyNumero || null,
                    mobile_money_titulaire: body.mobileMoneyTitulaire || null,
                    disponibilites: disponibiliteJours || null,
                    caution_montant: 50000,
                    caution_payee: 0,
                    date_candidature: new Date(),
                }
            });

            var token = jwt.sign({ id: user.id, email: user.email, role: user.role, livreurId: livreur.id },
                process.env.JWT_SECRET || 'glotelho_secret', { expiresIn: '30d' }
            );

            console.log('[Enrolement] Nouveau livreur :', user.email);
            res.status(201).json({
                message: 'Inscription reussie. Dossier en cours de validation.',
                token: token,
                data: buildProfile(livreur, user, vehicule, 'pending'),
            });
        } catch (err) {
            console.error('[Enrolement] Erreur :', err.message);
            res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }
    });
}

// ── GET /me ───────────────────────────────────────────────────
async function getMe(req, res) {
    try {
        var livreurId = req.user.livreurId || req.livreur.id;
        var livreur;
        if (livreurId) {
            livreur = await prisma.delivery_persons.findUnique({ where: { id: livreurId }, include: { vehicules: true } });
        } else {
            livreur = await prisma.delivery_persons.findFirst({ where: { user_id: req.user.id }, include: { vehicules: true } });
        }
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });
        var user = await prisma.users.findUnique({ where: { id: req.user.id } });
        res.json({ data: buildProfile(livreur, user, livreur.vehicules, null) });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

// ── PUT /me ───────────────────────────────────────────────────
async function updateMe(req, res) {
    var uploadFields = require('../../middlewares/upload').uploadFields;
    uploadFields(req, res, async function(err) {
        if (err) return res.status(400).json({ message: err.message });
        try {
            var livreur = await prisma.delivery_persons.findFirst({ where: { user_id: req.user.id }, include: { vehicules: true } });
            if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

            var body = req.body;
            var files = req.files || {};

            function getUrl(field) { return files[field] && files[field][0] ? fileUrl(req, files[field][0]) : null; }

            if (body.nom || body.prenom || body.telephone || body.email) {
                await prisma.users.update({
                    where: { id: req.user.id },
                    data: {
                        last_name: body.nom || undefined,
                        first_name: body.prenom || undefined,
                        phone: body.telephone || undefined,
                        email: body.email || undefined,
                    }
                });
            }

            var updateData = {};
            if (body.adresseResidence) updateData.adresse_residence = body.adresseResidence;
            if (body.cniNumero) updateData.cni_numero = body.cniNumero;
            if (getUrl('cniRecto')) updateData.cni_recto_url = getUrl('cniRecto');
            if (getUrl('cniVerso')) updateData.cni_verso_url = getUrl('cniVerso');
            if (getUrl('permis')) updateData.permis_url = getUrl('permis');
            if (getUrl('photoProfil')) updateData.photo_profil_url = getUrl('photoProfil');
            if (getUrl('photoVehicule')) updateData.vehicule_photo_url = getUrl('photoVehicule');
            if (body.vehiculeModele) updateData.vehicule_modele = body.vehiculeModele;
            if (body.vehiculeType) updateData.vehicule_type = body.vehiculeType;
            if (body.vehiculeMarque) updateData.vehicule_marque = body.vehiculeMarque;
            if (body.vehiculeImmatriculation) updateData.vehicule_immatriculation = body.vehiculeImmatriculation;
            if (body.assuranceNumero) updateData.assurance_numero = body.assuranceNumero;
            if (body.assuranceExpiration) updateData.assurance_expiration = new Date(body.assuranceExpiration);
            if (body.mobileMoneyNumero) updateData.mobile_money_numero = body.mobileMoneyNumero;
            if (body.mobileMoneyTitulaire) {
                updateData.mobile_money_nom = body.mobileMoneyTitulaire;
                updateData.mobile_money_titulaire = body.mobileMoneyTitulaire;
            }

            var updated = await prisma.delivery_persons.update({ where: { id: livreur.id }, data: updateData, include: { vehicules: true } });
            var user = await prisma.users.findUnique({ where: { id: req.user.id } });
            res.json({ data: buildProfile(updated, user, updated.vehicules, null) });
        } catch (err) {
            res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }
    });
}

// ── DISPONIBILITE ─────────────────────────────────────────────
async function toggleDisponibilite(req, res) {
    try {
        var available = req.body.available;
        var livreur = await prisma.delivery_persons.findFirst({ where: { user_id: req.user.id } });
        if (!livreur) return res.status(404).json({ message: 'Livreur introuvable.' });
        var newStatus = available ? 'Disponible' : 'Indisponible';
        await prisma.delivery_persons.update({
            where: { id: livreur.id },
            data: { available: available ? 1 : 0, status: newStatus }
        });
        res.json({ message: 'Disponibilite mise a jour.', status: newStatus });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

// ── COURSES ───────────────────────────────────────────────────
async function getCourses(req, res) {
    try {
        console.log('[DEBUG getCourses] req.user =', JSON.stringify(req.user));
        var livreur = await prisma.delivery_persons.findFirst({ where: { user_id: req.user.id } });
        console.log('[DEBUG getCourses] livreur trouvé =', livreur ? livreur.id : 'AUCUN');
        if (!livreur) return res.status(404).json({ message: 'Livreur introuvable.' });
        var courses = await prisma.deliveryorders.findMany({
            where: { delivery_person_id: livreur.id, status: { in: ['Assign_', 'Valide_', 'En_cours'] } },
            include: { customers: { include: { users: true } }, delivery_items: true, confirmations: true },
            orderBy: { creation_date: 'desc' }
        });
        console.log('[DEBUG getCourses] nombre trouvé =', courses.length, 'pour livreur.id =', livreur.id);
        res.json(courses);
    } catch (err) {
        console.error('[DEBUG getCourses] ERREUR:', err.message);
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function getHistorique(req, res) {
    try {
        var livreur = await prisma.delivery_persons.findFirst({ where: { user_id: req.user.id } });
        if (!livreur) return res.status(404).json({ message: 'Livreur introuvable.' });
        var courses = await prisma.deliveryorders.findMany({
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
        var livreur = await prisma.delivery_persons.findFirst({ where: { user_id: req.user.id } });
        var course = await prisma.deliveryorders.findUnique({ where: { id: parseInt(req.params.id) } });
        console.log('[DEBUG accepter] course.id =', req.params.id, '| course trouvé =', course ? 'oui' : 'non', '| status =', course ? course.status : 'N/A');
        if (!course) return res.status(404).json({ message: 'Course introuvable.' });
        if (course.status !== 'Assign_') {
            console.log('[DEBUG accepter] REFUS — statut actuel =', course.status, '(attendu: Assign_)');
            return res.status(400).json({ message: 'Cette course ne peut plus être acceptée.' });
        }

        await clearFirebasePosition(livreur.id);

        await prisma.deliveryorders.update({ where: { id: course.id }, data: { status: 'Valide_', delivery_person_id: livreur.id } });
        console.log('[DEBUG accepter] SUCCES — course', course.id, 'passée à Valide_');
        res.json({ message: 'Course acceptee.' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function refuserCourse(req, res) {
    try {
        var course = await prisma.deliveryorders.findUnique({ where: { id: parseInt(req.params.id) } });
        if (!course) return res.status(404).json({ message: 'Course introuvable.' });
        await prisma.deliveryorders.update({ where: { id: course.id }, data: { status: 'En_attente', delivery_person_id: null } });
        res.json({ message: 'Course refusee.' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function demarrerCourse(req, res) {
    try {
        var livreur = await prisma.delivery_persons.findFirst({ where: { user_id: req.user.id }, include: { users: true } });
        var courseId = parseInt(req.params.id);
        var course = await prisma.deliveryorders.findUnique({ where: { id: courseId }, include: { confirmations: true } });
        if (!course) return res.status(404).json({ message: 'Course introuvable.' });

        // ── Bloquer si le client n'a pas encore payé sa commande ──────────
        if (course.payment_status !== 'paid') {
            return res.status(400).json({
                message: 'Le client n\'a pas encore payé sa commande. Impossible de démarrer la livraison.'
            });
        }

        await prisma.deliveryorders.update({ where: { id: courseId }, data: { status: 'En_cours' } });
        await prisma.delivery_persons.update({ where: { id: livreur.id }, data: { status: 'En_livraison', available: 0 } });

        // Sécurité supplémentaire — effacer toute position résiduelle avant le départ.
        // Le client ne verra rien tant que le livreur n'aura pas cliqué
        // "Partager ma position" pour cette nouvelle course.
        try {
            await clearFirebasePosition(livreur.id);
        } catch (e) { console.warn('[CLEAR POSITION] Echec:', e.message); }

        var otp = course.confirmations && course.confirmations.length > 0 ? course.confirmations[0].otp_code || '' : '';
        var frontendUrl = process.env.FRONTEND_URL || 'http://localhost:5173';
        var trackingUrl = frontendUrl + '/suivi/' + courseId;
        var clientNom = course.client_nom || 'Client';
        var clientWa = course.client_whatsapp || course.client_telephone || '';
        var livreurNom = livreur.users ? livreur.users.first_name + ' ' + livreur.users.last_name : 'Votre livreur';

        var message = 'Bonjour ' + clientNom + ' !\n\n' +
            livreurNom + ' vient de récupérer votre colis et est en route.\n\n' +
            'Suivez la livraison en temps reel :\n' + trackingUrl + '\n\n' +
            'Montant a remettre au livreur (frais de livraison) :\n*' + Number(course.frais_livraison || 0).toLocaleString('fr-FR') + ' FCFA*\n\n' +
            'Code a donner au livreur a la reception :\n*' + otp + '*\n\nNe partagez pas ce code.';

        var waTel = clientWa.replace(/\s/g, '').replace(/\+/g, '');
        if (waTel && !waTel.startsWith('237')) waTel = '237' + waTel;
        var waLink = waTel ? 'https://wa.me/' + waTel + '?text=' + encodeURIComponent(message) : null;

        res.json({ message: 'Course demarree.', whatsapp_link: waLink, tracking_url: trackingUrl, otp: otp });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function updatePosition(req, res) {
    try {
        var latitude = req.body.latitude;
        var longitude = req.body.longitude;
        var speed = req.body.speed;
        if (!latitude || !longitude) return res.status(400).json({ message: 'Latitude et longitude requises.' });

        var livreur = await prisma.delivery_persons.findFirst({ where: { user_id: req.user.id }, include: { users: true, vehicules: true } });
        if (!livreur) return res.status(404).json({ message: 'Livreur introuvable.' });

        var courseId = parseInt(req.params.id);
        var firebaseDb = getFirebaseDB();
        if (firebaseDb) {
            await firebaseDb.ref('positions/' + livreur.id).set({
                latitude: parseFloat(latitude),
                longitude: parseFloat(longitude),
                speed: speed ? parseFloat(speed) : 0,
                livraison_id: courseId,
                livreur_nom: livreur.users ? livreur.users.first_name + ' ' + livreur.users.last_name : 'Livreur',
                vehicule: livreur.vehicules ? livreur.vehicules.type : 'moto',
                timestamp: Date.now(),
                status: 'En_livraison',
            });
        }
        res.json({ message: 'Position mise a jour.', latitude: latitude, longitude: longitude });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function cloturerCourse(req, res) {
    try {
        var courseId = parseInt(req.params.id);
        var livreur = await prisma.delivery_persons.findFirst({ where: { user_id: req.user.id } });
        var otpCode = req.body.otp_code;

        // Verifier OTP
        var confirmation = await prisma.confirmations.findFirst({ where: { deliveryorder_id: courseId } });
        if (confirmation && otpCode && confirmation.otp_code !== String(otpCode)) {
            return res.status(400).json({ message: 'Code OTP incorrect.' });
        }

        await prisma.deliveryorders.update({ where: { id: courseId }, data: { status: 'Livr_', tracking_blocked: true } });
        await prisma.delivery_persons.update({ where: { id: livreur.id }, data: { status: 'Disponible', available: 1 } });

        if (req.body.rapport) {
            await prisma.rapports.create({
                data: { deliveryorder_id: courseId, delivery_person_id: livreur.id, observations: req.body.rapport }
            });
        }

        await clearFirebasePosition(livreur.id);

        res.json({ message: 'Course cloturee avec succes.' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function signalerIncident(req, res) {
    try {
        var type_incident = req.body.type_incident;
        var description = req.body.description;
        var courseId = parseInt(req.params.id);
        var livreur = await prisma.delivery_persons.findFirst({ where: { user_id: req.user.id } });

        await prisma.deliveryorders.update({
            where: { id: courseId },
            data: { status: 'Suspendu', suspension_reason: type_incident + ' : ' + (description || '') }
        });

        var course = await prisma.deliveryorders.findUnique({ where: { id: courseId } });
        await prisma.litiges.create({
            data: {
                deliveryorder_id: courseId,
                delivery_person_id: livreur.id,
                statut: 'Ouvert',
                description: type_incident + ' : ' + (description || ''),
                motif: type_incident,
            }
        });

        res.json({ message: 'Incident signale. Litige ouvert.' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

module.exports = {
    register,
    getMe,
    updateMe,
    toggleDisponibilite,
    getCourses,
    getHistorique,
    accepterCourse,
    refuserCourse,
    demarrerCourse,
    updatePosition,
    cloturerCourse,
    signalerIncident,
    buildProfile,
    mapStatus
};