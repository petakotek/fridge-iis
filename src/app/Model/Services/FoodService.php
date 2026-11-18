<?php

namespace App\Model\Services;

use App\Model\Common\Verification;
use DateTimeInterface;
use Doctrine\DBAL\LockMode;
use Doctrine\ORM\QueryBuilder;
use App\Model\Entity\FoodEntity;
use App\Model\Entity\CategoryEntity;
use App\Model\Entity\HouseholdEntity;
use App\Model\Entity\ShelfEntity;
use App\Model\Entity\UserEntity;

final class FoodService extends BaseService
{
    /** @param array<int, CategoryEntity> $categories */
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
        UserEntity $user,
        array $categories = [],
    ): FoodEntity {

        Verification::assertHouseholdUser($household, $user);
        if ($shelf->getAppliance()?->getHousehold() !== $household) {
            throw new \DomainException('Shelf belongs to another household.');
        }
        $this->assertCategories($household, $categories);
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
        $connection = $this->entityManager->getConnection();
        $connection->beginTransaction();
        try {
            // Serialize additions to this shelf and reload its current capacity.
            $this->entityManager->refresh($shelf, LockMode::PESSIMISTIC_WRITE);
            $usedWeight = (int) $this->entityManager->createQueryBuilder()
                ->select('COALESCE(SUM(food.weight), 0)')
                ->from(FoodEntity::class, 'food')
                ->where('food.shelf = :shelf')
                ->andWhere('food.consumedAt IS NULL')
                ->andWhere('food.discardedAt IS NULL')
                ->setParameter('shelf', $shelf)
                ->getQuery()
                ->getSingleScalarResult();
            if ($weight > $shelf->getShelfCapacity() - $usedWeight) {
                throw new \DomainException('Food weight is too big for this shelf.');
            }

            $shelf->addFood($food);
            $this->syncCategories($food, $categories);
            $this->entityManager->persist($food);
            $this->entityManager->flush();
            $connection->commit();
        } catch (\Throwable $exception) {
            if ($connection->isTransactionActive()) {
                $connection->rollBack();
            }
            throw $exception;
        }

        return $food;
    }

    /** @param array<int, CategoryEntity>|null $categories null keeps the current categories */
    public function updateFood(
        FoodEntity $food,
        HouseholdEntity $household,
        UserEntity $user,
        ?array $categories = null,
    ): void {
        Verification::assertHouseholdUser($household, $user);
        if ($food->getShelf()->getAppliance()?->getHousehold() !== $household) {
            throw new \DomainException('Food belongs to another household.');
        }
        if ($categories !== null) {
            $this->assertCategories($household, $categories);
            $this->syncCategories($food, $categories);
        }
        $this->entityManager->flush();
    }

    /** @param array<int, CategoryEntity> $categories */
    private function assertCategories(HouseholdEntity $household, array $categories): void
    {
        foreach ($categories as $category) {
            Verification::assertHouseholdCategory($household, $category);
        }
    }

    /** @param array<int, CategoryEntity> $categories */
    private function syncCategories(FoodEntity $food, array $categories): void
    {
        foreach ($food->getCategories()->toArray() as $category) {
            if (!in_array($category, $categories, true)) {
                $food->removeCategory($category);
            }
        }
        foreach ($categories as $category) {
            $food->addCategory($category);
        }
    }

    public function getFoodById(int $id): ?FoodEntity {
        return $this->entityManager->getRepository(FoodEntity::class)
            ->findOneBy(
                ['id' => $id]
        );
    }

    /** @return array<int, FoodEntity> */
    public function getFoods(
        HouseholdEntity $household,
        int $limit,
        int $offset,
        ?ShelfEntity $shelf = null,
        string $status = 'active',
        ?UserEntity $consumer = null,
    ): array {
        if ($limit < 1 || $offset < 0) {
            throw new \InvalidArgumentException('Invalid pagination limit or offset.');
        }
        $sortField = match ($status) {
            'consumed' => 'food.consumedAt',
            'trashed' => 'food.discardedAt',
            default => 'food.name',
        };
        $direction = in_array($status, ['consumed', 'trashed'], true) ? 'DESC' : 'ASC';

        return $this->createFoodListQuery($household, $shelf, $status, $consumer)
            ->select('food', 'shelf', 'appliance')
            ->orderBy($sortField, $direction)
            ->addOrderBy('food.id', $direction)
            ->setMaxResults($limit)
            ->setFirstResult($offset)
            ->getQuery()
            ->getResult();
    }

    public function getFoodCount(
        HouseholdEntity $household,
        ?ShelfEntity $shelf = null,
        string $status = 'active',
        ?UserEntity $consumer = null,
    ): int {
        return (int) $this->createFoodListQuery($household, $shelf, $status, $consumer)
            ->select('COUNT(food.id)')
            ->getQuery()
            ->getSingleScalarResult();
    }

    private function createFoodListQuery(
        HouseholdEntity $household,
        ?ShelfEntity $shelf,
        string $status,
        ?UserEntity $consumer,
    ): QueryBuilder {
        $query = $this->entityManager->createQueryBuilder()
            ->from(FoodEntity::class, 'food')
            ->join('food.shelf', 'shelf')
            ->join('shelf.appliance', 'appliance')
            ->where('appliance.household = :household')
            ->setParameter('household', $household);

        if ($shelf !== null) {
            $query->andWhere('food.shelf = :shelf')->setParameter('shelf', $shelf);
        }
        switch ($status) {
            case 'active':
                $query->andWhere('food.consumedAt IS NULL')
                    ->andWhere('food.discardedAt IS NULL');
                break;
            case 'consumed':
                if ($consumer === null) {
                    throw new \InvalidArgumentException('A consumer is required for consumed food.');
                }
                $query->andWhere('food.consumer = :consumer')->setParameter('consumer', $consumer);
                break;
            case 'trashed':
                $query->andWhere('food.trashed = :trashed')->setParameter('trashed', true);
                break;
            case 'all':
                // The shelf detail also includes consumed and discarded food.
                break;
            default:
                throw new \InvalidArgumentException('Invalid food status.');
        }
        return $query;
    }

    public function getFoodsByShelf(ShelfEntity $shelf, int $limit = -1, int $offset = -1): array {
        return $this->entityManager->getRepository(FoodEntity::class)->findBy(
            ['shelf' => $shelf, 'consumedAt' => null, 'discardedAt' => null],
            ['name' => 'ASC', 'id' => 'ASC'],
            $limit === -1 ? null : $limit,
            $offset === -1 ? null : $offset,
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

    public function getConsumedFoods(UserEntity $user, DateTimeInterface $from, DateTimeInterface $to): array {
        return $this->entityManager->createQueryBuilder()
            ->select('food')
            ->from(FoodEntity::class, 'food')
            ->where('food.consumer = :user')
            ->andWhere('food.consumedAt >= :from')
            ->andWhere('food.consumedAt < :to')
            ->setParameter('user', $user)
            ->setParameter('from', $from)
            ->setParameter('to', $to)
            ->orderBy('food.consumedAt', 'DESC')
            ->addOrderBy('food.id', 'DESC')
            ->getQuery()
            ->getResult();
    }

    public function getConsumedCalories(UserEntity $user, DateTimeInterface $from, DateTimeInterface $to): int {
        return (int) $this->entityManager->createQueryBuilder()
            ->select('COALESCE(SUM(food.calories), 0)')
            ->from(FoodEntity::class, 'food')
            ->where('food.consumer = :user')
            ->andWhere('food.consumedAt >= :from')
            ->andWhere('food.consumedAt < :to')
            ->setParameter('user', $user)
            ->setParameter('from', $from)
            ->setParameter('to', $to)
            ->getQuery()
            ->getSingleScalarResult();
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
