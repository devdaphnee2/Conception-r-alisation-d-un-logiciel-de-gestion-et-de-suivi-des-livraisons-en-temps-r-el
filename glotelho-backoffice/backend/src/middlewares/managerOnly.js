function managerOnly(req, res, next) {
    if (!req.user || req.user.role !== 'manager') {
        return res.status(403).json({ message: 'Accès réservé aux managers.' });
    }
    next();
}

module.exports = managerOnly;