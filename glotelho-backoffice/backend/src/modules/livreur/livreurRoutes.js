const express        = require('express');
const router         = express.Router();
const authMiddleware = require('../../middlewares/authMiddleware');
const livreurOnly    = require('../../middlewares/livreurOnly');
const ctrl           = require('./livreurController');

// ── PUBLIQUES ─────────────────────────────────────────────────
router.post('/register', ctrl.register);
router.post('/login',    require('../auth/authController').loginMobile);
router.post('/auth/google', require('../auth/authController').loginMobile); // placeholder
router.post('/forgot-password', require('../auth/authController').forgotPassword);
router.post('/reset-password',  require('../auth/authController').resetPassword);

// ── PROTEGEES (livreur connecte) ─────────────────────────────
router.use(authMiddleware);

router.get   ('/me',               ctrl.getMe);
router.put   ('/me',               ctrl.updateMe);
router.post  ('/logout',           require('../auth/authController').logout);
router.patch ('/fcm-token',        require('../auth/authController').updateFcmToken);
router.patch ('/change-password',  require('../auth/authController').changePassword);
router.post  ('/disponibilite',    livreurOnly, ctrl.toggleDisponibilite);

// Courses
router.get  ('/courses',                  livreurOnly, ctrl.getCourses);
router.get  ('/historique',               livreurOnly, ctrl.getHistorique);
router.post ('/courses/:id/accepter',     livreurOnly, ctrl.accepterCourse);
router.post ('/courses/:id/refuser',      livreurOnly, ctrl.refuserCourse);
router.post ('/courses/:id/demarrer',     livreurOnly, ctrl.demarrerCourse);
router.post ('/courses/:id/position',     livreurOnly, ctrl.updatePosition);
router.post ('/courses/:id/cloturer',     livreurOnly, ctrl.cloturerCourse);
router.post ('/courses/:id/incident',     livreurOnly, ctrl.signalerIncident);

// Compatibilite ancienne structure /api/mobile/livreur/...
router.get  ('/profil',                   livreurOnly, ctrl.getMe);
router.post ('/fcm-token',                ctrl.updateMe);

module.exports = router;
