<?php

/** @testCase */

declare(strict_types=1);

namespace Tests\Services;

use App\Model\Entity\ApplianceEntity;
use App\Model\Services\ApplianceService;
use Tester\Assert;
use Tests\Support\ServiceTestCase;

require __DIR__ . '/../bootstrap.php';

final class ApplianceServiceTest extends ServiceTestCase
{
    public function testAddAndLookupAppliance(): void
    {
        $household = $this->household();
        $service = new ApplianceService($this->em);
        $appliance = $service->addAppliance($household, $household->getModerator(), '  Fridge  ');
        $id = $appliance->getId();
        $this->em->clear();
        $stored = $service->getApplianceById($id);
        Assert::same('Fridge', $stored->getName());
        Assert::same($household->getId(), $stored->getHousehold()->getId());
    }

    public function testListsOnlyHouseholdAppliancesInNameOrder(): void
    {
        $household = $this->household();
        $emptyHousehold = $this->household();
        $service = new ApplianceService($this->em);
        $fridge = $service->addAppliance($household, $household->getModerator(), 'Fridge');
        $freezer = $service->addAppliance($household, $household->getModerator(), 'Freezer');
        $this->appliance($this->household());
        Assert::same([$freezer, $fridge], $service->getAppliances($household));
        Assert::same([], $service->getAppliances($emptyHousehold));
    }

    public function testMissingApplianceIsRejected(): void
    {
        Assert::exception(fn() => (new ApplianceService($this->em))->getApplianceById(999), \InvalidArgumentException::class);
    }

    public function testRenamePersistsChange(): void
    {
        $household = $this->household();
        $appliance = $this->appliance($household);
        (new ApplianceService($this->em))->updateApplianceName($appliance, $household->getModerator(), $household, '  Freezer  ');
        $this->em->refresh($appliance);
        Assert::same('Freezer', $appliance->getName());
    }

    public function testTooLongNameIsRejectedWithoutSaving(): void
    {
        $household = $this->household();
        Assert::exception(fn() => (new ApplianceService($this->em))->addAppliance($household, $household->getModerator(), str_repeat('x', 256)), \InvalidArgumentException::class);
        Assert::same(0, $this->em->getRepository(ApplianceEntity::class)->count([]));
    }

    public function testMemberCannotManageAppliances(): void
    {
        $household = $this->household();
        $appliance = $this->appliance($household);
        $member = $this->user();
        $household->addUser($member);
        $this->em->flush();
        $service = new ApplianceService($this->em);
        foreach ([
            fn() => $service->addAppliance($household, $member, 'Freezer'),
            fn() => $service->updateApplianceName($appliance, $member, $household, 'Freezer'),
            fn() => $service->removeAppliance($household, $member, $appliance),
        ] as $operation) {
            Assert::exception($operation, \DomainException::class);
        }
        Assert::same('Fridge', $appliance->getName());
        Assert::same(1, $this->em->getRepository(ApplianceEntity::class)->count([]));
    }

    public function testRemoveEmptyAppliance(): void
    {
        $household = $this->household();
        $appliance = $this->appliance($household);
        $id = $appliance->getId();
        $service = new ApplianceService($this->em);
        $service->removeAppliance($household, $household->getModerator(), $appliance);
        $this->em->clear();
        Assert::null($this->em->find(ApplianceEntity::class, $id));
    }

    public function testRemoveForeignApplianceIsRejected(): void
    {
        $household = $this->household();
        $foreign = $this->appliance($this->household());
        Assert::exception(fn() => (new ApplianceService($this->em))->removeAppliance($household, $household->getModerator(), $foreign), \DomainException::class);
        Assert::same(1, $this->em->getRepository(ApplianceEntity::class)->count([]));
    }

    public function testRenameForeignApplianceIsRejected(): void
    {
        $household = $this->household();
        $foreign = $this->appliance($this->household());
        Assert::exception(fn() => (new ApplianceService($this->em))->updateApplianceName($foreign, $household->getModerator(), $household, 'Unauthorized'), \DomainException::class);
        $this->em->refresh($foreign);
        Assert::same('Fridge', $foreign->getName());
    }
}

(new ApplianceServiceTest())->run();
