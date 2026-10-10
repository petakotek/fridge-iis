<?php

namespace App\Model\Services;

use App\Model\Entity\CategoryEntity;
use App\Model\Entity\HouseholdEntity;
use App\Model\Entity\FoodEntity;
use App\Model\Entity\UserEntity;

final class CategoryService extends BaseService
{
    public function addCategory(HouseholdEntity $household, string $name, UserEntity $user, ?CategoryEntity $parent = null): CategoryEntity {
        $this->assertModerator($household, $user);
        if ($parent !== null) {
            $this->assertHousehold($household, $parent);
        }

        $category = new CategoryEntity($household, $name);
        $category->setParent($parent);

        $this->entityManager->persist($category);
        $this->entityManager->flush();

        return $category;
    }

    public function getCategoryById(HouseholdEntity $household, int $id): CategoryEntity {
        $category = $this->entityManager->getRepository(CategoryEntity::class)->findOneBy([
            'id' => $id,
            'household' => $household,
        ]);

        if ($category === null) {
            throw new \InvalidArgumentException('Category not found in this household.');
        }

        return $category;
    }

    /** @return list<CategoryEntity> */
    public function getCategories(HouseholdEntity $household): array {
        return $this->entityManager->getRepository(CategoryEntity::class)->findBy(
            ['household' => $household],
            ['name' => 'ASC', 'id' => 'ASC'],
        );
    }

    /** Returns direct children, or root categories when parent is null.
     * @return list<CategoryEntity>
     */
    public function getSubcategories(HouseholdEntity $household, ?CategoryEntity $parent = null): array {
        if ($parent !== null) {
            $this->assertHousehold($household, $parent);
        }

        return $this->entityManager->getRepository(CategoryEntity::class)->findBy(
            ['household' => $household, 'parent' => $parent],
            ['name' => 'ASC', 'id' => 'ASC'],
        );
    }

    public function updateCategoryName(HouseholdEntity $household, CategoryEntity $category, string $name, UserEntity $user): void {
        $this->assertModerator($household, $user);
        $this->assertHousehold($household, $category);
        $category->setName($name);
        $this->entityManager->flush();
    }

    public function moveCategory(HouseholdEntity $household, CategoryEntity $category, ?CategoryEntity $parent, UserEntity $user): void {
        $this->assertModerator($household, $user);
        $this->assertHousehold($household, $category);
        if ($parent !== null) {
            $this->assertHousehold($household, $parent);
        }

        $category->setParent($parent);
        $this->entityManager->flush();
    }

    public function removeCategory(HouseholdEntity $household, CategoryEntity $category, UserEntity $user): void {
        $this->assertModerator($household, $user);
        $this->assertHousehold($household, $category);

        if ($this->entityManager->getRepository(CategoryEntity::class)->count(['parent' => $category]) > 0) {
            throw new \DomainException('Cannot remove a category with subcategories.');
        }

        // Query the owning side so the check does not depend on a loaded inverse collection.
        $foodCount = $this->entityManager->createQueryBuilder()
            ->select('COUNT(food.id)')
            ->from(FoodEntity::class, 'food')
            ->join('food.categories', 'category')
            ->where('category = :category')
            ->setParameter('category', $category)
            ->getQuery()
            ->getSingleScalarResult();

        if ((int) $foodCount > 0 || !$category->getFoods()->isEmpty()) {
            throw new \DomainException('Cannot remove a category assigned to food.');
        }

        $this->entityManager->remove($category);
        $this->entityManager->flush();
        $household->getCategories()->removeElement($category);
    }

    private function assertHousehold(HouseholdEntity $household, CategoryEntity $category): void {
        if ($category->getHousehold() !== $household) {
            throw new \DomainException('Category belongs to another household.');
        }
    }

    private function assertModerator(HouseholdEntity $household, UserEntity $user): void {
        if ($household->getModerator() !== $user) {
            throw new \DomainException('Only the household moderator can manage its categories.');
        }
    }
}
