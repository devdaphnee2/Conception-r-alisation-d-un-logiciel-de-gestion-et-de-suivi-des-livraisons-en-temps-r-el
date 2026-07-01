const bcrypt = require('bcrypt');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const IMG = 'https://placehold.co/600x380/2f3131/f1f1f1?font=playfair-display&text=';
// Photos de profil simulees — cadrage visage (carre, format portrait)
const FACE = 'https://placehold.co/300x300/7d5700/ffffff?text=';

const profils = [{
        last_name: 'ESSOMBA',
        first_name: 'Rodrigue',
        email: 'essomba.rodrigue@gmail.com',
        phone: '655112233',
        zone_affectee: 'Makepe',
        vehicule: { type: 'moto', plate_number: 'LT-9012-C', brand: 'Yamaha' },
        photo_profil: FACE + 'Photo+Visage%0AEssomba',
        cni_numero: 'CNI-CM-001234567',
        cni_photo_avant: IMG + 'CNI+RECTO%0AEssomba+Rodrigue',
        cni_photo_arriere: IMG + 'CNI+VERSO%0AEssomba+Rodrigue',
        permis_categorie: 'A',
        permis_photo: IMG + 'PERMIS+CAT.+A%0AEssomba+Rodrigue',
        adresse_domicile: 'Makepe Missoke, Rue des Brasseries, Douala',
        experience: '2 ans — ancien livreur Jumia Food (2021-2023). References disponibles.',
        contact_urgence_nom: 'Marie ESSOMBA',
        contact_urgence_tel: '699887766',
        caution_montant: 50000,
        caution_payee: false,
        note_manager: 'Candidature serieuse. Documents complets. Photo de profil conforme.',
    },
    {
        last_name: 'BELLO',
        first_name: 'Hamidou',
        email: 'bello.hamidou@yahoo.fr',
        phone: '677445566',
        zone_affectee: 'Bonaberi',
        vehicule: { type: 'moto', plate_number: 'LT-3456-D', brand: 'Honda' },
        photo_profil: FACE + 'Photo+Visage%0ABello',
        cni_numero: 'CNI-CM-009876543',
        cni_photo_avant: IMG + 'CNI+RECTO%0ABello+Hamidou',
        cni_photo_arriere: IMG + 'CNI+VERSO%0ABello+Hamidou',
        permis_categorie: 'A',
        permis_photo: IMG + 'PERMIS+CAT.+A%0ABello+Hamidou',
        adresse_domicile: 'Bonaberi Centre, Quartier Ndokotti, Douala',
        experience: 'Aucune experience prealable. Premiere demande.',
        contact_urgence_nom: 'Fatima BELLO',
        contact_urgence_tel: '691223344',
        caution_montant: 50000,
        caution_payee: true,
        note_manager: 'Premiere demande. Motive mais sans experience. Caution reglee.',
    },
    {
        last_name: 'MESSI ATANGANA',
        first_name: 'Christelle',
        email: 'christelle.messi@gmail.com',
        phone: '699334455',
        zone_affectee: 'Logbaba',
        vehicule: { type: 'voiture', plate_number: 'LT-7890-E', brand: 'Toyota' },
        photo_profil: null, // Photo manquante intentionnellement — pour tester l'alerte
        cni_numero: 'CNI-CM-005678901',
        cni_photo_avant: IMG + 'CNI+RECTO%0AMessi+Christelle',
        cni_photo_arriere: IMG + 'CNI+VERSO%0AMessi+Christelle',
        permis_categorie: 'B',
        permis_photo: IMG + 'PERMIS+CAT.+B%0AMessi+Christelle',
        adresse_domicile: 'Logbaba Carrefour, Face Ecole Publique, Douala',
        experience: '5 ans — ancienne livreure Jumia (2018-2023). Certifiee.',
        contact_urgence_nom: 'Paul MESSI',
        contact_urgence_tel: '677112233',
        caution_montant: 75000,
        caution_payee: true,
        note_manager: 'ATTENTION : photo de profil manquante. A demander avant approbation.',
    },
    {
        last_name: 'NKOMO',
        first_name: 'Patrick Junior',
        email: 'patrick.nkomo@hotmail.com',
        phone: '650789012',
        zone_affectee: 'Deido',
        vehicule: { type: 'moto', plate_number: 'LT-2345-F', brand: 'Suzuki' },
        photo_profil: FACE + 'Photo+Visage%0ANkomo',
        cni_numero: 'CNI-CM-004567890',
        cni_photo_avant: IMG + 'CNI+RECTO%0ANkomo+Patrick',
        cni_photo_arriere: null,
        permis_categorie: 'A',
        permis_photo: IMG + 'PERMIS+CAT.+A%0ANkomo+Patrick',
        adresse_domicile: 'Deido, Rue de la Joie, Douala',
        experience: '1 an — livraison independante quartier Deido (2023).',
        contact_urgence_nom: 'Claire NKOMO',
        contact_urgence_tel: '655334411',
        caution_montant: 50000,
        caution_payee: false,
        note_manager: 'ATTENTION : photo CNI verso manquante.',
    },
    {
        last_name: 'FOUDA MBARGA',
        first_name: 'Serge',
        email: 'serge.fouda@gmail.com',
        phone: '691567890',
        zone_affectee: 'Akwa',
        vehicule: { type: 'moto', plate_number: 'LT-6789-G', brand: 'Honda' },
        photo_profil: FACE + 'Photo+Visage%0AFouda',
        cni_numero: 'CNI-CM-003456789',
        cni_photo_avant: IMG + 'CNI+RECTO%0AFouda+Serge',
        cni_photo_arriere: IMG + 'CNI+VERSO%0AFouda+Serge',
        permis_categorie: 'A',
        permis_photo: IMG + 'PERMIS+CAT.+A%0AFouda+Serge',
        adresse_domicile: 'Akwa, Avenue de Gaulle, Imm. Azur Apt 12, Douala',
        experience: '3 ans — livreur DHL Cameroun (2020-2022). Certifie.',
        contact_urgence_nom: 'Jacqueline FOUDA',
        contact_urgence_tel: '677445500',
        caution_montant: 50000,
        caution_payee: true,
        note_manager: 'Tres bon profil. Documents complets. Caution reglee. Recommande prioritaire.',
    },
];

