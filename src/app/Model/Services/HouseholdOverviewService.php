<?php declare(strict_types=1);

namespace App\Model\Services;

use App\Model\Entity\HouseholdEntity;
use Nette\Utils\Paginator;

/**
 * Read-only overview of a household (appliances → shelves → paginated foods),
 * shared by the guest view and the pending-requester view on Home.
 */
final class HouseholdOverviewService
{
    private const FoodsPerShelf = 2;

    public function __construct(
        private ApplianceService $appliances,
        private ShelfService $shelves,
        private FoodService $foods,
    ) {
    }

    /**
     * @param array<int|string, mixed> $requestedPages shelf id => requested page
     * @return array{appliances: list<array{appliance: mixed, shelves: list<array{shelf: mixed, foods: array, paginator: Paginator}>}>, pages: array<int, int>}
     */
    public function build(HouseholdEntity $household, array $requestedPages): array
    {
        $pages = [];
        $appliances = [];
        foreach ($this->appliances->getAppliances($household) as $appliance) {
            $shelves = [];
            foreach ($this->shelves->getShelves($appliance) as $shelf) {
                $paginator = new Paginator;
                $paginator->setItemsPerPage(self::FoodsPerShelf);
                $paginator->setItemCount($this->foods->getFoodCount($household, $shelf));
                $page = filter_var($requestedPages[$shelf->getId()] ?? 1, FILTER_VALIDATE_INT);
                $paginator->setPage($page === false ? 1 : $page);
                $pages[$shelf->getId()] = $paginator->getPage();
                $shelves[] = [
                    'shelf' => $shelf,
                    'foods' => $this->foods->getFoods(
                        $household,
                        $paginator->getItemsPerPage(),
                        $paginator->getOffset(),
                        $shelf,
                    ),
                    'paginator' => $paginator,
                ];
            }
            $appliances[] = ['appliance' => $appliance, 'shelves' => $shelves];
        }

        return ['appliances' => $appliances, 'pages' => $pages];
    }
}
