const nodemailer = require('nodemailer');

async function sendResetPasswordEmail(email, resetUrl, prenom) {
    var transporter = nodemailer.createTransporter({
        service: 'gmail',
        auth: { user: process.env.EMAIL_USER, pass: process.env.EMAIL_PASS }
    });

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

module.exports = { sendResetPasswordEmail };
