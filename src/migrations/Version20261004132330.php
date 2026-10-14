<?php

declare(strict_types=1);

namespace Database\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20261004132330 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE ApplianceEntity (id INT AUTO_INCREMENT NOT NULL, name VARCHAR(255) NOT NULL, household_id INT NOT NULL, INDEX IDX_67A1F418E79FF843 (household_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE CategoryEntity (id INT AUTO_INCREMENT NOT NULL, name VARCHAR(50) NOT NULL, lft INT NOT NULL, rgt INT NOT NULL, level INT NOT NULL, tree_root INT DEFAULT NULL, parent_id INT DEFAULT NULL, INDEX IDX_A6EB9A53A977936C (tree_root), INDEX IDX_A6EB9A53727ACA70 (parent_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE categoryentity_foodentity (categoryentity_id INT NOT NULL, foodentity_id INT NOT NULL, INDEX IDX_6B23B378189FBC46 (categoryentity_id), INDEX IDX_6B23B37887A81F7F (foodentity_id), PRIMARY KEY (categoryentity_id, foodentity_id)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE FoodEntity (id INT AUTO_INCREMENT NOT NULL, name VARCHAR(255) NOT NULL, expiry DATETIME NOT NULL, weight INT NOT NULL, barcode VARCHAR(13) NOT NULL, price NUMERIC(10, 2) NOT NULL, calories INT NOT NULL, protein INT NOT NULL, fat INT NOT NULL, carb INT NOT NULL, fibre INT NOT NULL, consumed TINYINT NOT NULL, shelf_id INT NOT NULL, INDEX IDX_3D806BF87C12FBC0 (shelf_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE HouseholdEntity (id INT AUTO_INCREMENT NOT NULL, PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE ShelfEntity (id INT AUTO_INCREMENT NOT NULL, shelfCapacity INT NOT NULL, appliance_id INT NOT NULL, INDEX IDX_897BA670E1EFC7B6 (appliance_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE UserEntity (id INT AUTO_INCREMENT NOT NULL, name VARCHAR(255) NOT NULL, surname VARCHAR(255) NOT NULL, authLevel INT NOT NULL, household_id INT DEFAULT NULL, INDEX IDX_2E23554AE79FF843 (household_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('ALTER TABLE ApplianceEntity ADD CONSTRAINT FK_67A1F418E79FF843 FOREIGN KEY (household_id) REFERENCES HouseholdEntity (id) ON DELETE RESTRICT');
        $this->addSql('ALTER TABLE CategoryEntity ADD CONSTRAINT FK_A6EB9A53A977936C FOREIGN KEY (tree_root) REFERENCES CategoryEntity (id) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE CategoryEntity ADD CONSTRAINT FK_A6EB9A53727ACA70 FOREIGN KEY (parent_id) REFERENCES CategoryEntity (id) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE categoryentity_foodentity ADD CONSTRAINT FK_6B23B378189FBC46 FOREIGN KEY (categoryentity_id) REFERENCES CategoryEntity (id) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE categoryentity_foodentity ADD CONSTRAINT FK_6B23B37887A81F7F FOREIGN KEY (foodentity_id) REFERENCES FoodEntity (id) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE FoodEntity ADD CONSTRAINT FK_3D806BF87C12FBC0 FOREIGN KEY (shelf_id) REFERENCES ShelfEntity (id) ON DELETE RESTRICT');
        $this->addSql('ALTER TABLE ShelfEntity ADD CONSTRAINT FK_897BA670E1EFC7B6 FOREIGN KEY (appliance_id) REFERENCES ApplianceEntity (id) ON DELETE RESTRICT');
        $this->addSql('ALTER TABLE UserEntity ADD CONSTRAINT FK_2E23554AE79FF843 FOREIGN KEY (household_id) REFERENCES HouseholdEntity (id)');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE ApplianceEntity DROP FOREIGN KEY FK_67A1F418E79FF843');
        $this->addSql('ALTER TABLE CategoryEntity DROP FOREIGN KEY FK_A6EB9A53A977936C');
        $this->addSql('ALTER TABLE CategoryEntity DROP FOREIGN KEY FK_A6EB9A53727ACA70');
        $this->addSql('ALTER TABLE categoryentity_foodentity DROP FOREIGN KEY FK_6B23B378189FBC46');
        $this->addSql('ALTER TABLE categoryentity_foodentity DROP FOREIGN KEY FK_6B23B37887A81F7F');
        $this->addSql('ALTER TABLE FoodEntity DROP FOREIGN KEY FK_3D806BF87C12FBC0');
        $this->addSql('ALTER TABLE ShelfEntity DROP FOREIGN KEY FK_897BA670E1EFC7B6');
        $this->addSql('ALTER TABLE UserEntity DROP FOREIGN KEY FK_2E23554AE79FF843');
        $this->addSql('DROP TABLE ApplianceEntity');
        $this->addSql('DROP TABLE CategoryEntity');
        $this->addSql('DROP TABLE categoryentity_foodentity');
        $this->addSql('DROP TABLE FoodEntity');
        $this->addSql('DROP TABLE HouseholdEntity');
        $this->addSql('DROP TABLE ShelfEntity');
        $this->addSql('DROP TABLE UserEntity');
    }

    public function isTransactional(): bool
    {
        return false;
    }
}
