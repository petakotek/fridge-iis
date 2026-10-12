<?php

namespace App\Model\Services;

use App\Model\Common\Verification;
use App\Model\Entity\CategoryEntity;
use App\Model\Entity\HouseholdEntity;
use App\Model\Entity\FoodEntity;
use App\Model\Entity\UserEntity;

final class CategoryService extends BaseService
{
    public function addCategory(HouseholdEntity $household, string $name, UserEntity $user, ?CategoryEntity $parent = null): CategoryEntity {
        Verification::assertModerator($household, $user);
        if ($parent !== null) {
            Verification::assertHouseholdCategory($household, $parent);
        }

        $category = new CategoryEntity($household, $name);
        $category->setParent($parent);

        $this->entityManager->persist($category);
        $this->entityManager->flush();

        return $category;
    }

    public function getCategoryById(int $id): CategoryEntity {
        $category = $this->entityManager->getRepository(CategoryEntity::class)
            ->findOneBy(
                ['id' => $id]
        );

        if ($category === null) {
            throw new \InvalidArgumentException('Category not found in this household.');
        }

        return $category;
    }

    public function getCategories(HouseholdEntity $household): array {
        return $this->entityManager->getRepository(CategoryEntity::class)
            ->findBy(
                ['household' => $household],
                ['name' => 'ASC', 'id' => 'ASC'],
        );
    }

    public function getSubcategories(HouseholdEntity $household, ?CategoryEntity $parent = null): array {
        if ($parent !== null) {
            Verification::assertHouseholdCategory($household, $parent);
        }

        return $this->entityManager->getRepository(CategoryEntity::class)
            ->findBy(
                ['household' => $household, 'parent' => $parent],
                ['name' => 'ASC'],
        );
    }

    public function updateCategoryName(HouseholdEntity $household, CategoryEntity $category, string $name, UserEntity $user): void {
        Verification::assertModerator($household, $user);
        Verification::assertHouseholdCategory($household, $category);
        $category->setName($name);
        $this->entityManager->flush();
    }

    public function moveCategory(HouseholdEntity $household, CategoryEntity $category, ?CategoryEntity $parent, UserEntity $user): void {
        Verification::assertModerator($household, $user);
        Verification::assertHouseholdCategory($household, $category);
        if ($parent !== null) {
            Verification::assertHouseholdCategory($household, $parent);
        }

        $category->setParent($parent);
        $this->entityManager->flush();
    }

    public function removeCategory(HouseholdEntity $household, CategoryEntity $category, UserEntity $user): void {
        Verification::assertModerator($household, $user);
        Verification::assertHouseholdCategory($household, $category);

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

        // remove category from Household categories
        $household->removeCategory($category);
    }

}
