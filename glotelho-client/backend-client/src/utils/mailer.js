// src/utils/mailer.js
// Service d'envoi d'emails — Nodemailer + Gmail
// Adapté du backend manager Glotelho

const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// ── Email de bienvenue (compte Google) ──────────────────────────
async function sendWelcomeGoogleEmail(toEmail, fullName) {
  const mailOptions = {
    from: process.env.EMAIL_FROM || 'Glotelho Express <noreply@glotelho.cm>',
    to: toEmail,
    subject: 'Bienvenue sur Glotelho Express !',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 520px; margin: 0 auto; background: #f9f9f9; padding: 32px; border-radius: 12px;">
        <div style="text-align: center; margin-bottom: 28px;">
          <h2 style="color: #C8960C; font-size: 22px; margin: 0;">Glotelho Express</h2>
          <p style="color: #817564; font-size: 12px; margin: 4px 0 0;">Application mobile de livraison rapide</p>
        </div>

        <div style="background: #ffffff; border-radius: 10px; padding: 28px; border: 1px solid #d3c4b0;">
          <h3 style="color: #1a1c1c; font-size: 18px; margin: 0 0 12px;">Compte créé avec succès !</h3>
          <p style="color: #4f4536; font-size: 14px; line-height: 1.6; margin: 0 0 20px;">
            Bonjour ${fullName || ''},<br><br>
            Votre compte Glotelho Express a été créé via Google Sign-In.<br><br>
            <strong>Votre email de connexion :</strong> ${toEmail}<br><br>
            Si vous souhaitez également vous connecter avec un mot de passe 
            (sans Google), utilisez la fonction <strong>"Mot de passe oublié"</strong> 
            dans l'application pour en créer un.
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

// ── Email de réinitialisation de mot de passe ───────────────────
async function sendResetPasswordEmail(toEmail, resetToken, fullName) {
  // Le lien pointe vers l'écran de reset dans l'app mobile
  // En production, ce serait un deep link vers l'app
  const resetUrl = `${process.env.APP_URL || 'http://localhost:3001'}/reset-password?token=${resetToken}`;

  const mailOptions = {
    from: process.env.EMAIL_FROM || 'Glotelho Express <noreply@glotelho.cm>',
    to: toEmail,
    subject: 'Réinitialisation de votre mot de passe — Glotelho Express',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 520px; margin: 0 auto; background: #f9f9f9; padding: 32px; border-radius: 12px;">
        <div style="text-align: center; margin-bottom: 28px;">
          <h2 style="color: #C8960C; font-size: 22px; margin: 0;">Glotelho Express</h2>
          <p style="color: #817564; font-size: 12px; margin: 4px 0 0;">Application mobile de livraison rapide</p>
        </div>

        <div style="background: #ffffff; border-radius: 10px; padding: 28px; border: 1px solid #d3c4b0;">
          <h3 style="color: #1a1c1c; font-size: 18px; margin: 0 0 12px;">Réinitialisation du mot de passe</h3>
          <p style="color: #4f4536; font-size: 14px; line-height: 1.6; margin: 0 0 20px;">
            Bonjour ${fullName || ''},<br><br>
            Vous avez demandé à réinitialiser votre mot de passe sur Glotelho Express.<br>
            Copiez le code ci-dessous dans l'application :
          </p>

          <div style="text-align: center; margin: 28px 0;">
            <div style="background: #0D1B2A; color: #C8960C; padding: 16px 32px; border-radius: 10px; font-size: 18px; font-weight: bold; letter-spacing: 4px; display: inline-block; font-family: monospace;">
              ${resetToken}
            </div>
          </div>

          <p style="color: #817564; font-size: 12px; margin: 0; line-height: 1.6;">
            Ce code est valide pendant <strong>1 heure</strong>.<br>
            Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.
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

// ── Vérifier la connexion au démarrage ──────────────────────────
async function verifyMailer() {
  try {
    await transporter.verify();
    console.log('[Mailer] Connexion Gmail OK — prêt à envoyer des emails');
  } catch (error) {
    console.warn('[Mailer] Gmail non disponible :', error.message);
    console.warn('[Mailer] Vérifiez EMAIL_USER et EMAIL_PASS dans .env');
  }
}

module.exports = { sendWelcomeGoogleEmail, sendResetPasswordEmail, verifyMailer };