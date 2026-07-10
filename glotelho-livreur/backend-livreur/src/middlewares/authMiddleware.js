const jwt = require('jsonwebtoken');
const pool = require('../config/db');

const authMiddleware = async (req, res, next) => {
  const header = req.headers['authorization'];
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Non authentifié' });
  }

  const token = header.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    if (!decoded.livreurId) {
      return res.status(401).json({ message: 'Token invalide' });
    }

    const connection = await pool.getConnection();
    try {
      const [rows] = await connection.query(
        `SELECT dp.id, dp.status, u.email
         FROM delivery_persons dp
         JOIN users u ON u.id = dp.user_id
         WHERE dp.id = ?`,
        [decoded.livreurId]
      );

      if (!rows.length) {
        return res.status(401).json({ message: 'Non authentifié' });
      }

      req.livreur = {
        id: decoded.livreurId,
        status: rows[0].status,
        email: rows[0].email
      };

      next();
    } finally {
      connection.release();
    }
  } catch (err) {
    console.error('[authMiddleware] Erreur:', err.message);
    return res.status(401).json({ message: 'Non authentifié' });
  }
};

module.exports = authMiddleware;