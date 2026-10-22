<?php

/** @testCase */

declare(strict_types=1);

namespace Tests\Services;

use App\Model\Entity\HouseholdEntity;
use App\Model\Entity\UserEntity;
use App\Model\Services\HouseholdService;
use Tester\Assert;
use Tests\Support\ServiceTestCase;

require __DIR__ . '/../bootstrap.php';

final class HouseholdServiceTest extends ServiceTestCase
{
    public function testCreateHouseholdPersistsModeratorMembershipAndToken(): void
    {
        $moderator = $this->user();
        $household = (new HouseholdService($this->em))->createHousehold('  Home  ', $moderator);
        $id = $household->getId();
        Assert::same($household, $moderator->getHousehold());
        Assert::true($household->isInHousehold($moderator));
        $this->em->clear();

        $stored = (new HouseholdService($this->em))->getHouseholdById($id);
        Assert::same('Home', $stored->getName());
        Assert::match('~^[a-zA-Z0-9]{10}$~', $stored->getToken());
        Assert::same($moderator->getId(), $stored->getModerator()->getId());
        Assert::same($stored, $stored->getModerator()->getHousehold());
        Assert::true($stored->isInHousehold($stored->getModerator()));
    }

    public function testCreateHouseholdRejectsInvalidName(): void
    {
        $moderator = $this->user();
        foreach ([' ', str_repeat('x', 256)] as $name) {
            Assert::exception(fn() => (new HouseholdService($this->em))->createHousehold($name, $moderator), \InvalidArgumentException::class);
        }
        Assert::null($moderator->getHousehold());
        Assert::same(0, $this->em->getRepository(HouseholdEntity::class)->count([]));
    }

    public function testLookupByIdAndToken(): void
    {
        $household = $this->household();
        $service = new HouseholdService($this->em);
        Assert::same($household, $service->getHouseholdById($household->getId()));
        Assert::same($household, $service->getHouseholdByToken($household->getToken()));
        Assert::exception(fn() => $service->getHouseholdById(999), \InvalidArgumentException::class);
        Assert::exception(fn() => $service->getHouseholdByToken('missing'), \InvalidArgumentException::class);
    }

    public function testUpdateNamePersistsChange(): void
    {
        $household = $this->household();
        (new HouseholdService($this->em))->updateName($household, $household->getModerator(), '  New home  ');
        $this->em->refresh($household);
        Assert::same('New home', $household->getName());
    }

    public function testRegenerateTokenInvalidatesOldTokenAndKeepsMembersAndRequests(): void
    {
        $household = $this->household();
        $member = $this->user();
        $household->addUser($member);
        $requester = $this->user();
        $service = new HouseholdService($this->em);
        $oldToken = $household->getToken();
        $service->createHouseholdRequest($household, $requester, $oldToken);
        $this->em->flush();

        $service->regenerateToken($household, $household->getModerator());
        $newToken = $household->getToken();
        Assert::notSame($oldToken, $newToken);
        $householdId = $household->getId();
        $memberId = $member->getId();
        $requesterId = $requester->getId();
        $this->em->clear();

        $stored = $service->getHouseholdById($householdId);
        Assert::exception(fn() => $service->getHouseholdByToken($oldToken), \InvalidArgumentException::class);
        Assert::same($stored, $service->getHouseholdByToken($newToken));
        Assert::same($stored, $this->em->find(UserEntity::class, $memberId)->getHousehold());
        Assert::same($stored, $this->em->find(UserEntity::class, $requesterId)->getHouseholdRequest());
    }

    public function testNonModeratorCannotManageHousehold(): void
    {
        $household = $this->household();
        $member = $this->user();
        $household->addUser($member);
        $requester = $this->user();
        $requester->setRequest($household);
        $this->em->flush();
        $service = new HouseholdService($this->em);
        $token = $household->getToken();

        foreach ([
            fn() => $service->updateName($household, $member, 'Unauthorized'),
            fn() => $service->regenerateToken($household, $member),
            fn() => $service->addUser($requester, $member, $household),
            fn() => $service->removeHouseholdUser($household, $member, $household->getModerator()),
            fn() => $service->acceptHouseholdRequest($household, $member, $requester),
            fn() => $service->removeHouseholdRequest($household, $member, $requester),
            fn() => $service->removeHousehold($household, $member),
        ] as $operation) {
            Assert::exception($operation, \DomainException::class, 'Current user is not moderator for this household.');
        }
        Assert::same('Test household', $household->getName());
        Assert::same($token, $household->getToken());
        Assert::same($household, $member->getHousehold());
        Assert::null($requester->getHousehold());
        Assert::same($household, $requester->getHouseholdRequest());
        Assert::same(1, $this->em->getRepository(HouseholdEntity::class)->count([]));
    }

