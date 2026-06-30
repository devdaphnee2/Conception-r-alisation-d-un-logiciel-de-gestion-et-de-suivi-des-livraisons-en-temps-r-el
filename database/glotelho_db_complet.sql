-- ═══════════════════════════════════════════════════════════════
-- BASE DE DONNÉES GLOTELHO — SYSTÈME DE SUIVI DES LIVRAISONS
-- ═══════════════════════════════════════════════════════════════
-- 18 tables — Architecture relationnelle MySQL (CORRIGÉ)
-- ═══════════════════════════════════════════════════════════════

DROP DATABASE IF EXISTS glotelho_db;
CREATE DATABASE glotelho_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE glotelho_db;

SET FOREIGN_KEY_CHECKS = 0;

-- ═══════════════════════════════════════════════════════════════
-- 1. USERS — Authentification centralisée avec fcm_token pour FCM
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE users (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    last_name       VARCHAR(100) NOT NULL,
    first_name      VARCHAR(100) NOT NULL,
    email           VARCHAR(150) UNIQUE NOT NULL,
    password        VARCHAR(255) NOT NULL,
    phone           VARCHAR(20) NOT NULL,
    role            ENUM('manager','delivery_person','customer') NOT NULL,
    fcm_token       VARCHAR(255) NULL COMMENT 'Token Firebase pour notifications push',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_role (role),
    INDEX idx_email (email)
) ENGINE=InnoDB COMMENT='Table parent : tous les utilisateurs du système';

