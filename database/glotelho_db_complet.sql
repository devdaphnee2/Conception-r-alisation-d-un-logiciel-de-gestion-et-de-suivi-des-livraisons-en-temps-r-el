DROP DATABASE IF EXISTS glotelho_db;
CREATE DATABASE glotelho_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE glotelho_db;

SET FOREIGN_KEY_CHECKS = 0;

-- ═══════════════════════════════════════════
-- USERS (table parent — héritée par customer, delivery_person, manager)
-- ═══════════════════════════════════════════
CREATE TABLE users (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    last_name   VARCHAR(100) NOT NULL,
    first_name  VARCHAR(100) NOT NULL,
    email       VARCHAR(150) UNIQUE NOT NULL,
    password    VARCHAR(255) NOT NULL,
    phone       VARCHAR(20) NOT NULL,
    role        ENUM('manager','delivery_person','customer') NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════
-- VEHICULE (créée AVANT delivery_persons et races qui en dépendent)
-- ═══════════════════════════════════════════
CREATE TABLE vehicules (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    type        VARCHAR(50) NOT NULL,         -- moto, voiture, tricycle...
    plate_number VARCHAR(30) UNIQUE NOT NULL,
    brand       VARCHAR(50) NULL,
    status      ENUM('Disponible','En_cours_dutilisation','En_maintenance') DEFAULT 'Disponible',
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════
-- MANAGER
-- ═══════════════════════════════════════════
CREATE TABLE managers (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT UNIQUE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════
-- DELIVERY_PERSON (livreur)
-- ═══════════════════════════════════════════
CREATE TABLE delivery_persons (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT UNIQUE NOT NULL,
    vehicle_id  INT NULL,
    status      ENUM('Disponible','Indisponible','Suspendu') DEFAULT 'Disponible',
    available   TINYINT(1) DEFAULT 1,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (vehicle_id) REFERENCES vehicules(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════
-- CUSTOMERS
-- ═══════════════════════════════════════════
CREATE TABLE customers (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT UNIQUE NOT NULL,
    address     VARCHAR(255) NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════
-- ORDERS (commande)
-- ═══════════════════════════════════════════
CREATE TABLE orders (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    customer_id     INT NOT NULL,
    status          VARCHAR(50) DEFAULT 'En_cours',
    total_amount    DECIMAL(10,2) NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════
-- DELIVERYORDERS (livraison)
-- ═══════════════════════════════════════════
CREATE TABLE deliveryorders (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    manager_id          INT NOT NULL,
    delivery_person_id  INT NULL,
    status              ENUM('En_attente','assigné','En_cours',
                              'Livré','Suspendu')
                              DEFAULT 'En_attente',
    delivery_address    VARCHAR(255) NOT NULL,
    creation_date       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    delivery_date       DATETIME NULL,
    tracking_blocked    TINYINT(1) DEFAULT 0,
    suspension_reason   TEXT NULL,
    FOREIGN KEY (manager_id) REFERENCES managers(id),
    FOREIGN KEY (delivery_person_id) REFERENCES delivery_persons(id)
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════
-- DELIVERY_ITEM (colis + instructions + montant à recouvrer)
-- ═══════════════════════════════════════════
CREATE TABLE delivery_items (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    deliveryorder_id    INT NOT NULL,
    order_id            INT NOT NULL,
    delivery_instructions TEXT NULL,
    route_info          TEXT NULL,
    amount_to_collect   DECIMAL(10,2) DEFAULT 0,
    status              VARCHAR(50) DEFAULT 'En_attente',
    FOREIGN KEY (deliveryorder_id) REFERENCES deliveryorders(id) ON DELETE CASCADE,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════
-- RACE (course = ensemble de trajets de livraison)
-- ═══════════════════════════════════════════
CREATE TABLE races (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    delivery_person_id  INT NOT NULL,
    vehicle_id          INT NULL,
    departure_time      DATETIME NULL,
    return_time         DATETIME NULL,
    status              ENUM('En_attente','En_cours','Terminée') DEFAULT 'En_attente',
    report              TEXT NULL,
    FOREIGN KEY (delivery_person_id) REFERENCES delivery_persons(id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicules(id)
) ENGINE=InnoDB;

-- Table de liaison Race <-> DeliveryOrders (une course regroupe plusieurs livraisons)
CREATE TABLE race_deliveryorders (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    race_id             INT NOT NULL,
    deliveryorder_id    INT NOT NULL,
    sequence_order      INT NULL,             -- ordre de passage dans la course
    FOREIGN KEY (race_id) REFERENCES races(id) ON DELETE CASCADE,
    FOREIGN KEY (deliveryorder_id) REFERENCES deliveryorders(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════
-- POSITION_TRACKING (map)
-- ═══════════════════════════════════════════
CREATE TABLE position_tracking (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    race_id             INT NOT NULL,
    delivery_person_id  INT NOT NULL,
    latitude            DECIMAL(10,8) NOT NULL,
    longitude           DECIMAL(11,8) NOT NULL,
    recorded_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (race_id) REFERENCES races(id) ON DELETE CASCADE,
    FOREIGN KEY (delivery_person_id) REFERENCES delivery_persons(id)
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════
-- PHOTO (photo du colis livré, prise par le livreur)
-- ═══════════════════════════════════════════
CREATE TABLE photos (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    deliveryorder_id    INT NOT NULL,
    delivery_person_id  INT NOT NULL,
    path                VARCHAR(255) NOT NULL,  -- chemin stockage
    taken_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (deliveryorder_id) REFERENCES deliveryorders(id) ON DELETE CASCADE,
    FOREIGN KEY (delivery_person_id) REFERENCES delivery_persons(id)
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════
-- NOTIFICATION
-- ═══════════════════════════════════════════
CREATE TABLE notifications (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    message         TEXT NOT NULL,
    type            ENUM('FCM','SMS') DEFAULT 'FCM',
    recipient_id    INT NOT NULL,
    is_read         TINYINT(1) DEFAULT 0,
    sent_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;