<?php

/** @testCase */

declare(strict_types=1);

namespace Tests\Services;

use App\Model\Entity\FoodEntity;
use App\Model\Entity\HouseholdEntity;
use App\Model\Entity\UserEntity;
use App\Model\Security\UserAuthenticator;
use App\Model\Services\AdminService;
use App\Model\Services\HouseholdService;
use App\Model\Services\UserService;
use Tester\Assert;
use Tests\Support\ServiceTestCase;

require __DIR__ . '/../bootstrap.php';

final class AdminServiceTest extends ServiceTestCase
{
    private function service(): AdminService
    {
        return new AdminService($this->em, new UserService($this->em), new HouseholdService($this->em));
    }

    private function admin(): UserEntity
    {
        $user = $this->user();
        $user->setAdminLevel();
        $this->save($user);
        return $user;
    }

    public function testEveryAdminOperationRejectsOrdinaryUsersAndHouseholdModerators(): void
    {
        $household = $this->household();
        $member = $this->user();
        $household->addUser($member);
        $this->save($member);
        $service = $this->service();
        foreach ([$this->user(), $household->getModerator(), $member] as $actor) {
            foreach ([
                fn() => $service->getUsers($actor),
                fn() => $service->getHouseholds($actor),
                fn() => $service->createUser($actor, 'Eva', 'Nova', 'eva@example.test', 'password123'),
                fn() => $service->updateUser($actor, $member, 'Eva', 'Nova', 'eva@example.test', null, true),
                fn() => $service->deleteUser($actor, $member),
                fn() => $service->createHousehold($actor, 'Forbidden'),
                fn() => $service->updateHousehold($actor, $household, 'Forbidden'),
                fn() => $service->deleteHousehold($actor, $household),
                fn() => $service->addMember($actor, $household, $member),
                fn() => $service->removeMember($actor, $household, $member),
                fn() => $service->setModerator($actor, $household, $member),
            ] as $operation) {
                Assert::exception($operation, \DomainException::class, 'Přístup má pouze administrátor systému.');
            }
        }
        Assert::same('Test household', $household->getName());
        Assert::same($household, $member->getHousehold());
    }

    public function testUserCreationAndEditingPersistProfilePasswordAndRoles(): void
    {
        $admin = $this->admin();
        $service = $this->service();
        $user = $service->createUser($admin, 'Eva', 'Nova', 'eva@example.test', 'password123');
        Assert::false($user->isAdmin());
        $otherAdmin = $service->createUser($admin, 'Admin', 'Druhy', 'other@example.test', 'password123', true);
        Assert::true($otherAdmin->isAdmin());
        Assert::null($otherAdmin->getHousehold());
        $service->updateUser($admin, $user, 'Ema', 'Novotna', 'ema@example.test', 'changed-password', true);
        $id = $user->getId();
        $this->em->clear();
        $stored = $this->em->find(UserEntity::class, $id);
        Assert::same('Ema', $stored->getName());
        Assert::same('Novotna', $stored->getSurname());
        Assert::true($stored->verifyPassword('changed-password'));
        Assert::true($stored->isAdmin());
        $authenticator = new UserAuthenticator(new UserService($this->em));
        Assert::same(['admin'], $authenticator->authenticate('ema@example.test', 'changed-password')->getRoles());
        $admin = $this->em->find(UserEntity::class, $admin->getId());
        $service->updateUser($admin, $stored, 'Ema', 'Novotna', 'ema@example.test', null, false);
        Assert::true($stored->verifyPassword('changed-password'));
        Assert::same(['user'], $authenticator->authenticate('ema@example.test', 'changed-password')->getRoles());
    }

    public function testInvalidProfilesDoNotGrantAdminRoleOrOverwriteExistingAccount(): void
    {
        $admin = $this->admin();
        $user = $this->user();
        $service = $this->service();
        Assert::exception(fn() => $service->updateUser($admin, $user, 'Eva', 'Nova', $admin->getEmail(), null, true), \DomainException::class);
        Assert::exception(fn() => $service->updateUser($admin, $user, '', 'Nova', 'new@example.test', null, true), \InvalidArgumentException::class);
        Assert::exception(fn() => $service->createUser($admin, 'Eva', 'Nova', 'eva@example.test', 'short'), \InvalidArgumentException::class);
        Assert::false($user->isAdmin());
        Assert::same(2, $this->em->getRepository(UserEntity::class)->count([]));
    }

    public function testSelfDeletionAndDemotionAreRejected(): void
    {
        $admin = $this->admin();
        $service = $this->service();
        Assert::exception(fn() => $service->deleteUser($admin, $admin), \DomainException::class);
        Assert::exception(fn() => $service->updateUser($admin, $admin, 'A', 'B', 'a@example.test', null, false), \DomainException::class);
        Assert::true($admin->isAdmin());
        Assert::same(1, $this->em->getRepository(UserEntity::class)->count([]));
    }

