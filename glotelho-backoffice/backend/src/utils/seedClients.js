const bcrypt = require('bcrypt');
const prisma = require('./prismaClient');

async function seedClients() {

    // ── CLIENTS ──
    const clientsData = [
        { last_name: 'Mbarga', first_name: 'Paul', email: 'paul.mbarga@gmail.com', phone: '677001001', address: 'Bonamoussadi, Rue des Manguiers, Douala', latitude: 4.0511, longitude: 9.7679 },
        { last_name: 'Ngo Biyong', first_name: 'Marie', email: 'marie.ngobiyong@gmail.com', phone: '699002002', address: 'Akwa, Avenue de Gaulle, Douala', latitude: 4.0490, longitude: 9.6990 },
        { last_name: 'Tchamba', first_name: 'Albert', email: 'albert.tchamba@gmail.com', phone: '655003003', address: 'Makepe, Bloc 3, Douala', latitude: 4.0620, longitude: 9.7450 },
        { last_name: 'Fouda', first_name: 'Celine', email: 'celine.fouda@gmail.com', phone: '678004004', address: 'Deido, Carrefour Ndokotti, Douala', latitude: 4.0720, longitude: 9.7100 },
        { last_name: 'Kamdem', first_name: 'Roger', email: 'roger.kamdem@gmail.com', phone: '691005005', address: 'Logpom, Cite des Palmiers, Douala', latitude: 4.0830, longitude: 9.7320 },
    ];

    var customers = [];

    for (var i = 0; i < clientsData.length; i++) {
        var c = clientsData[i];
        var user = await prisma.users.create({
            data: {
                last_name: c.last_name,
                first_name: c.first_name,
                email: c.email,
                password: await bcrypt.hash('password123', 10),
                phone: c.phone,
                role: 'customer',
            }
        });
        var customer = await prisma.customers.create({
            data: {
                user_id: user.id,
                address: c.address,
                latitude: c.latitude,
                longitude: c.longitude,
            }
        });
        customers.push(customer);
        console.log('Client cree : ' + c.first_name + ' ' + c.last_name);
    }

    // ── COMMANDES ──
    var ordersData = [
        // Paul Mbarga
        {
            customer_idx: 0,
            total_amount: 45000,
            status: 'En_cours',
            items: [
                { product_name: 'Television Samsung 43 pouces', qty: 1, to_deliver_now: true, instructions: 'Fragile - ne pas incliner - emballage bulles obligatoire' },
                { product_name: 'Support mural TV', qty: 1, to_deliver_now: true, instructions: 'Peut etre transporte normalement' },
                { product_name: 'Barre de son Samsung', qty: 1, to_deliver_now: false, instructions: 'Article en attente de stock - livraison programmee' },
            ]
        },
        // Paul Mbarga commande 2
        {
            customer_idx: 0,
            total_amount: 12500,
            status: 'En_cours',
            items: [
                { product_name: 'Fer a repasser Philips', qty: 2, to_deliver_now: true, instructions: 'Boites fragiles - eviter chocs' },
            ]
        },
        // Marie Ngo Biyong
        {
            customer_idx: 1,
            total_amount: 78000,
            status: 'En_cours',
            items: [
                { product_name: 'Climatiseur Midea 1.5 CV', qty: 1, to_deliver_now: true, instructions: 'Tres lourd - prevoir 2 livreurs - ne pas coucher sur le cote' },
                { product_name: 'Kit installation clim', qty: 1, to_deliver_now: true, instructions: 'Transporter avec le climatiseur' },
            ]
        },
        // Albert Tchamba
        {
            customer_idx: 2,
            total_amount: 31500,
            status: 'En_cours',
            items: [
                { product_name: 'Mixeur Moulinex', qty: 1, to_deliver_now: true, instructions: 'Fragile - emballage intact' },
                { product_name: 'Cafetiere DeLonghi', qty: 1, to_deliver_now: true, instructions: 'Fragile - maintenir a la verticale' },
                { product_name: 'Grille-pain Tefal', qty: 2, to_deliver_now: false, instructions: 'Rupture de stock partielle - livraison suivante' },
            ]
        },
        // Celine Fouda
        {
            customer_idx: 3,
            total_amount: 55000,
            status: 'En_cours',
            items: [
                { product_name: 'Machine a laver 7kg Hisense', qty: 1, to_deliver_now: true, instructions: 'Tres lourd - utiliser diable - ne pas incliner plus de 45 degres' },
            ]
        },
        // Roger Kamdem
        {
            customer_idx: 4,
            total_amount: 18000,
            status: 'En_cours',
            items: [
                { product_name: 'Ventilateur sur pied Binatone', qty: 3, to_deliver_now: true, instructions: 'Verifier emballage avant livraison' },
                { product_name: 'Lampes LED 15W', qty: 10, to_deliver_now: true, instructions: 'Fragiles - emballage mousse' },
                { product_name: 'Multiprise 5 prises', qty: 2, to_deliver_now: false, instructions: 'En attente de livraison fournisseur' },
            ]
        },
    ];

    for (var j = 0; j < ordersData.length; j++) {
        var od = ordersData[j];
        var order = await prisma.orders.create({
            data: {
                customer_id: customers[od.customer_idx].id,
                total_amount: od.total_amount,
                status: od.status,
            }
        });

        console.log('Commande #' + order.id + ' creee pour client idx ' + od.customer_idx + ' — ' + od.total_amount + ' FCFA');

        for (var k = 0; k < od.items.length; k++) {
            var item = od.items[k];
            await prisma.delivery_items.create({
                data: {
                    deliveryorder_id: 1,
                    order_id: order.id,
                    product_name: item.product_name,
                    delivery_instructions: item.instructions,
                    route_info: item.to_deliver_now ? 'A livrer maintenant' : 'A programmer pour une prochaine livraison',
                    status: item.to_deliver_now ? 'En_attente' : 'Programme',
                }
            });
            console.log('  Article : ' + item.product_name + (item.to_deliver_now ? ' [MAINTENANT]' : ' [PLUS TARD]'));
        }
    }

    console.log('\nSeed termine avec succes !');
    console.log(customers.length + ' clients crees');
    console.log(ordersData.length + ' commandes creees');
}

seedClients()
    .catch(e => console.error('Erreur :', e))
    .finally(() => prisma.$disconnect());