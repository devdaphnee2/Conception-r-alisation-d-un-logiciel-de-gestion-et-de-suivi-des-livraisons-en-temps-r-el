const bcrypt = require('bcrypt');
const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();

async function run() {
    const hash = await bcrypt.hash('password123', 10);

    const v = await p.vehicules.create({
        data: { type: 'moto', plate_number: 'LT-9999-X', brand: 'Honda', status: 'Disponible' }
    });

    const u = await p.users.create({
        data: { first_name: 'Eric', last_name: 'Kamga', email: 'eric.kamga@glotelho.cm', password: hash, phone: '655000001', role: 'delivery_person' }
    });

    await p.delivery_persons.create({
        data: { user_id: u.id, vehicle_id: v.id, zone_affectee: 'Bonamoussadi', status: 'Disponible', available: true }
    });

    console.log('Livreur cree : eric.kamga@glotelho.cm / password123');
}

run().catch(console.error).finally(() => p.$disconnect());