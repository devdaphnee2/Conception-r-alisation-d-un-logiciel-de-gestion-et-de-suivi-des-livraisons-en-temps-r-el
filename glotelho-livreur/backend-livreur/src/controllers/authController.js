const bcrypt           = require('bcryptjs');
const jwt              = require('jsonwebtoken');
const crypto           = require('crypto');
const { OAuth2Client } = require('google-auth-library');
const pool             = require('../config/db');
const { parseDisponibilites, fileUrl } = require('../utils/helpers');
const { sendResetPasswordEmail }       = require('../utils/mailer');

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

function generateToken(livreurId) {
  return jwt.sign({ livreurId }, process.env.JWT_SECRET, { expiresIn: '30d' });
}

function buildProfile(row) {
  let disponibilites = [];
  try { disponibilites = JSON.parse(row.disponibilites || '[]'); } catch (_) {}

  const statusMap = {
    'Disponible'   : 'approved',
    'En_livraison' : 'approved',
    'Indisponible' : 'pending',
    'Suspendu'     : 'rejected',
    'Hors_service' : 'rejected',
  };

  return {
    _id                 : String(row.livreur_id),
    nom                 : row.last_name   || '',
    prenom              : row.first_name  || '',
    dateNaissance       : row.date_naissance || null,
    telephone           : row.phone       || '',
    email               : row.email       || '',
    photoUrl            : row.photo_profil_url || null,
    adresseResidence    : row.adresse_residence || '',
    cniNumero           : row.cni_numero  || '',
    cniRectoUrl         : row.cni_recto_url  || null,
    cniVersoUrl         : row.cni_verso_url  || null,
    permisUrl           : row.permis_url     || null,
    vehicule: {
      type               : row.vehicule_type            || '',
      marque             : row.vehicule_marque           || '',
      modele             : row.vehicule_modele           || '',
      immatriculation    : row.vehicule_immatriculation  || '',
      photoUrl           : row.vehicule_photo_url        || null,
      assuranceNumero    : row.assurance_numero          || '',
      assuranceExpiration: row.assurance_expiration      || null,
    },
    disponibilites,
    mobileMoneyNumero   : row.mobile_money_numero    || '',
    mobileMoneyTitulaire: row.mobile_money_titulaire || '',
    status              : statusMap[row.status] || 'pending',
    soldeCommission     : parseFloat(row.solde_commission || 0),
    emprunt             : parseFloat(row.emprunt || 0),
    note                : parseFloat(row.note    || 0),
  };
}

const SELECT_PROFILE = `
  SELECT
    dp.id              AS livreur_id,
    dp.status,
    dp.date_naissance,
    dp.photo_profil_url,
    dp.adresse_residence,
    dp.cni_numero,
    dp.cni_recto_url,
    dp.cni_verso_url,
    dp.permis_url,
    dp.vehicule_type,
    dp.vehicule_marque,
    dp.vehicule_modele,
    dp.vehicule_immatriculation,
    dp.vehicule_photo_url,
    dp.assurance_numero,
    dp.assurance_expiration,
    dp.mobile_money_numero,
    dp.mobile_money_titulaire,
    dp.disponibilites,
    dp.solde_commission,
    dp.emprunt,
    dp.note,
    u.id               AS user_id,
    u.last_name,
    u.first_name,
    u.email,
    u.phone,
    u.password
  FROM delivery_persons dp
  JOIN users u ON u.id = dp.user_id
  WHERE dp.id = ?
`;

