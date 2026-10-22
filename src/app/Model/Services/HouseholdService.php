<?php

namespace App\Model\Services;

use App\Model\Common\Verification;
use App\Model\Entity\ApplianceEntity;
use App\Model\Entity\HouseholdEntity;
use App\Model\Entity\UserEntity;

final class HouseholdService extends BaseService
{
    public function createHousehold(string $name, UserEntity $moderator): HouseholdEntity {
        if ($moderator->getHousehold() !== null || $moderator->getHouseholdRequest() !== null) {
            throw new \DomainException('User already belongs to or has requested a household.');
        }
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
            $household->removeUser($householdUser);
            $householdUser->removeHousehold($household);
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

    public function regenerateToken(HouseholdEntity $household, UserEntity $user): void {
        Verification::assertModerator($household, $user);

        $oldToken = $household->getToken();
        do {
            $household->generateToken();
        } while ($household->getToken() === $oldToken);

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
        $household->removeUser($remover);
        $remover->removeHousehold($household);
        $this->entityManager->flush();
    }

    public function createHouseholdRequest(HouseholdEntity $household, UserEntity $requester, string $token): void {
        if ($token === $household->getToken()) {
            if ($requester->getHouseholdRequest() !== null) {
                throw new \DomainException('User already has a pending household request.');
            }
            $requester->setRequest($household);
            $this->entityManager->flush();
        }
    }

    public function cancelOwnRequest(UserEntity $requester): void {
        if ($requester->getHouseholdRequest() === null) {
            throw new \DomainException('User has no pending household request.');
        }
        $requester->unsetHouseholdRequest();
        $this->entityManager->flush();
    }

    public function leaveHousehold(UserEntity $member): void {
        $household = $member->getHousehold();
        if ($household === null) {
            throw new \DomainException('User does not belong to a household.');
        }
        if ($household->getModerator() === $member) {
            throw new \DomainException('Moderator must transfer management before leaving.');
        }
        $household->removeUser($member);
        $member->removeHousehold($household);
        $this->entityManager->flush();
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

        $requester->unsetHouseholdRequest();
        $this->entityManager->flush();
    }
}
