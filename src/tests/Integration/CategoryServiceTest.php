<?php

/** @testCase */

declare(strict_types=1);

namespace Tests\Services;

use App\Model\Entity\CategoryEntity;
use App\Model\Services\CategoryService;
use Tester\Assert;
use Tests\Support\ServiceTestCase;

require __DIR__ . '/../bootstrap.php';

final class CategoryServiceTest extends ServiceTestCase
{
    public function testAddRootAndChildPersistsHierarchy(): void
    {
        $household = $this->household();
        $service = new CategoryService($this->em);
        $root = $service->addCategory($household, ' Dairy ', $household->getModerator());
        $child = $service->addCategory($household, 'Yoghurt', $household->getModerator(), $root);
        Assert::true($household->getCategories()->contains($child));
        $id = $child->getId();
        $this->em->clear();
        $stored = $service->getCategoryById($id);
        Assert::same('Yoghurt', $stored->getName());
        Assert::same('Dairy', $stored->getParent()->getName());
        Assert::same($household->getId(), $stored->getHousehold()->getId());
        Assert::null($stored->getParent()->getParent());
    }

    public function testInvalidCategoryNamesAreRejected(): void
    {
        $household = $this->household();
        foreach ([' ', str_repeat('x', 51)] as $name) {
            Assert::exception(fn() => (new CategoryService($this->em))->addCategory($household, $name, $household->getModerator()), \InvalidArgumentException::class);
        }
        Assert::same(0, $this->em->getRepository(CategoryEntity::class)->count([]));
        Assert::count(0, $household->getCategories());
    }

    public function testGetCategoryByIdRejectsMissingCategory(): void
    {
        Assert::exception(fn() => (new CategoryService($this->em))->getCategoryById(999), \InvalidArgumentException::class);
    }

    public function testListsAreSortedAndScopedByHouseholdAndParent(): void
    {
        $household = $this->household();
        $other = $this->household();
        $root = $this->category($household, 'Z-root');
        $a = $this->category($household, 'A-child', $root);
        $b = $this->category($household, 'B-child', $root);
        $this->category($other, 'Foreign');
        $service = new CategoryService($this->em);
        Assert::same([$a, $b, $root], $service->getCategories($household));
        Assert::same([$root], $service->getSubcategories($household));
        Assert::same([$a, $b], $service->getSubcategories($household, $root));
        Assert::same([], $service->getSubcategories($household, $a));
    }

    public function testRenamePersistsNormalizedName(): void
    {
        $household = $this->household();
        $category = $this->category($household);
        (new CategoryService($this->em))->updateCategoryName($household, $category, '  Milk  ', $household->getModerator());
        $this->em->refresh($category);
        Assert::same('Milk', $category->getName());
    }

    public function testMoveCategoryToParentAndBackToRoot(): void
    {
        $household = $this->household();
        $root = $this->category($household);
        $category = $this->category($household, 'Milk');
        $service = new CategoryService($this->em);
        $service->moveCategory($household, $category, $root, $household->getModerator());
        $this->em->refresh($category);
        Assert::same($root, $category->getParent());
        $service->moveCategory($household, $category, null, $household->getModerator());
        $this->em->refresh($category);
        Assert::null($category->getParent());
    }

    public function testMoveRejectsSelfAndDescendantCycles(): void
    {
        $household = $this->household();
        $root = $this->category($household);
        $child = $this->category($household, 'Milk', $root);
        $service = new CategoryService($this->em);
        Assert::exception(fn() => $service->moveCategory($household, $root, $root, $household->getModerator()), \DomainException::class);
        Assert::exception(fn() => $service->moveCategory($household, $root, $child, $household->getModerator()), \DomainException::class);
        Assert::null($root->getParent());
        Assert::same($root, $child->getParent());
    }

