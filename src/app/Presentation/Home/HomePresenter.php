<?php declare(strict_types=1);

namespace App\Presentation\Home;

use App\Model\Services\ApplianceService;
use App\Presentation\Accessory\AuthenticatedPresenter;
use App\Model\Services\HouseholdService;
use App\Model\Services\UserService;
use Nette\Application\UI\Form;
use Nette\Utils\Paginator;

final class HomePresenter extends AuthenticatedPresenter
{
    public function __construct(UserService $users, private HouseholdService $households, private ApplianceService $appliance)
    {
        parent::__construct($users);
    }

    public function renderDefault(int $page = 1): void
    {
        if ($this->currentUser->isAdmin()) {
            $this->redirect('Admin:default');
        }
        $this->template->household = $this->currentUser->getHousehold();
        $this->template->request = $this->currentUser->getHouseholdRequest();
        $this->template->isModerator = $this->currentUser->getHousehold()?->getModerator() === $this->currentUser;

        $household = $this->currentUser->getHousehold();
        $paginator = new Paginator();
        $paginator->setItemsPerPage(15);

        if ($household !== null) {
            $paginator->setItemCount($this->appliance->countAppliances($household));
        }
        $paginator->setPage($page);
        $this->template->appliances = $household !== null
            ? $this->appliance->getAppliances(
                $household,
                $paginator->getItemsPerPage(),
                $paginator->getOffset(),
            )
            : [];

        $this->template->paginator = $paginator;
    }

    protected function createComponentCancelRequestForm(): Form
    {
        $form = new Form;
        $form->addSubmit('send', 'Zrušit žádost');
        $form->onSuccess[] = function (): void {
            try {
                $this->households->cancelOwnRequest($this->currentUser);
                $this->flashMessage('Žádost byla zrušena.');
            } catch (\DomainException) {
                $this->flashMessage('Žádost už není aktivní.', 'error');
            }
            $this->redirect('Home:default');
        };
        return $form;
    }
}
