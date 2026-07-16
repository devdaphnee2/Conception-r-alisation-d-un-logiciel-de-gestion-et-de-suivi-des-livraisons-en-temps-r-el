const prisma = require('../../utils/prismaClient');

// Helper — cherche le user via user_id du livreur directement
async function getUserForLivreur(livreurId) {
    var livreur = await prisma.delivery_persons.findUnique({ where: { id: livreurId } });
    if (livreur && livreur.user_id) {
        return await prisma.users.findUnique({ where: { id: livreur.user_id } });
    }
    return null;
}

// Liste profils en attente
async function listeEnAttente(req, res) {
    try {
        var livreurs = await prisma.delivery_persons.findMany({
            where: { status: 'Indisponible' },
            include: { vehicules: true, photos: true },
            orderBy: { id: 'desc' },
        });
        var result = [];
        for (var i = 0; i < livreurs.length; i++) {
            var l = livreurs[i];
            var user = await getUserForLivreur(l.id);
            result.push(Object.assign({}, l, { user: user }));
        }
        res.json(result);
    } catch (error) {
        console.error('listeEnAttente error:', error.message);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Detail d'un profil
async function detailProfil(req, res) {
    try {
        var livreur = await prisma.delivery_persons.findUnique({
            where: { id: parseInt(req.params.id) },
            include: { vehicules: true }
        });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });
        var user = await getUserForLivreur(livreur.id);
        res.json(Object.assign({}, livreur, { user: user }));
    } catch (error) {
        console.error('detailProfil error:', error.message);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Envoyer notification caution
async function envoyerNotificationCaution(req, res) {
    try {
        var livreur = await prisma.delivery_persons.findUnique({ where: { id: parseInt(req.params.id) } });
        if (!livreur) return res.status(404).json({ message: 'Livreur introuvable.' });
        var user = await getUserForLivreur(livreur.id);
        var montantFinal = req.body.montant || livreur.caution_montant || 50000;
        var prenom    = user ? user.first_name : 'Livreur';
        var telephone = user ? user.phone : '';
        var smsMessage = 'Bonjour ' + prenom + ',\n\nVotre profil Glotelho a ete retenu !\n\n' +
            'Pour finaliser votre inscription, veuillez regler votre caution de ' +
            Number(montantFinal).toLocaleString('fr-FR') + ' FCFA dans les 48h :\n\n' +
            'Orange Money : *144*1*1*698000000*' + montantFinal + '#\n' +
            'MTN MoMo : *126*1*1*677000000*' + montantFinal + '#\n\nMerci et bienvenue chez Glotelho !';
        console.log('SMS simule vers ' + telephone + ' :\n' + smsMessage);
        await prisma.delivery_persons.update({
            where: { id: parseInt(req.params.id) },
            data: {
                caution_montant: parseFloat(montantFinal),
                note_manager: (livreur.note_manager ? livreur.note_manager + '\n' : '') +
                    '[' + new Date().toLocaleString('fr-FR') + '] Notification SMS caution envoyee — ' + Number(montantFinal).toLocaleString('fr-FR') + ' FCFA'
            }
        });
        res.json({ message: 'Notification SMS envoyee a ' + prenom + ' (' + telephone + ')', sms_preview: smsMessage, telephone });
    } catch (error) {
        console.error('envoyerNotificationCaution error:', error.message);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Marquer caution payee
async function marquerCautionPayee(req, res) {
    try {
        var livreur = await prisma.delivery_persons.findUnique({ where: { id: parseInt(req.params.id) } });
        if (!livreur) return res.status(404).json({ message: 'Livreur introuvable.' });
        var updated = await prisma.delivery_persons.update({
            where: { id: parseInt(req.params.id) },
            data: {
                caution_payee: 1,
                note_manager: (livreur.note_manager ? livreur.note_manager + '\n' : '') +
                    '[' + new Date().toLocaleString('fr-FR') + '] Caution marquee comme payee par le manager'
            }
        });
        res.json({ message: 'Caution marquee comme payee.', livreur: updated });
    } catch (error) {
        console.error('marquerCautionPayee error:', error.message);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Approuver profil
async function approuver(req, res) {
    try {
        var livreur = await prisma.delivery_persons.findUnique({ where: { id: parseInt(req.params.id) } });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });
        if (livreur.status !== 'Indisponible') return res.status(400).json({ message: "Ce profil n'est pas en attente d'approbation." });
        var user    = await getUserForLivreur(livreur.id);
        var updated = await prisma.delivery_persons.update({
            where: { id: parseInt(req.params.id) },
            data: {
                status: 'Disponible', available: 1, date_activation: new Date(),
                note_manager: (livreur.note_manager ? livreur.note_manager + '\n' : '') +
                    '[' + new Date().toLocaleString('fr-FR') + '] Profil approuve — acces plateforme accorde'
            }
        });
        var nom = user ? user.first_name + ' ' + user.last_name : 'Le livreur';
        res.json({ message: nom + ' est maintenant actif et peut recevoir des courses. Il a 14 jours pour payer sa caution.', livreur: updated });
    } catch (error) {
        console.error('approuver error:', error.message);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// Rejeter profil
async function rejeter(req, res) {
    try {
        var motif = req.body.motif;
        if (!motif) return res.status(400).json({ message: 'Le motif est obligatoire.' });
        var livreur = await prisma.delivery_persons.findUnique({ where: { id: parseInt(req.params.id) } });
        if (!livreur) return res.status(404).json({ message: 'Profil introuvable.' });
        var updated = await prisma.delivery_persons.update({
            where: { id: parseInt(req.params.id) },
            data: {
                status: 'Hors_service', available: 0,
                note_manager: (livreur.note_manager ? livreur.note_manager + '\n' : '') +
                    '[' + new Date().toLocaleString('fr-FR') + '] REJETE : ' + motif
            }
        });
        res.json({ message: 'Profil rejete.', livreur: updated, motif });
    } catch (error) {
        console.error('rejeter error:', error.message);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

module.exports = { listeEnAttente, detailProfil, envoyerNotificationCaution, marquerCautionPayee, approuver, rejeter };