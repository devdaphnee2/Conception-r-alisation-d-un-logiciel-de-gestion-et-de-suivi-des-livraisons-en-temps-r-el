const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

async function sendResetPasswordEmail(toEmail, resetToken, fullName) {
  const resetUrl = `${process.env.APP_URL}/reset-password?token=${resetToken}`;

  await transporter.sendMail({
    from   : process.env.EMAIL_FROM,
    to     : toEmail,
    subject: 'Réinitialisation de votre mot de passe — Glotelho Delivery',
    html   : `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #C8960C;">Glotelho Delivery</h2>
        <p>Bonjour <strong>${fullName || 'Livreur'}</strong>,</p>
        <p>Vous avez demandé la réinitialisation de votre mot de passe.</p>
        <p>Cliquez sur le bouton ci-dessous pour créer un nouveau mot de passe :</p>
        <a href="${resetUrl}"
           style="display:inline-block; padding:12px 24px; background:#C8960C;
                  color:white; text-decoration:none; border-radius:6px; margin:16px 0;">
          Réinitialiser mon mot de passe
        </a>
        <p>Ce lien est valable pendant <strong>1 heure</strong>.</p>
        <p>Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.</p>
        <hr style="margin-top:32px; border:none; border-top:1px solid #eee;" />
        <p style="color:#999; font-size:12px;">Glotelho Delivery — Ne pas répondre à cet email.</p>
      </div>
    `,
  });
}

module.exports = { sendResetPasswordEmail };