const bcrypt = require('bcrypt');
const prisma = require('./prismaClient');

async function seedData() {

    // Client test
    const clientUser = await prisma.users.create({
        data: {
            last_name: 'Mbarga',
            first_name: 'Paul',
            email: 'client@glotelho.com',
            password: await bcrypt.hash('password123', 10),
            phone: '677000001',
            role: 'customer',
        }
    });

    await prisma.customers.create({
        data: {
            user_id: clientUser.id,
            address: 'Bonamoussadi, Douala',
        }
    });

    // Vehicule test
    const vehicule = await prisma.vehicules.create({
        data: {
            type: 'moto',
            plate_number: 'LT-1234-A',
            brand: 'Honda',
            status: 'Disponible',
        }
    });

    // Livreur test
    const livreurUser = await prisma.users.create({
        data: {
            last_name: 'Kamga',
            first_name: 'Eric',
            email: 'livreur@glotelho.com',
            password: await bcrypt.hash('password123', 10),
            phone: '699000002',
            role: 'delivery_person',
        }

    });

    await prisma.delivery_persons.create({
        data: {
            user_id: livreurUser.id,
            vehicle_id: vehicule.id,
            status: 'Disponible',
            available: true,
            zone_affectee: 'Bonamoussadi',
        }
    });

    console.log('Donnees de test creees avec succes');
}

seedData()
    .catch(e => console.error('Erreur :', e))
    .finally(() => prisma.$disconnect());