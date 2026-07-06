// backend/src/config/firebaseAdmin.js
// Initialisation Firebase Admin SDK — une seule instance
const admin = require('firebase-admin');
const path = require('path');

let db = null;

function getFirebaseDB() {
    if (db) return db;

    try {
        const serviceAccount = require('./firebase-admin.json');

        if (!admin.apps.length) {
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
                databaseURL: process.env.FIREBASE_DATABASE_URL ||
                    'https://glotelho-livraison-default-rtdb.europe-west1.firebasedatabase.app'
            });
        }

        db = admin.database();
        console.log('[Firebase Admin] Connexion Realtime Database OK');
        return db;
    } catch (err) {
        console.warn('[Firebase Admin] Non configure :', err.message);
        return null;
    }
}

module.exports = { getFirebaseDB };