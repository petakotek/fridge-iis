<?php

declare(strict_types=1);

namespace Database\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20261010122215 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE UserEntity DROP FOREIGN KEY `FK_2E23554AE79FF843`');
        $this->addSql('ALTER TABLE UserEntity ADD CONSTRAINT FK_2E23554AE79FF843 FOREIGN KEY (household_id) REFERENCES HouseholdEntity (id) ON DELETE SET NULL');
        $this->addSql('ALTER TABLE UserEntity ADD CONSTRAINT FK_2E23554A24179495 FOREIGN KEY (householdRequest) REFERENCES HouseholdEntity (id) ON DELETE SET NULL');
        $this->addSql('CREATE INDEX IDX_2E23554A24179495 ON UserEntity (householdRequest)');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE UserEntity DROP FOREIGN KEY FK_2E23554AE79FF843');
        $this->addSql('ALTER TABLE UserEntity DROP FOREIGN KEY FK_2E23554A24179495');
        $this->addSql('DROP INDEX IDX_2E23554A24179495 ON UserEntity');
        $this->addSql('ALTER TABLE UserEntity ADD CONSTRAINT `FK_2E23554AE79FF843` FOREIGN KEY (household_id) REFERENCES HouseholdEntity (id) ON DELETE CASCADE');
    }

    public function isTransactional(): bool
    {
        return false;
    }
}