-- ═══════════════════════════════════════════════════════════════
-- 2. VEHICULES — Flotte de véhicules (déplacée AVANT delivery_persons)
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE vehicules (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    type            VARCHAR(50) NOT NULL COMMENT 'moto, voiture, tricycle, vélo, etc',
    plate_number    VARCHAR(30) UNIQUE NOT NULL COMMENT 'Numéro de plaque',
    brand           VARCHAR(50) NULL COMMENT 'Marque du véhicule',
    status          ENUM('Disponible','En_cours_dutilisation','En_maintenance') DEFAULT 'Disponible',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Catalogue des véhicules de la flotte';

-- ═══════════════════════════════════════════════════════════════
-- 3. MANAGERS — Lien user ↔ manager pour les permissions
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE managers (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    user_id         INT UNIQUE NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Profil manager avec permissions de gestion';

-- ═══════════════════════════════════════════════════════════════
-- 4. DELIVERY_PERSONS — Profil livreur avec statut service et zone affectée
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE delivery_persons (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    user_id         INT UNIQUE NOT NULL,
    vehicle_id      INT NULL,
    status          ENUM('Disponible','En_livraison','Indisponible','Suspendu','Hors_service') DEFAULT 'Disponible' COMMENT 'Statut actuel du livreur',
    zone_affectee   VARCHAR(100) NULL COMMENT 'Zone ou bloc géographique de livraison',
    available       TINYINT(1) DEFAULT 1,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (vehicle_id) REFERENCES vehicules(id) ON DELETE SET NULL,
    INDEX idx_status (status)
) ENGINE=InnoDB COMMENT='Profil livreur avec zone et statut service';

-- ═══════════════════════════════════════════════════════════════
-- 5. CUSTOMERS — Profil client avec adresse de livraison (lat/lng)
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE customers (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    user_id         INT UNIQUE NOT NULL,
    address         VARCHAR(255) NULL COMMENT 'Adresse textuelle de livraison',
    latitude        DECIMAL(10,8) NULL COMMENT 'Coordonnée GPS latitude du domicile',
    longitude       DECIMAL(11,8) NULL COMMENT 'Coordonnée GPS longitude du domicile',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Profil client avec adresse et coordonnées GPS';

-- ═══════════════════════════════════════════════════════════════
-- 6. ORDERS — Commandes e-commerce depuis Glotelho
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE orders (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    customer_id     INT NOT NULL,
    status          VARCHAR(50) DEFAULT 'En_cours' COMMENT 'En_cours, Payée, Livrée, Annulée',
    total_amount    DECIMAL(10,2) NOT NULL COMMENT 'Montant total de la commande',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    INDEX idx_customer (customer_id),
    INDEX idx_status (status),
    INDEX idx_created (created_at)
) ENGINE=InnoDB COMMENT='Commandes e-commerce de Glotelho';

-- ═══════════════════════════════════════════════════════════════
-- 7. DELIVERYORDERS — CŒUR du système : chaque livraison à effectuer
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE deliveryorders (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    manager_id              INT NOT NULL COMMENT 'Manager qui a créé la livraison',
    delivery_person_id      INT NULL COMMENT 'Livreur assigné',
    customer_id             INT NOT NULL COMMENT 'Client destinataire',
    status                  ENUM('En_attente','Assigné','En_cours','Livré','Suspendu','Annulé') DEFAULT 'En_attente' COMMENT 'État de la livraison',
    delivery_address        VARCHAR(255) NOT NULL COMMENT 'Adresse de destination',
    delivery_latitude       DECIMAL(10,8) NULL COMMENT 'GPS latitude destination',
    delivery_longitude      DECIMAL(11,8) NULL COMMENT 'GPS longitude destination',
    zone_bloc               VARCHAR(100) NULL COMMENT 'Zone ou bloc pour assignation',
    amount_to_collect       DECIMAL(10,2) DEFAULT 0 COMMENT 'Montant à recouvrer',
    collected_amount        DECIMAL(10,2) DEFAULT 0 COMMENT 'Montant effectivement collecté',
    estimated_delivery_time DATETIME NULL COMMENT 'ETA estimée',
    creation_date           TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Création de la livraison',
    delivery_date           DATETIME NULL COMMENT 'Date/heure de livraison réelle',
    suspension_reason       TEXT NULL COMMENT 'Raison de suspension si suspendue',
    tracking_blocked        TINYINT(1) DEFAULT 0 COMMENT 'Si 1, suivi GPS désactivé',
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (manager_id) REFERENCES managers(id),
    FOREIGN KEY (delivery_person_id) REFERENCES delivery_persons(id) ON DELETE SET NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    INDEX idx_status (status),
    INDEX idx_delivery_person (delivery_person_id),
    INDEX idx_customer (customer_id),
    INDEX idx_created (creation_date)
) ENGINE=InnoDB COMMENT='CŒUR du système : chaque livraison à effectuer';

-- ═══════════════════════════════════════════════════════════════
-- 8. DELIVERY_ITEMS — Articles/colis dans une livraison
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE delivery_items (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    deliveryorder_id        INT NOT NULL,
    order_id                INT NOT NULL,
    product_name            VARCHAR(255) NOT NULL COMMENT 'Nom du produit/colis',
    delivery_instructions   TEXT NULL COMMENT 'Instructions spéciales de livraison',
    route_info              TEXT NULL COMMENT 'Informations d\'itinéraire',
    status                  VARCHAR(50) DEFAULT 'En_attente' COMMENT 'État du colis',
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (deliveryorder_id) REFERENCES deliveryorders(id) ON DELETE CASCADE,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Articles/colis contenus dans une livraison';

-- ═══════════════════════════════════════════════════════════════
-- 9. RACES — Tournée/course d'un livreur pour un jour
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE races (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    delivery_person_id      INT NOT NULL COMMENT 'Livreur effectuant la course',
    vehicle_id              INT NULL COMMENT 'Véhicule utilisé',
    departure_time          DATETIME NULL COMMENT 'Heure de départ de la journée',
    return_time             DATETIME NULL COMMENT 'Heure de retour à l\'agence',
    status                  ENUM('En_attente','En_cours','Terminée') DEFAULT 'En_attente' COMMENT 'État de la course',
    report                  TEXT NULL COMMENT 'Rapport global de la journée',
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (delivery_person_id) REFERENCES delivery_persons(id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicules(id),
    INDEX idx_status (status),
    INDEX idx_delivery_person (delivery_person_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB COMMENT='Tournée/course d\'un livreur pour un jour';

-- ═══════════════════════════════════════════════════════════════
-- 10. RACE_DELIVERYORDERS — Liaison : une course regroupe plusieurs livraisons
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE race_deliveryorders (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    race_id                 INT NOT NULL,
    deliveryorder_id        INT NOT NULL,
    sequence_order          INT NULL COMMENT 'Ordre de passage dans la course',
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (race_id) REFERENCES races(id) ON DELETE CASCADE,
    FOREIGN KEY (deliveryorder_id) REFERENCES deliveryorders(id) ON DELETE CASCADE,
    INDEX idx_race (race_id)
) ENGINE=InnoDB COMMENT='Liaison : une course regroupe plusieurs livraisons';

-- ═══════════════════════════════════════════════════════════════
-- 11. POSITION_TRACKING — Historique GPS pour chaque livreur (temps réel)
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE position_tracking (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    race_id                 INT NOT NULL,
    delivery_person_id      INT NOT NULL,
    latitude                DECIMAL(10,8) NOT NULL COMMENT 'Coordonnée GPS latitude',
    longitude               DECIMAL(11,8) NOT NULL COMMENT 'Coordonnée GPS longitude',
    speed                   FLOAT NULL COMMENT 'Vitesse enregistrée en km/h',
    recorded_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Moment de l\'enregistrement',
    FOREIGN KEY (race_id) REFERENCES races(id) ON DELETE CASCADE,
    FOREIGN KEY (delivery_person_id) REFERENCES delivery_persons(id),
    INDEX idx_recorded (recorded_at),
    INDEX idx_race (race_id),
    INDEX idx_delivery_person (delivery_person_id)
) ENGINE=InnoDB COMMENT='Historique GPS temps réel de chaque livreur';

-- ═══════════════════════════════════════════════════════════════
-- 12. PHOTOS — Photos du colis/signature prise par le livreur
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE photos (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    deliveryorder_id        INT NOT NULL,
    delivery_person_id      INT NOT NULL,
    path                    VARCHAR(255) NOT NULL COMMENT 'Chemin/URL de stockage',
    taken_at                TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Date/heure de la photo',
    FOREIGN KEY (deliveryorder_id) REFERENCES deliveryorders(id) ON DELETE CASCADE,
    FOREIGN KEY (delivery_person_id) REFERENCES delivery_persons(id)
) ENGINE=InnoDB COMMENT='Photos du colis/signature prises par le livreur';

-- ═══════════════════════════════════════════════════════════════
-- 13. CONFIRMATIONS — Confirmation de réception OTP/Signature du client
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE confirmations (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    deliveryorder_id        INT NOT NULL,
    customer_id             INT NOT NULL,
    delivery_person_id      INT NOT NULL,
    methode                 ENUM('OTP','Signature') NOT NULL COMMENT 'Méthode de confirmation',
    otp_code                VARCHAR(10) NULL COMMENT 'Code OTP saisi (NULL si signature)',
    signature_path          VARCHAR(255) NULL COMMENT 'Chemin signature digitale (NULL si OTP)',
    confirmed_at            DATETIME NULL COMMENT 'Date/heure de confirmation',
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (deliveryorder_id) REFERENCES deliveryorders(id),
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (delivery_person_id) REFERENCES delivery_persons(id)
) ENGINE=InnoDB COMMENT='Confirmation de réception OTP ou signature du client';

-- ═══════════════════════════════════════════════════════════════
-- 14. RAPPORTS — Rapport de livraison rédigé par le livreur
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE rapports (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    deliveryorder_id        INT NOT NULL,
    delivery_person_id      INT NOT NULL,
    observations            TEXT NULL COMMENT 'Observations du livreur',
    photo_url               VARCHAR(255) NULL COMMENT 'Photo additionnelle',
    status_report           VARCHAR(50) DEFAULT 'Soumis' COMMENT 'Soumis, Validé, Rejeté',
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (deliveryorder_id) REFERENCES deliveryorders(id),
    FOREIGN KEY (delivery_person_id) REFERENCES delivery_persons(id),
    INDEX idx_status (status_report)
) ENGINE=InnoDB COMMENT='Rapport de livraison rédigé par le livreur';

-- ═══════════════════════════════════════════════════════════════
-- 15. NOTIFICATIONS — Notifications FCM/SMS/internes à tous les acteurs
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE notifications (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    recipient_id            INT NOT NULL COMMENT 'Utilisateur destinataire',
    message                 TEXT NOT NULL COMMENT 'Contenu du message',
    type                    ENUM('FCM','SMS','Interne') DEFAULT 'FCM' COMMENT 'Type de notification',
    is_read                 TINYINT(1) DEFAULT 0 COMMENT 'Si lue ou non',
    sent_at                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Date/heure d\'envoi',
    FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_recipient (recipient_id),
    INDEX idx_read (is_read),
    INDEX idx_sent (sent_at)
) ENGINE=InnoDB COMMENT='Notifications FCM/SMS/internes à tous les acteurs';

-- ═══════════════════════════════════════════════════════════════
-- 16. RECOUVREMENT — Suivi des paiements collectés par le livreur
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE recouvrement (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    deliveryorder_id        INT NOT NULL,
    delivery_person_id      INT NOT NULL,
    amount_to_collect       DECIMAL(10,2) NOT NULL COMMENT 'Montant à recouvrer',
    amount_collected        DECIMAL(10,2) NOT NULL COMMENT 'Montant effectivement reçu',
    payment_method          ENUM('Espèces','OM','MoMo','Carte','Autre') NOT NULL COMMENT 'Mode de paiement',
    reference_number        VARCHAR(100) NULL COMMENT 'N° de transaction (OM, MoMo, etc)',
    collected_at            DATETIME NULL COMMENT 'Date/heure du paiement',
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (deliveryorder_id) REFERENCES deliveryorders(id),
    FOREIGN KEY (delivery_person_id) REFERENCES delivery_persons(id),
    INDEX idx_collected (collected_at)
) ENGINE=InnoDB COMMENT='Suivi des paiements collectés par le livreur';

-- ═══════════════════════════════════════════════════════════════
-- 17. REMISES_COMPENSATIONS — Gestion des rabais, retours, livraisons gratuites
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE remises_compensations (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    order_id                INT NOT NULL COMMENT 'Commande concernée',
    type                    ENUM('Retour_produit','Rabais','Livraison_gratuite','Autre') NOT NULL COMMENT 'Type de compensation',
    reason                  TEXT NOT NULL COMMENT 'Raison de la compensation',
    amount                  DECIMAL(10,2) NULL COMMENT 'Montant de la compensation',
    approved_by_manager_id  INT NOT NULL COMMENT 'Manager qui approuve',
    status                  ENUM('Approuvée','En_attente','Rejetée') DEFAULT 'En_attente' COMMENT 'État de la compensation',
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (approved_by_manager_id) REFERENCES managers(id),
    INDEX idx_status (status)
) ENGINE=InnoDB COMMENT='Gestion des rabais, retours, livraisons gratuites';

-- ═══════════════════════════════════════════════════════════════
-- 18. BORDEREAUX — Bordereaux générés et imprimables pour le livreur
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE bordereaux (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    deliveryorder_id        INT NOT NULL,
    generated_by_manager_id INT NOT NULL COMMENT 'Manager ayant généré',
    pdf_path                VARCHAR(255) NULL COMMENT 'Chemin du PDF généré',
    status                  ENUM('Généré','Imprimé','Distribué') DEFAULT 'Généré' COMMENT 'État du bordereau',
    generated_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Date de génération',
    FOREIGN KEY (deliveryorder_id) REFERENCES deliveryorders(id),
    FOREIGN KEY (generated_by_manager_id) REFERENCES managers(id),
    INDEX idx_status (status)
) ENGINE=InnoDB COMMENT='Bordereaux générés et imprimables pour le livreur';

SET FOREIGN_KEY_CHECKS = 1;

-- ═══════════════════════════════════════════════════════════════
-- INDICES SUPPLÉMENTAIRES POUR OPTIMISATION
-- (idx_notations_delivery supprimé : table "notations" inexistante)
-- ═══════════════════════════════════════════════════════════════
CREATE INDEX idx_deliveryorders_zone ON deliveryorders(zone_bloc);
CREATE INDEX idx_position_delivery_person ON position_tracking(delivery_person_id);
CREATE INDEX idx_photos_delivery ON photos(deliveryorder_id);
CREATE INDEX idx_confirmations_delivery ON confirmations(deliveryorder_id);
CREATE INDEX idx_rapports_delivery ON rapports(deliveryorder_id);
CREATE INDEX idx_recouvrement_delivery ON recouvrement(deliveryorder_id);

-- ═══════════════════════════════════════════════════════════════
-- FIN DU SCRIPT
-- ═══════════════════════════════════════════════════════════════


ALTER TABLE bordereaux 
MODIFY COLUMN status ENUM('Genere','Imprime','Distribue') DEFAULT 'Genere';



-- Table des tokens de réinitialisation de mot de passe
CREATE TABLE IF NOT EXISTS password_resets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_token (token)
) ENGINE=InnoDB COMMENT='Tokens de réinitialisation de mot de passe';