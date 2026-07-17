const nodemailer = require('nodemailer');

function getTransporter() {
    return nodemailer.createTransport({
        service: 'gmail',
        auth: { user: process.env.EMAIL_USER, pass: process.env.EMAIL_PASS }
    });
}

async function sendResetPasswordEmail(email, resetUrl, prenom) {
    var transporter = getTransporter();

    await transporter.sendMail({
        from: '"Glotelho" <' + process.env.EMAIL_USER + '>',
        to: email,
        subject: 'Reinitialisation de votre mot de passe Glotelho',
        html: '<h2>Bonjour ' + (prenom || '') + '</h2>' +
            '<p>Cliquez sur le lien ci-dessous pour reinitialiser votre mot de passe :</p>' +
            '<a href="' + resetUrl + '" style="background:#7d5700;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;">Reinitialiser mon mot de passe</a>' +
            '<p>Ce lien expire dans 1 heure.</p>' +
            '<p>Si vous n\'avez pas fait cette demande, ignorez cet email.</p>',
    });
}

// Email envoye au commercant quand un litige qu'il a declare est resolu (approuve ou rejete)
async function sendLitigeResoluEmail(email, prenom, litigeId, decision, montant) {
    var transporter = getTransporter();
    var decisionLabel = decision === 'Rejetee' ? 'rejete' : 'resolu (' + (decision || 'decision enregistree') + ')';
    var montantHtml = montant ? '<p><strong>Montant :</strong> ' + Number(montant).toLocaleString('fr-FR') + ' FCFA</p>' : '';

    await transporter.sendMail({
        from: '"Glotelho" <' + process.env.EMAIL_USER + '>',
        to: email,
        subject: 'Votre litige #' + litigeId + ' a ete ' + (decision === 'Rejetee' ? 'rejete' : 'resolu'),
        html: '<h2>Bonjour ' + (prenom || '') + '</h2>' +
            '<p>Votre litige <strong>#' + litigeId + '</strong> a ete ' + decisionLabel + '.</p>' +
            montantHtml +
            '<p>Vous pouvez consulter le detail depuis votre espace commercant Glotelho.</p>',
    });
}

// Email envoye au commercant quand une de ses livraisons est retardee / suspendue (incident signale par le livreur)
async function sendLivraisonRetardeeEmail(email, prenom, livraisonId, motif) {
    var transporter = getTransporter();

    await transporter.sendMail({
        from: '"Glotelho" <' + process.env.EMAIL_USER + '>',
        to: email,
        subject: 'Retard sur votre livraison #' + livraisonId,
        html: '<h2>Bonjour ' + (prenom || '') + '</h2>' +
            '<p>Votre livraison <strong>#' + livraisonId + '</strong> rencontre un retard.</p>' +
            '<p><strong>Motif :</strong> ' + (motif || 'Non precise') + '</p>' +
            '<p>Un litige a ete automatiquement ouvert et sera traite par notre equipe.</p>',
    });
}

module.exports = { sendResetPasswordEmail, sendLitigeResoluEmail, sendLivraisonRetardeeEmail };