<?php declare(strict_types=1);

namespace App\Presentation\Appliance;

use App\Model\Entity\ApplianceEntity;
use App\Model\Services\ApplianceService;
use App\Model\Services\UserService;
use App\Model\Services\ShelfService;
use App\Presentation\Accessory\AuthenticatedPresenter;
use Nette\Application\UI\Form;

final class AppliancePresenter extends AuthenticatedPresenter
{
    private ApplianceEntity $selectedAppliance;

    public function __construct(UserService $users, private ApplianceService $appliance, private ShelfService $shelves)
    {
        parent::__construct($users);
    }

    protected function startup(): void
    {
        parent::startup();
        if ($this->getAction() !== 'detail' && $this->currentUser->getHousehold()?->getModerator() !== $this->currentUser) {
            $this->error('Přístup odepřen.', 403);
        }
    }

    public function actionDetail(int $id): void
    {
        $this->loadAppliance($id);
        $this->template->shelves = $this->shelves->getShelves($this->selectedAppliance);
        $this->template->isModerator = $this->currentUser->getHousehold()?->getModerator() === $this->currentUser;
    }

    public function actionEdit(int $id): void
    {
        $this->loadAppliance($id);
    }

    public function actionDelete(int $id): void
    {
        $this->loadAppliance($id);
    }

    private function loadAppliance(int $id): void
    {
        try {
            $appliance = $this->appliance->getApplianceById($id);
        } catch (\InvalidArgumentException) {
            $this->error('Spotřebič nebyl nalezen.', 404);
        }
        if ($this->currentUser->getHousehold() === null || $appliance === null || $appliance->getHousehold() !== $this->currentUser->getHousehold()) {
            $this->error('Spotřebič nebyl nalezen.', 404);
        }
        $this->selectedAppliance = $appliance;
        $this->template->appliance = $appliance;
    }

    private function nameForm(string $submitLabel): Form
    {
        $form = new Form;
        $form->addProtection('Platnost formuláře vypršela. Odešlete jej znovu.');
        $form->addText('name', 'Název spotřebiče')
            ->setRequired('Zadejte název spotřebiče.')
            ->addRule(Form::MaxLength, 'Název může mít nejvýše 255 znaků.', 255);
        $form->addSubmit('send', $submitLabel);
        return $form;
    }

    protected function createComponentCreateForm(): Form
    {
        $form = $this->nameForm('Vytvořit spotřebič');
        $form->onSuccess[] = function (Form $form, $data): void {
            try {
                $this->appliance->addAppliance(
                    $this->currentUser->getHousehold(), $this->currentUser, $data->name,
                );
            } catch (\DomainException|\InvalidArgumentException) {
                $form->addError('Spotřebič se nepodařilo vytvořit. Zkontrolujte název.');
                return;
            }
            $this->flashMessage('Spotřebič byl vytvořen.');
            $this->redirect('Home:default');
        };
        return $form;
    }

    protected function createComponentEditForm(): Form
    {
        $form = $this->nameForm('Uložit změny');
        $form->setDefaults(['name' => $this->selectedAppliance->getName()]);
        $form->onSuccess[] = function (Form $form, $data): void {
            try {
                $this->appliance->updateApplianceName(
                    $this->selectedAppliance, $this->currentUser,
                    $this->currentUser->getHousehold(), $data->name,
                );
            } catch (\DomainException|\InvalidArgumentException) {
                $form->addError('Název spotřebiče se nepodařilo změnit.');
                return;
            }
            $this->flashMessage('Spotřebič byl upraven.');
            $this->redirect('Home:default');
        };
        return $form;
    }

    protected function createComponentDeleteForm(): Form
    {
        $form = new Form;
        $form->addProtection('Platnost formuláře vypršela. Odešlete jej znovu.');
        $form->addSubmit('send', 'Smazat spotřebič');
        $form->onSuccess[] = function (Form $form): void {
            try {
                $this->appliance->removeAppliance(
                    $this->currentUser->getHousehold(), $this->currentUser, $this->selectedAppliance,
                );
            } catch (\DomainException) {
                $form->addError('Spotřebič se nepodařilo smazat.');
                return;
            }
            $this->flashMessage('Spotřebič byl smazán.');
            $this->redirect('Home:default');
        };
        return $form;
    }
}
