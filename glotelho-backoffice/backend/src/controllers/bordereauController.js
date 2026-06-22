const prisma = require('../utils/prismaClient');
const PDFDocument = require('pdfkit');
const path = require('path');

function genererNumero(id) {
    var prefix = 'GLT';
    var date = new Date();
    var annee = date.getFullYear().toString().slice(-2);
    var mois = String(date.getMonth() + 1).padStart(2, '0');
    var random = Math.random().toString(36).substring(2, 6).toUpperCase();
    return prefix + annee + mois + '-' + String(id).padStart(4, '0') + '-' + random;
}

async function generer(req, res) {
    try {
        var livraison = await prisma.deliveryorders.findUnique({
            where: { id: parseInt(req.params.id) },
            include: {
                customers: { include: { users: true } },
                delivery_persons: { include: { users: true, vehicules: true } },
                managers: { include: { users: true } },
                delivery_items: true,
            }
        });

        if (!livraison) {
            return res.status(404).json({ message: 'Livraison introuvable.' });
        }

        var existing = await prisma.bordereaux.findFirst({
            where: { deliveryorder_id: livraison.id }
        });

        if (!existing) {
            var manager = await prisma.managers.findUnique({
                where: { user_id: req.user.id }
            });
            await prisma.bordereaux.create({
                data: {
                    deliveryorder_id: livraison.id,
                    generated_by_manager_id: manager.id,
                    status: 'Genere',
                }
            });
        }

        var numero = genererNumero(livraison.id);

        // Page A4 taille fixe, pas de pagination automatique
        var doc = new PDFDocument({
            margin: 0,
            size: 'A4',
            autoFirstPage: true,
            bufferPages: true,
        });

        res.setHeader('Content-Type', 'application/pdf');
        res.setHeader('Content-Disposition', 'attachment; filename=bordereau_' + livraison.id + '.pdf');
        doc.pipe(res);

        var W = 595;
        var H = 842;
        var PL = 40;
        var PR = 40;
        var col1 = PL;
        var col2 = 310;
        var colW = (W - PL - PR - 20) / 2;

        // ── HEADER ──
        doc.rect(0, 0, W, 80).fill('#0F0F1A');

        // Logo
        var logoPath = path.join(__dirname, '..', 'public', 'logo_glotelho.png');
        try {
            doc.image(logoPath, PL, 10, { height: 55 });
        } catch (e) {
            doc.fillColor('white').fontSize(22).font('Helvetica-Bold').text('GLOTELHO', PL, 25);
        }

        doc.fillColor('#E8580A').fontSize(11).font('Helvetica-Bold')
            .text('BORDEREAU DE LIVRAISON', 200, 18, { width: W - 240, align: 'right' });
        doc.fillColor('white').fontSize(9).font('Helvetica')
            .text(numero, 200, 34, { width: W - 240, align: 'right' });
        doc.fillColor('#8A8AA3').fontSize(8).font('Helvetica')
            .text('Back-office de gestion des livraisons', 200, 48, { width: W - 240, align: 'right' });

        // Statut badge
        var statusLabel = (livraison.status || '').replace('_', ' ');
        doc.roundedRect(PL, 88, 120, 20, 6).fill('#FFF1E8');
        doc.fillColor('#E8580A').fontSize(9).font('Helvetica-Bold')
            .text('Statut : ' + statusLabel, PL + 8, 93);

        doc.fillColor('#8A8AA3').fontSize(8).font('Helvetica')
            .text('Ref : ' + numero, W - PR - 160, 93, { width: 160, align: 'right' });

        var y = 120;

        function sep(yPos) {
            doc.moveTo(PL, yPos).lineTo(W - PR, yPos).strokeColor('#ECECF2').lineWidth(0.5).stroke();
        }

        function sectionTitle(label, yPos) {
            doc.rect(PL, yPos, W - PL - PR, 16).fill('#F5F5F8');
            doc.fillColor('#1C1C2E').fontSize(9).font('Helvetica-Bold').text(label, PL + 6, yPos + 4);
            return yPos + 22;
        }

        function cell(label, value, x, yPos, w) {
            doc.fillColor('#8A8AA3').fontSize(7.5).font('Helvetica').text(label, x, yPos, { width: w || colW });
            doc.fillColor('#1C1C2E').fontSize(9).font('Helvetica-Bold').text(value || '—', x, yPos + 10, { width: w || colW });
            return yPos + 24;
        }

        // ── SECTION LIVRAISON ──
        y = sectionTitle('INFORMATIONS DE LIVRAISON', y);

        cell('Adresse de livraison', livraison.delivery_address, col1, y);
        cell('Zone / Bloc', livraison.zone_bloc || '—', col2, y);
        y += 24;

        cell('Montant a recouvrer', livraison.amount_to_collect ? livraison.amount_to_collect + ' FCFA' : '—', col1, y);
        cell('Date de livraison', livraison.delivery_date ? new Date(livraison.delivery_date).toLocaleDateString('fr-FR') : '—', col2, y);
        y += 24;

        cell('Date de creation', new Date(livraison.creation_date).toLocaleDateString('fr-FR'), col1, y);
        y += 28;

        sep(y);
        y += 8;

        // ── SECTION CLIENT ──
        y = sectionTitle('CLIENT DESTINATAIRE', y);

        var cFN = livraison.customers && livraison.customers.users ? livraison.customers.users.first_name : '';
        var cLN = livraison.customers && livraison.customers.users ? livraison.customers.users.last_name : '';
        var cPhone = livraison.customers && livraison.customers.users ? livraison.customers.users.phone : '—';
        var cAddr = livraison.customers && livraison.customers.address ? livraison.customers.address : null;
        var cLat = livraison.customers && livraison.customers.latitude ? livraison.customers.latitude : null;
        var cLng = livraison.customers && livraison.customers.longitude ? livraison.customers.longitude : null;

        cell('Nom complet', cFN + ' ' + cLN, col1, y);
        cell('Telephone', cPhone, col2, y);
        y += 24;

        if (cAddr) {
            cell('Adresse du client', cAddr, col1, y, W - PL - PR);
            y += 24;
        }
        if (cLat && cLng) {
            cell('Coordonnees GPS', cLat + ', ' + cLng, col1, y, W - PL - PR);
            y += 24;
        }

        y += 4;
        sep(y);
        y += 8;

        // ── SECTION LIVREUR ──
        y = sectionTitle('LIVREUR ASSIGNE', y);

        if (livraison.delivery_persons) {
            var lFN = livraison.delivery_persons.users ? livraison.delivery_persons.users.first_name : '';
            var lLN = livraison.delivery_persons.users ? livraison.delivery_persons.users.last_name : '';
            var lPhone = livraison.delivery_persons.users ? livraison.delivery_persons.users.phone : '—';
            var lVeh = livraison.delivery_persons.vehicules ?
                livraison.delivery_persons.vehicules.brand + ' ' + livraison.delivery_persons.vehicules.type + ' — ' + livraison.delivery_persons.vehicules.plate_number :
                '—';
            var lZone = livraison.delivery_persons.zone_affectee || '—';

            cell('Nom complet', lFN + ' ' + lLN, col1, y);
            cell('Telephone', lPhone, col2, y);
            y += 24;
            cell('Vehicule', lVeh, col1, y);
            cell('Zone affectee', lZone, col2, y);
            y += 24;
        } else {
            doc.fillColor('#8A8AA3').fontSize(9).font('Helvetica').text('Aucun livreur assigne', col1, y);
            y += 24;
        }

        y += 4;
        sep(y);
        y += 8;

        // ── SECTION MANAGER ──
        y = sectionTitle('MANAGER', y);

        var mFN = livraison.managers && livraison.managers.users ? livraison.managers.users.first_name : '';
        var mLN = livraison.managers && livraison.managers.users ? livraison.managers.users.last_name : '';
        cell('Cree par', mFN + ' ' + mLN, col1, y, W - PL - PR);
        y += 28;

        sep(y);
        y += 12;

        // ── PIED DE PAGE ──
        var footerY = H - 30;
        doc.rect(0, footerY - 8, W, 38).fill('#0F0F1A');
        doc.fillColor('#8A8AA3').fontSize(7.5).font('Helvetica')
            .text(
                'Genere le ' + new Date().toLocaleDateString('fr-FR') + '  |  ' + numero + '  |  Glotelho Back-office',
                PL, footerY, { width: W - PL - PR, align: 'center' }
            );

        doc.end();

    } catch (error) {
        console.error('Erreur bordereau :', error);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

module.exports = { generer };