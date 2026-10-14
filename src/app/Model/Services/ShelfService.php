<?php

namespace App\Model\Services;

use App\Model\Common\Verification;
use App\Model\Entity\ApplianceEntity;
use App\Model\Entity\HouseholdEntity;
use App\Model\Entity\ShelfEntity;
use App\Model\Entity\UserEntity;

final class ShelfService extends BaseService
{
    public function addShelf(HouseholdEntity $household, UserEntity $moderator, int $capacity, ApplianceEntity $appliance): ShelfEntity {
        Verification::assertModerator($household, $moderator);

        $shelf = new ShelfEntity($capacity);
        $appliance->addShelf($shelf);

        $this->entityManager->persist($shelf);
        $this->entityManager->flush();

        return $shelf;
    }

    public function getShelves(ApplianceEntity $appliance) : array {
        $shelves = $this->entityManager->getRepository(ShelfEntity::class)->findBy(
            ['appliance' => $appliance]
        );

        if (empty($shelves)) {
            return [];
        }

        return $shelves;
    }

    public function getShelfById(int $id): ShelfEntity {
        $shelf = $this->entityManager->getRepository(ShelfEntity::class)->findOneBy(
            ['id' => $id]
        );

        if (empty($shelf)) {
            throw new \DomainException('Shelf not found.');
        }

        return $shelf;
    }

    public function removeShelf(HouseholdEntity $household, UserEntity $moderator, ShelfEntity $shelf) : void {
        Verification::assertModerator($household, $moderator);

        $appliance = $shelf->getAppliance();
        $appliance->removeShelf($shelf);

        $this->entityManager->remove($shelf);
        $this->entityManager->flush();
    }
}