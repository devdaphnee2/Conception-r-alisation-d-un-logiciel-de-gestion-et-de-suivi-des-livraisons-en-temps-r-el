const express = require('express');
const router = express.Router();
const authMiddleware = require('../middlewares/authMiddleware');
const livreurOnly = require('../middlewares/livreurOnly');
const ctrl = require('../controllers/livreurMobileController');

router.use(authMiddleware, livreurOnly);

// Profil
router.get('/profil', ctrl.getProfil);
router.post('/fcm-token', ctrl.updateFcmToken);
router.post('/disponibilite', ctrl.toggleDisponibilite);

// Courses
router.get('/courses', ctrl.getCourses);
router.get('/historique', ctrl.getHistorique);
router.post('/courses/:id/accepter', ctrl.accepterCourse);
router.post('/courses/:id/refuser', ctrl.refuserCourse);
router.post('/courses/:id/demarrer', ctrl.demarrerCourse);
router.post('/courses/:id/position', ctrl.updatePosition);
router.post('/courses/:id/arrivee', ctrl.signalerArrivee);
router.post('/courses/:id/cloturer', ctrl.cloturerCourse);
router.post('/courses/:id/incident', ctrl.signalerIncident);

module.exports = router;