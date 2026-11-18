<?php

/** @testCase */

declare(strict_types=1);

namespace Tests\Services;

use App\Model\Entity\CategoryEntity;
use App\Model\Entity\FoodEntity;
use App\Model\Services\ApplianceService;
use App\Model\Services\CategoryService;
use App\Model\Services\FoodService;
use App\Model\Services\ProductLookupService;
use App\Model\Services\ShelfService;
use App\Model\Services\UserService;
use App\Presentation\Food\FoodPresenter;
use Nette\Application\UI\Presenter;
use Latte\Engine;
use Latte\Loaders\StringLoader;
use Nette\Bridges\ApplicationLatte\UIExtension;
use Nette\Bridges\FormsLatte\FormsExtension;
use Nette\Caching\Storages\MemoryStorage;
use Tester\Assert;
use Tests\Support\ServiceTestCase;

require __DIR__ . '/../bootstrap.php';

final class FoodCategoriesTest extends ServiceTestCase
{
    public function testMemberCanCreateFoodWithSeveralCategories(): void
    {
        $household = $this->household();
        $member = $this->user();
        $household->addUser($member);
        $shelf = $this->shelf($household);
        $root = $this->category($household);
        $child = $this->category($household, 'Yoghurt', $root);
        $food = (new FoodService($this->em))->addFood(
            'Yoghurt', '8591234567890', 19.90, 60, 4, 3, 5, 0, 100,
            $shelf, $household, $member, [$root, $child, $child],
        );
        $foodId = $food->getId();
        $expected = [$root->getId(), $child->getId()];
        Assert::true($root->getFoods()->contains($food));
        Assert::true($child->getFoods()->contains($food));
        $this->em->clear();
        $stored = $this->em->find(FoodEntity::class, $foodId);
        $actual = $stored->getCategories()->map(fn(CategoryEntity $category) => $category->getId())->toArray();
        sort($actual);
        Assert::same($expected, $actual);
    }

    public function testCategoriesCanBeReplacedPreservedAndRemoved(): void
    {
        $household = $this->household();
        $food = $this->food($this->shelf($household));
        $first = $this->category($household, 'First');
        $second = $this->category($household, 'Second');
        $service = new FoodService($this->em);
        $service->updateFood($food, $household, $household->getModerator(), [$first]);
        $service->updateFood($food, $household, $household->getModerator(), [$second]);
        Assert::false($first->getFoods()->contains($food));
        Assert::true($second->getFoods()->contains($food));
        $this->em->refresh($food);
        Assert::same([$second], $food->getCategories()->toArray());

        $food->setName('New name');
        $service->updateFood($food, $household, $household->getModerator());
        $this->em->refresh($food);
        Assert::same([$second], $food->getCategories()->toArray());

        $service->updateFood($food, $household, $household->getModerator(), []);
        Assert::false($second->getFoods()->contains($food));
        $this->em->refresh($food);
        Assert::count(0, $food->getCategories());
        Assert::same(0, (int) $this->em->getConnection()->fetchOne('SELECT COUNT(*) FROM categoryentity_foodentity'));
    }

    public function testForeignCategoryDoesNotCreateFoodOrPartlyChangeSelection(): void
    {
        $household = $this->household();
        $shelf = $this->shelf($household);
        $food = $this->food($shelf);
        $existing = $this->category($household, 'Existing');
        $replacement = $this->category($household, 'Replacement');
        $foreign = $this->category($this->household());
        $service = new FoodService($this->em);
        $service->updateFood($food, $household, $household->getModerator(), [$existing]);

        Assert::exception(fn() => $service->addFood(
            'Invalid', '', 0, 0, 0, 0, 0, 0, 100,
            $shelf, $household, $household->getModerator(), [$replacement, $foreign],
        ), \DomainException::class);
        Assert::same(1, $this->em->getRepository(FoodEntity::class)->count([]));
        Assert::count(1, $shelf->getFoods());
        Assert::exception(fn() => $service->updateFood(
            $food, $household, $household->getModerator(), [$replacement, $foreign],
        ), \DomainException::class);
        Assert::same([$existing], $food->getCategories()->toArray());
        Assert::false($replacement->getFoods()->contains($food));
        Assert::false($foreign->getFoods()->contains($food));
        $this->em->refresh($food);
        Assert::same([$existing], $food->getCategories()->toArray());
    }

