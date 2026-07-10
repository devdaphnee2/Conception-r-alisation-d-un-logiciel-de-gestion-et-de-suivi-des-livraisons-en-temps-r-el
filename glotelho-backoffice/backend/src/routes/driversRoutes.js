const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const prisma = require('../utils/prismaClient');

// ── MULTER ───────────────────────────────────────────────────
const uploadDir = path.join(__dirname, '../../uploads/livreurs');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
    destination: function(req, file, cb) { cb(null, uploadDir); },
    filename: function(req, file, cb) {
        cb(null, file.fieldname + '_' + Date.now() + path.extname(file.originalname));
    }
});

const upload = multer({
    storage: storage,
    limits: { fileSize: 10 * 1024 * 1024 },
    fileFilter: function(req, file, cb) {
        var allowed = ['.jpg', '.jpeg', '.png', '.pdf'];
        if (allowed.includes(path.extname(file.originalname).toLowerCase())) cb(null, true);
        else cb(new Error('Format non autorise.'));
    }
});

var uploadFields = upload.fields([
    { name: 'photoProfil', maxCount: 1 },
    { name: 'cniRecto', maxCount: 1 },
    { name: 'cniVerso', maxCount: 1 },
    { name: 'permis', maxCount: 1 },
    { name: 'photoVehicule', maxCount: 1 },
]);

function fileUrl(req, filename) {
    if (!filename) return null;
    var base = process.env.BACKEND_URL || ('http://' + (req.hostname || 'localhost') + ':' + (process.env.PORT || 5000));
    return base + '/uploads/livreurs/' + path.basename(filename);
}

function mapStatus(status) {
    if (status === 'Disponible' || status === 'En_livraison') return 'approved';
    if (status === 'Hors_service') return 'rejected';
    return 'pending';
}

