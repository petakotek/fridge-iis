<?php

declare(strict_types=1);

namespace Database\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20261008082027 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE CategoryEntity ADD household_id INT NOT NULL');
        $this->addSql('ALTER TABLE CategoryEntity ADD CONSTRAINT FK_A6EB9A53E79FF843 FOREIGN KEY (household_id) REFERENCES HouseholdEntity (id) ON DELETE CASCADE');
        $this->addSql('CREATE INDEX IDX_A6EB9A53E79FF843 ON CategoryEntity (household_id)');
        $this->addSql('ALTER TABLE FoodEntity ADD consumedAt DATETIME DEFAULT NULL, ADD trashed TINYINT DEFAULT NULL, ADD discardedAt DATETIME DEFAULT NULL, ADD consumer_id INT DEFAULT NULL, DROP consumed');
        $this->addSql('ALTER TABLE FoodEntity ADD CONSTRAINT FK_3D806BF837FDBD6D FOREIGN KEY (consumer_id) REFERENCES UserEntity (id)');
        $this->addSql('CREATE INDEX IDX_3D806BF837FDBD6D ON FoodEntity (consumer_id)');
        $this->addSql('ALTER TABLE categoryentity_foodentity DROP PRIMARY KEY, ADD PRIMARY KEY (foodentity_id, categoryentity_id)');
        $this->addSql('ALTER TABLE HouseholdEntity ADD name VARCHAR(255) NOT NULL, ADD token VARCHAR(255) NOT NULL, ADD moderator_id INT NOT NULL');
        $this->addSql('ALTER TABLE HouseholdEntity ADD CONSTRAINT FK_DC751E25D0AFA354 FOREIGN KEY (moderator_id) REFERENCES UserEntity (id) ON DELETE RESTRICT');
        $this->addSql('CREATE UNIQUE INDEX UNIQ_DC751E25D0AFA354 ON HouseholdEntity (moderator_id)');
        $this->addSql('ALTER TABLE UserEntity ADD password VARCHAR(255) NOT NULL, ADD isAdmin TINYINT DEFAULT 0 NOT NULL, CHANGE authLevel householdRequest INT NOT NULL');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE CategoryEntity DROP FOREIGN KEY FK_A6EB9A53E79FF843');
        $this->addSql('DROP INDEX IDX_A6EB9A53E79FF843 ON CategoryEntity');
        $this->addSql('ALTER TABLE CategoryEntity DROP household_id');
        $this->addSql('ALTER TABLE categoryentity_foodentity DROP PRIMARY KEY, ADD PRIMARY KEY (categoryentity_id, foodentity_id)');
        $this->addSql('ALTER TABLE FoodEntity DROP FOREIGN KEY FK_3D806BF837FDBD6D');
        $this->addSql('DROP INDEX IDX_3D806BF837FDBD6D ON FoodEntity');
        $this->addSql('ALTER TABLE FoodEntity ADD consumed TINYINT NOT NULL, DROP consumedAt, DROP trashed, DROP discardedAt, DROP consumer_id');
        $this->addSql('ALTER TABLE HouseholdEntity DROP FOREIGN KEY FK_DC751E25D0AFA354');
        $this->addSql('DROP INDEX UNIQ_DC751E25D0AFA354 ON HouseholdEntity');
        $this->addSql('ALTER TABLE HouseholdEntity DROP name, DROP token, DROP moderator_id');
        $this->addSql('ALTER TABLE UserEntity DROP password, DROP isAdmin, CHANGE householdRequest authLevel INT NOT NULL');
    }

    public function isTransactional(): bool
    {
        return false;
    }
}
