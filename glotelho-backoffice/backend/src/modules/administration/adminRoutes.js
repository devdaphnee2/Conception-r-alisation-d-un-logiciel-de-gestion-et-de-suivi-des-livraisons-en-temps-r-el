const express        = require('express');
const router         = express.Router();
const authMiddleware = require('../../middlewares/authMiddleware');
const managerOnly    = require('../../middlewares/managerOnly');

router.use(authMiddleware, managerOnly);
module.exports = router;

const livreurRouter      = require('./livreurRoutesAdminRoutes');
const litigeRouter       = require('./litigeRoutesAdminRoutes');
const recouvrementRouter = require('./recouvrementRoutesAdminRoutes');
const profilRouter       = require('./profilAdminRoutes');
const bordereauRouter    = require('./bordereauAdminRoutes');

module.exports.livreurRouter      = livreurRouter;
module.exports.litigeRouter       = litigeRouter;
module.exports.recouvrementRouter = recouvrementRouter;
module.exports.profilRouter       = profilRouter;
module.exports.bordereauRouter    = bordereauRouter;
