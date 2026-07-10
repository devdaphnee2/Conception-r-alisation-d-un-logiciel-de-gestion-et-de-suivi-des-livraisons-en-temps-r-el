const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'mysql-2f53019-glotelho.b.aivencloud.com',
  port: parseInt(process.env.DB_PORT) || 15689,
  user: process.env.DB_USER || 'avnadmin',
  password: process.env.DB_PASSWORD || 'AVNS_b9Ig3r5-y6ZhOHePhkM',
  database: process.env.DB_NAME || 'defaultdb',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 10000,
  idleTimeout: 60000,
  ssl: {
    rejectUnauthorized: false
  }
});

(async () => {
  try {
    const connection = await pool.getConnection();
    console.log('✅ [Livreur] Connecté à la base de données MySQL (Aiven)');
    connection.release();
  } catch (err) {
    console.error('❌ [Livreur] Erreur de connexion :', err.message);
    process.exit(1);
  }
})();

module.exports = pool;