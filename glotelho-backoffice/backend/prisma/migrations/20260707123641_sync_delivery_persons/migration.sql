/*
  Warnings:

  - You are about to alter the column `methode` on the `confirmations` table. The data in that column could be lost. The data in that column will be cast from `Enum(EnumId(4))` to `VarChar(20)`.
  - You are about to alter the column `status` on the `delivery_persons` table. The data in that column could be lost. The data in that column will be cast from `Enum(EnumId(1))` to `VarChar(191)`.

*/
-- DropForeignKey
ALTER TABLE `delivery_persons` DROP FOREIGN KEY `delivery_persons_ibfk_1`;

-- DropForeignKey
ALTER TABLE `delivery_persons` DROP FOREIGN KEY `delivery_persons_ibfk_2`;

-- DropIndex
DROP INDEX `user_id` ON `delivery_persons`;

-- AlterTable
ALTER TABLE `confirmations` MODIFY `customer_id` INTEGER NULL,
    MODIFY `delivery_person_id` INTEGER NULL,
    MODIFY `methode` VARCHAR(20) NULL DEFAULT 'OTP';

-- AlterTable
ALTER TABLE `delivery_persons` ADD COLUMN `vehiculesId` INTEGER NULL,
    MODIFY `status` VARCHAR(191) NULL DEFAULT 'Disponible',
    MODIFY `available` TINYINT NULL DEFAULT 1,
    MODIFY `caution_payee` TINYINT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE `users` ADD COLUMN `delivery_personsId` INTEGER NULL;

-- AddForeignKey
ALTER TABLE `delivery_persons` ADD CONSTRAINT `delivery_persons_vehiculesId_fkey` FOREIGN KEY (`vehiculesId`) REFERENCES `vehicules`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `users` ADD CONSTRAINT `users_delivery_personsId_fkey` FOREIGN KEY (`delivery_personsId`) REFERENCES `delivery_persons`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
