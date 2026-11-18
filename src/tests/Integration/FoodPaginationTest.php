<?php

/** @testCase */

declare(strict_types=1);

namespace Tests\Services;

use App\Model\Services\ApplianceService;
use App\Model\Services\FoodService;
use App\Model\Services\HouseholdService;
use App\Model\Services\ShelfService;
use App\Presentation\Guest\GuestPresenter;
use Latte\Engine;
use Nette\Application\UI\Control;
use Nette\Bridges\ApplicationLatte\DefaultTemplate;
use Tester\Assert;
use Tests\Support\ServiceTestCase;

require __DIR__ . '/../bootstrap.php';

final class FoodPaginationTest extends ServiceTestCase
{
    public function testPagesSpanShelvesAndRespectHouseholdAndStatus(): void
    {
        $household = $this->household();
        $firstShelf = $this->shelf($household);
        $secondShelf = $this->shelf($household);
        $service = new FoodService($this->em);
        $foods = [];
        foreach (['Zebra', 'Apple', 'Apple', 'Milk', 'Apple'] as $index => $name) {
            $food = $this->food($index % 2 === 0 ? $firstShelf : $secondShelf);
            $food->setName($name);
            $foods[] = $food;
        }
        $service->consumeFood($this->food($firstShelf), $household->getModerator());
        $service->trashFood($this->food($secondShelf));
        $foreignShelf = $this->shelf($this->household());
        $this->food($foreignShelf);
        $emptyShelf = $this->shelf($household);
        $this->em->flush();

        Assert::same(5, $service->getFoodCount($household));
        Assert::same([$foods[1], $foods[2]], $service->getFoods($household, 2, 0));
        Assert::same([$foods[4], $foods[3]], $service->getFoods($household, 2, 2));
        Assert::same([$foods[0]], $service->getFoods($household, 2, 4));
        Assert::same([], $service->getFoods($household, 2, 6));
        Assert::same(3, $service->getFoodCount($household, $firstShelf));
        Assert::same([$foods[2], $foods[4]], $service->getFoods($household, 2, 0, $firstShelf));
        Assert::same([$foods[4]], $service->getFoodsByShelf($firstShelf, 1, 1));
        Assert::same(0, $service->getFoodCount($household, $foreignShelf));
        Assert::same([], $service->getFoods($household, 12, 0, $foreignShelf));
        Assert::same(0, $service->getFoodCount($household, $emptyShelf));
        Assert::same([], $service->getFoods($household, 12, 0, $emptyShelf));
        Assert::same(7, $service->getFoodCount($household, status: 'all'));
        Assert::count(4, $service->getFoods($household, 12, 0, $firstShelf, 'all'));
    }

    public function testHistoryPaginationKeepsDateOrderAndConsumerFilter(): void
    {
        $household = $this->household();
        $member = $this->user();
        $household->addUser($member);
        $this->em->flush();
        $firstShelf = $this->shelf($household);
        $secondShelf = $this->shelf($household);
        $service = new FoodService($this->em);

        foreach (['consumed', 'trashed'] as $status) {
            $foods = [];
            foreach ([$firstShelf, $secondShelf, $firstShelf] as $index => $shelf) {
                $food = $this->food($shelf);
                if ($status === 'consumed') {
                    $service->consumeFood($food, $member);
                } else {
                    $service->trashFood($food);
                }
                $dateField = $status === 'consumed' ? 'consumedAt' : 'discardedAt';
                $this->em->getConnection()->update('FoodEntity', [
                    $dateField => $index === 0 ? '2026-01-02 12:00:00' : '2026-01-01 12:00:00',
                ], ['id' => $food->getId()]);
                $foods[] = $food;
            }
            Assert::same(3, $service->getFoodCount($household, status: $status, consumer: $member));
            Assert::same([$foods[0], $foods[2]], $service->getFoods($household, 2, 0, status: $status, consumer: $member));
            Assert::same([$foods[1]], $service->getFoods($household, 2, 2, status: $status, consumer: $member));
            Assert::same(2, $service->getFoodCount($household, $firstShelf, $status, $member));
        }

        $otherConsumerFood = $this->food($firstShelf);
        $service->consumeFood($otherConsumerFood, $household->getModerator());
        Assert::same(3, $service->getFoodCount($household, status: 'consumed', consumer: $member));
        Assert::same([$otherConsumerFood], $service->getFoods($household, 12, 0, status: 'consumed', consumer: $household->getModerator()));
        Assert::exception(fn() => $service->getFoodCount($household, status: 'consumed'), \InvalidArgumentException::class);
    }

    public function testGuestPagesShelvesIndependentlyAndOnlyShowsStoredFood(): void
    {
        $household = $this->household();
        $firstShelf = $this->shelf($household, 5000);
        $secondShelf = $this->shelf($household, 5000);
        $emptyShelf = $this->shelf($household);
        $foods = [];
        foreach ([$firstShelf, $secondShelf] as $shelf) {
            for ($index = 0; $index < 13; $index++) {
                $foods[$shelf->getId()][] = $this->food($shelf);
            }
        }
        $service = new FoodService($this->em);
        $service->consumeFood($this->food($firstShelf), $household->getModerator());
        $service->trashFood($this->food($secondShelf));
        $foreignShelf = $this->shelf($this->household());
        $this->food($foreignShelf);

        $presenter = new GuestPresenter(
            new HouseholdService($this->em),
            new ApplianceService($this->em),
            new ShelfService($this->em),
            $service,
        );
        // Supply the household normally verified by startup, without opening an HTTP session.
        (new \ReflectionProperty(GuestPresenter::class, 'household'))->setValue($presenter, $household);
        $template = new DefaultTemplate(new Engine);
        (new \ReflectionProperty(Control::class, 'template'))->setValue($presenter, $template);
        $presenter->renderDefault([$firstShelf->getId() => 2, $secondShelf->getId() => 1]);
        $rows = [];
        foreach ($template->appliances as $appliance) {
            foreach ($appliance['shelves'] as $row) {
                $rows[$row['shelf']->getId()] = $row;
            }
        }
        $pageSize = $rows[$firstShelf->getId()]['paginator']->getItemsPerPage();
        Assert::same(array_slice($foods[$firstShelf->getId()], $pageSize, $pageSize), $rows[$firstShelf->getId()]['foods']);
        Assert::same(array_slice($foods[$secondShelf->getId()], 0, $pageSize), $rows[$secondShelf->getId()]['foods']);
        Assert::same(13, $rows[$firstShelf->getId()]['paginator']->getItemCount());
        Assert::same([], $rows[$emptyShelf->getId()]['foods']);
        Assert::false(isset($rows[$foreignShelf->getId()]));
        Assert::same(2, $template->pages[$firstShelf->getId()]);
        Assert::same(1, $template->pages[$secondShelf->getId()]);

        $presenter->renderDefault([$firstShelf->getId() => 999, $secondShelf->getId() => -2, $emptyShelf->getId() => 'invalid']);
        Assert::same((int) ceil(13 / $pageSize), $template->pages[$firstShelf->getId()]);
        Assert::same(1, $template->pages[$secondShelf->getId()]);
        Assert::same(1, $template->pages[$emptyShelf->getId()]);
    }
}

(new FoodPaginationTest())->run();