async function seed() {
    console.log('\n=== Seed profils enrolement V3 (avec photo profil) ===\n');

    for (const p of profils) {
        try {
            const existing = await prisma.users.findUnique({ where: { email: p.email } });
            if (existing) {
                console.log('  [IGNORE] Deja existant : ' + p.first_name + ' ' + p.last_name);
                continue;
            }

            const vehicule = await prisma.vehicules.create({
                data: { type: p.vehicule.type, plate_number: p.vehicule.plate_number, brand: p.vehicule.brand, status: 'Disponible' }
            });

            const user = await prisma.users.create({
                data: {
                    last_name: p.last_name,
                    first_name: p.first_name,
                    email: p.email,
                    password: await bcrypt.hash('password123', 10),
                    phone: p.phone,
                    role: 'delivery_person',
                }
            });

            await prisma.delivery_persons.create({
                data: {
                    user_id: user.id,
                    vehicle_id: vehicule.id,
                    zone_affectee: p.zone_affectee,
                    status: 'Indisponible',
                    available: false,
                    photo_profil: p.photo_profil,
                    cni_numero: p.cni_numero,
                    cni_photo_avant: p.cni_photo_avant,
                    cni_photo_arriere: p.cni_photo_arriere,
                    permis_categorie: p.permis_categorie,
                    permis_photo: p.permis_photo,
                    adresse_domicile: p.adresse_domicile,
                    experience: p.experience,
                    contact_urgence_nom: p.contact_urgence_nom,
                    contact_urgence_tel: p.contact_urgence_tel,
                    caution_montant: p.caution_montant,
                    caution_payee: p.caution_payee,
                    note_manager: p.note_manager,
                }
            });

            const photoStatus = p.photo_profil ? 'PHOTO OK' : 'PHOTO MANQUANTE';
            console.log('  [OK] ' + p.first_name + ' ' + p.last_name + ' — ' + photoStatus);
        } catch (err) {
            console.error('  [ERREUR] ' + p.first_name + ' : ' + err.message);
        }
    }

    const total = await prisma.delivery_persons.count({ where: { status: 'Indisponible' } });
    console.log('\n' + total + ' profil(s) en attente dans la base.\n');
}

seed().catch(e => { console.error(e);
    process.exit(1); }).finally(() => prisma.$disconnect());