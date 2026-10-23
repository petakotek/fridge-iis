<?php declare(strict_types=1);

namespace App\Presentation\Household;

use App\Model\Services\HouseholdService;
use App\Model\Services\UserService;
use App\Presentation\Accessory\AuthenticatedPresenter;
use Nette\Application\UI\Form;

final class HouseholdPresenter extends AuthenticatedPresenter
{
    public function __construct(UserService $users, private HouseholdService $households)
    {
        parent::__construct($users);
    }

    public function actionCreate(): void
    {
        $this->requireNoHousehold();
    }

    public function actionRequest(): void
    {
        $this->requireNoHousehold();
    }

    public function actionSettings(): void
    {
        if ($this->currentUser->getHousehold()?->getModerator() !== $this->currentUser) {
            $this->error('Přístup odepřen.', 403);
        }
    }

    public function renderSettings(): void
    {
        $this->template->household = $this->currentUser->getHousehold();
        $this->template->requests = $this->households->getHouseholdRequests($this->currentUser->getHousehold());
        $this->template->members = $this->households->getHouseholdMembers($this->currentUser->getHousehold());
    }

    protected function createComponentCreateForm(): Form
    {
        $form = new Form;
        $form->addText('name', 'Název domácnosti')->setRequired()->addRule($form::MaxLength, null, 255);
        $form->addSubmit('send', 'Vytvořit domácnost');
        $form->onSuccess[] = function (Form $form, $data): void {
            try {
                $this->households->createHousehold($data->name, $this->currentUser);
            } catch (\DomainException|\InvalidArgumentException) {
                $form->addError('Domácnost se nepodařilo vytvořit. Zkontrolujte název a stav svého účtu.');
                return;
            }
            $this->flashMessage('Domácnost byla vytvořena.');
            $this->redirect('Home:default');
        };
        return $form;
    }

    protected function createComponentRequestForm(): Form
    {
        $form = new Form;
        $form->addText('token', 'Pozvánkový token')->setRequired();
        $form->addSubmit('send', 'Odeslat žádost');
        $form->onSuccess[] = function (Form $form, $data): void {
            try {
                $token = trim($data->token);
                $household = $this->households->getHouseholdByToken($token);
                $this->households->createHouseholdRequest($household, $this->currentUser, $token);
            } catch (\InvalidArgumentException) {
                $form->addError('Domácnost s tímto tokenem nebyla nalezena.');
                return;
            } catch (\DomainException) {
                $form->addError('Už máte aktivní žádost.');
                return;
            }
            $this->flashMessage('Žádost byla odeslána správci domácnosti.');
            $this->redirect('Home:default');
        };
        return $form;
    }

    protected function createComponentSettingsForm(): Form
    {
        $form = new Form;
        $form->addText('name', 'Název domácnosti')->setRequired()->addRule($form::MaxLength, null, 255);
        $form->addSubmit('send', 'Uložit změny');
        $form->setDefaults(['name' => $this->currentUser->getHousehold()?->getName()]);
        $form->onSuccess[] = function (Form $form, $data): void {
            $household = $this->currentUser->getHousehold();
            if ($household === null) {
                $this->error('Domácnost nenalezena.', 404);
            }
            try {
                $this->households->updateName($household, $this->currentUser, $data->name);
            } catch (\DomainException|\InvalidArgumentException) {
                $form->addError('Název domácnosti se nepodařilo změnit.');
                return;
            }
            $this->flashMessage('Nastavení domácnosti bylo uloženo.');
            $this->redirect('this');
        };
        return $form;
    }

    protected function createComponentRegenerateTokenForm(): Form
    {
        $form = new Form;
        $form->addSubmit('send', 'Vygenerovat nový token');
        $form->onSuccess[] = function (Form $form): void {
            $household = $this->currentUser->getHousehold();
            if ($household === null) {
                $this->error('Domácnost nenalezena.', 404);
            }
            try {
                $this->households->regenerateToken($household, $this->currentUser);
            } catch (\DomainException) {
                $this->error('Přístup odepřen.', 403);
            }
            $this->flashMessage('Byl vygenerován nový pozvánkový token.');
            $this->redirect('this');
        };
        return $form;
    }

