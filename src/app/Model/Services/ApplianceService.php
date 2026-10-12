<?php

namespace App\Model\Services;

use App\Model\Common\Verification;
use App\Model\Entity\ApplianceEntity;
use App\Model\Entity\HouseholdEntity;
use App\Model\Entity\UserEntity;

final class ApplianceService extends BaseService
{
    public function addAppliance(HouseholdEntity $household, UserEntity $moderator, string $applianceName): ApplianceEntity {
        Verification::assertModerator($household, $moderator);

        $appliance = new ApplianceEntity($applianceName);
        $household->addAppliance($appliance);

        $this->entityManager->persist($appliance);
        $this->entityManager->flush();

        return $appliance;
    }

    public function getApplianceById(int $id): ?ApplianceEntity {
        $appliance = $this->entityManager->getRepository(ApplianceEntity::class)
            ->findOneBy(
                ['id' => $id]
        );

        if ($appliance === null) {
            throw new \InvalidArgumentException('Appliance not found.');
        }

        return $appliance;
    }

    public function getAppliances(HouseholdEntity $household): array {
        return $this->entityManager->getRepository(ApplianceEntity::class)
            ->findBy(
                ['household' => $household],
                ['name' => 'ASC'],
        );
    }

    public function updateApplianceName(ApplianceEntity $appliance, UserEntity $user, HouseholdEntity $household, string $name): void {
        Verification::assertModerator($household, $user);
        $appliance->setName($name);
        $this->entityManager->persist($appliance);
        $this->entityManager->flush();
    }

    public function removeAppliance(HouseholdEntity $household, UserEntity $moderator, ApplianceEntity $appliance): void {
        Verification::assertModerator($household, $moderator);
        if ($appliance->getHousehold() !== $household) {
            throw new \DomainException('Appliance is not in this household.');
        }
        $this->entityManager->remove($appliance);
        $this->entityManager->flush();
        // remove appliance from Household appliances
        $household->removeAppliance($appliance);
    }
}