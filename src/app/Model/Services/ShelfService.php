<?php

namespace App\Model\Services;

use App\Model\Common\Verification;
use App\Model\Entity\ApplianceEntity;
use App\Model\Entity\HouseholdEntity;
use App\Model\Entity\ShelfEntity;
use App\Model\Entity\UserEntity;

final class ShelfService extends BaseService
{
    public function addShelf(HouseholdEntity $household, UserEntity $moderator, int $capacity, ApplianceEntity $appliance, string $name = 'Police'): ShelfEntity {
        Verification::assertModerator($household, $moderator);
        Verification::assertHouseholdAppliance($household, $appliance);

        $shelf = new ShelfEntity($capacity);
        $shelf->setName($name);
        $appliance->addShelf($shelf);

        $this->entityManager->persist($shelf);
        $this->entityManager->flush();

        return $shelf;
    }

    public function getShelves(ApplianceEntity $appliance) : array {
        $shelves = $this->entityManager->getRepository(ShelfEntity::class)->findBy(
            ['appliance' => $appliance],
            ['id' => 'ASC'],
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

    public function updateShelf(HouseholdEntity $household, UserEntity $moderator, ShelfEntity $shelf, string $name, int $capacity): void
    {
        Verification::assertModerator($household, $moderator);
        $appliance = $shelf->getAppliance();
        if ($appliance === null) {
            throw new \DomainException('Shelf has no appliance.');
        }
        Verification::assertHouseholdAppliance($household, $appliance);
        $usedCapacity = 0;
        foreach ($shelf->getFoods() as $food) {
            if (!$food->isConsumed() && !$food->isTrashed()) {
                $usedCapacity += $food->getWeight();
            }
        }
        if ($capacity < $usedCapacity) {
            throw new \DomainException('Capacity is smaller than the stored food weight.');
        }
        // Validate both values before changing the managed entity.
        $validated = new ShelfEntity($capacity);
        $validated->setName($name);
        $shelf->setName($validated->getName());
        $shelf->setCapacity($capacity);
        $this->entityManager->flush();
    }

    public function removeShelf(HouseholdEntity $household, UserEntity $moderator, ShelfEntity $shelf) : void {
        Verification::assertModerator($household, $moderator);

        $appliance = $shelf->getAppliance();
        if ($appliance === null) {
            throw new \DomainException('Shelf has no appliance.');
        }
        Verification::assertHouseholdAppliance($household, $appliance);
        $appliance->removeShelf($shelf);

        $this->entityManager->remove($shelf);
        $this->entityManager->flush();
    }
}