    public function testOutsiderCannotChangeCategoriesOrUseForeignFood(): void
    {
        $household = $this->household();
        $food = $this->food($this->shelf($household));
        $category = $this->category($household);
        $foreignHousehold = $this->household();
        $foreignShelf = $this->shelf($foreignHousehold);
        $foreignFood = $this->food($foreignShelf);
        $service = new FoodService($this->em);
        Assert::exception(fn() => $service->updateFood(
            $food, $household, $foreignHousehold->getModerator(), [$category],
        ), \DomainException::class);
        Assert::exception(fn() => $service->updateFood(
            $foreignFood, $household, $household->getModerator(), [$category],
        ), \DomainException::class);
        Assert::exception(fn() => $service->addFood(
            'Invalid', '', 0, 0, 0, 0, 0, 0, 100,
            $foreignShelf, $household, $household->getModerator(), [$category],
        ), \DomainException::class);
        Assert::count(0, $food->getCategories());
        Assert::count(0, $foreignFood->getCategories());
    }

    public function testFormsOfferHouseholdCategoryPathsAndPreselectExistingCategories(): void
    {
        $household = $this->household();
        $shelf = $this->shelf($household);
        $food = $this->food($shelf);
        $root = $this->category($household, 'Dairy');
        $child = $this->category($household, 'Yoghurt', $root);
        $foreign = $this->category($this->household(), 'Foreign');
        $food->addCategory($child);
        $this->em->flush();
        $presenter = new FoodPresenter(
            new UserService($this->em),
            new FoodService($this->em),
            new ShelfService($this->em),
            new ApplianceService($this->em),
            new ProductLookupService(new MemoryStorage),
            new CategoryService($this->em),
        );
        (new \ReflectionProperty(FoodPresenter::class, 'household'))->setValue($presenter, $household);
        (new \ReflectionProperty(FoodPresenter::class, 'food'))->setValue($presenter, $food);
        (new \ReflectionProperty(FoodPresenter::class, 'availableShelves'))->setValue($presenter, [$shelf->getId() => $shelf]);
        (new \ReflectionProperty(Presenter::class, 'action'))->setValue($presenter, 'edit');
        $editForm = (new \ReflectionMethod(FoodPresenter::class, 'createComponentEditForm'))->invoke($presenter);
        Assert::same([$child->getId()], $editForm['categoryIds']->getValue());
        Assert::same('Dairy / Yoghurt', $editForm['categoryIds']->getItems()[$child->getId()]);
        Assert::false(isset($editForm['categoryIds']->getItems()[$foreign->getId()]));

        (new \ReflectionProperty(Presenter::class, 'action'))->setValue($presenter, 'add');
        $addForm = (new \ReflectionMethod(FoodPresenter::class, 'createComponentAddForm'))->invoke($presenter);
        Assert::same($editForm['categoryIds']->getItems(), $addForm['categoryIds']->getItems());
        Assert::same([], $addForm['categoryIds']->getValue());

        $latte = new Engine;
        $latte->addExtension(new FormsExtension);
        $latte->addExtension(new UIExtension(null));
        $latte->setLoader(new StringLoader([
            'main' => '{formContext $form}{include "categoryFields.latte", form: $form}{/formContext}',
            'categoryFields.latte' => file_get_contents(__DIR__ . '/../../app/Presentation/Food/categoryFields.latte'),
        ]));
        $html = $latte->renderToString('main', ['form' => $editForm, 'basePath' => '']);
        Assert::contains(' multiple', $html);
        Assert::same(2, substr_count($html, '<option '));
        Assert::same(1, substr_count($html, ' selected'));
        Assert::contains('data-category-picker', $html);
        Assert::contains('Dairy / Yoghurt', $html);

    }
}

(new FoodCategoriesTest())->run();
