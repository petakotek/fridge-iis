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
        Assert::exception(fn() => $service->removeShelf($household, $member, $shelf), \DomainException::class);
        Assert::same(1, $this->em->getRepository(ShelfEntity::class)->count([]));
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
