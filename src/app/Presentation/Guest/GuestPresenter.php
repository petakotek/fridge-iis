<?php declare(strict_types=1);

namespace App\Presentation\Guest;

use App\Model\Entity\HouseholdEntity;
use App\Model\Services\HouseholdOverviewService;
use App\Model\Services\HouseholdService;
use Nette\Application\UI\Form;
use Nette\Application\UI\Presenter;

final class GuestPresenter extends Presenter
{
    private HouseholdEntity $household;

    public function __construct(
        private HouseholdService $households,
        private HouseholdOverviewService $overview,
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
        $overview = $this->overview->build($this->household, $pages);
        $this->template->household = $this->household;
        $this->template->appliances = $overview['appliances'];
        $this->template->pages = $overview['pages'];
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
