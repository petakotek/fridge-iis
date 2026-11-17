<?php declare(strict_types=1);

namespace App\Model\Services;

use App\Model\Common\Verification;
use App\Model\Entity\HouseholdEntity;
use App\Model\Entity\UserEntity;
use Doctrine\ORM\EntityManagerInterface;

final class AdminService extends BaseService
{
    public function __construct(EntityManagerInterface $entityManager, private UserService $users, private HouseholdService $households)
    {
        parent::__construct($entityManager);
    }

    /** @return UserEntity[] */
    public function getUsers(UserEntity $admin): array
    {
        Verification::assertAdmin($admin);
        return $this->entityManager->getRepository(UserEntity::class)->findBy([], ['surname' => 'ASC', 'name' => 'ASC']);
    }

    /** @return HouseholdEntity[] */
    public function getHouseholds(UserEntity $admin): array
    {
        Verification::assertAdmin($admin);
        return $this->entityManager->getRepository(HouseholdEntity::class)->findBy([], ['name' => 'ASC']);
    }

    public function createUser(UserEntity $admin, string $name, string $surname, string $email, string $password, bool $isAdmin = false): UserEntity
    {
        Verification::assertAdmin($admin);
        return $this->entityManager->wrapInTransaction(function () use ($name, $surname, $email, $password, $isAdmin): UserEntity {
            $user = $this->users->createUser($name, $surname, $email, $password);
            $user->setAdminLevel($isAdmin);
            return $user;
        });
    }

    public function updateUser(UserEntity $admin, UserEntity $user, string $name, string $surname, string $email, ?string $password, bool $isAdmin): void
    {
        Verification::assertAdmin($admin);
        if ($user === $admin && !$isAdmin) {
            throw new \DomainException('Nemůžete odebrat administrátorskou roli vlastnímu účtu.');
        }
        if ($isAdmin && $user->getHousehold() !== null) {
            throw new \DomainException('Před změnou na administrátora odeberte uživatele z domácnosti.');
        }
        // Validate and save the profile before changing the role; a rejected profile must not change permissions.
        $this->users->updateProfile($user, $name, $surname, $email, $password);
        if ($isAdmin) {
            $user->unsetHouseholdRequest();
        }
        $user->setAdminLevel($isAdmin);
        $this->entityManager->flush();
    }

    public function deleteUser(UserEntity $admin, UserEntity $user): void
    {
        Verification::assertAdmin($admin);
        if ($user === $admin) {
            throw new \DomainException('Vlastní administrátorský účet nemůžete smazat.');
        }
        $this->entityManager->wrapInTransaction(function () use ($user): void {
            if (($household = $user->getHousehold()) !== null) {
                if ($household->getModerator() === $user) {
                    $household->setModerator(null);
                }
                $household->removeUser($user);
                $user->removeHousehold($household);
            }
            $user->unsetHouseholdRequest();
            $this->entityManager->remove($user);
        });
    }

    public function createHousehold(UserEntity $admin, string $name, ?UserEntity $moderator = null): HouseholdEntity
    {
        Verification::assertAdmin($admin);
        if ($moderator !== null) {
            $this->assertAvailableMember($moderator);
        }
        $household = new HouseholdEntity($name);
        $household->generateToken();
        if ($moderator !== null) {
            $household->setModerator($moderator);
            $moderator->unsetHouseholdRequest();
        }
        $this->entityManager->persist($household);
        $this->entityManager->flush();
        return $household;
    }

    public function updateHousehold(UserEntity $admin, HouseholdEntity $household, string $name): void
    {
        Verification::assertAdmin($admin);
        $this->households->updateName($household, $admin, $name);
    }

    public function deleteHousehold(UserEntity $admin, HouseholdEntity $household): void
    {
        Verification::assertAdmin($admin);
        $this->households->removeHousehold($household, $admin);
    }

    public function addMember(UserEntity $admin, HouseholdEntity $household, UserEntity $member): void
    {
        Verification::assertAdmin($admin);
        $this->assertAvailableMember($member);
        $household->addUser($member);
        $member->unsetHouseholdRequest();
        $this->entityManager->flush();
    }

    public function removeMember(UserEntity $admin, HouseholdEntity $household, UserEntity $member): void
    {
        Verification::assertAdmin($admin);
        Verification::assertHouseholdUser($household, $member);
        if ($household->getModerator() === $member) {
            $household->setModerator(null);
        }
        $household->removeUser($member);
        $member->removeHousehold($household);
        $this->entityManager->flush();
    }

    public function setModerator(UserEntity $admin, HouseholdEntity $household, UserEntity $member): void
    {
        Verification::assertAdmin($admin);
        Verification::assertHouseholdUser($household, $member);
        $household->setModerator($member);
        $this->entityManager->flush();
    }

    private function assertAvailableMember(UserEntity $member): void
    {
        if ($member->isAdmin() || $member->getHousehold() !== null) {
            throw new \DomainException('Vyberte registrovaného uživatele bez domácnosti.');
        }
    }
}