    public function testAddUserSynchronizesBothSidesAndIsIdempotent(): void
    {
        $household = $this->household();
        $member = $this->user();
        $service = new HouseholdService($this->em);
        $service->addUser($member, $household->getModerator(), $household);
        $service->addUser($member, $household->getModerator(), $household);
        Assert::true($household->isInHousehold($member));
        $this->em->refresh($member);
        Assert::same($household, $member->getHousehold());
        Assert::same(2, $this->em->getRepository(UserEntity::class)->count(['household' => $household]));
    }

    public function testAddUserRejectsMemberOfAnotherHousehold(): void
    {
        $household = $this->household();
        $other = $this->household();
        $member = $this->user();
        $other->addUser($member);
        $this->em->flush();
        Assert::exception(fn() => (new HouseholdService($this->em))->addUser($member, $household->getModerator(), $household), \DomainException::class);
        Assert::same($other, $member->getHousehold());
        Assert::false($household->isInHousehold($member));
    }

    public function testRemoveMemberKeepsUserAccount(): void
    {
        $household = $this->household();
        $member = $this->user();
        $household->addUser($member);
        $this->em->flush();
        (new HouseholdService($this->em))->removeHouseholdUser($household, $household->getModerator(), $member);
        Assert::false($household->isInHousehold($member));
        $this->em->refresh($member);
        Assert::null($member->getHousehold());
        Assert::same(2, $this->em->getRepository(UserEntity::class)->count([]));
    }

    public function testLeaveHouseholdPersistsAfterLazyCollectionLoads(): void
    {
        $household = $this->household();
        $member = $this->user();
        $household->addUser($member);
        $this->em->flush();
        $memberId = $member->getId();
        $this->em->clear();

        $member = $this->em->find(UserEntity::class, $memberId);
        (new HouseholdService($this->em))->leaveHousehold($member);
        $this->em->clear();

        Assert::null($this->em->find(UserEntity::class, $memberId)->getHousehold());
    }

    public function testModeratorRemovalPersistsAfterLazyCollectionLoads(): void
    {
        $household = $this->household();
        $member = $this->user();
        $household->addUser($member);
        $this->em->flush();
        $householdId = $household->getId();
        $memberId = $member->getId();
        $this->em->clear();

        $household = $this->em->find(HouseholdEntity::class, $householdId);
        $member = $this->em->find(UserEntity::class, $memberId);
        (new HouseholdService($this->em))->removeHouseholdUser($household, $household->getModerator(), $member);
        $this->em->clear();

        Assert::null($this->em->find(UserEntity::class, $memberId)->getHousehold());
    }

    public function testModeratorCannotLeaveHousehold(): void
    {
        $household = $this->household();
        Assert::exception(
            fn() => (new HouseholdService($this->em))->leaveHousehold($household->getModerator()),
            \DomainException::class,
        );
    }

    public function testCannotRemoveModeratorOrForeignUser(): void
    {
        $household = $this->household();
        $outsider = $this->user();
        $service = new HouseholdService($this->em);
        Assert::exception(fn() => $service->removeHouseholdUser($household, $household->getModerator(), $household->getModerator()), \DomainException::class);
        Assert::exception(fn() => $service->removeHouseholdUser($household, $household->getModerator(), $outsider), \DomainException::class);
        Assert::true($household->isInHousehold($household->getModerator()));
    }