function buildProfile(livreur, user, vehicule, statusOverride) {
    var status = statusOverride || mapStatus(livreur.status);

    var joursRestants = null;
    if (livreur.date_activation && !livreur.caution_payee) {
        var diff = Math.floor((new Date() - new Date(livreur.date_activation)) / (1000 * 60 * 60 * 24));
        joursRestants = Math.max(0, 14 - diff);
    }

    return {
        id: String(livreur.id),
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
            assuranceNumero: livreur.assurance_numero || '',
            assuranceExpiration: livreur.assurance_expiration ? new Date(livreur.assurance_expiration).toISOString() : new Date().toISOString(),
        } : {
            type: livreur.vehicule_type || '',
            marque: livreur.vehicule_marque || '',
            modele: livreur.vehicule_modele || '',
            immatriculation: livreur.vehicule_immatriculation || '',
            assuranceNumero: livreur.assurance_numero || '',
            assuranceExpiration: livreur.assurance_expiration ? new Date(livreur.assurance_expiration).toISOString() : new Date().toISOString(),
        },
        disponibilites: livreur.disponibilites ? livreur.disponibilites : '',
        mobileMoneyNumero: livreur.mobile_money_numero || '',
        mobileMoneyTitulaire: livreur.mobile_money_titulaire || '',
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

// ── POST /api/v1/drivers/register ───────────────────────────
router.post('/register', function(req, res) {
    uploadFields(req, res, async function(err) {
        if (err) return res.status(400).json({ message: err.message });

        try {
            var body = req.body;

            if (!body.nom || !body.prenom || !body.telephone) {
                return res.status(400).json({ message: 'Nom, prénom et téléphone requis.' });
            }

            if (body.email && body.email.trim() !== '') {
                var existing = await prisma.users.findUnique({ where: { email: body.email } });
                if (existing) return res.status(400).json({ message: 'Cet email est déjà utilisé.' });
            }

            var existingPhone = await prisma.users.findFirst({ where: { phone: body.telephone } });
            if (existingPhone) return res.status(400).json({ message: 'Ce numéro est déjà utilisé.' });

            var hashedPassword = await bcrypt.hash(body.password || 'glotelho2026', 10);
            var emailFinal = body.email && body.email.trim() !== '' ?
                body.email : body.telephone.replace(/\s/g, '') + '@glotelho.cm';

            var user = await prisma.users.create({
                data: {
                    first_name: body.prenom,
                    last_name: body.nom,
                    email: emailFinal,
                    password: hashedPassword,
                    phone: body.telephone,
                    role: 'delivery_person',
                }
            });

            var vehicule = null;
            if (body.vehiculeImmatriculation) {
                vehicule = await prisma.vehicules.findFirst({ where: { plate_number: body.vehiculeImmatriculation } });
                if (!vehicule) {
                    vehicule = await prisma.vehicules.create({
                        data: {
                            type: body.vehiculeType || 'moto',
                            brand: body.vehiculeMarque || null,
                            plate_number: body.vehiculeImmatriculation,
                            status: 'Disponible',
                        }
                    });
                }
            }

            // Gestion propre des dispos
            // Gestion propre des dispos
            var disponibilitesFinales = null;
            try {
                if (body.disponibilites) {
                    var dispos = typeof body.disponibilites === 'string' ? JSON.parse(body.disponibilites) : body.disponibilites;
                    if (Array.isArray(dispos)) {
                        var joursStr = dispos.map(function(d) { return d.jour || d; }).filter(Boolean).join(',');


                        var heuresStr = (dispos[0] && dispos[0].heureDebut) ? `${dispos[0].heureDebut}-${dispos[0].heureFin || '18:00'}` : '';

                        disponibilitesFinales = (joursStr || heuresStr) ? `${joursStr} ${heuresStr}`.trim() : null;
                    }
                }
            } catch (e) {}

            var files = req.files || {};

            function getUrl(field) { return files[field] && files[field][0] ? fileUrl(req, files[field][0].filename) : null; }

            var dateNaissance = null;
            if (body.dateNaissance) { try { dateNaissance = new Date(body.dateNaissance); } catch (e) {} }

            var assuranceExpiration = null;
            if (body.assuranceExpiration) { try { assuranceExpiration = new Date(body.assuranceExpiration); } catch (e) {} }

            // 👇 CREATION DU PROFIL (Nettoyé avec les bons champs)
            var livreur = await prisma.delivery_persons.create({
                data: {
                    user_id: user.id,
                    vehicle_id: vehicule ? vehicule.id : null, // Corrigé ici
                    status: 'Indisponible',
                    available: 0,

                    date_naissance: dateNaissance,
                    adresse_residence: body.adresseResidence || null,
                    cni_numero: body.cniNumero || null,
                    cni_recto_url: getUrl('cniRecto'),
                    cni_verso_url: getUrl('cniVerso'),
                    permis_url: getUrl('permis'),
                    photo_profil_url: getUrl('photoProfil'),

                    vehicule_type: body.vehiculeType || null,
                    vehicule_marque: body.vehiculeMarque || null,
                    vehicule_modele: body.vehiculeModele || null,
                    vehicule_immatriculation: body.vehiculeImmatriculation || null,
                    vehicule_photo_url: getUrl('photoVehicule'),

                    assurance_numero: body.assuranceNumero || null,
                    assurance_expiration: assuranceExpiration,

                    mobile_money_numero: body.mobileMoneyNumero || null,
                    mobile_money_titulaire: body.mobileMoneyTitulaire || null,
                    disponibilites: disponibilitesFinales,

                    caution_montant: 50000,
                    caution_payee: 0,
                    date_candidature: new Date(),
                }
            });

            var token = jwt.sign({ id: user.id, email: user.email, role: user.role },
                process.env.JWT_SECRET || 'glotelho_secret', { expiresIn: '30d' }
            );

            res.status(201).json({
                message: 'Inscription réussie. Votre dossier est en cours de validation.',
                token: token,
                data: buildProfile(livreur, user, vehicule, 'pending'),
            });

        } catch (error) {
            console.error('[Enrolement] Erreur :', error.message);
            res.status(500).json({ message: 'Erreur serveur', error: error.message });
        }
    });
});

// ── POST /api/v1/drivers/login ───────────────────────────────
// 👇 AJOUT DE LA ROUTE LOGIN QUI MANQUAIT POUR L'APP MOBILE !
router.post('/login', async function(req, res) {
    try {
        var telephone = req.body.telephone || req.body.email; // Supporte le mail ou le tel
        var password = req.body.password;

        if (!telephone || !password) {
            return res.status(400).json({ message: 'Identifiant et mot de passe requis.' });
        }

        // 1. Chercher l'utilisateur (on s'en fout du role, on veut juste voir si le compte existe)
        var user = await prisma.users.findFirst({
            where: {
                OR: [{ phone: telephone }, { email: telephone }]
            }
        });

        if (!user) {
            return res.status(401).json({ message: 'Identifiants incorrects.' });
        }

        // 2. Vérifier le mot de passe
        var valid = await bcrypt.compare(password, user.password);
        if (!valid) {
            return res.status(401).json({ message: 'Identifiants incorrects.' });
        }

        // 3. Vérifier que c'est bien un livreur
        var livreur = await prisma.delivery_persons.findFirst({
            where: { user_id: user.id }
        });

        if (!livreur) {
            return res.status(401).json({ message: 'Aucun profil livreur associé à ce compte.' });
        }

        // 4. Générer le token
        var token = jwt.sign({ id: user.id, email: user.email, role: user.role },
            process.env.JWT_SECRET || 'glotelho_secret', { expiresIn: '30d' }
        );

        res.status(200).json({ token: token });

    } catch (error) {
        console.error('[/login] Erreur :', error.message);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

// ── GET /api/v1/drivers/me ───────────────────────────────────
router.get('/me', async function(req, res) {
    try {
        // 1. Récupération du token depuis l'en-tête (Header)
        var authHeader = req.headers.authorization || req.headers.Authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ message: 'Non authentifié' });
        }

        var token = authHeader.split(' ')[1];
        var decoded;

        try {
            // 2. Décodage du token
            decoded = jwt.verify(token, process.env.JWT_SECRET || 'glotelho_secret');
        } catch (err) {
            return res.status(401).json({ message: 'Token invalide ou expiré. Veuillez vous reconnecter.' });
        }

        // 3. Tolérance pour les vieux tokens (qui utilisaient livreurId au lieu de id)
        var userId = decoded.id;
        if (!userId && decoded.livreurId) {
            // S'il a un vieux token, on retrouve son userId à partir de son livreurId
            var oldLivreur = await prisma.delivery_persons.findUnique({ where: { id: decoded.livreurId } });
            if (oldLivreur) userId = oldLivreur.user_id;
        }

        if (!userId) {
            return res.status(400).json({ message: 'Impossible d\'identifier l\'utilisateur.' });
        }

        // 4. Recherche dans la base de données avec le VRAI userId
        var livreur = await prisma.delivery_persons.findFirst({
            where: { user_id: userId },
            include: { vehicules: true }
        });

        if (!livreur) return res.status(404).json({ message: 'Profil livreur introuvable.' });

        var user = await prisma.users.findUnique({ where: { id: userId } });

        var status = mapStatus(livreur.status);

        // 5. Renvoi des données formatées
        res.status(200).json({
            data: buildProfile(livreur, user, livreur.vehicules, status)
        });

    } catch (error) {
        console.error('[/me] Erreur :', error.message);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

module.exports = router;