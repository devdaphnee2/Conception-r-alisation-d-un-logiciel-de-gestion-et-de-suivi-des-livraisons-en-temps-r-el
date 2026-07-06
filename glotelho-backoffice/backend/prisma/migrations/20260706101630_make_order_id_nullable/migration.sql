-- CreateTable
CREATE TABLE `bordereaux` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `deliveryorder_id` INTEGER NOT NULL,
    `generated_by_manager_id` INTEGER NOT NULL,
    `pdf_path` VARCHAR(255) NULL,
    `status` ENUM('Genere', 'Imprime', 'Distribue') NULL DEFAULT 'Genere',
    `generated_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    INDEX `generated_by_manager_id`(`generated_by_manager_id`),
    INDEX `deliveryorder_id`(`deliveryorder_id`),
    INDEX `idx_status`(`status`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `confirmations` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `deliveryorder_id` INTEGER NOT NULL,
    `customer_id` INTEGER NOT NULL,
    `delivery_person_id` INTEGER NOT NULL,
    `methode` ENUM('OTP', 'Signature') NOT NULL,
    `otp_code` VARCHAR(10) NULL,
    `signature_path` VARCHAR(255) NULL,
    `confirmed_at` DATETIME(0) NULL,
    `created_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    INDEX `customer_id`(`customer_id`),
    INDEX `delivery_person_id`(`delivery_person_id`),
    INDEX `idx_confirmations_delivery`(`deliveryorder_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `customers` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `user_id` INTEGER NOT NULL,
    `address` VARCHAR(255) NULL,
    `latitude` DECIMAL(10, 8) NULL,
    `longitude` DECIMAL(11, 8) NULL,
    `created_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    UNIQUE INDEX `user_id`(`user_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `delivery_items` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `deliveryorder_id` INTEGER NOT NULL,
    `order_id` INTEGER NULL,
    `product_name` VARCHAR(255) NOT NULL,
    `delivery_instructions` TEXT NULL,
    `route_info` TEXT NULL,
    `status` VARCHAR(50) NULL DEFAULT 'En_attente',
    `created_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    `quantity` INTEGER NULL DEFAULT 1,
    `unit_price` DECIMAL(10, 2) NULL,

    INDEX `deliveryorder_id`(`deliveryorder_id`),
    INDEX `order_id`(`order_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `delivery_persons` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `user_id` INTEGER NOT NULL,
    `vehicle_id` INTEGER NULL,
    `status` ENUM('Disponible', 'En_livraison', 'Indisponible', 'Suspendu', 'Hors_service') NULL DEFAULT 'Disponible',
    `zone_affectee` VARCHAR(100) NULL,
    `available` BOOLEAN NULL DEFAULT true,
    `created_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    `cni_numero` VARCHAR(50) NULL,
    `cni_photo_avant` VARCHAR(255) NULL,
    `cni_photo_arriere` VARCHAR(255) NULL,
    `permis_categorie` VARCHAR(10) NULL,
    `permis_photo` VARCHAR(255) NULL,
    `adresse_domicile` VARCHAR(255) NULL,
    `experience` TEXT NULL,
    `contact_urgence_nom` VARCHAR(100) NULL,
    `contact_urgence_tel` VARCHAR(20) NULL,
    `caution_montant` DECIMAL(10, 2) NULL DEFAULT 50000.00,
    `caution_payee` BOOLEAN NULL DEFAULT false,
    `date_candidature` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    `note_manager` TEXT NULL,
    `photo_profil` VARCHAR(255) NULL,

    UNIQUE INDEX `user_id`(`user_id`),
    INDEX `idx_status`(`status`),
    INDEX `vehicle_id`(`vehicle_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `deliveryorders` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `manager_id` INTEGER NOT NULL,
    `delivery_person_id` INTEGER NULL,
    `customer_id` INTEGER NOT NULL,
    `status` ENUM('En_attente', 'Assigné', 'En_cours', 'Livré', 'Suspendu', 'Annulé') NULL DEFAULT 'En_attente',
    `delivery_address` VARCHAR(255) NOT NULL,
    `delivery_latitude` DECIMAL(10, 8) NULL,
    `delivery_longitude` DECIMAL(11, 8) NULL,
    `zone_bloc` VARCHAR(100) NULL,
    `amount_to_collect` DECIMAL(10, 2) NULL DEFAULT 0.00,
    `collected_amount` DECIMAL(10, 2) NULL DEFAULT 0.00,
    `estimated_delivery_time` DATETIME(0) NULL,
    `creation_date` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    `delivery_date` DATETIME(0) NULL,
    `suspension_reason` TEXT NULL,
    `tracking_blocked` BOOLEAN NULL DEFAULT false,
    `created_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    `updated_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    `client_nom` VARCHAR(150) NULL,
    `client_telephone` VARCHAR(30) NULL,
    `client_whatsapp` VARCHAR(30) NULL,
    `delivery_instructions` TEXT NULL,

    INDEX `idx_created`(`creation_date`),
    INDEX `idx_customer`(`customer_id`),
    INDEX `idx_delivery_person`(`delivery_person_id`),
    INDEX `idx_deliveryorders_zone`(`zone_bloc`),
    INDEX `idx_status`(`status`),
    INDEX `manager_id`(`manager_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `managers` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `user_id` INTEGER NOT NULL,
    `created_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    UNIQUE INDEX `user_id`(`user_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `notifications` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `recipient_id` INTEGER NOT NULL,
    `message` TEXT NOT NULL,
    `type` ENUM('FCM', 'SMS', 'Interne') NULL DEFAULT 'FCM',
    `is_read` BOOLEAN NULL DEFAULT false,
    `sent_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    INDEX `idx_read`(`is_read`),
    INDEX `idx_recipient`(`recipient_id`),
    INDEX `idx_sent`(`sent_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `orders` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `customer_id` INTEGER NOT NULL,
    `status` VARCHAR(50) NULL DEFAULT 'En_cours',
    `total_amount` DECIMAL(10, 2) NOT NULL,
    `created_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    `updated_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    INDEX `idx_created`(`created_at`),
    INDEX `idx_customer`(`customer_id`),
    INDEX `idx_status`(`status`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `photos` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `deliveryorder_id` INTEGER NOT NULL,
    `delivery_person_id` INTEGER NOT NULL,
    `path` VARCHAR(255) NOT NULL,
    `taken_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    INDEX `delivery_person_id`(`delivery_person_id`),
    INDEX `idx_photos_delivery`(`deliveryorder_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `position_tracking` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `race_id` INTEGER NOT NULL,
    `delivery_person_id` INTEGER NOT NULL,
    `latitude` DECIMAL(10, 8) NOT NULL,
    `longitude` DECIMAL(11, 8) NOT NULL,
    `speed` FLOAT NULL,
    `recorded_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    INDEX `idx_delivery_person`(`delivery_person_id`),
    INDEX `idx_position_delivery_person`(`delivery_person_id`),
    INDEX `idx_race`(`race_id`),
    INDEX `idx_recorded`(`recorded_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `race_deliveryorders` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `race_id` INTEGER NOT NULL,
    `deliveryorder_id` INTEGER NOT NULL,
    `sequence_order` INTEGER NULL,
    `created_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    INDEX `deliveryorder_id`(`deliveryorder_id`),
    INDEX `idx_race`(`race_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `races` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `delivery_person_id` INTEGER NOT NULL,
    `vehicle_id` INTEGER NULL,
    `departure_time` DATETIME(0) NULL,
    `return_time` DATETIME(0) NULL,
    `status` ENUM('En_attente', 'En_cours', 'Terminée') NULL DEFAULT 'En_attente',
    `report` TEXT NULL,
    `created_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    `updated_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    INDEX `idx_created`(`created_at`),
    INDEX `idx_delivery_person`(`delivery_person_id`),
    INDEX `idx_status`(`status`),
    INDEX `vehicle_id`(`vehicle_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `rapports` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `deliveryorder_id` INTEGER NOT NULL,
    `delivery_person_id` INTEGER NOT NULL,
    `observations` TEXT NULL,
    `photo_url` VARCHAR(255) NULL,
    `status_report` VARCHAR(50) NULL DEFAULT 'Soumis',
    `created_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    `updated_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    INDEX `delivery_person_id`(`delivery_person_id`),
    INDEX `idx_rapports_delivery`(`deliveryorder_id`),
    INDEX `idx_status`(`status_report`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `recouvrement` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `deliveryorder_id` INTEGER NOT NULL,
    `delivery_person_id` INTEGER NOT NULL,
    `amount_to_collect` DECIMAL(10, 2) NOT NULL,
    `amount_collected` DECIMAL(10, 2) NOT NULL,
    `payment_method` ENUM('Espèces', 'OM', 'MoMo', 'Carte', 'Autre') NOT NULL,
    `reference_number` VARCHAR(100) NULL,
    `collected_at` DATETIME(0) NULL,
    `created_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    INDEX `delivery_person_id`(`delivery_person_id`),
    INDEX `idx_collected`(`collected_at`),
    INDEX `idx_recouvrement_delivery`(`deliveryorder_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `remises_compensations` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `order_id` INTEGER NOT NULL,
    `type` ENUM('Retour_produit', 'Rabais', 'Livraison_gratuite', 'Autre') NOT NULL,
    `reason` TEXT NOT NULL,
    `amount` DECIMAL(10, 2) NULL,
    `approved_by_manager_id` INTEGER NOT NULL,
    `status` ENUM('Approuvée', 'En_attente', 'Rejetée') NULL DEFAULT 'En_attente',
    `created_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    `updated_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    INDEX `approved_by_manager_id`(`approved_by_manager_id`),
    INDEX `idx_status`(`status`),
    INDEX `order_id`(`order_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `users` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `last_name` VARCHAR(100) NOT NULL,
    `first_name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(150) NOT NULL,
    `password` VARCHAR(255) NOT NULL,
    `phone` VARCHAR(20) NOT NULL,
    `role` ENUM('manager', 'delivery_person', 'customer') NOT NULL,
    `fcm_token` VARCHAR(255) NULL,
    `created_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    `updated_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    `reset_password_token` VARCHAR(255) NULL,
    `reset_password_expires` DATETIME(0) NULL,
    `google_id` VARCHAR(255) NULL,
    `photo_url` VARCHAR(500) NULL,

    UNIQUE INDEX `email`(`email`),
    UNIQUE INDEX `google_id`(`google_id`),
    INDEX `idx_email`(`email`),
    INDEX `idx_role`(`role`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `vehicules` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `type` VARCHAR(50) NOT NULL,
    `plate_number` VARCHAR(30) NOT NULL,
    `brand` VARCHAR(50) NULL,
    `status` ENUM('Disponible', 'En_cours_dutilisation', 'En_maintenance') NULL DEFAULT 'Disponible',
    `created_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    `updated_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    UNIQUE INDEX `plate_number`(`plate_number`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `litiges` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `deliveryorder_id` INTEGER NOT NULL,
    `customer_id` INTEGER NULL,
    `delivery_person_id` INTEGER NULL,
    `manager_id` INTEGER NULL,
    `statut` ENUM('Ouvert', 'En_cours', 'Resolu', 'Cloture') NULL DEFAULT 'Ouvert',
    `description` TEXT NOT NULL,
    `decision` VARCHAR(100) NULL,
    `motif` TEXT NULL,
    `date_ouverture` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    `date_cloture` TIMESTAMP(0) NULL,

    INDEX `customer_id`(`customer_id`),
    INDEX `delivery_person_id`(`delivery_person_id`),
    INDEX `idx_deliveryorder`(`deliveryorder_id`),
    INDEX `idx_statut`(`statut`),
    INDEX `manager_id`(`manager_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `notations` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `deliveryorder_id` INTEGER NOT NULL,
    `customer_id` INTEGER NOT NULL,
    `delivery_person_id` INTEGER NOT NULL,
    `note` TINYINT NOT NULL,
    `commentaire` TEXT NULL,
    `created_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    UNIQUE INDEX `uniq_notation_livraison`(`deliveryorder_id`),
    INDEX `customer_id`(`customer_id`),
    INDEX `delivery_person_id`(`delivery_person_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `password_resets` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `user_id` INTEGER NOT NULL,
    `token` VARCHAR(255) NOT NULL,
    `created_at` TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    INDEX `idx_token`(`token`),
    INDEX `user_id`(`user_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `bordereaux` ADD CONSTRAINT `bordereaux_ibfk_1` FOREIGN KEY (`deliveryorder_id`) REFERENCES `deliveryorders`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `bordereaux` ADD CONSTRAINT `bordereaux_ibfk_2` FOREIGN KEY (`generated_by_manager_id`) REFERENCES `managers`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `confirmations` ADD CONSTRAINT `confirmations_ibfk_1` FOREIGN KEY (`deliveryorder_id`) REFERENCES `deliveryorders`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `confirmations` ADD CONSTRAINT `confirmations_ibfk_2` FOREIGN KEY (`customer_id`) REFERENCES `customers`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `confirmations` ADD CONSTRAINT `confirmations_ibfk_3` FOREIGN KEY (`delivery_person_id`) REFERENCES `delivery_persons`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `customers` ADD CONSTRAINT `customers_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `delivery_items` ADD CONSTRAINT `delivery_items_ibfk_1` FOREIGN KEY (`deliveryorder_id`) REFERENCES `deliveryorders`(`id`) ON DELETE CASCADE ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `delivery_items` ADD CONSTRAINT `delivery_items_ibfk_2` FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON DELETE CASCADE ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `delivery_persons` ADD CONSTRAINT `delivery_persons_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `delivery_persons` ADD CONSTRAINT `delivery_persons_ibfk_2` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicules`(`id`) ON DELETE SET NULL ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `deliveryorders` ADD CONSTRAINT `deliveryorders_ibfk_1` FOREIGN KEY (`manager_id`) REFERENCES `managers`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `deliveryorders` ADD CONSTRAINT `deliveryorders_ibfk_2` FOREIGN KEY (`delivery_person_id`) REFERENCES `delivery_persons`(`id`) ON DELETE SET NULL ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `deliveryorders` ADD CONSTRAINT `deliveryorders_ibfk_3` FOREIGN KEY (`customer_id`) REFERENCES `customers`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `managers` ADD CONSTRAINT `managers_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `notifications` ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`recipient_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `orders` ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customers`(`id`) ON DELETE CASCADE ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `photos` ADD CONSTRAINT `photos_ibfk_1` FOREIGN KEY (`deliveryorder_id`) REFERENCES `deliveryorders`(`id`) ON DELETE CASCADE ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `photos` ADD CONSTRAINT `photos_ibfk_2` FOREIGN KEY (`delivery_person_id`) REFERENCES `delivery_persons`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `position_tracking` ADD CONSTRAINT `position_tracking_ibfk_1` FOREIGN KEY (`race_id`) REFERENCES `races`(`id`) ON DELETE CASCADE ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `position_tracking` ADD CONSTRAINT `position_tracking_ibfk_2` FOREIGN KEY (`delivery_person_id`) REFERENCES `delivery_persons`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `race_deliveryorders` ADD CONSTRAINT `race_deliveryorders_ibfk_1` FOREIGN KEY (`race_id`) REFERENCES `races`(`id`) ON DELETE CASCADE ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `race_deliveryorders` ADD CONSTRAINT `race_deliveryorders_ibfk_2` FOREIGN KEY (`deliveryorder_id`) REFERENCES `deliveryorders`(`id`) ON DELETE CASCADE ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `races` ADD CONSTRAINT `races_ibfk_1` FOREIGN KEY (`delivery_person_id`) REFERENCES `delivery_persons`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `races` ADD CONSTRAINT `races_ibfk_2` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicules`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `rapports` ADD CONSTRAINT `rapports_ibfk_1` FOREIGN KEY (`deliveryorder_id`) REFERENCES `deliveryorders`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `rapports` ADD CONSTRAINT `rapports_ibfk_2` FOREIGN KEY (`delivery_person_id`) REFERENCES `delivery_persons`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `recouvrement` ADD CONSTRAINT `recouvrement_ibfk_1` FOREIGN KEY (`deliveryorder_id`) REFERENCES `deliveryorders`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `recouvrement` ADD CONSTRAINT `recouvrement_ibfk_2` FOREIGN KEY (`delivery_person_id`) REFERENCES `delivery_persons`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `remises_compensations` ADD CONSTRAINT `remises_compensations_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `remises_compensations` ADD CONSTRAINT `remises_compensations_ibfk_2` FOREIGN KEY (`approved_by_manager_id`) REFERENCES `managers`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `litiges` ADD CONSTRAINT `litiges_ibfk_1` FOREIGN KEY (`deliveryorder_id`) REFERENCES `deliveryorders`(`id`) ON DELETE CASCADE ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `litiges` ADD CONSTRAINT `litiges_ibfk_2` FOREIGN KEY (`customer_id`) REFERENCES `customers`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `litiges` ADD CONSTRAINT `litiges_ibfk_3` FOREIGN KEY (`delivery_person_id`) REFERENCES `delivery_persons`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `litiges` ADD CONSTRAINT `litiges_ibfk_4` FOREIGN KEY (`manager_id`) REFERENCES `managers`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `notations` ADD CONSTRAINT `notations_ibfk_1` FOREIGN KEY (`deliveryorder_id`) REFERENCES `deliveryorders`(`id`) ON DELETE CASCADE ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `notations` ADD CONSTRAINT `notations_ibfk_2` FOREIGN KEY (`customer_id`) REFERENCES `customers`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `notations` ADD CONSTRAINT `notations_ibfk_3` FOREIGN KEY (`delivery_person_id`) REFERENCES `delivery_persons`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `password_resets` ADD CONSTRAINT `password_resets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE RESTRICT;
