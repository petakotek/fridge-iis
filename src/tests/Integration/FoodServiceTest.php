<?php

/** @testCase */

declare(strict_types=1);

namespace Tests\Services;

use App\Model\Entity\CategoryEntity;
use App\Model\Entity\FoodEntity;
use App\Model\Entity\HouseholdEntity;
use App\Model\Entity\ShelfEntity;
use App\Model\Entity\UserEntity;
use App\Model\Services\FoodService;
use Tester\Assert;
use Tests\Support\ServiceTestCase;

require __DIR__ . '/../bootstrap.php';

final class FoodServiceTest extends ServiceTestCase
{
    private function addFood(ShelfEntity $shelf, HouseholdEntity $household, UserEntity $user, int $weight = 100): FoodEntity
    {
        return (new FoodService($this->em))->addFood('  Yoghurt  ', '8591234567890', 19.90, 60, 4, 3, 5, 0, $weight, $shelf, $household, $user);
    }

    public function testMemberCanAddFoodAndValuesArePersisted(): void
    {
        $household = $this->household();
        $shelf = $this->shelf($household);
        $member = $this->user();
        $household->addUser($member);
        $this->em->flush();
        $food = $this->addFood($shelf, $household, $member);
        Assert::true($shelf->getFoods()->contains($food));
        $id = $food->getId();
        $shelfId = $shelf->getId();
        $this->em->clear();

        $stored = (new FoodService($this->em))->getFoodById($id);
        Assert::same('Yoghurt', $stored->getName());
        Assert::same('8591234567890', $stored->getBarcode());
        Assert::same(19.90, $stored->getPrice());
        Assert::same(60.0, $stored->getCalories());
        Assert::same(4, $stored->getProtein());
        Assert::same(3, $stored->getFat());
        Assert::same(5, $stored->getCarb());
        Assert::same(0, $stored->getFibre());
        Assert::same(100, $stored->getWeight());
        Assert::null($stored->getConsumedAt());
        Assert::null($stored->getDiscardedAt());
        Assert::true($this->em->find(ShelfEntity::class, $shelfId)->getFoods()->contains($stored));
    }

    public function testOutsiderCannotAddOrUpdateFood(): void
    {
        $household = $this->household();
        $shelf = $this->shelf($household);
        $food = $this->food($shelf);
        $outsider = $this->user();
        Assert::exception(fn() => $this->addFood($shelf, $household, $outsider), \DomainException::class);
        Assert::exception(fn() => (new FoodService($this->em))->updateFood($food, $household, $outsider), \DomainException::class);
        Assert::same(1, $this->em->getRepository(FoodEntity::class)->count([]));
    }

    public function testUpdateFoodPersistsNameAndExpiry(): void
    {
        $household = $this->household();
        $food = $this->food($this->shelf($household));
        $food->setName('Milk');
        $expiry = new \DateTime('2030-01-15 12:00:00');
        $food->setExpiry($expiry);
        (new FoodService($this->em))->updateFood($food, $household, $household->getModerator());
        $this->em->refresh($food);
        Assert::same('Milk', $food->getName());
        Assert::equal($expiry, $food->getExpiry());
    }

    public function testMissingFoodReturnsNull(): void
    {
        Assert::null((new FoodService($this->em))->getFoodById(999));
    }

    public function testShelfContentsExcludeConsumedDiscardedAndOtherShelfFood(): void
    {
        $household = $this->household();
        $shelf = $this->shelf($household);
        $active = $this->food($shelf);
        $consumed = $this->food($shelf);
        $discarded = $this->food($shelf);
        $this->food($this->shelf($household));
        $emptyShelf = $this->shelf($household);
        $service = new FoodService($this->em);
        $service->consumeFood($consumed, $household->getModerator());
        $service->trashFood($discarded);
        // Clear the identity map so the result proves the database query applies all filters.
        $shelfId = $shelf->getId();
        $emptyId = $emptyShelf->getId();
        $this->em->clear();
        $foods = $service->getFoodsByShelf($this->em->find(ShelfEntity::class, $shelfId));
        Assert::same([$active->getId()], array_map(fn(FoodEntity $food) => $food->getId(), $foods));
        Assert::same([], $service->getFoodsByShelf($this->em->find(ShelfEntity::class, $emptyId)));
    }

    public function testConsumeFoodPersistsConsumerAndTimeWithoutDeletingRecord(): void
    {
        $household = $this->household();
        $member = $this->user();
        $household->addUser($member);
        $food = $this->food($this->shelf($household));
        $before = time();
        (new FoodService($this->em))->consumeFood($food, $member);
        $after = time();
        $id = $food->getId();
        $this->em->clear();
        $stored = $this->em->find(FoodEntity::class, $id);
        Assert::true($stored->isConsumed());
        Assert::true($stored->getConsumedAt()->getTimestamp() >= $before);
        Assert::true($stored->getConsumedAt()->getTimestamp() <= $after);
        Assert::null($stored->getDiscardedAt());
        $consumer = $this->em->find(UserEntity::class, $member->getId());
        Assert::true($consumer->getFoodsConsumed()->contains($stored));
        Assert::same(19.90, $stored->getPrice());
    }

