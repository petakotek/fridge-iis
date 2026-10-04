<?php

use App\Bootstrap;
use Doctrine\Migrations\Configuration\EntityManager\ExistingEntityManager;
use Doctrine\Migrations\Configuration\Migration\ConfigurationArray;
use Doctrine\Migrations\DependencyFactory;
use Doctrine\ORM\EntityManagerInterface;

require_once __DIR__ . '/vendor/autoload.php';

$container = (new Bootstrap())->bootWebApplication();
$entityManager = $container->getByType(EntityManagerInterface::class);

return DependencyFactory::fromEntityManager(
    new ConfigurationArray([
        'table_storage' => [
            'table_name' => 'doctrine_migration_versions',
        ],
        'migrations_paths' => [
            'Database\Migrations' => __DIR__ . '/migrations',
        ],
        'all_or_nothing' => false,
        'transactional' => false,
        'check_database_platform' => true,
    ]),
    new ExistingEntityManager($entityManager),
);