    public function testAdministratorCannotBecomeMemberModeratorOrRequester(): void
    {
        $admin = $this->admin();
        $household = $this->household();
        $service = $this->service();
        foreach ([
            fn() => $service->addMember($admin, $household, $admin),
            fn() => $service->createHousehold($admin, 'Invalid', $admin),
            fn() => $household->addUser($admin),
            fn() => $household->setModerator($admin),
            fn() => (new HouseholdService($this->em))->createHousehold('Invalid', $admin),
            fn() => (new HouseholdService($this->em))->createHouseholdRequest($household, $admin, $household->getToken()),
        ] as $operation) {
            Assert::exception($operation, \DomainException::class);
        }
        Assert::null($admin->getHousehold());
        Assert::null($admin->getHouseholdRequest());
        Assert::same(1, $this->em->getRepository(HouseholdEntity::class)->count([]));
    }

    public function testHouseholdsCanBeCreatedEmptyOrForAnotherUser(): void
    {
        $admin = $this->admin();
        $service = $this->service();
        $empty = $service->createHousehold($admin, 'Empty');
        Assert::null($empty->getModerator());
        $member = $this->user();
        $member->setRequest($empty);
        $this->save($member);
        $household = $service->createHousehold($admin, 'Family', $member);
        Assert::same($member, $household->getModerator());
        Assert::same($household, $member->getHousehold());
        Assert::null($member->getHouseholdRequest());
        Assert::null($admin->getHousehold());
        $service->updateHousehold($admin, $household, 'Renamed');
        $this->em->refresh($household);
        Assert::same('Renamed', $household->getName());
    }

    public function testAddingMembersCancelsRequestsAndRejectsOtherHouseholdMembers(): void
    {
        $admin = $this->admin();
        $household = $this->household();
        $other = $this->household();
        $member = $this->user();
        $member->setRequest($other);
        $this->save($member);
        $service = $this->service();
        $service->addMember($admin, $household, $member);
        $this->em->refresh($member);
        Assert::same($household, $member->getHousehold());
        Assert::null($member->getHouseholdRequest());
        Assert::exception(fn() => $service->addMember($admin, $other, $member), \DomainException::class);
        Assert::exception(fn() => $service->removeMember($admin, $other, $member), \DomainException::class);
        Assert::exception(fn() => $service->setModerator($admin, $other, $member), \DomainException::class);
    }

    public function testModeratorCanBeRemovedAndReplacedWhileAdminStaysOutside(): void
    {
        $admin = $this->admin();
        $household = $this->household();
        $oldModerator = $household->getModerator();
        $member = $this->user();
        $service = $this->service();
        $service->addMember($admin, $household, $member);
        $service->removeMember($admin, $household, $oldModerator);
        Assert::null($household->getModerator());
        Assert::null($oldModerator->getHousehold());
        $service->setModerator($admin, $household, $member);
        $householdId = $household->getId();
        $this->em->clear();
        Assert::same($member->getId(), $this->em->find(HouseholdEntity::class, $householdId)->getModerator()->getId());
        Assert::null($this->em->find(UserEntity::class, $admin->getId())->getHousehold());
    }

    public function testPromotionRequiresLeavingHouseholdAndCancelsPendingRequest(): void
    {
        $admin = $this->admin();
        $household = $this->household();
        $member = $household->getModerator();
        $service = $this->service();
        Assert::exception(fn() => $service->updateUser($admin, $member, 'A', 'B', $member->getEmail(), null, true), \DomainException::class);
        $requester = $this->user();
        $requester->setRequest($household);
        $this->save($requester);
        $service->updateUser($admin, $requester, 'A', 'B', $requester->getEmail(), null, true);
        $this->em->refresh($requester);
        Assert::true($requester->isAdmin());
        Assert::null($requester->getHouseholdRequest());
    }

    public function testDeletingModeratorPreservesHouseholdMembersAndFood(): void
    {
        $admin = $this->admin();
        $household = $this->household();
        $moderatorId = $household->getModerator()->getId();
        $member = $this->user();
        $household->addUser($member);
        $food = $this->food($this->shelf($household));
        $food->setConsumed($household->getModerator());
        $this->save($food);
        $this->service()->deleteUser($admin, $household->getModerator());
        $this->em->clear();
        Assert::null($this->em->find(UserEntity::class, $moderatorId));
        Assert::null($this->em->find(HouseholdEntity::class, $household->getId())->getModerator());
        Assert::same($household->getId(), $this->em->find(UserEntity::class, $member->getId())->getHousehold()->getId());
        Assert::notNull($this->em->find(FoodEntity::class, $food->getId()));
    }

    public function testDeletingHouseholdRemovesContentsButPreservesAccountsAndOtherHouseholds(): void
    {
        $admin = $this->admin();
        $household = $this->household();
        $memberId = $household->getModerator()->getId();
        $food = $this->food($this->shelf($household));
        $other = $this->household();
        $otherFood = $this->food($this->shelf($other));
        $requester = $this->user();
        $requester->setRequest($household);
        $this->save($requester);
        $householdId = $household->getId();
        $this->service()->deleteHousehold($admin, $household);
        $this->em->clear();
        Assert::null($this->em->find(HouseholdEntity::class, $householdId));
        Assert::null($this->em->find(FoodEntity::class, $food->getId()));
        Assert::notNull($this->em->find(FoodEntity::class, $otherFood->getId()));
        Assert::null($this->em->find(UserEntity::class, $memberId)->getHousehold());
        Assert::null($this->em->find(UserEntity::class, $requester->getId())->getHouseholdRequest());
        Assert::true($this->em->find(UserEntity::class, $admin->getId())->isAdmin());
    }
}

(new AdminServiceTest())->run();