    public function testTrashFoodPersistsTimeWithoutDeletingRecord(): void
    {
        $household = $this->household();
        $food = $this->food($this->shelf($household));
        $before = time();
        (new FoodService($this->em))->trashFood($food);
        $after = time();
        $this->em->refresh($food);
        Assert::true($food->isTrashed());
        Assert::false($food->isConsumed());
        Assert::null($food->getConsumedAt());
        Assert::true($food->getDiscardedAt()->getTimestamp() >= $before);
        Assert::true($food->getDiscardedAt()->getTimestamp() <= $after);
        Assert::same(1, $this->em->getRepository(FoodEntity::class)->count([]));
    }

    public function testRemoveFoodClearsCategoryLinksButKeepsCategories(): void
    {
        $household = $this->household();
        $food = $this->food($this->shelf($household));
        $categories = [$this->category($household), $this->category($household, 'Breakfast')];
        foreach ($categories as $category) {
            $food->addCategory($category);
        }
        $this->em->flush();
        $id = $food->getId();
        (new FoodService($this->em))->removeFood($food);
        Assert::count(0, $food->getCategories());
        foreach ($categories as $category) {
            Assert::false($category->getFoods()->contains($food));
        }
        $this->em->clear();
        Assert::null($this->em->find(FoodEntity::class, $id));
        Assert::same(2, $this->em->getRepository(CategoryEntity::class)->count([]));
        Assert::same(0, (int) $this->em->getConnection()->fetchOne('SELECT COUNT(*) FROM categoryentity_foodentity'));
    }

    public function testSingleFoodAboveShelfCapacityIsRejected(): void
    {
        $household = $this->household();
        $shelf = $this->shelf($household, 100);
        Assert::exception(fn() => $this->addFood($shelf, $household, $household->getModerator(), 101), \DomainException::class);
        Assert::count(0, $shelf->getFoods());
        Assert::same(0, $this->em->getRepository(FoodEntity::class)->count([]));
    }

    public function testTotalShelfCapacityCannotBeExceeded(): void
    {
        // Arrange
        $household = $this->household();
        $shelf = $this->shelf($household, 150);

        // Act
        $this->addFood($shelf, $household, $household->getModerator(), 100);

        // Assert
        Assert::exception(fn() => $this->addFood($shelf, $household, $household->getModerator(), 51), \DomainException::class);
        Assert::same(1, $this->em->getRepository(FoodEntity::class)->count([]));
    }

    public function testExactCapacityAndSpaceReleasedByConsumptionAndDiscard(): void
    {
        $household = $this->household();
        $shelf = $this->shelf($household, 100);
        $service = new FoodService($this->em);
        $first = $this->addFood($shelf, $household, $household->getModerator(), 100);
        $service->consumeFood($first, $household->getModerator());
        $second = $this->addFood($shelf, $household, $household->getModerator(), 100);
        $service->trashFood($second);
        $third = $this->addFood($shelf, $household, $household->getModerator(), 100);
        Assert::same([$third], $service->getFoodsByShelf($shelf));
        Assert::same(3, $this->em->getRepository(FoodEntity::class)->count([]));
    }

    public function testOutsiderCannotConsumeFood(): void
    {
        $household = $this->household();
        $food = $this->food($this->shelf($household));
        $outsider = $this->user();
        Assert::exception(fn() => (new FoodService($this->em))->consumeFood($food, $outsider), \DomainException::class);
        Assert::null($food->getConsumedAt());
    }

    public function testConsumedFoodCannotBeConsumedAgain(): void
    {
        $household = $this->household();
        $food = $this->food($this->shelf($household));
        $service = new FoodService($this->em);
        $service->consumeFood($food, $household->getModerator());
        $consumedAt = clone $food->getConsumedAt();

        Assert::equal($consumedAt, $food->getConsumedAt());
    }

    public function testConsumedFoodCannotBeDiscarded(): void
    {
        $household = $this->household();
        $food = $this->food($this->shelf($household));
        $service = new FoodService($this->em);
        $service->consumeFood($food, $household->getModerator());
        Assert::true($food->isConsumed());
        Assert::null($food->getDiscardedAt());
    }

    public function testDiscardedFoodCannotBeConsumed(): void
    {
        $household = $this->household();
        $food = $this->food($this->shelf($household));
        $service = new FoodService($this->em);
        $service->trashFood($food);
        Assert::true($food->isTrashed());
        Assert::null($food->getConsumedAt());
    }
}

(new FoodServiceTest())->run();