    public function testForeignCategoriesAndParentsAreRejected(): void
    {
        $household = $this->household();
        $category = $this->category($household);
        $foreign = $this->category($this->household());
        $service = new CategoryService($this->em);
        $moderator = $household->getModerator();
        foreach ([
            fn() => $service->addCategory($household, 'Milk', $moderator, $foreign),
            fn() => $service->getSubcategories($household, $foreign),
            fn() => $service->updateCategoryName($household, $foreign, 'Renamed', $moderator),
            fn() => $service->moveCategory($household, $category, $foreign, $moderator),
            fn() => $service->moveCategory($household, $foreign, null, $moderator),
            fn() => $service->removeCategory($household, $foreign, $moderator),
        ] as $operation) {
            Assert::exception($operation, \DomainException::class);
        }
        Assert::same(2, $this->em->getRepository(CategoryEntity::class)->count([]));
        Assert::same('Dairy', $foreign->getName());
        Assert::null($category->getParent());
    }

    public function testMemberCannotManageCategories(): void
    {
        $household = $this->household();
        $category = $this->category($household);
        $member = $this->user();
        $household->addUser($member);
        $this->em->flush();
        $service = new CategoryService($this->em);
        foreach ([
            fn() => $service->addCategory($household, 'Milk', $member),
            fn() => $service->updateCategoryName($household, $category, 'Milk', $member),
            fn() => $service->moveCategory($household, $category, null, $member),
            fn() => $service->removeCategory($household, $category, $member),
        ] as $operation) {
            Assert::exception($operation, \DomainException::class);
        }
        Assert::same('Dairy', $category->getName());
        Assert::same(1, $this->em->getRepository(CategoryEntity::class)->count([]));
    }

    public function testRemoveUnusedLeafDeletesItAndUpdatesCollection(): void
    {
        $household = $this->household();
        $root = $this->category($household);
        $child = $this->category($household, 'Milk', $root);
        $id = $child->getId();
        (new CategoryService($this->em))->removeCategory($household, $child, $household->getModerator());
        Assert::false($household->getCategories()->contains($child));
        $this->em->clear();
        Assert::null($this->em->find(CategoryEntity::class, $id));
        Assert::same(1, $this->em->getRepository(CategoryEntity::class)->count([]));
    }

    public function testRemoveCategoryWithChildrenIsRejected(): void
    {
        $household = $this->household();
        $root = $this->category($household);
        $this->category($household, 'Milk', $root);
        Assert::exception(fn() => (new CategoryService($this->em))->removeCategory($household, $root, $household->getModerator()), \DomainException::class, 'Cannot remove a category with subcategories.');
        Assert::same(2, $this->em->getRepository(CategoryEntity::class)->count([]));
    }

    public function testRemoveCategoryAssignedToPersistedFoodIsRejected(): void
    {
        $household = $this->household();
        $category = $this->category($household);
        $food = $this->food($this->shelf($household));
        $food->addCategory($category);
        $this->em->flush();
        $categoryId = $category->getId();
        $this->em->clear();
        $category = $this->em->find(CategoryEntity::class, $categoryId);
        $household = $category->getHousehold();
        // The inverse food collection is not initialized; the owning-side query must protect it.
        Assert::exception(fn() => (new CategoryService($this->em))->removeCategory($household, $category, $household->getModerator()), \DomainException::class, 'Cannot remove a category assigned to food.');
        Assert::same(1, $this->em->getRepository(CategoryEntity::class)->count([]));
    }

    public function testRemoveCategoryAssignedToUnsavedFoodIsRejected(): void
    {
        $household = $this->household();
        $category = $this->category($household);
        $food = $this->food($this->shelf($household));
        $food->addCategory($category); // Association intentionally not flushed.
        Assert::exception(fn() => (new CategoryService($this->em))->removeCategory($household, $category, $household->getModerator()), \DomainException::class, 'Cannot remove a category assigned to food.');
        Assert::true($category->getFoods()->contains($food));
    }
}

(new CategoryServiceTest())->run();
