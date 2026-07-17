const prisma = require('../../utils/prismaClient');
const bcrypt = require('bcrypt');

// Helper pour récupérer le user lié au livreur de manière sécurisée
async function getUserForLivreur(livreurId, userId) {
    if (userId) {
        return await prisma.users.findUnique({ where: { id: userId } });
    }
    var livreur = await prisma.delivery_persons.findUnique({ where: { id: livreurId } });
    if (livreur && livreur.user_id) {
        return await prisma.users.findUnique({ where: { id: livreur.user_id } });
    }
    return null;
}

// Liste principale
async function index(req, res) {
    try {
        const where = req.query.all === 'true' ? { status: { in: ['Disponible', 'En_livraison', 'Suspendu', 'Hors_service'] } } : { status: 'Disponible' };
        const livreurs = await prisma.delivery_persons.findMany({
            include: { vehicules: true },
            where,
            orderBy: { id: 'desc' },
        });

        const result = [];
        for (let l of livreurs) {
            const user = await getUserForLivreur(l.id, l.user_id);
            result.push({...l, users: user, user: user });
        }
        res.json(result);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

async function store(req, res) {
    try {
        const { last_name, first_name, email, password, phone, zone_affectee, vehicle_id } = req.body;
        if (!last_name || !first_name || !email || !password || !phone) {
            return res.status(400).json({ message: 'Tous les champs obligatoires doivent être remplis.' });
        }
        const existing = await prisma.users.findUnique({ where: { email } });
        if (existing) return res.status(400).json({ message: 'Cet email est déjà utilisé.' });

        const hashedPassword = await bcrypt.hash(password, 10);
        const user = await prisma.users.create({
            data: { last_name, first_name, email, password: hashedPassword, phone, role: 'delivery_person' }
        });
        const livreur = await prisma.delivery_persons.create({
            data: {
                user_id: user.id,
                vehicle_id: vehicle_id ? parseInt(vehicle_id) : null,
                zone_affectee: zone_affectee || null,
                status: 'Disponible',
                available: 1,
            }
        });
        res.status(201).json({ message: 'Livreur créé avec succès.', livreur });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Affichage détaillé
async function show(req, res) {
    try {
        const livreur = await prisma.delivery_persons.findUnique({
            where: { id: parseInt(req.params.id) },
            include: {
                vehicules: true,
                deliveryorders: {
                    orderBy: { creation_date: 'desc' },
                    take: 20,
                    include: { customers: { include: { users: true } } }
                },
            }
        });

        if (!livreur) return res.status(404).json({ message: 'Livreur introuvable.' });

        const user = await getUserForLivreur(livreur.id, livreur.user_id);
        const data = {...livreur, users: user, user: user };

        res.json(data);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

async function update(req, res) {
    try {
        // 👇 On récupère les nouveaux champs du corps de la requête
        const {
            last_name,
            first_name,
            phone,
            zone_affectee,
            vehicule_type,
            vehicule_marque,
            vehicule_modele,
            vehicule_immatriculation
        } = req.body;

        const livreur = await prisma.delivery_persons.findUnique({ where: { id: parseInt(req.params.id) } });
        if (!livreur) return res.status(404).json({ message: 'Livreur introuvable.' });

        // Mise à jour de la table users (Nom, prénom, téléphone)
        await prisma.users.update({
            where: { id: livreur.user_id },
            data: { last_name, first_name, phone }
        });

        // 👇 Mise à jour de la table delivery_persons avec les nouveaux champs
        const updated = await prisma.delivery_persons.update({
            where: { id: parseInt(req.params.id) },
            data: {
                zone_affectee: zone_affectee || null,
                vehicule_type: vehicule_type || null,
                vehicule_marque: vehicule_marque || null,
                vehicule_modele: vehicule_modele || null,
                vehicule_immatriculation: vehicule_immatriculation || null
            }
        });

        res.json({ message: 'Le profil du livreur a été mis à jour avec succès.', livreur: updated });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

async function suspendre(req, res) {
    try {
        const livreur = await prisma.delivery_persons.update({
            where: { id: parseInt(req.params.id) },
            data: { status: 'Suspendu', available: 0 }
        });
        res.json({ message: 'Livreur suspendu.', livreur });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

async function reactiver(req, res) {
    try {
        const livreur = await prisma.delivery_persons.update({
            where: { id: parseInt(req.params.id) },
            data: { status: 'Disponible', available: 1 }
        });
        res.json({ message: 'Livreur réactivé.', livreur });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// 👇 NOUVELLE ACTION : Marquer la caution payée depuis la liste active
async function validerCaution(req, res) {
    try {
        const livreur = await prisma.delivery_persons.findUnique({
            where: { id: parseInt(req.params.id) }
        });
        if (!livreur) return res.status(404).json({ message: 'Livreur introuvable.' });

        const updated = await prisma.delivery_persons.update({
            where: { id: parseInt(req.params.id) },
            data: {
                caution_payee: 1,
                note_manager: (livreur.note_manager ? livreur.note_manager + '\n' : '') +
                    '[' + new Date().toLocaleString('fr-FR') + '] Caution marquée comme payée depuis le profil actif.'
            }
        });

        res.json({ message: 'La caution a été validée avec succès.', livreur: updated });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

module.exports = { index, store, show, update, suspendre, reactiver, validerCaution };