// ─── REGISTER ────────────────────────────────────────────────────
exports.register = async (req, res) => {
  const conn = await pool.getConnection();
  try {
    const {
      nom, prenom, dateNaissance, telephone, email, password,
      adresseResidence, cniNumero,
      vehiculeType, vehiculeMarque, vehiculeModele, vehiculeImmatriculation,
      assuranceNumero, assuranceExpiration,
      mobileMoneyNumero, mobileMoneyTitulaire,
    } = req.body;

    const disponibilites = parseDisponibilites(req.body);
    const files = req.files || {};

    if (!telephone || !password) {
      return res.status(400).json({ message: 'Le téléphone et le mot de passe sont requis.' });
    }

    const [existPhone] = await conn.query(
      'SELECT id FROM users WHERE phone = ?', [telephone]
    );
    if (existPhone.length) {
      return res.status(409).json({ message: 'Ce numéro de téléphone est déjà utilisé.' });
    }

    if (email) {
      const [existEmail] = await conn.query(
        'SELECT id FROM users WHERE email = ?', [email]
      );
      if (existEmail.length) {
        return res.status(409).json({ message: 'Cet email est déjà utilisé.' });
      }
    }

    await conn.beginTransaction();

    const hashedPassword = await bcrypt.hash(password, 12);

    const [userResult] = await conn.query(
      `INSERT INTO users (last_name, first_name, email, password, phone, role)
       VALUES (?, ?, ?, ?, ?, 'delivery_person')`,
      [nom || '', prenom || '', email || '', hashedPassword, telephone]
    );
    const userId = userResult.insertId;

    const [dpResult] = await conn.query(
      `INSERT INTO delivery_persons
         (user_id, status,
          date_naissance, photo_profil_url, adresse_residence,
          cni_numero, cni_recto_url, cni_verso_url, permis_url,
          vehicule_type, vehicule_marque, vehicule_modele,
          vehicule_immatriculation, vehicule_photo_url,
          assurance_numero, assurance_expiration,
          mobile_money_numero, mobile_money_titulaire,
          disponibilites)
       VALUES (?, 'Indisponible', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userId,
        dateNaissance ? new Date(dateNaissance).toISOString().slice(0, 10) : null,
        fileUrl(req, files.photoProfil?.[0]),
        adresseResidence || null,
        cniNumero || null,
        fileUrl(req, files.cniRecto?.[0]),
        fileUrl(req, files.cniVerso?.[0]),
        fileUrl(req, files.permis?.[0]),
        vehiculeType || null,
        vehiculeMarque || null,
        vehiculeModele || null,
        vehiculeImmatriculation || null,
        fileUrl(req, files.photoVehicule?.[0]),
        assuranceNumero || null,
        assuranceExpiration ? new Date(assuranceExpiration).toISOString().slice(0, 10) : null,
        mobileMoneyNumero || null,
        mobileMoneyTitulaire || null,
        JSON.stringify(disponibilites),
      ]
    );
    const livreurId = dpResult.insertId;

    await conn.commit();

    const token = generateToken(livreurId);
    return res.status(201).json({
      token,
      data: { _id: String(livreurId), status: 'pending' },
    });

  } catch (err) {
    await conn.rollback();
    console.error('[register]', err.message);
    return res.status(500).json({ message: 'Erreur serveur lors de l\'inscription.' });
  } finally {
    conn.release();
  }
};

// ─── LOGIN ───────────────────────────────────────────────────────
exports.login = async (req, res) => {
  try {
    const { telephone, password } = req.body;
    if (!telephone || !password) {
      return res.status(400).json({ message: 'Identifiant et mot de passe requis.' });
    }

    const conn = await pool.getConnection();
    try {
      const [rows] = await conn.query(
        `SELECT dp.id AS livreur_id, u.password
         FROM delivery_persons dp
         JOIN users u ON u.id = dp.user_id
         WHERE u.phone = ? OR u.email = ?`,
        [telephone, telephone]
      );

      if (!rows.length) {
        return res.status(401).json({ message: 'Identifiants incorrects.' });
      }

      const valid = await bcrypt.compare(password, rows[0].password);
      if (!valid) {
        return res.status(401).json({ message: 'Identifiants incorrects.' });
      }

      const token = generateToken(rows[0].livreur_id);
      return res.status(200).json({ token });
    } finally {
      conn.release();
    }
  } catch (err) {
    console.error('[login]', err.message);
    if (err.code === 'ECONNRESET') {
      return res.status(503).json({ message: 'La base de données est temporairement indisponible. Réessayez.' });
    }
    return res.status(500).json({ message: 'Erreur serveur lors de la connexion.' });
  }
};

// ─── GOOGLE AUTH ──────────────────────────────────────────────
exports.googleAuth = async (req, res) => {
  const conn = await pool.getConnection();
  try {
    const { idToken } = req.body;
    if (!idToken) return res.status(400).json({ message: 'idToken requis.' });

    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    const { email, given_name, family_name, picture } = payload;

    const [rows] = await conn.query(
      `SELECT dp.id AS livreur_id FROM delivery_persons dp
       JOIN users u ON u.id = dp.user_id WHERE u.email = ?`,
      [email]
    );

    if (rows.length) {
      conn.release();
      return res.status(200).json({ token: generateToken(rows[0].livreur_id) });
    }

    await conn.beginTransaction();

    const [userResult] = await conn.query(
      `INSERT INTO users (last_name, first_name, email, password, phone, role)
       VALUES (?, ?, ?, '', '', 'delivery_person')`,
      [family_name || '', given_name || '', email]
    );

    const [dpResult] = await conn.query(
      `INSERT INTO delivery_persons (user_id, status, photo_profil_url)
       VALUES (?, 'Indisponible', ?)`,
      [userResult.insertId, picture || null]
    );

    await conn.commit();
    return res.status(200).json({ token: generateToken(dpResult.insertId) });

  } catch (err) {
    await conn.rollback();
    console.error('[googleAuth]', err.message);
    if (err.message?.toLowerCase().includes('invalid') || err.message?.toLowerCase().includes('expired')) {
      return res.status(401).json({ message: 'Token Google invalide ou expiré.' });
    }
    return res.status(500).json({ message: 'Erreur serveur.' });
  } finally {
    conn.release();
  }
};

// ─── GET PROFILE ──────────────────────────────────────────────
exports.getMe = async (req, res) => {
  try {
    const [rows] = await pool.query(SELECT_PROFILE, [req.livreur.id]);
    if (!rows.length) return res.status(404).json({ message: 'Livreur introuvable.' });
    return res.status(200).json({ data: buildProfile(rows[0]) });
  } catch (err) {
    console.error('[getMe]', err.message);
    return res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// ─── UPDATE PROFILE ───────────────────────────────────────────
exports.updateMe = async (req, res) => {
  const conn = await pool.getConnection();
  try {
    const livreurId = req.livreur.id;
    const files = req.files || {};
    const body  = req.body;

    const [rows] = await conn.query(SELECT_PROFILE, [livreurId]);
    if (!rows.length) return res.status(404).json({ message: 'Livreur introuvable.' });
    const cur = rows[0];

    await conn.query(
      `UPDATE users SET last_name=?, first_name=?, phone=?, email=? WHERE id=?`,
      [
        body.nom       || cur.last_name,
        body.prenom    || cur.first_name,
        body.telephone || cur.phone,
        body.email     || cur.email,
        cur.user_id,
      ]
    );

    const disponibilites = parseDisponibilites(body);

    await conn.query(
      `UPDATE delivery_persons SET
         date_naissance           = ?,
         photo_profil_url         = ?,
         adresse_residence        = ?,
         cni_numero               = ?,
         cni_recto_url            = ?,
         cni_verso_url            = ?,
         permis_url               = ?,
         vehicule_type            = ?,
         vehicule_marque          = ?,
         vehicule_modele          = ?,
         vehicule_immatriculation = ?,
         vehicule_photo_url       = ?,
         assurance_numero         = ?,
         assurance_expiration     = ?,
         mobile_money_numero      = ?,
         mobile_money_titulaire   = ?,
         disponibilites           = ?
       WHERE id = ?`,
      [
        body.dateNaissance ? new Date(body.dateNaissance).toISOString().slice(0, 10) : cur.date_naissance,
        fileUrl(req, files.photoProfil?.[0])    || cur.photo_profil_url,
        body.adresseResidence        || cur.adresse_residence,
        body.cniNumero               || cur.cni_numero,
        fileUrl(req, files.cniRecto?.[0])        || cur.cni_recto_url,
        fileUrl(req, files.cniVerso?.[0])        || cur.cni_verso_url,
        fileUrl(req, files.permis?.[0])          || cur.permis_url,
        body.vehiculeType            || cur.vehicule_type,
        body.vehiculeMarque          || cur.vehicule_marque,
        body.vehiculeModele          || cur.vehicule_modele,
        body.vehiculeImmatriculation || cur.vehicule_immatriculation,
        fileUrl(req, files.photoVehicule?.[0])   || cur.vehicule_photo_url,
        body.assuranceNumero         || cur.assurance_numero,
        body.assuranceExpiration ? new Date(body.assuranceExpiration).toISOString().slice(0, 10) : cur.assurance_expiration,
        body.mobileMoneyNumero       || cur.mobile_money_numero,
        body.mobileMoneyTitulaire    || cur.mobile_money_titulaire,
        disponibilites.length ? JSON.stringify(disponibilites) : cur.disponibilites,
        livreurId,
      ]
    );

    const [updated] = await conn.query(SELECT_PROFILE, [livreurId]);
    return res.status(200).json({ data: buildProfile(updated[0]) });

  } catch (err) {
    console.error('[updateMe]', err.message);
    return res.status(500).json({ message: 'Erreur serveur lors de la mise à jour.' });
  } finally {
    conn.release();
  }
};

// ─── LOGOUT ────────────────────────────────────────────────────
exports.logout = async (req, res) => {
  try {
    await pool.query(
      `UPDATE users SET fcm_token = NULL
       WHERE id = (SELECT user_id FROM delivery_persons WHERE id = ?)`,
      [req.livreur.id]
    );
    return res.status(200).json({ message: 'Déconnecté.' });
  } catch (err) {
    console.error('[logout]', err.message);
    return res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// ─── FCM TOKEN ─────────────────────────────────────────────────
exports.updateFcmToken = async (req, res) => {
  try {
    const { fcm_token } = req.body;
    if (!fcm_token) return res.status(400).json({ message: 'fcm_token requis.' });

    await pool.query(
      `UPDATE users SET fcm_token = ?
       WHERE id = (SELECT user_id FROM delivery_persons WHERE id = ?)`,
      [fcm_token, req.livreur.id]
    );
    return res.status(200).json({ fcm_token });
  } catch (err) {
    console.error('[updateFcmToken]', err.message);
    return res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// ─── FORGOT PASSWORD ──────────────────────────────────────────
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'Email requis.' });

    const [rows] = await pool.query(
      `SELECT u.id AS user_id, u.first_name, u.last_name
       FROM users u
       JOIN delivery_persons dp ON dp.user_id = u.id
       WHERE u.email = ? AND u.role = 'delivery_person'`,
      [email]
    );

    if (!rows.length) {
      return res.status(200).json({
        message: 'Si un compte existe avec cet email, un lien de réinitialisation vous a été envoyé.'
      });
    }

    const user = rows[0];
    const resetToken = crypto.randomBytes(32).toString('hex');

    await pool.query('DELETE FROM password_resets WHERE user_id = ?', [user.user_id]);
    await pool.query(
      'INSERT INTO password_resets (user_id, token) VALUES (?, ?)',
      [user.user_id, resetToken]
    );

    const fullName = [user.first_name, user.last_name].filter(Boolean).join(' ').trim();

    try {
      await sendResetPasswordEmail(email, resetToken, fullName);
    } catch (mailErr) {
      console.error('[forgot-password] Email échoué :', mailErr.message);
    }

    return res.status(200).json({
      message: 'Si un compte existe avec cet email, un lien de réinitialisation vous a été envoyé.'
    });

  } catch (err) {
    console.error('[forgotPassword]', err.message);
    return res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// ─── RESET PASSWORD ────────────────────────────────────────────
exports.resetPassword = async (req, res) => {
  try {
    const { token, newPassword } = req.body;

    if (!token || !newPassword) {
      return res.status(400).json({ message: 'Token et nouveau mot de passe requis.' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'Le mot de passe doit contenir au moins 6 caractères.' });
    }

    const [rows] = await pool.query(
      `SELECT user_id, created_at FROM password_resets WHERE token = ?`,
      [token]
    );

    if (!rows.length) {
      return res.status(400).json({ message: 'Token invalide ou expiré.' });
    }

    const expiresAt = new Date(rows[0].created_at);
    expiresAt.setHours(expiresAt.getHours() + 1);

    if (new Date() > expiresAt) {
      await pool.query('DELETE FROM password_resets WHERE token = ?', [token]);
      return res.status(400).json({ message: 'Token invalide ou expiré.' });
    }

    const userId = rows[0].user_id;
    const hashedPassword = await bcrypt.hash(newPassword, 12);

    await pool.query('UPDATE users SET password = ? WHERE id = ?', [hashedPassword, userId]);
    await pool.query('DELETE FROM password_resets WHERE token = ?', [token]);

    return res.status(200).json({ message: 'Mot de passe réinitialisé avec succès.' });

  } catch (err) {
    console.error('[resetPassword]', err.message);
    return res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// ─── CHANGE PASSWORD ──────────────────────────────────────────
exports.changePassword = async (req, res) => {
  try {
    const { old_password, new_password } = req.body;

    if (!old_password || !new_password) {
      return res.status(400).json({ message: 'Ancien et nouveau mot de passe requis.' });
    }
    if (new_password.length < 6) {
      return res.status(400).json({ message: 'Le nouveau mot de passe doit contenir au moins 6 caractères.' });
    }

    const [rows] = await pool.query(SELECT_PROFILE, [req.livreur.id]);
    if (!rows.length) return res.status(404).json({ message: 'Livreur introuvable.' });

    const isValid = await bcrypt.compare(old_password, rows[0].password);
    if (!isValid) {
      return res.status(401).json({ message: 'Ancien mot de passe incorrect.' });
    }

    const hashedPassword = await bcrypt.hash(new_password, 12);
    await pool.query('UPDATE users SET password = ? WHERE id = ?', [hashedPassword, rows[0].user_id]);

    return res.status(200).json({ message: 'Mot de passe modifié avec succès.' });

  } catch (err) {
    console.error('[changePassword]', err.message);
    return res.status(500).json({ message: 'Erreur serveur.' });
  }
};