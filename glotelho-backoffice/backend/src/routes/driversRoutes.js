// backend/src/routes/driversRoutes.js
// Endpoints pour l'app mobile livreur — enrolement + profil
const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const prisma = require('../utils/prismaClient');

// ── CONFIGURATION MULTER ─────────────────────────────────────
const uploadDir = path.join(__dirname, '../../uploads/livreurs');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
    destination: function(req, file, cb) {
        cb(null, uploadDir);
    },
    filename: function(req, file, cb) {
        var ext = path.extname(file.originalname);
        var name = file.fieldname + '_' + Date.now() + ext;
        cb(null, name);
    }
});

const upload = multer({
    storage: storage,
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max
    fileFilter: function(req, file, cb) {
        var allowed = ['.jpg', '.jpeg', '.png', '.pdf'];
        var ext = path.extname(file.originalname).toLowerCase();
        if (allowed.includes(ext)) cb(null, true);
        else cb(new Error('Format non autorise. Utilisez JPG, PNG ou PDF.'));
    }
});

var uploadFields = upload.fields([
    { name: 'photoProfil', maxCount: 1 },
    { name: 'cniRecto', maxCount: 1 },
    { name: 'cniVerso', maxCount: 1 },
    { name: 'permis', maxCount: 1 },
    { name: 'photoVehicule', maxCount: 1 },
]);

// URL de base pour acceder aux fichiers
function fileUrl(req, filename) {
    if (!filename) return null;
    var base = process.env.BACKEND_URL || ('http://' + req.hostname + ':' + (process.env.PORT || 5000));
    return base + '/uploads/livreurs/' + path.basename(filename);
}

