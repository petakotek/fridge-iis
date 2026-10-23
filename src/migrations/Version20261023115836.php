<?php

declare(strict_types=1);

namespace Database\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20261023115836 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Cascade household deletion to appliances, shelves and food.';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('ALTER TABLE ApplianceEntity DROP FOREIGN KEY `FK_67A1F418E79FF843`');
        $this->addSql('ALTER TABLE ApplianceEntity ADD CONSTRAINT FK_67A1F418E79FF843 FOREIGN KEY (household_id) REFERENCES HouseholdEntity (id) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE FoodEntity DROP FOREIGN KEY `FK_3D806BF87C12FBC0`');
        $this->addSql('ALTER TABLE FoodEntity ADD CONSTRAINT FK_3D806BF87C12FBC0 FOREIGN KEY (shelf_id) REFERENCES ShelfEntity (id) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE ShelfEntity DROP FOREIGN KEY `FK_897BA670E1EFC7B6`');
        $this->addSql('ALTER TABLE ShelfEntity ADD CONSTRAINT FK_897BA670E1EFC7B6 FOREIGN KEY (appliance_id) REFERENCES ApplianceEntity (id) ON DELETE CASCADE');
    }

    public function down(Schema $schema): void
    {
        $this->addSql('ALTER TABLE ApplianceEntity DROP FOREIGN KEY FK_67A1F418E79FF843');
        $this->addSql('ALTER TABLE ApplianceEntity ADD CONSTRAINT `FK_67A1F418E79FF843` FOREIGN KEY (household_id) REFERENCES HouseholdEntity (id) ON DELETE SET NULL');
        $this->addSql('ALTER TABLE FoodEntity DROP FOREIGN KEY FK_3D806BF87C12FBC0');
        $this->addSql('ALTER TABLE FoodEntity ADD CONSTRAINT `FK_3D806BF87C12FBC0` FOREIGN KEY (shelf_id) REFERENCES ShelfEntity (id) ON DELETE RESTRICT');
        $this->addSql('ALTER TABLE ShelfEntity DROP FOREIGN KEY FK_897BA670E1EFC7B6');
        $this->addSql('ALTER TABLE ShelfEntity ADD CONSTRAINT `FK_897BA670E1EFC7B6` FOREIGN KEY (appliance_id) REFERENCES ApplianceEntity (id) ON DELETE SET NULL');
    }

    public function isTransactional(): bool
    {
        return false;
    }
}
