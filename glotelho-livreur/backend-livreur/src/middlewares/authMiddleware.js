const jwt  = require('jsonwebtoken');
const pool = require('../config/db');

const authMiddleware = async (req, res, next) => {
  const header = req.headers['authorization'];
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Non authentifié' });
  }

  const token = header.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const [rows] = await pool.query(
      `SELECT dp.id, dp.account_status AS status, u.email
       FROM delivery_persons dp
       JOIN users u ON u.id = dp.user_id
       WHERE dp.id = ?`,
      [decoded.livreurId]
    );

    if (!rows.length) {
      return res.status(401).json({ message: 'Non authentifié' });
    }

    req.livreur = { id: decoded.livreurId };
    next();
  } catch {
    return res.status(401).json({ message: 'Non authentifié' });
  }
};

module.exports = authMiddleware;