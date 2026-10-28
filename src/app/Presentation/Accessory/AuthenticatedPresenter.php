<?php declare(strict_types=1);

namespace App\Presentation\Accessory;

use App\Model\Entity\UserEntity;
use App\Model\Services\UserService;
use App\Model\Services\ApplianceService;
use Nette\Application\UI\Form;
use Nette\Application\UI\Presenter;

abstract class AuthenticatedPresenter extends Presenter
{
    protected UserEntity $currentUser;
    private ApplianceService $navigationAppliances;

    public function injectApplianceNavigation(ApplianceService $appliances): void
    {
        $this->navigationAppliances = $appliances;
    }


    public function __construct(protected UserService $users)
    {
        parent::__construct();
    }

    protected function startup(): void
    {
        parent::startup();
        $this->getSession()->start();
        if (!$this->getUser()->isLoggedIn()) {
            $this->redirect('Auth:login');
        }

        try {
            $this->currentUser = $this->users->getUserById((int) $this->getUser()->getId());
        } catch (\InvalidArgumentException) {
            $this->getUser()->logout(true);
            $this->redirect('Auth:login');
        }
    }

    protected function beforeRender(): void
    {
        parent::beforeRender();
        $household = $this->currentUser->getHousehold();
        $this->template->currentUser = $this->currentUser;
        $this->template->sidebarAppliances = $household !== null
            ? $this->navigationAppliances->getAppliances($household)
            : [];
        $this->template->accountRole = $this->currentUser->isAdmin()
            ? 'Administrátor'
            : ($household !== null
                ? ($household->getModerator() === $this->currentUser ? 'Správce domácnosti' : 'Člen domácnosti')
                : ($this->currentUser->getHouseholdRequest() !== null ? 'Žadatel' : 'Bez domácnosti'));
    }

    protected function createComponentLogoutForm(): Form
    {
        $form = new Form;
        $form->addSubmit('send', 'Odhlásit se');
        $form->onSuccess[] = function (): void {
            $this->getUser()->logout(true);
            $this->redirect('Auth:login');
        };
        return $form;
    }
}
