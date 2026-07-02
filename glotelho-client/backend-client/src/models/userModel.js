// src/models/userModel.js
const pool = require('../config/db');

const findUserByEmail = async (email) => {
  const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
  return rows[0];
};

// ✅ password inclus pour permettre bcrypt.compare dans changePassword
const findUserById = async (id) => {
  const [rows] = await pool.query(
    `SELECT id, last_name, first_name, email, phone, role, fcm_token, avatar_url, password
     FROM users WHERE id = ?`,
    [id]
  );
  return rows[0];
};

const createUserAndCustomer = async (data) => {
  const { full_name, email, password, phone, address, latitude, longitude } = data;

  const [userResult] = await pool.query(
    `INSERT INTO users (first_name, last_name, email, password, phone, role)
     VALUES (?, '', ?, ?, ?, 'customer')`,
    [full_name, email, password, phone]
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
    `SELECT u.id, u.first_name, u.last_name, u.email, u.phone, u.fcm_token, u.avatar_url,
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

module.exports = {
  findUserByEmail,
  findUserById,
  createUserAndCustomer,
  getCustomerByUserId,
  updateFcmToken,
  updateAvatarUrl
};