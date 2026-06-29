// Middleware : acces reserve aux livreurs (role delivery_person)
function livreurOnly(req, res, next) {
    if (req.user ? .role !== 'delivery_person') {
        return res.status(403).json({ message: 'Acces reserve aux livreurs.' });
    }
    next();
}

module.exports = livreurOnly;