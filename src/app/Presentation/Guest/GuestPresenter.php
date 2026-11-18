<?php declare(strict_types=1);

namespace App\Presentation\Guest;

use App\Model\Entity\HouseholdEntity;
use App\Model\Services\ApplianceService;
use App\Model\Services\FoodService;
use App\Model\Services\HouseholdService;
use App\Model\Services\ShelfService;
use Nette\Application\UI\Form;
use Nette\Application\UI\Presenter;
use Nette\Utils\Paginator;

final class GuestPresenter extends Presenter
{
    private HouseholdEntity $household;

    public function __construct(
        private HouseholdService $households,
        private ApplianceService $appliances,
        private ShelfService $shelves,
        private FoodService $foods,
    ) {
        parent::__construct();
    }

    protected function startup(): void
    {
        parent::startup();
        $session = $this->getSession('guest');
        $householdId = $session->get('householdId');
        $token = $session->get('token');

        try {
            if ($householdId === null || $token === null) {
                throw new \InvalidArgumentException('Guest session missing.');
            }
            $this->household = $this->households->getHouseholdById((int) $householdId);
            if ($this->household->getToken() !== $token) {
                throw new \InvalidArgumentException('Guest token no longer valid.');
            }
        } catch (\InvalidArgumentException) {
            $session->remove();
            if ($householdId !== null) {
                $this->flashMessage('Přístup hosta vypršel.', 'error');
            }
            $this->redirect('Sign:in');
        }
    }

    public function renderDefault(array $pages = []): void
    {
        $requestedPages = $pages;
        $pages = [];
        $appliances = [];
        foreach ($this->appliances->getAppliances($this->household) as $appliance) {
            $shelves = [];
            foreach ($this->shelves->getShelves($appliance) as $shelf) {
                $paginator = new Paginator;
                $paginator->setItemsPerPage(2);
                $paginator->setItemCount($this->foods->getFoodCount($this->household, $shelf));
                $page = filter_var($requestedPages[$shelf->getId()] ?? 1, FILTER_VALIDATE_INT);
                $paginator->setPage($page === false ? 1 : $page);
                $pages[$shelf->getId()] = $paginator->getPage();
                $shelves[] = [
                    'shelf' => $shelf,
                    'foods' => $this->foods->getFoods(
                        $this->household,
                        $paginator->getItemsPerPage(),
                        $paginator->getOffset(),
                        $shelf,
                    ),
                    'paginator' => $paginator,
                ];
            }
            $appliances[] = ['appliance' => $appliance, 'shelves' => $shelves];
        }
        $this->template->household = $this->household;
        $this->template->appliances = $appliances;
        $this->template->pages = $pages;
    }

    protected function createComponentLeaveForm(): Form
    {
        $form = new Form;
        $form->addSubmit('send', 'Ukončit přístup hosta');
        $form->onSuccess[] = function (): void {
            $this->getSession('guest')->remove();
            $this->redirect('Sign:in');
        };
        return $form;
    }
}