    protected function createComponentDeleteHouseholdForm(): Form
    {
        $form = new Form;
        $form->addText('confirmation', 'Pro potvrzení napište název domácnosti')->setRequired();
        $form->addSubmit('send', 'Smazat domácnost');
        $form->onSuccess[] = function (Form $form, $data): void {
            $household = $this->currentUser->getHousehold();
            if ($household === null) {
                $this->error('Domácnost nenalezena.', 404);
            }
            if (trim($data->confirmation) !== $household->getName()) {
                $form->addError('Zadaný název domácnosti nesouhlasí.');
                return;
            }
            try {
                $this->households->removeHousehold($household, $this->currentUser);
            } catch (\DomainException) {
                $this->error('Přístup odepřen.', 403);
            }
            $this->flashMessage('Domácnost byla smazána.');
            $this->redirect('Home:default');
        };
        return $form;
    }

    protected function createComponentTransferModeratorForm(): Form
    {
        $household = $this->currentUser->getHousehold();
        $options = [];
        if ($household !== null) {
            foreach ($this->households->getHouseholdMembers($household) as $member) {
                if ($member !== $this->currentUser) {
                    $options[$member->getId()] = $member->getName() . ' ' . $member->getSurname() . ' (' . $member->getEmail() . ')';
                }
            }
        }

        $form = new Form;
        $form->addSelect('memberId', 'Nový správce', $options)->setPrompt('Vyberte člena')->setRequired();
        $form->addSubmit('send', 'Předat správu');
        $form->onSuccess[] = function (Form $form, $data): void {
            $household = $this->currentUser->getHousehold();
            if ($household === null) {
                $this->error('Domácnost nenalezena.', 404);
            }
            try {
                $newModerator = $this->users->getUserById((int) $data->memberId);
                $this->households->transferModerator($household, $this->currentUser, $newModerator);
            } catch (\DomainException|\InvalidArgumentException) {
                $form->addError('Správu se nepodařilo předat. Ověřte členství vybraného uživatele.');
                return;
            }
            $this->flashMessage('Správa domácnosti byla předána. Nyní jste jejím členem.');
            $this->redirect('Home:default');
        };
        return $form;
    }

    protected function createComponentDecisionForm(): Form
    {
        $household = $this->currentUser->getHousehold();
        $options = [];
        foreach ($this->households->getHouseholdRequests($household) as $requester) {
            $options[$requester->getId()] = $requester->getName() . ' ' . $requester->getSurname() . ' (' . $requester->getEmail() . ')';
        }

        $form = new Form;
        $form->addSelect('requesterId', 'Žadatel', $options)->setPrompt('Vyberte žadatele')->setRequired();
        $form->addSubmit('accept', 'Přijmout');
        $form->addSubmit('reject', 'Zamítnout');
        $form->onSuccess[] = function (Form $form, $data) use ($household): void {
            try {
                $requester = $this->users->getUserById((int) $data->requesterId);
                if ($requester->getHouseholdRequest() !== $household) {
                    throw new \DomainException('Požadavek již není aktuální.');
                }
                if ($form['accept']->isSubmittedBy()) {
                    $this->households->acceptHouseholdRequest($household, $this->currentUser, $requester);
                    $this->flashMessage('Žadatel byl přijat do domácnosti.');
                } elseif ($form['reject']->isSubmittedBy()) {
                    $this->households->removeHouseholdRequest($household, $this->currentUser, $requester);
                    $this->flashMessage('Žádost byla zamítnuta.');
                } else {
                    $form->addError('Vyberte, zda žádost přijmout nebo zamítnout.');
                    return;
                }
            } catch (\DomainException|\InvalidArgumentException) {
                $form->addError('Žádost už není aktivní. Obnovte stránku.');
                return;
            }
            $this->redirect('this');
        };
        return $form;
    }

    private function requireNoHousehold(): void
    {
        if ($this->currentUser->getHousehold() !== null || $this->currentUser->getHouseholdRequest() !== null) {
            $this->redirect('Home:default');
        }
    }
}
