/*
  Warnings:

  - You are about to drop the column `unit_price` on the `delivery_items` table. All the data in the column will be lost.
  - You are about to drop the column `adresse_domicile` on the `delivery_persons` table. All the data in the column will be lost.
  - You are about to drop the column `cni_photo_arriere` on the `delivery_persons` table. All the data in the column will be lost.
  - You are about to drop the column `cni_photo_avant` on the `delivery_persons` table. All the data in the column will be lost.
  - You are about to drop the column `contact_urgence_nom` on the `delivery_persons` table. All the data in the column will be lost.
  - You are about to drop the column `contact_urgence_tel` on the `delivery_persons` table. All the data in the column will be lost.
  - You are about to drop the column `experience` on the `delivery_persons` table. All the data in the column will be lost.
  - You are about to drop the column `permis_categorie` on the `delivery_persons` table. All the data in the column will be lost.
  - You are about to drop the column `permis_photo` on the `delivery_persons` table. All the data in the column will be lost.
  - You are about to drop the column `photo_profil` on the `delivery_persons` table. All the data in the column will be lost.
  - You are about to drop the column `vehiculesId` on the `delivery_persons` table. All the data in the column will be lost.
  - The values [Assigné,Livré,Annulé] on the enum `deliveryorders_status` will be removed. If these variants are still used in the database, this will fail.
  - You are about to drop the column `delivery_personsId` on the `users` table. All the data in the column will be lost.
  - You are about to alter the column `photo_url` on the `users` table. The data in that column could be lost. The data in that column will be cast from `VarChar(500)` to `VarChar(255)`.
  - You are about to drop the `litiges` table. If the table is not empty, all the data it contains will be lost.
  - A unique constraint covering the columns `[user_id]` on the table `delivery_persons` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[phone]` on the table `users` will be added. If there are existing duplicate values, this will fail.
  - Made the column `methode` on table `confirmations` required. This step will fail if there are existing NULL values in that column.

*/
-- DropForeignKey
ALTER TABLE `delivery_persons` DROP FOREIGN KEY `delivery_persons_vehiculesId_fkey`;

-- DropForeignKey
ALTER TABLE `litiges` DROP FOREIGN KEY `litiges_ibfk_1`;

-- DropForeignKey
ALTER TABLE `litiges` DROP FOREIGN KEY `litiges_ibfk_2`;

-- DropForeignKey
ALTER TABLE `litiges` DROP FOREIGN KEY `litiges_ibfk_3`;

-- DropForeignKey
ALTER TABLE `litiges` DROP FOREIGN KEY `litiges_ibfk_4`;

-- DropForeignKey
ALTER TABLE `users` DROP FOREIGN KEY `users_delivery_personsId_fkey`;

-- DropIndex
DROP INDEX `google_id` ON `users`;

-- AlterTable
ALTER TABLE `confirmations` MODIFY `methode` ENUM('OTP', 'Signature') NOT NULL;

-- AlterTable
ALTER TABLE `delivery_items` DROP COLUMN `unit_price`,
    ADD COLUMN `price` DECIMAL(10, 2) NULL DEFAULT 0.00;

-- AlterTable
ALTER TABLE `delivery_persons` DROP COLUMN `adresse_domicile`,
    DROP COLUMN `cni_photo_arriere`,
    DROP COLUMN `cni_photo_avant`,
    DROP COLUMN `contact_urgence_nom`,
    DROP COLUMN `contact_urgence_tel`,
    DROP COLUMN `experience`,
    DROP COLUMN `permis_categorie`,
    DROP COLUMN `permis_photo`,
    DROP COLUMN `photo_profil`,
    DROP COLUMN `vehiculesId`,
    ADD COLUMN `adresse_residence` VARCHAR(255) NULL,
    ADD COLUMN `assurance_expiration` DATE NULL,
    ADD COLUMN `assurance_numero` VARCHAR(100) NULL,
    ADD COLUMN `cni_recto_url` VARCHAR(255) NULL,
    ADD COLUMN `cni_verso_url` VARCHAR(255) NULL,
    ADD COLUMN `date_activation` TIMESTAMP(0) NULL,
    ADD COLUMN `date_naissance` DATE NULL,
    ADD COLUMN `disponibilites` TEXT NULL,
    ADD COLUMN `emprunt` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    ADD COLUMN `mobile_money_numero` VARCHAR(30) NULL,
    ADD COLUMN `mobile_money_titulaire` VARCHAR(150) NULL,
    ADD COLUMN `note` DECIMAL(3, 2) NOT NULL DEFAULT 0.00,
    ADD COLUMN `permis_url` VARCHAR(255) NULL,
    ADD COLUMN `photo_profil_url` VARCHAR(255) NULL,
    ADD COLUMN `solde_commission` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    ADD COLUMN `vehicule_immatriculation` VARCHAR(50) NULL,
    ADD COLUMN `vehicule_marque` VARCHAR(100) NULL,
    ADD COLUMN `vehicule_modele` VARCHAR(100) NULL,
    ADD COLUMN `vehicule_photo_url` VARCHAR(255) NULL,
    ADD COLUMN `vehicule_type` VARCHAR(50) NULL,
    MODIFY `available` BOOLEAN NULL DEFAULT true,
    MODIFY `cni_numero` VARCHAR(100) NULL,
    MODIFY `date_candidature` TIMESTAMP(0) NULL DEFAULT CURRENT_TIMESTAMP(0);

-- AlterTable
ALTER TABLE `deliveryorders` MODIFY `status` ENUM('En_attente', 'Assign_', 'En_cours', 'Livr_', 'Suspendu', 'Annul_', 'Commande') NULL DEFAULT 'En_attente';

-- AlterTable
ALTER TABLE `orders` ADD COLUMN `cancellation_reason` TEXT NULL,
    ADD COLUMN `delivery_address` TEXT NULL,
    ADD COLUMN `delivery_type` VARCHAR(20) NULL DEFAULT 'home',
    ADD COLUMN `payment_method` VARCHAR(50) NULL,
    ADD COLUMN `reference` VARCHAR(20) NULL,
    ADD COLUMN `shipping_fee` DECIMAL(10, 2) NULL DEFAULT 0.00;

-- AlterTable
ALTER TABLE `users` DROP COLUMN `delivery_personsId`,
    ADD COLUMN `avatar_url` VARCHAR(255) NULL,
    ADD COLUMN `has_password` BOOLEAN NOT NULL DEFAULT true,
    MODIFY `last_name` VARCHAR(100) NULL,
    MODIFY `photo_url` VARCHAR(255) NULL;

-- DropTable
DROP TABLE `litiges`;

-- CreateIndex
CREATE UNIQUE INDEX `user_id` ON `delivery_persons`(`user_id`);

-- CreateIndex
CREATE INDEX `idx_reference` ON `orders`(`reference`);

-- CreateIndex
CREATE UNIQUE INDEX `idx_unique_phone` ON `users`(`phone`);

-- CreateIndex
CREATE INDEX `idx_google_id` ON `users`(`google_id`);

-- AddForeignKey
ALTER TABLE `delivery_persons` ADD CONSTRAINT `delivery_persons_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE `delivery_persons` ADD CONSTRAINT `delivery_persons_ibfk_2` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicules`(`id`) ON DELETE SET NULL ON UPDATE RESTRICT;
