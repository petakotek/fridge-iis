<?php declare(strict_types=1);

namespace App\Presentation\Account;

use App\Model\Services\HouseholdService;
use App\Model\Services\UserService;
use App\Presentation\Accessory\AuthenticatedPresenter;
use Nette\Application\UI\Form;

final class AccountPresenter extends AuthenticatedPresenter
{
    public function __construct(UserService $users, private HouseholdService $households)
    {
        parent::__construct($users);
    }

    protected function createComponentProfileForm(): Form
    {
        $form = new Form;
        $form->addText('name', 'Jméno')->setRequired()->addRule($form::MaxLength, null, 255);
        $form->addText('surname', 'Příjmení')->setRequired()->addRule($form::MaxLength, null, 255);
        $form->addEmail('email', 'E-mail')->setRequired()->addRule($form::MaxLength, null, 255);
        $form->addPassword('newPassword', 'Nové heslo')->addCondition($form::Filled)->addRule($form::MinLength, 'Nové heslo musí mít alespoň 8 znaků.', 8);
        $form->addPassword('currentPassword', 'Současné heslo');
        $form->addSubmit('send', 'Uložit změny');
        $form->setDefaults([
            'name' => $this->currentUser->getName(),
            'surname' => $this->currentUser->getSurname(),
            'email' => $this->currentUser->getEmail(),
        ]);
        $form->onSuccess[] = function (Form $form, $data): void {
            $emailChanged = trim($data->email) !== $this->currentUser->getEmail();
            $passwordChanged = $data->newPassword !== '';
            if (($emailChanged || $passwordChanged) && !$this->currentUser->verifyPassword($data->currentPassword)) {
                $form->addError('Pro změnu e-mailu nebo hesla zadejte současné heslo.');
                return;
            }
            try {
                $this->users->updateProfile(
                    $this->currentUser,
                    $data->name,
                    $data->surname,
                    $data->email,
                    $passwordChanged ? $data->newPassword : null,
                );
            } catch (\DomainException|\InvalidArgumentException $exception) {
                $form->addError($exception instanceof \DomainException ? 'Tento e-mail už používá jiný účet.' : 'Zkontrolujte vyplněné údaje.');
                return;
            }
            $this->flashMessage('Profil byl uložen.');
            $this->redirect('this');
        };
        return $form;
    }

    protected function createComponentLeaveHouseholdForm(): Form
    {
        $form = new Form;
        $form->addSubmit('send', 'Opustit domácnost');
        $form->onSuccess[] = function (): void {
            try {
                $this->households->leaveHousehold($this->currentUser);
                $this->flashMessage('Opustili jste domácnost.');
            } catch (\DomainException) {
                $this->flashMessage('Domácnost nelze opustit. Správce musí nejprve předat správu.', 'error');
            }
            $this->redirect('this');
        };
        return $form;
    }
}
