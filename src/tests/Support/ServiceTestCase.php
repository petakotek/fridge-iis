<?php

declare(strict_types=1);

namespace Tests\Support;

use App\Model\Doctrine\EntityManagerFactory;
use App\Model\Entity\ApplianceEntity;
use App\Model\Entity\CategoryEntity;
use App\Model\Entity\FoodEntity;
use App\Model\Entity\HouseholdEntity;
use App\Model\Entity\ShelfEntity;
use App\Model\Entity\UserEntity;
use Doctrine\ORM\EntityManager;
use Doctrine\ORM\Tools\SchemaTool;
use Tester\TestCase;

abstract class ServiceTestCase extends TestCase
{
    protected EntityManager $em;
    private int $userSequence = 0;

    protected function setUp(): void
    {
        if (!extension_loaded('pdo_sqlite')) {
            throw new \RuntimeException('Tests require pdo_sqlite. Enable it in the PHP CLI configuration.');
        }

        // Deliberately do not load Bootstrap, .env or application database credentials.
        $this->em = EntityManagerFactory::create(
            ['driver' => 'pdo_sqlite', 'memory' => true],
            __DIR__ . '/../../app/Model/Entity',
            sys_get_temp_dir(),
            true,
        );
        $this->em->getConnection()->executeStatement('PRAGMA foreign_keys = ON');
        (new SchemaTool($this->em))->createSchema($this->em->getMetadataFactory()->getAllMetadata());
        $this->userSequence = 0;
    }

    protected function tearDown(): void
    {
        if (isset($this->em)) {
            $this->em->close();
            $this->em->getConnection()->close();
        }
    }

    protected function user(): UserEntity
    {
        $user = new UserEntity('Jan', 'Novak', 'user' . ++$this->userSequence . '@example.test');
        $user->setPassword('fixture-password');
        $this->save($user);
        return $user;
    }

    protected function household(?UserEntity $moderator = null): HouseholdEntity
    {
        $household = new HouseholdEntity('Test household');
        $household->setModerator($moderator ?? $this->user());
        $household->generateToken();
        $this->save($household);
        return $household;
    }

    protected function appliance(HouseholdEntity $household): ApplianceEntity
    {
        $appliance = new ApplianceEntity('Fridge');
        $household->addAppliance($appliance);
        $this->save($appliance);
        return $appliance;
    }

    protected function shelf(HouseholdEntity $household, int $capacity = 1000): ShelfEntity
    {
        $shelf = new ShelfEntity($capacity);
        $shelf->setName('Test shelf');
        $this->appliance($household)->addShelf($shelf);
        $this->save($shelf);
        return $shelf;
    }

    protected function food(ShelfEntity $shelf, int $weight = 100): FoodEntity
    {
        $food = new FoodEntity('Yoghurt', '8591234567890', 19.90, 60, 4, 3, 5, 0, $weight);
        $shelf->addFood($food);
        $this->save($food);
        return $food;
    }

    protected function category(HouseholdEntity $household, string $name = 'Dairy', ?CategoryEntity $parent = null): CategoryEntity
    {
        $category = new CategoryEntity($household, $name);
        $category->setParent($parent);
        $this->save($category);
        return $category;
    }

    protected function save(object ...$entities): void
    {
        foreach ($entities as $entity) {
            $this->em->persist($entity);
        }
        $this->em->flush();
    }
}
