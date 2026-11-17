<?php declare(strict_types=1);

namespace Database\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20261116190000 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Create the system administrator without household membership.';
    }

    public function up(Schema $schema): void
    {
        $env = parse_ini_file(__DIR__ . '/../.env', scanner_mode: INI_SCANNER_RAW) ?: [];
        $email = trim($env['ADMIN_EMAIL'] ?? 'admin@spiz.local');
        $password = $env['ADMIN_PASSWORD'] ?? 'Admin12345!';
        $this->abortIf(!filter_var($email, FILTER_VALIDATE_EMAIL) || mb_strlen($email) > 255, 'Invalid ADMIN_EMAIL.');
        $this->abortIf(mb_strlen($password) < 8, 'ADMIN_PASSWORD must contain at least 8 characters.');
        $this->abortIf((bool) $this->connection->fetchOne('SELECT id FROM UserEntity WHERE email = ?', [$email]), 'ADMIN_EMAIL already belongs to an existing account. Choose another email in .env.');
        $this->addSql(
            'INSERT INTO UserEntity (name, surname, email, password, isAdmin, household_id, householdRequest) VALUES (?, ?, ?, ?, 1, NULL, NULL)',
            ['Administrátor', 'Systému', $email, password_hash($password, PASSWORD_DEFAULT)],
        );
    }

    public function down(Schema $schema): void
    {
        $this->throwIrreversibleMigrationException('The administrator account may have been edited or used since its creation.');
    }
}
