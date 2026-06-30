// src/config/db.js
// ═══════════════════════════════════════════════════════════════════
// CONNEXION À LA BASE DE DONNÉES
// ═══════════════════════════════════════════════════════════════════

// mysql2/promise : version asynchrone du driver MySQL
// dotenv : permet de charger les identifiants depuis .env
const mysql = require('mysql2/promise');
require('dotenv').config();

// Création d'un pool de connexions réutilisables.
// Avantage : les connexions sont maintenues ouvertes et partagées.
// Évite d'ouvrir/fermer une connexion à chaque requête.
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,    // Si occupé, la requête attend
  connectionLimit: 10,         // Maximum 10 connexions simultanées
  queueLimit: 0                // File d'attente illimitée
});

// Test automatique de connexion au démarrage du serveur
// Si erreur, affiche un message dans la console
(async () => {
  try {
    const connection = await pool.getConnection();
    console.log('✅ [Client] Connecté à la base de données MySQL');
    connection.release();
  } catch (err) {
    console.error('❌ [Client] Erreur de connexion :', err.message);
  }
})();

module.exports = pool;