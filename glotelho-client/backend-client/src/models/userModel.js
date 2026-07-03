// src/models/userModel.js
const pool = require('../config/db');

const findUserByEmail = async (email) => {
  const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
  return rows[0];
};

// ✅ password inclus pour bcrypt.compare dans changePassword
const findUserById = async (id) => {
  const [rows] = await pool.query(
    `SELECT id, last_name, first_name, email, phone, role, fcm_token,
            avatar_url, photo_url, password, google_id, has_password
     FROM users WHERE id = ?`,
    [id]
  );
  return rows[0];
};

// ✅ Recherche par Google ID
const findUserByGoogleId = async (googleId) => {
  const [rows] = await pool.query(
    'SELECT * FROM users WHERE google_id = ?',
    [googleId]
  );
  return rows[0];
};

// ✅ Lier un Google ID à un compte existant
const linkGoogleId = async (userId, googleId, photoUrl) => {
  await pool.query(
    'UPDATE users SET google_id = ?, photo_url = COALESCE(photo_url, ?) WHERE id = ?',
    [googleId, photoUrl || null, userId]
  );
};

const createUserAndCustomer = async (data) => {
  const {
    full_name, email, password, phone,
    address, latitude, longitude,
    google_id, has_password = 1, photo_url
  } = data;

  const [userResult] = await pool.query(
    `INSERT INTO users
     (first_name, last_name, email, password, phone, role, google_id, has_password, photo_url)
     VALUES (?, '', ?, ?, ?, 'customer', ?, ?, ?)`,
    [full_name, email, password, phone, google_id || null, has_password, photo_url || null]
  );
  const userId = userResult.insertId;

  await pool.query(
    `INSERT INTO customers (user_id, address, latitude, longitude)
     VALUES (?, ?, ?, ?)`,
    [userId, address || null, latitude || null, longitude || null]
  );

  return userId;
};

const getCustomerByUserId = async (userId) => {
  const [rows] = await pool.query(
    `SELECT u.id, u.first_name, u.last_name, u.email, u.phone,
            u.fcm_token, u.avatar_url, u.photo_url,
            c.address, c.latitude, c.longitude
     FROM users u
     JOIN customers c ON u.id = c.user_id
     WHERE u.id = ?`,
    [userId]
  );
  return rows[0];
};

const updateFcmToken = async (userId, fcmToken) => {
  await pool.query('UPDATE users SET fcm_token = ? WHERE id = ?', [fcmToken, userId]);
};

const updateAvatarUrl = async (userId, avatarUrl) => {
  await pool.query('UPDATE users SET avatar_url = ? WHERE id = ?', [avatarUrl, userId]);
};

// ✅ Mise à jour profil avec vérification unicité email
const updateProfile = async (userId, data) => {
  const { full_name, email, phone } = data;

  if (email) {
    const [existing] = await pool.query(
      'SELECT id FROM users WHERE email = ? AND id != ?',
      [email, userId]
    );
    if (existing.length > 0) {
      throw new Error('EMAIL_ALREADY_TAKEN');
    }
  }

  await pool.query(
    `UPDATE users SET first_name = ?, email = ?, phone = ? WHERE id = ?`,
    [full_name, email, phone, userId]
  );
};

module.exports = {
  findUserByEmail,
  findUserById,
  findUserByGoogleId,
  linkGoogleId,
  createUserAndCustomer,
  getCustomerByUserId,
  updateFcmToken,
  updateAvatarUrl,
  updateProfile
};