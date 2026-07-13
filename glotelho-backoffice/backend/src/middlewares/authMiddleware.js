const jwt = require('jsonwebtoken');

function authMiddleware(req, res, next) {
    var authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ message: 'Token manquant. Connexion requise.' });
    }
    var token = authHeader.split(' ')[1];
    try {
        var decoded = jwt.verify(token, process.env.JWT_SECRET || 'glotelho_secret');
        req.user = decoded;
        req.livreur = { id: decoded.livreurId || decoded.id };
        next();
    } catch (error) {
        return res.status(401).json({ message: 'Token invalide ou expire.' });
    }
}

module.exports = authMiddleware;
