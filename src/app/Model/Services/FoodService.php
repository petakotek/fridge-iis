<?php

namespace App\Model\Services;

use App\Model\Common\Verification;
use App\Model\Entity\FoodEntity;
use App\Model\Entity\HouseholdEntity;
use App\Model\Entity\ShelfEntity;
use App\Model\Entity\UserEntity;

final class FoodService extends BaseService
{
    public function addFood(
        string $name,
        string $barcode,
        float $price,
        int $calories,
        int $protein,
        int $fat,
        int $carb,
        int $fibre,
        int $weight,
        ShelfEntity $shelf,
        HouseholdEntity $household,
        UserEntity $user
    ): FoodEntity {

        Verification::assertHouseholdUser($household, $user);
        $food = new FoodEntity(
            $name,
            $barcode,
            $price,
            $calories,
            $protein,
            $fat,
            $carb,
            $fibre,
            $weight
        );
        $shelf->addFood($food);
        $this->entityManager->persist($food);
        $this->entityManager->flush();

        return $food;
    }

    public function updateFood(FoodEntity $food, HouseholdEntity $household, UserEntity $user): void {
        Verification::assertHouseholdUser($household, $user);

        $this->entityManager->flush();
    }

    public function getFoodById(int $id): ?FoodEntity {
        return $this->entityManager->getRepository(FoodEntity::class)
            ->findOneBy(
                ['id' => $id]
        );
    }

    public function getFoodsByShelf(ShelfEntity $shelf): array {
        return $this->entityManager->getRepository(FoodEntity::class)
            ->findBy(
                ['shelf' => $shelf->getId(),
                 'consumedAt' => null,
                 'discardedAt' => null
                ]
            );
    }

    public function getConsumedFoodsByShelf(ShelfEntity $shelf, UserEntity $user): array {
        return $this->entityManager->getRepository(FoodEntity::class)->findBy(
            ['shelf' => $shelf, 'consumer' => $user],
            ['consumedAt' => 'DESC', 'id' => 'DESC'],
        );
    }

    public function getTrashedFoodsByShelf(ShelfEntity $shelf): array {
        return $this->entityManager->getRepository(FoodEntity::class)->findBy(
            ['shelf' => $shelf, 'trashed' => true],
            ['discardedAt' => 'DESC', 'id' => 'DESC'],
        );
    }

    public function removeFood(FoodEntity $food): void {
        foreach ($food->getCategories() as $category){
            $food->removeCategory($category);
        }

        $this->entityManager->remove($food);
        $this->entityManager->flush();
    }

    public function trashFood(FoodEntity $food): void {
        $food->setTrashed();
        $this->entityManager->flush();
    }

    public function restoreFood(FoodEntity $food, UserEntity $user): void {
        $shelf = $food->getShelf();
        $household = $shelf->getAppliance()?->getHousehold();
        if ($household === null) {
            throw new \DomainException('Food has no household.');
        }
        Verification::assertHouseholdUser($household, $user);
        if (!$food->isConsumed() && !$food->isTrashed()) {
            throw new \DomainException('Food is already stored.');
        }

        // Check capacity while this food is still excluded from stored food weight.
        $shelf->addFood($food);
        $food->setStored();
        $this->entityManager->flush();
    }

    public function consumeFood(FoodEntity $food, UserEntity $user): void {
        $shelf = $food->getShelf();
        $appliance = $shelf->getAppliance();
        Verification::assertHouseholdUser($appliance->getHousehold(), $user);
        $food->setConsumed($user);
        $this->entityManager->flush();
    }
}
