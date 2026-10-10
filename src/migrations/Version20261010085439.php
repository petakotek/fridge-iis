<?php

declare(strict_types=1);

namespace Database\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20261010085439 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE ApplianceEntity CHANGE household_id household_id INT DEFAULT NULL');
        $this->addSql('ALTER TABLE ApplianceEntity ADD CONSTRAINT FK_67A1F418E79FF843 FOREIGN KEY (household_id) REFERENCES HouseholdEntity (id) ON DELETE SET NULL');
        $this->addSql('ALTER TABLE FoodEntity DROP FOREIGN KEY `FK_3D806BF837FDBD6D`');
        $this->addSql('ALTER TABLE FoodEntity CHANGE expiry expiry DATETIME DEFAULT NULL, CHANGE weight weight INT DEFAULT NULL, CHANGE barcode barcode VARCHAR(13) DEFAULT NULL, CHANGE price price NUMERIC(10, 2) DEFAULT NULL, CHANGE calories calories INT DEFAULT NULL, CHANGE protein protein INT DEFAULT NULL, CHANGE fat fat INT DEFAULT NULL, CHANGE carb carb INT DEFAULT NULL, CHANGE fibre fibre INT DEFAULT NULL');
        $this->addSql('ALTER TABLE FoodEntity ADD CONSTRAINT FK_3D806BF837FDBD6D FOREIGN KEY (consumer_id) REFERENCES UserEntity (id) ON DELETE SET NULL');
        $this->addSql('ALTER TABLE HouseholdEntity DROP FOREIGN KEY `FK_DC751E25D0AFA354`');
        $this->addSql('ALTER TABLE HouseholdEntity CHANGE moderator_id moderator_id INT DEFAULT NULL');
        $this->addSql('ALTER TABLE HouseholdEntity ADD CONSTRAINT FK_DC751E25D0AFA354 FOREIGN KEY (moderator_id) REFERENCES UserEntity (id) ON DELETE SET NULL');
        $this->addSql('ALTER TABLE ShelfEntity DROP FOREIGN KEY `FK_897BA670E1EFC7B6`');
        $this->addSql('ALTER TABLE ShelfEntity ADD name VARCHAR(255) DEFAULT \'My Shelf\', CHANGE appliance_id appliance_id INT DEFAULT NULL');
        $this->addSql('ALTER TABLE ShelfEntity ADD CONSTRAINT FK_897BA670E1EFC7B6 FOREIGN KEY (appliance_id) REFERENCES ApplianceEntity (id) ON DELETE SET NULL');
        $this->addSql('ALTER TABLE UserEntity DROP FOREIGN KEY `FK_2E23554AE79FF843`');
        $this->addSql('ALTER TABLE UserEntity ADD CONSTRAINT FK_2E23554AE79FF843 FOREIGN KEY (household_id) REFERENCES HouseholdEntity (id) ON DELETE CASCADE');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE ApplianceEntity DROP FOREIGN KEY FK_67A1F418E79FF843');
        $this->addSql('ALTER TABLE ApplianceEntity CHANGE household_id household_id INT NOT NULL');
        $this->addSql('ALTER TABLE FoodEntity DROP FOREIGN KEY FK_3D806BF837FDBD6D');
        $this->addSql('ALTER TABLE FoodEntity CHANGE expiry expiry DATETIME NOT NULL, CHANGE weight weight INT NOT NULL, CHANGE barcode barcode VARCHAR(13) NOT NULL, CHANGE price price NUMERIC(10, 2) NOT NULL, CHANGE calories calories INT NOT NULL, CHANGE protein protein INT NOT NULL, CHANGE fat fat INT NOT NULL, CHANGE carb carb INT NOT NULL, CHANGE fibre fibre INT NOT NULL');
        $this->addSql('ALTER TABLE FoodEntity ADD CONSTRAINT `FK_3D806BF837FDBD6D` FOREIGN KEY (consumer_id) REFERENCES UserEntity (id)');
        $this->addSql('ALTER TABLE HouseholdEntity DROP FOREIGN KEY FK_DC751E25D0AFA354');
        $this->addSql('ALTER TABLE HouseholdEntity CHANGE moderator_id moderator_id INT NOT NULL');
        $this->addSql('ALTER TABLE HouseholdEntity ADD CONSTRAINT `FK_DC751E25D0AFA354` FOREIGN KEY (moderator_id) REFERENCES UserEntity (id)');
        $this->addSql('ALTER TABLE ShelfEntity DROP FOREIGN KEY FK_897BA670E1EFC7B6');
        $this->addSql('ALTER TABLE ShelfEntity DROP name, CHANGE appliance_id appliance_id INT NOT NULL');
        $this->addSql('ALTER TABLE ShelfEntity ADD CONSTRAINT `FK_897BA670E1EFC7B6` FOREIGN KEY (appliance_id) REFERENCES ApplianceEntity (id)');
        $this->addSql('ALTER TABLE UserEntity DROP FOREIGN KEY FK_2E23554AE79FF843');
        $this->addSql('ALTER TABLE UserEntity ADD CONSTRAINT `FK_2E23554AE79FF843` FOREIGN KEY (household_id) REFERENCES HouseholdEntity (id)');
    }

    public function isTransactional(): bool
    {
        return false;
    }
}