// ── POST /api/v1/drivers/register ───────────────────────────
// Inscription livreur avec toutes les infos + photos
router.post('/register', function(req, res) {
    uploadFields(req, res, async function(err) {
        if (err) {
            return res.status(400).json({ message: err.message });
        }

        try {
            var body = req.body;

            // Champs obligatoires
            if (!body.nom || !body.prenom || !body.email || !body.password || !body.telephone) {
                return res.status(400).json({ message: 'Nom, prénom, email, mot de passe et téléphone sont requis.' });
            }

            // Verifier si email deja utilise (seulement si email fourni)
            if (body.email && body.email.trim() !== '') {
                var existing = await prisma.users.findUnique({ where: { email: body.email } });
                if (existing) {
                    return res.status(400).json({ message: 'Cet email est déjà utilisé.' });
                }
            }

            // Hash mot de passe
            var hashedPassword = await bcrypt.hash(body.password, 10);

            // Creer le user
            var user = await prisma.users.create({
                data: {
                    first_name: body.prenom,
                    last_name: body.nom,
                    email: body.email,
                    password: hashedPassword,
                    phone: body.telephone,
                    role: 'delivery_person',
                }
            });

            // Creer ou trouver le vehicule
            var vehicule = null;
            if (body.vehiculeImmatriculation) {
                vehicule = await prisma.vehicules.findFirst({
                    where: { plate_number: body.vehiculeImmatriculation }
                });
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

            // Disponibilites
            var disponibiliteJours = '';
            var disponibiliteHeures = '';
            try {
                if (body.disponibilites) {
                    var dispos = typeof body.disponibilites === 'string' ?
                        JSON.parse(body.disponibilites) :
                        body.disponibilites;
                    if (Array.isArray(dispos)) {
                        var jours = dispos.map(function(d) { return d.jour || d.day || d; }).filter(Boolean);
                        disponibiliteJours = jours.join(',');
                        var heureDebut = dispos[0] && dispos[0].heureDebut ? dispos[0].heureDebut : '';
                        var heureFin = dispos[0] && dispos[0].heureFin ? dispos[0].heureFin : '';
                        if (heureDebut && heureFin) disponibiliteHeures = heureDebut + '-' + heureFin;
                    }
                }
            } catch (e) { /* ignore */ }

            // Paths des fichiers uploades
            var files = req.files || {};
            var photoProfilPath = files.photoProfil && files.photoProfil[0] ? fileUrl(req, files.photoProfil[0].filename) : null;
            var cniRectoPath = files.cniRecto && files.cniRecto[0] ? fileUrl(req, files.cniRecto[0].filename) : null;
            var cniVersoPath = files.cniVerso && files.cniVerso[0] ? fileUrl(req, files.cniVerso[0].filename) : null;
            var permisPath = files.permis && files.permis[0] ? fileUrl(req, files.permis[0].filename) : null;
            var photoVehiculePath = files.photoVehicule && files.photoVehicule[0] ? fileUrl(req, files.photoVehicule[0].filename) : null;

            // Date de naissance
            var dateNaissance = null;
            if (body.dateNaissance) {
                try { dateNaissance = new Date(body.dateNaissance); } catch (e) {}
            }

            // Assurance expiration
            var assuranceExpiration = null;
            if (body.assuranceExpiration) {
                try { assuranceExpiration = new Date(body.assuranceExpiration); } catch (e) {}
            }

            // Creer le profil delivery_person
            var livreur = await prisma.delivery_persons.create({
                data: {
                    user_id: user.id,
                    vehicle_id: vehicule ? vehicule.id : null,
                    status: 'Indisponible', // En attente de validation
                    available: 0,
                    // Infos personnelles
                    date_naissance: dateNaissance,
                    adresse_domicile: body.adresseResidence || null,
                    // CNI
                    cni_numero: body.cniNumero || null,
                    cni_photo_avant: cniRectoPath,
                    cni_photo_arriere: cniVersoPath,
                    // Permis
                    permis_photo: permisPath,
                    permis_categorie: body.permisCategorie || null,
                    // Photo profil
                    photo_profil: photoProfilPath,
                    // Vehicule
                    vehicule_modele: body.vehiculeModele || null,
                    photo_vehicule: photoVehiculePath,
                    // Assurance
                    assurance_numero: body.assuranceNumero || null,
                    assurance_expiration: assuranceExpiration,
                    // Mobile Money
                    mobile_money_numero: body.mobileMoneyNumero || null,
                    mobile_money_nom: body.mobileMoneyTitulaire || null,
                    // Disponibilite
                    disponibilite_jours: disponibiliteJours || null,
                    disponibilite_heures: disponibiliteHeures || null,
                    // Caution
                    caution_montant: 50000,
                    caution_payee: 0,
                    date_candidature: new Date(),
                }
            });

            // Generer token JWT
            var token = jwt.sign({ id: user.id, email: user.email, role: user.role },
                process.env.JWT_SECRET || 'glotelho_secret', { expiresIn: '8h' }
            );

            console.log('[Enrolement] Nouveau livreur inscrit :', user.email);

            res.status(201).json({
                message: 'Inscription réussie. Votre dossier est en cours de validation.',
                token: token,
                data: {
                    id: livreur.id,
                    user_id: user.id,
                    email: user.email,
                    nom: user.last_name,
                    prenom: user.first_name,
                    status: 'Indisponible',
                    message: 'Dossier soumis — en attente de validation par le manager.',
                }
            });

        } catch (error) {
            console.error('[Enrolement] Erreur :', error.message);
            res.status(500).json({ message: 'Erreur serveur', error: error.message });
        }
    });
});

// ── GET /api/v1/drivers/me ───────────────────────────────────
// Profil du livreur connecte
const authMiddleware = require('../middlewares/authMiddleware');

router.get('/me', authMiddleware, async function(req, res) {
    try {
        var livreur = await prisma.delivery_persons.findUnique({
            where: { user_id: req.user.id },
            include: {
                users: true,
                vehicules: true,
            }
        });

        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });

        res.json({
            data: {
                id: livreur.id,
                user_id: livreur.user_id,
                status: livreur.status,
                available: livreur.available,
                zone_affectee: livreur.zone_affectee,
                caution_payee: livreur.caution_payee,
                photo_profil: livreur.photo_profil,
                user: {
                    id: livreur.users.id,
                    first_name: livreur.users.first_name,
                    last_name: livreur.users.last_name,
                    email: livreur.users.email,
                    phone: livreur.users.phone,
                },
                vehicule: livreur.vehicules ? {
                    type: livreur.vehicules.type,
                    brand: livreur.vehicules.brand,
                    plate_number: livreur.vehicules.plate_number,
                } : null,
            }
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

module.exports = router;