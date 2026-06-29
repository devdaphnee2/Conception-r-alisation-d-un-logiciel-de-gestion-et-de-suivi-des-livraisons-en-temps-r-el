const prisma = require('../utils/prismaClient');
const bcrypt = require('bcrypt');

// Liste principale — EXCLUT Indisponible (en attente) et Hors_service (rejetes)
// Uniquement les livreurs approuves : Disponible, En_livraison, Suspendu
async function index(req, res) {
    try {
        const where = req.query.all === 'true'
            ? { status: { in: ['Disponible', 'En_livraison', 'Suspendu'] } }
            : { status: 'Disponible' };

        const livreurs = await prisma.delivery_persons.findMany({
            include: { users: true, vehicules: true },
            where,
            orderBy: { id: 'desc' },
        });
        res.json(livreurs);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

async function store(req, res) {
    try {
        const { last_name, first_name, email, password, phone, zone_affectee, vehicle_id } = req.body;
        if (!last_name || !first_name || !email || !password || !phone) {
            return res.status(400).json({ message: 'Tous les champs obligatoires doivent etre remplis.' });
        }
        const existing = await prisma.users.findUnique({ where: { email } });
        if (existing) return res.status(400).json({ message: 'Cet email est deja utilise.' });

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
                available: true,
            }
        });
        res.status(201).json({ message: 'Livreur cree avec succes.', livreur });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

async function show(req, res) {
    try {
        const livreur = await prisma.delivery_persons.findUnique({
            where: { id: parseInt(req.params.id) },
            include: {
                users: true, vehicules: true,
                deliveryorders: {
                    orderBy: { creation_date: 'desc' },
                    take: 20,
                    include: { customers: { include: { users: true } } }
                },
            }
        });
        if (!livreur) return res.status(404).json({ message: 'Livreur introuvable.' });
        res.json(livreur);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

async function update(req, res) {
    try {
        const { last_name, first_name, phone, zone_affectee, vehicle_id } = req.body;
        const livreur = await prisma.delivery_persons.findUnique({ where: { id: parseInt(req.params.id) } });
        if (!livreur) return res.status(404).json({ message: 'Livreur introuvable.' });
        await prisma.users.update({ where: { id: livreur.user_id }, data: { last_name, first_name, phone } });
        const updated = await prisma.delivery_persons.update({
            where: { id: parseInt(req.params.id) },
            data: { zone_affectee: zone_affectee || null, vehicle_id: vehicle_id ? parseInt(vehicle_id) : null }
        });
        res.json({ message: 'Livreur modifie.', livreur: updated });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

async function suspendre(req, res) {
    try {
        const livreur = await prisma.delivery_persons.update({
            where: { id: parseInt(req.params.id) },
            data: { status: 'Suspendu', available: false }
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
            data: { status: 'Disponible', available: true }
        });
        res.json({ message: 'Livreur reactive.', livreur });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

module.exports = { index, store, show, update, suspendre, reactiver };
