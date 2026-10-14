<?php

namespace App\Model\Doctrine;
use Doctrine\Common\EventManager;
use Doctrine\DBAL\DriverManager;
use Doctrine\ORM\EntityManager;
use Doctrine\ORM\ORMSetup;
use Gedmo\Tree\TreeListener;
use Symfony\Component\Cache\Adapter\ArrayAdapter;
use Symfony\Component\Cache\Adapter\FilesystemAdapter;

class EntityManagerFactory
{
    public static function create(array $connectionParameters,
                                  string $entityDirectory,
                                  string $cacheDirectory,
                                  bool $debugMode) : EntityManager {
        // Development and CLI commands (especially migrations) need current mapping.
        $cache = $debugMode || PHP_SAPI === 'cli'
            ? new ArrayAdapter()
            : new FilesystemAdapter(
                namespace: 'doctrine_metadata',
                defaultLifetime: 0,
                directory: $cacheDirectory,
            );

        $configuration = ORMSetup::createAttributeMetadataConfiguration(
            paths: [$entityDirectory],
            isDevMode: $debugMode,
            cache: $cache,
        );

        $configuration->enableNativeLazyObjects(true);

        $eventManager = new EventManager();
        $eventManager->addEventSubscriber(new TreeListener());

        $connection = DriverManager::getConnection($connectionParameters);

        return new EntityManager(
            $connection,
            $configuration,
            $eventManager,
        );
    }
}
