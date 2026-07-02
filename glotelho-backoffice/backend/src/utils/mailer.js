// backend/src/utils/mailer.js
// Service d'envoi d'emails via Nodemailer + Gmail
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

// Envoyer un email de reinitialisation de mot de passe
async function sendResetPasswordEmail(toEmail, resetUrl, prenom) {
    const mailOptions = {
        from: process.env.EMAIL_FROM || 'Glotelho <noreply@glotelho.cm>',
        to: toEmail,
        subject: 'Reinitialisation de votre mot de passe — Glotelho',
        html: `
            <div style="font-family: Arial, sans-serif; max-width: 520px; margin: 0 auto; background: #f9f9f9; padding: 32px; border-radius: 12px;">

                <div style="text-align: center; margin-bottom: 28px;">
                    <h2 style="color: #7d5700; font-size: 22px; margin: 0;">Glotelho</h2>
                    <p style="color: #817564; font-size: 12px; margin: 4px 0 0;">Back-office de gestion des livraisons</p>
                </div>

                <div style="background: #ffffff; border-radius: 10px; padding: 28px; border: 1px solid #d3c4b0;">
                    <h3 style="color: #1a1c1c; font-size: 18px; margin: 0 0 12px;">Reinitialisation du mot de passe</h3>
                    <p style="color: #4f4536; font-size: 14px; line-height: 1.6; margin: 0 0 20px;">
                        Bonjour ${prenom || ''},<br><br>
                        Vous avez demande a reinitialiser votre mot de passe sur le back-office Glotelho.<br>
                        Cliquez sur le bouton ci-dessous pour choisir un nouveau mot de passe.
                    </p>

                    <div style="text-align: center; margin: 28px 0;">
                        <a href="${resetUrl}"
                           style="background-color: #7d5700; color: #ffffff; padding: 14px 32px; border-radius: 10px; text-decoration: none; font-size: 14px; font-weight: bold; display: inline-block;">
                            Reinitialiser mon mot de passe
                        </a>
                    </div>

                    <p style="color: #817564; font-size: 12px; margin: 0; line-height: 1.6;">
                        Ce lien est valide pendant <strong>1 heure</strong>.<br>
                        Si vous n'avez pas demande cette reinitialisation, ignorez simplement cet email.
                    </p>
                </div>

                <p style="color: #817564; font-size: 11px; text-align: center; margin: 20px 0 0;">
                    © ${new Date().getFullYear()} Glotelho — Douala, Cameroun
                </p>
            </div>
        `,
    };

    await transporter.sendMail(mailOptions);
}

// Verifier la connexion au demarrage (optionnel)
async function verifyMailer() {
    try {
        await transporter.verify();
        console.log('[Mailer] Connexion Gmail OK — pret a envoyer des emails');
    } catch (error) {
        console.warn('[Mailer] Connexion Gmail non disponible :', error.message);
        console.warn('[Mailer] Verifiez EMAIL_USER et EMAIL_PASS dans .env');
    }
}

module.exports = { sendResetPasswordEmail, verifyMailer };