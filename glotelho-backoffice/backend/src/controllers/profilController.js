const prisma = require('../utils/prismaClient');

// Liste profils en attente
async function listeEnAttente(req, res) {
    try {
        const livreurs = await prisma.delivery_persons.findMany({
            where: { status: 'Indisponible' },
            include: { users: true, vehicules: true },
            orderBy: { id: 'desc' },
        });
        res.json(livreurs);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Detail d'un profil
async function detailProfil(req, res) {
    try {
        const livreur = await prisma.delivery_persons.findUnique({
            where: { id: parseInt(req.params.id) },
            include: { users: true, vehicules: true }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });
        res.json(livreur);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Envoyer SMS notification caution au livreur
// En production : integrer Africa's Talking, Twilio ou Orange SMS API
async function envoyerNotificationCaution(req, res) {
    try {
        const { montant } = req.body;
        const livreur = await prisma.delivery_persons.findUnique({
            where: { id: parseInt(req.params.id) },
            include: { users: true }
        });
        if (!livreur) return res.status(404).json({ message: 'Livreur introuvable.' });

        const montantFinal = montant || livreur.caution_montant || 50000;

        // Message SMS simule
        const smsMessage = `Bonjour ${livreur.users.first_name},\n\nVotre profil Glotelho a été retenu ! 🎉\n\nPour finaliser votre inscription, veuillez régler votre caution de ${Number(montantFinal).toLocaleString('fr-FR')} FCFA dans les 48h :\n\n📱 Orange Money : *144*1*1*698000000*${Number(montantFinal).toLocaleString('fr-FR').replace(/\s/g,'')}#\nCode marchand OM : 698000000\n\n📱 MTN MoMo : *126*1*1*677000000*${Number(montantFinal).toLocaleString('fr-FR').replace(/\s/g,'')}#\nCode marchand MoMo : 677000000\n\n📲 Payer via l'app : https://glotelho.cm/app/livreur/caution\n\nMerci et bienvenue chez Glotelho !`;

        // TODO: Integrer SMS API ici
        // await sendSMS(livreur.users.phone, smsMessage);
        console.log('SMS simule vers ' + livreur.users.phone + ' :\n' + smsMessage);

        // Marquer notification envoyee
        await prisma.delivery_persons.update({
            where: { id: parseInt(req.params.id) },
            data: {
                caution_montant: parseFloat(montantFinal),
                note_manager: (livreur.note_manager ? livreur.note_manager + '\n' : '') +
                    '[' + new Date().toLocaleString('fr-FR') + '] Notification SMS caution envoyee — ' + Number(montantFinal).toLocaleString('fr-FR') + ' FCFA'
            }
        });

        res.json({
            message: 'Notification SMS envoyee a ' + livreur.users.first_name + ' (' + livreur.users.phone + ')',
            sms_preview: smsMessage,
            telephone: livreur.users.phone,
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Cocher caution payee
async function marquerCautionPayee(req, res) {
    try {
        const livreur = await prisma.delivery_persons.findUnique({
            where: { id: parseInt(req.params.id) },
            include: { users: true }
        });
        if (!livreur) return res.status(404).json({ message: 'Livreur introuvable.' });

        const updated = await prisma.delivery_persons.update({
            where: { id: parseInt(req.params.id) },
            data: {
                caution_payee: true,
                note_manager: (livreur.note_manager ? livreur.note_manager + '\n' : '') +
                    '[' + new Date().toLocaleString('fr-FR') + '] Caution marquee comme payee par le manager'
            }
        });

        res.json({ message: 'Caution marquee comme payee.', livreur: updated });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Approuver profil (caution doit etre payee)
async function approuver(req, res) {
    try {
        const livreur = await prisma.delivery_persons.findUnique({
            where: { id: parseInt(req.params.id) },
            include: { users: true }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });
        if (livreur.status !== 'Indisponible') {
            return res.status(400).json({ message: 'Ce profil n\'est pas en attente d\'approbation.' });
        }

        const updated = await prisma.delivery_persons.update({
            where: { id: parseInt(req.params.id) },
            data: {
                status: 'Disponible',
                available: true,
                note_manager: (livreur.note_manager ? livreur.note_manager + '\n' : '') +
                    '[' + new Date().toLocaleString('fr-FR') + '] Profil approuve — acces plateforme accorde'
            }
        });

        res.json({
            message: livreur.users.first_name + ' ' + livreur.users.last_name + ' est maintenant actif et peut recevoir des courses.',
            livreur: updated
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Rejeter profil
async function rejeter(req, res) {
    try {
        const { motif } = req.body;
        if (!motif) return res.status(400).json({ message: 'Le motif est obligatoire.' });
        const livreur = await prisma.delivery_persons.findUnique({
            where: { id: parseInt(req.params.id) },
            include: { users: true }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });
        const updated = await prisma.delivery_persons.update({
            where: { id: parseInt(req.params.id) },
            data: {
                status: 'Hors_service',
                available: false,
                note_manager: (livreur.note_manager ? livreur.note_manager + '\n' : '') +
                    '[' + new Date().toLocaleString('fr-FR') + '] REJETE : ' + motif
            }
        });
        res.json({ message: 'Profil rejete.', livreur: updated, motif });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

module.exports = { listeEnAttente, detailProfil, envoyerNotificationCaution, marquerCautionPayee, approuver, rejeter };