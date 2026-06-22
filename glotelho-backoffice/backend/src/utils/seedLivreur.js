const bcrypt = require('bcrypt');
const prisma = require('./prismaClient');

async function run() {
    const v = await prisma.vehicules.create({
        data: {
            type: 'moto',
            plate_number: 'LT-1234-A',
            brand: 'Honda',
            status: 'Disponible'
        }
    });

    const u = await prisma.users.create({
        data: {
            last_name: 'Kamga',
            first_name: 'Eric',
            email: 'livreur@glotelho.com',
            password: await bcrypt.hash('password123', 10),
            phone: '699000002',
            role: 'delivery_person'
        }
    });

    await prisma.delivery_persons.create({
        data: {
            user_id: u.id,
            vehicle_id: v.id,
            status: 'Disponible',
            available: true,
            zone_affectee: 'Bonamoussadi'
        }
    });

    console.log('Livreur et vehicule crees avec succes');
}

run()
    .catch(e => console.error('Erreur :', e))
    .finally(() => prisma.$disconnect());