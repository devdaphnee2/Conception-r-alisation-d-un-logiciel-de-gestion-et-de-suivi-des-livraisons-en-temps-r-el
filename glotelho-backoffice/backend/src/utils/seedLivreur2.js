const bcrypt = require('bcrypt');
const prisma = require('./prismaClient');

async function run() {
    const v = await prisma.vehicules.create({
        data: {
            type: 'voiture',
            plate_number: 'LT-5678-B',
            brand: 'Toyota',
            status: 'Disponible'
        }
    });

    const u = await prisma.users.create({
        data: {
            last_name: 'Nkoulou',
            first_name: 'Jean',
            email: 'livreur2@glotelho.com',
            password: await bcrypt.hash('password123', 10),
            phone: '699000003',
            role: 'delivery_person'
        }
    });

    await prisma.delivery_persons.create({
        data: {
            user_id: u.id,
            vehicle_id: v.id,
            status: 'Disponible',
            available: true,
            zone_affectee: 'Akwa'
        }
    });

    console.log('Livreur 2 cree avec succes');
}

run()
    .catch(e => console.error('Erreur :', e))
    .finally(() => prisma.$disconnect());