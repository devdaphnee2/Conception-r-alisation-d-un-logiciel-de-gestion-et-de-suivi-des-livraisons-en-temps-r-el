-- ═══════════════════════════════════════════════════════════════
-- BASE DE DONNÉES GLOTELHO — SYSTÈME DE SUIVI DES LIVRAISONS
-- Version finale — toutes les migrations incluses
-- ═══════════════════════════════════════════════════════════════

DROP DATABASE IF EXISTS glotelho_db;
CREATE DATABASE glotelho_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE glotelho_db;

SET FOREIGN_KEY_CHECKS = 0;

-- ═══════════════════════════════════════════════════════════════
-- 1. USERS
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE users (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    last_name       VARCHAR(100) NOT NULL,
    first_name      VARCHAR(100) NOT NULL,
    email           VARCHAR(150) UNIQUE NOT NULL,
    password        VARCHAR(255) NOT NULL,
    phone           VARCHAR(20) NOT NULL,
    role            ENUM('manager','delivery_person','customer') NOT NULL,
    fcm_token       VARCHAR(255) NULL,
    -- Google OAuth
    google_id       VARCHAR(255) NULL UNIQUE,
    photo_url       VARCHAR(500) NULL,
    -- Reset password
    reset_password_token   VARCHAR(255) NULL,
    reset_password_expires DATETIME     NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_role (role),
    INDEX idx_email (email)
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════════════════════════
-- 2. VEHICULES
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE vehicules (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    type            VARCHAR(50) NOT NULL,
    plate_number    VARCHAR(30) UNIQUE NOT NULL,
    brand           VARCHAR(50) NULL,
    status          ENUM('Disponible','En_cours_dutilisation','En_maintenance') DEFAULT 'Disponible',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════════════════════════
-- 3. MANAGERS
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE managers (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    user_id         INT UNIQUE NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════════════════════════
-- 4. DELIVERY_PERSONS — avec champs enrolement et photo profil
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE delivery_persons (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    user_id                 INT UNIQUE NOT NULL,
    vehicle_id              INT NULL,
    status                  ENUM('Disponible','En_livraison','Indisponible','Suspendu','Hors_service') DEFAULT 'Disponible',
    zone_affectee           VARCHAR(100) NULL,
    available               TINYINT(1) DEFAULT 1,
    -- Champs enrolement
    photo_profil            VARCHAR(255) NULL COMMENT 'Photo visage du livreur obligatoire',
    cni_numero              VARCHAR(50)  NULL,
    cni_photo_avant         VARCHAR(255) NULL,
    cni_photo_arriere       VARCHAR(255) NULL,
    permis_categorie        VARCHAR(10)  NULL,
    permis_photo            VARCHAR(255) NULL,
    adresse_domicile        VARCHAR(255) NULL,
    experience              TEXT         NULL,
    contact_urgence_nom     VARCHAR(100) NULL,
    contact_urgence_tel     VARCHAR(20)  NULL,
    caution_montant         DECIMAL(10,2) DEFAULT 50000,
    caution_payee           TINYINT(1)   DEFAULT 0,
    date_candidature        TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    note_manager            TEXT         NULL,
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (vehicle_id) REFERENCES vehicules(id) ON DELETE SET NULL,
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════════════════════════
-- 5. CUSTOMERS
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE customers (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    user_id         INT UNIQUE NOT NULL,
    address         VARCHAR(255) NULL,
    latitude        DECIMAL(10,8) NULL,
    longitude       DECIMAL(11,8) NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════════════════════════
-- 6. ORDERS
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE orders (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    customer_id     INT NOT NULL,
    status          VARCHAR(50) DEFAULT 'En_cours',
    total_amount    DECIMAL(10,2) NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    INDEX idx_customer (customer_id),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════════════════════════
-- 7. DELIVERYORDERS
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE deliveryorders (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    manager_id              INT NOT NULL,
    delivery_person_id      INT NULL,
    customer_id             INT NOT NULL,
    order_id                INT NULL COMMENT 'Commande source si creee depuis une commande',
    status                  ENUM('En_attente','Assign_','En_cours','Livr_','Suspendu','Annul_') DEFAULT 'En_attente',
    delivery_address        VARCHAR(255) NOT NULL,
    delivery_latitude       DECIMAL(10,8) NULL,
    delivery_longitude      DECIMAL(11,8) NULL,
    zone_bloc               VARCHAR(100) NULL,
    amount_to_collect       DECIMAL(10,2) DEFAULT 0,
    collected_amount        DECIMAL(10,2) DEFAULT 0,
    delivery_instructions   TEXT NULL,
    estimated_delivery_time DATETIME NULL,
    creation_date           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    delivery_date           DATETIME NULL,
    suspension_reason       TEXT NULL,
    tracking_blocked        TINYINT(1) DEFAULT 0,
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (manager_id) REFERENCES managers(id),
    FOREIGN KEY (delivery_person_id) REFERENCES delivery_persons(id) ON DELETE SET NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL,
    INDEX idx_status (status),
    INDEX idx_delivery_person (delivery_person_id),
    INDEX idx_customer (customer_id)
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════════════════════════
-- 8. DELIVERY_ITEMS
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE delivery_items (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    deliveryorder_id        INT NULL,
    order_id                INT NULL,
    product_name            VARCHAR(255) NOT NULL,
    quantity                INT DEFAULT 1,
    unit_price              DECIMAL(10,2) NULL,
    status                  ENUM('Disponible','Non_disponible') DEFAULT 'Disponible',
    description             TEXT NULL,
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (deliveryorder_id) REFERENCES deliveryorders(id) ON DELETE CASCADE,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════════════════════════
-- 9. RACES — Courses effectuees
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE races (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    delivery_person_id      INT NOT NULL,
    start_time              DATETIME NOT NULL,
    end_time                DATETIME NULL,
    status                  VARCHAR(50) DEFAULT 'En_cours',
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (delivery_person_id) REFERENCES delivery_persons(id)
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════════════════════════
-- 10. RACE_DELIVERYORDERS — Lien course ↔ livraisons
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE race_deliveryorders (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    race_id                 INT NOT NULL,
    deliveryorder_id        INT NOT NULL,
    FOREIGN KEY (race_id) REFERENCES races(id) ON DELETE CASCADE,
    FOREIGN KEY (deliveryorder_id) REFERENCES deliveryorders(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════════════════════════
-- 11. POSITION_TRACKING — Historique GPS
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE position_tracking (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    delivery_person_id      INT NOT NULL,
    latitude                DECIMAL(10,8) NOT NULL,
    longitude               DECIMAL(11,8) NOT NULL,
    speed                   DECIMAL(5,2) NULL,
    timestamp               TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (delivery_person_id) REFERENCES delivery_persons(id) ON DELETE CASCADE,
    INDEX idx_delivery_person (delivery_person_id),
    INDEX idx_timestamp (timestamp)
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════════════════════════
-- 12. PHOTOS
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE photos (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    deliveryorder_id        INT NOT NULL,
    delivery_person_id      INT NOT NULL,
    path                    VARCHAR(255) NOT NULL,
    taken_at                TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (deliveryorder_id) REFERENCES deliveryorders(id) ON DELETE CASCADE,
    FOREIGN KEY (delivery_person_id) REFERENCES delivery_persons(id)
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════════════════════════
-- 13. CONFIRMATIONS — OTP de livraison
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE confirmations (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    deliveryorder_id        INT NOT NULL,
    type                    VARCHAR(50) DEFAULT 'otp',
    value                   VARCHAR(20) NULL COMMENT 'Code OTP',
    confirmed_at            DATETIME NULL,
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (deliveryorder_id) REFERENCES deliveryorders(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════════════════════════
-- 14. RAPPORTS
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE rapports (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    deliveryorder_id        INT NOT NULL,
    type                    VARCHAR(50) DEFAULT 'livraison',
    contenu                 TEXT NULL,
    auteur                  VARCHAR(100) NULL,
    photo_url               VARCHAR(255) NULL,
    status_report           VARCHAR(50) DEFAULT 'Soumis',
    dateCreation            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (deliveryorder_id) REFERENCES deliveryorders(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════════════════════════
-- 15. NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE notifications (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    recipient_id            INT NOT NULL,
    message                 TEXT NOT NULL,
    type                    ENUM('FCM','SMS','Interne') DEFAULT 'FCM',
    is_read                 TINYINT(1) DEFAULT 0,
    sent_at                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_recipient (recipient_id),
    INDEX idx_read (is_read)
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════════════════════════
-- 16. RECOUVREMENT — Dettes financieres livreurs
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE recouvrement (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    deliveryorder_id        INT NOT NULL,
    delivery_person_id      INT NOT NULL,
    motif                   VARCHAR(100) NULL COMMENT 'perte_colis, colis_casse',
    amount_to_collect       DECIMAL(10,2) NOT NULL DEFAULT 0,
    amount_collected        DECIMAL(10,2) NOT NULL DEFAULT 0,
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (deliveryorder_id) REFERENCES deliveryorders(id),
    FOREIGN KEY (delivery_person_id) REFERENCES delivery_persons(id)
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════════════════════════
-- 17. REMISES_COMPENSATIONS — Litiges
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE remises_compensations (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    order_id                INT NOT NULL,
    type                    ENUM('Retour_produit','Rabais','Livraison_gratuite','Autre') NOT NULL,
    reason                  TEXT NOT NULL,
    amount                  DECIMAL(10,2) NULL,
    approved_by_manager_id  INT NOT NULL,
    status                  ENUM('Approuvee','En_attente','Rejetee','Cloture') DEFAULT 'En_attente',
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (approved_by_manager_id) REFERENCES managers(id),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════════════════════════
-- 18. BORDEREAUX
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE bordereaux (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    deliveryorder_id        INT NOT NULL,
    generated_by_manager_id INT NOT NULL,
    pdf_path                VARCHAR(255) NULL,
    status                  ENUM('Genere','Imprime','Distribue') DEFAULT 'Genere',
    generated_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (deliveryorder_id) REFERENCES deliveryorders(id),
    FOREIGN KEY (generated_by_manager_id) REFERENCES managers(id),
    INDEX idx_status (status)
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;

-- ═══════════════════════════════════════════════════════════════
-- INDICES SUPPLEMENTAIRES
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