// src/models/userModel.js
// Modèle utilisateur (client) — version adaptée du backend manager

const pool = require('../config/db');

// Trouver un utilisateur par email
const findUserByEmail = async (email) => {
  const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
  return rows[0];
};

// Trouver un utilisateur par ID
const findUserById = async (id) => {
  const [rows] = await pool.query(
    `SELECT id, last_name, first_name, email, phone, role, fcm_token
     FROM users WHERE id = ?`,
    [id]
  );
  return rows[0];
};

// Créer un utilisateur (users) + profil client (customers)
const createUserAndCustomer = async (data) => {
  const { last_name, first_name, email, password, phone, address, latitude, longitude } = data;

  // 1. Insertion dans users (role = 'customer')
  const [userResult] = await pool.query(
    `INSERT INTO users (last_name, first_name, email, password, phone, role)
     VALUES (?, ?, ?, ?, ?, 'customer')`,
    [last_name, first_name, email, password, phone]
  );
  const userId = userResult.insertId;

  // 2. Insertion dans customers
  await pool.query(
    `INSERT INTO customers (user_id, address, latitude, longitude)
     VALUES (?, ?, ?, ?)`,
    [userId, address || null, latitude || null, longitude || null]
  );

  return userId;
};

// Récupérer un client avec ses informations complètes (users + customers)
const getCustomerByUserId = async (userId) => {
  const [rows] = await pool.query(
    `SELECT u.id, u.last_name, u.first_name, u.email, u.phone, u.fcm_token,
            c.address, c.latitude, c.longitude
     FROM users u
     JOIN customers c ON u.id = c.user_id
     WHERE u.id = ?`,
    [userId]
  );
  return rows[0];
};

// Mettre à jour le token FCM
const updateFcmToken = async (userId, fcmToken) => {
  await pool.query('UPDATE users SET fcm_token = ? WHERE id = ?', [fcmToken, userId]);
};

module.exports = {
  findUserByEmail,
  findUserById,
  createUserAndCustomer,
  getCustomerByUserId,
  updateFcmToken
};