    public function testRemoveHouseholdDetachesAllMembersAndKeepsAccounts(): void
    {
        $household = $this->household();
        $moderator = $household->getModerator();
        $member = $this->user();
        $household->addUser($member);
        $this->em->flush();
        $id = $household->getId();
        (new HouseholdService($this->em))->removeHousehold($household, $moderator);
        Assert::false($household->isInHousehold($member));
        Assert::false($household->isInHousehold($moderator));
        $this->em->clear();
        Assert::null($this->em->find(HouseholdEntity::class, $id));
        Assert::same(2, $this->em->getRepository(UserEntity::class)->count([]));
        Assert::null($this->em->find(UserEntity::class, $member->getId())->getHousehold());
        Assert::null($this->em->find(UserEntity::class, $moderator->getId())->getHousehold());
    }

    public function testRequestRequiresMatchingTokenAndIsScopedToHousehold(): void
    {
        $household = $this->household();
        $other = $this->household();
        $requester = $this->user();
        $service = new HouseholdService($this->em);
        $service->createHouseholdRequest($household, $requester, 'invalid');
        $this->em->refresh($requester);
        Assert::null($requester->getHouseholdRequest());
        $service->createHouseholdRequest($household, $requester, $household->getToken());
        $this->em->refresh($requester);
        Assert::same($household, $requester->getHouseholdRequest());
        Assert::same([$requester], $service->getHouseholdRequests($household));
        Assert::same([], $service->getHouseholdRequests($other));
    }

    public function testRequesterCanCancelOwnRequest(): void
    {
        $household = $this->household();
        $requester = $this->user();
        $requester->setRequest($household);
        $this->em->flush();
        $requesterId = $requester->getId();

        (new HouseholdService($this->em))->cancelOwnRequest($requester);
        $this->em->clear();

        Assert::null($this->em->find(UserEntity::class, $requesterId)->getHouseholdRequest());
    }

    public function testExistingMemberCannotRequestAnotherHousehold(): void
    {
        $household = $this->household();
        $other = $this->household();
        $member = $household->getModerator();
        (new HouseholdService($this->em))->createHouseholdRequest($other, $member, $other->getToken());
        $this->em->refresh($member);
        Assert::null($member->getHouseholdRequest());
        Assert::same($household, $member->getHousehold());
    }

    public function testAcceptRequestAddsMemberAndClearsRequest(): void
    {
        $household = $this->household();
        $requester = $this->user();
        $requester->setRequest($household);
        $this->em->flush();
        (new HouseholdService($this->em))->acceptHouseholdRequest($household, $household->getModerator(), $requester);
        Assert::true($household->isInHousehold($requester));
        $this->em->refresh($requester);
        Assert::same($household, $requester->getHousehold());
        Assert::null($requester->getHouseholdRequest());
    }

    public function testAcceptForeignRequestDoesNotChangeIt(): void
    {
        $household = $this->household();
        $other = $this->household();
        $requester = $this->user();
        $requester->setRequest($other);
        $this->em->flush();
        (new HouseholdService($this->em))->acceptHouseholdRequest($household, $household->getModerator(), $requester);
        $this->em->refresh($requester);
        Assert::null($requester->getHousehold());
        Assert::same($other, $requester->getHouseholdRequest());
    }

    public function testRemoveRequestDoesNotAddMember(): void
    {
        $household = $this->household();
        $requester = $this->user();
        $requester->setRequest($household);
        $this->em->flush();
        (new HouseholdService($this->em))->removeHouseholdRequest($household, $household->getModerator(), $requester);
        $this->em->refresh($requester);
        Assert::null($requester->getHouseholdRequest());
        Assert::null($requester->getHousehold());
    }

    public function testRemoveForeignRequestIsRejected(): void
    {
        $household = $this->household();
        $other = $this->household();
        $requester = $this->user();
        $requester->setRequest($other);
        $this->em->flush();
        Assert::exception(fn() => (new HouseholdService($this->em))->removeHouseholdRequest($household, $household->getModerator(), $requester), \DomainException::class);
        Assert::same($other, $requester->getHouseholdRequest());
    }

    public function testModeratorCannotAcceptOrRejectOwnRequest(): void
    {
        $household = $this->household();
        $moderator = $household->getModerator();
        $service = new HouseholdService($this->em);
        Assert::exception(fn() => $service->acceptHouseholdRequest($household, $moderator, $moderator), \DomainException::class);
        Assert::exception(fn() => $service->removeHouseholdRequest($household, $moderator, $moderator), \DomainException::class);
    }
}

(new HouseholdServiceTest())->run();
