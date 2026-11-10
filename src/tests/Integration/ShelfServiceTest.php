<?php

/** @testCase */

declare(strict_types=1);

namespace Tests\Services;

use App\Model\Entity\ShelfEntity;
use App\Model\Services\ShelfService;
use Tester\Assert;
use Tests\Support\ServiceTestCase;

require __DIR__ . '/../bootstrap.php';

final class ShelfServiceTest extends ServiceTestCase
{
    public function testAddAndLookupShelf(): void
    {
        $household = $this->household();
        $appliance = $this->appliance($household);
        $service = new ShelfService($this->em);
        $shelf = $service->addShelf($household, $household->getModerator(), 500, $appliance);
        $id = $shelf->getId();
        $this->em->clear();
        $stored = $service->getShelfById($id);
        Assert::same(500, $stored->getShelfCapacity());
        Assert::same($appliance->getId(), $stored->getAppliance()->getId());
    }

    public function testGetShelvesIsScopedToAppliance(): void
    {
        $household = $this->household();
        $shelf = $this->shelf($household);
        $emptyAppliance = $this->appliance($household);
        $this->shelf($this->household());
        $service = new ShelfService($this->em);
        Assert::same([$shelf], $service->getShelves($shelf->getAppliance()));
        Assert::same([], $service->getShelves($emptyAppliance));
    }

    public function testMissingShelfIsRejected(): void
    {
        Assert::exception(fn() => (new ShelfService($this->em))->getShelfById(999), \DomainException::class, 'Shelf not found.');
    }

    public function testNonPositiveCapacityIsRejected(): void
    {
        $household = $this->household();
        $appliance = $this->appliance($household);
        foreach ([0, -1] as $capacity) {
            Assert::exception(fn() => (new ShelfService($this->em))->addShelf($household, $household->getModerator(), $capacity, $appliance), \InvalidArgumentException::class);
        }
        Assert::same(0, $this->em->getRepository(ShelfEntity::class)->count([]));
    }

    public function testMemberCannotManageShelves(): void
    {
        $household = $this->household();
        $shelf = $this->shelf($household);
        $member = $this->user();
        $household->addUser($member);
        $this->em->flush();
        $service = new ShelfService($this->em);
        Assert::exception(fn() => $service->addShelf($household, $member, 500, $shelf->getAppliance()), \DomainException::class);
        Assert::exception(fn() => $service->updateShelf($household, $member, $shelf, 'Changed', 500), \DomainException::class);
        Assert::exception(fn() => $service->removeShelf($household, $member, $shelf), \DomainException::class);
        Assert::same(1, $this->em->getRepository(ShelfEntity::class)->count([]));
    }

    public function testUpdateShelfPersistsNameAndCapacity(): void
    {
        $household = $this->household();
        $shelf = $this->shelf($household);
        (new ShelfService($this->em))->updateShelf($household, $household->getModerator(), $shelf, '  Upper shelf  ', 750);
        $this->em->refresh($shelf);
        Assert::same('Upper shelf', $shelf->getName());
        Assert::same(750, $shelf->getShelfCapacity());
    }

    public function testForeignShelfManagementIsRejected(): void
    {
        $household = $this->household();
        $shelf = $this->shelf($this->household());
        $service = new ShelfService($this->em);
        foreach ([
            fn() => $service->addShelf($household, $household->getModerator(), 500, $shelf->getAppliance()),
            fn() => $service->updateShelf($household, $household->getModerator(), $shelf, 'Changed', 500),
            fn() => $service->removeShelf($household, $household->getModerator(), $shelf),
        ] as $operation) {
            Assert::exception($operation, \DomainException::class);
        }
        Assert::same('Test shelf', $shelf->getName());
        Assert::same(1, $this->em->getRepository(ShelfEntity::class)->count([]));
    }

    public function testInvalidUpdateLeavesShelfUnchanged(): void
    {
        $household = $this->household();
        $shelf = $this->shelf($household);
        $this->food($shelf, 100);
        $service = new ShelfService($this->em);
        Assert::exception(fn() => $service->updateShelf($household, $household->getModerator(), $shelf, 'Changed', 99), \DomainException::class);
        foreach (['', '   ', str_repeat('x', 256)] as $name) {
            Assert::exception(fn() => $service->updateShelf($household, $household->getModerator(), $shelf, $name, 500), \InvalidArgumentException::class);
        }
        Assert::exception(fn() => $service->updateShelf($household, $household->getModerator(), $shelf, 'Changed', 0), \DomainException::class);
        Assert::same('Test shelf', $shelf->getName());
        Assert::same(1000, $shelf->getShelfCapacity());
    }

    public function testNamedShelfCreationAndValidation(): void
    {
        $household = $this->household();
        $appliance = $this->appliance($household);
        $service = new ShelfService($this->em);
        $shelf = $service->addShelf($household, $household->getModerator(), 500, $appliance, '  Upper shelf  ');
        $this->em->refresh($shelf);
        Assert::same('Upper shelf', $shelf->getName());
        Assert::exception(fn() => $service->addShelf($household, $household->getModerator(), 500, $appliance, ' '), \InvalidArgumentException::class);
        Assert::same(1, $this->em->getRepository(ShelfEntity::class)->count([]));
    }

    public function testRemoveShelfCascadesToFood(): void
    {
        $household = $this->household();
        $shelf = $this->shelf($household);
        $foodId = $this->food($shelf)->getId();
        (new ShelfService($this->em))->removeShelf($household, $household->getModerator(), $shelf);
        $this->em->clear();
        Assert::null($this->em->find(\App\Model\Entity\FoodEntity::class, $foodId));
    }

    public function testRemoveEmptyShelf(): void
    {
        $household = $this->household();
        $shelf = $this->shelf($household);
        $id = $shelf->getId();
        (new ShelfService($this->em))->removeShelf($household, $household->getModerator(), $shelf);
        $this->em->clear();
        Assert::null($this->em->find(ShelfEntity::class, $id));
    }
}

(new ShelfServiceTest())->run();
