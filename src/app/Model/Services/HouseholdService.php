<?php

namespace App\Model\Services;

use App\Model\Common\Verification;
use App\Model\Entity\ApplianceEntity;
use App\Model\Entity\HouseholdEntity;
use App\Model\Entity\UserEntity;

final class HouseholdService extends BaseService
{
    public function createHousehold(string $name, UserEntity $moderator): HouseholdEntity {
        $household = new HouseholdEntity($name);
        $household->generateToken();

        $household->setModerator($moderator);
        $this->entityManager->persist($household);
        $this->entityManager->flush();

        return $household;
    }

    public function removeHousehold(HouseholdEntity $household, UserEntity $user): void {
        Verification::assertModerator($household, $user);
        $householdUsers = $this->entityManager->getRepository(UserEntity::class)
            ->findBy(
                ['household' => $household]
        );

        foreach ($householdUsers as $householdUser) {
            $householdUser->removeHousehold($household);
            $household->removeUser($householdUser);
        }

        $this->entityManager->remove($household);
        $this->entityManager->flush();
    }

    public function updateName(HouseholdEntity $household, UserEntity $user, string $newName): void {
        Verification::assertModerator($household, $user);

        $household->setName($newName);
        $this->entityManager->persist($household);
        $this->entityManager->flush();
    }

    public function getHouseholdById(int $householdId): HouseholdEntity {
        $household = $this->entityManager->getRepository(HouseholdEntity::class)
            ->findOneBy(
                ['id' => $householdId]
        );

        if ($household === null) {
            throw new \InvalidArgumentException('Household not found by id.');
        }
        return $household;
    }

    public function getHouseholdByToken(string $token): HouseholdEntity {
        $household = $this->entityManager->getRepository(HouseholdEntity::class)
            ->findOneBy(
                ['token' => $token]
        );
        if ($household === null) {
            throw new \InvalidArgumentException('Household not found by token.');
        }

        return $household;
    }

    public function addAppliance(HouseholdEntity $household, UserEntity $moderator, string $applianceName): ApplianceEntity {
        Verification::assertModerator($household, $moderator);

        $appliance = new ApplianceEntity($applianceName);
        $household->addAppliance($appliance);

        $this->entityManager->persist($appliance);
        $this->entityManager->flush();

        return $appliance;
    }

    public function removeAppliance(HouseholdEntity $household, UserEntity $moderator, ApplianceEntity $appliance): void {
        Verification::assertModerator($household, $moderator);
        if ($appliance->getHousehold() !== $household) {
            throw new \DomainException('Appliance is not in this household.');
        }
        $this->entityManager->remove($appliance);
        $this->entityManager->flush();
        $household->removeAppliance($appliance);
    }

    public function addUser(UserEntity $user, UserEntity $moderator, HouseholdEntity $household): void {
        Verification::assertModerator($household, $moderator);
        $household->addUser($user);
        $this->entityManager->flush();
    }

    public function removeHouseholdUser(HouseholdEntity $household, UserEntity $moderator, UserEntity $remover): void {
        Verification::assertModerator($household, $moderator);

        if ($remover === $moderator) {
            throw new \DomainException('Moderator cannot be removed by himself.');
        }
        $remover->removeHousehold($household);
        $household->removeUser($remover);
        $this->entityManager->flush();
    }

    public function createHouseholdRequest(HouseholdEntity $household, UserEntity $requester, string $token): void {
        if ($token === $household->getToken()) {
            $requester->setRequest($household);
            $this->entityManager->flush();
        }
    }

    public function getHouseholdRequests(HouseholdEntity $household): array {
        return $this->entityManager->getRepository(UserEntity::class)
            ->findBy(
                ['householdRequest' => $household]
        );
    }

    public function acceptHouseholdRequest(HouseholdEntity $household, UserEntity $moderator, UserEntity $requester): void {
        Verification::assertModerator($household, $moderator);

        if ($requester === $moderator) {
            throw new \DomainException('Moderator cannot be accepted by himself.');
        }

        if ($requester->getHouseholdRequest() === $household) {
            $household->addUser($requester);
            $requester->unsetHouseholdRequest();
            $this->entityManager->flush();
        }
    }

    public function removeHouseholdRequest(HouseholdEntity $household, UserEntity $moderator, UserEntity $requester): void {
        Verification::assertModerator($household, $moderator);

        if ($requester === $moderator) {
            throw new \DomainException('Moderator cannot be removed by himself.');
        }

        if ($requester->getHouseholdRequest() !== $household) {
            throw new \DomainException('Household request is not in this household.');
        }

        $requester->unsetHouseholdRequest($household);
        $this->entityManager->flush();
    }
}