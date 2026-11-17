<?php declare(strict_types=1);

namespace App\Presentation\Admin;

use App\Model\Entity\HouseholdEntity;
use App\Model\Entity\UserEntity;
use App\Model\Services\AdminService;
use App\Model\Services\HouseholdService;
use App\Model\Services\UserService;
use App\Presentation\Accessory\AuthenticatedPresenter;
use Doctrine\DBAL\Exception\UniqueConstraintViolationException;
use Nette\Application\UI\Form;

final class AdminPresenter extends AuthenticatedPresenter
{
    private ?UserEntity $editedUser = null;
    private ?HouseholdEntity $editedHousehold = null;

    public function __construct(UserService $users, private AdminService $admin, private HouseholdService $households)
    {
        parent::__construct($users);
    }

    protected function startup(): void
    {
        parent::startup();
        // Read the current database flag, including role changes made after login.
        if (!$this->currentUser->isAdmin()) {
            $this->error('Přístup má pouze administrátor systému.', 403);
        }
    }

    public function renderDefault(): void
    {
        $this->template->accounts = $this->admin->getUsers($this->currentUser);
    }

    public function actionEditUser(int $id): void
    {
        $this->editedUser = $this->findUser($id);
        $this->template->editedUser = $this->editedUser;
    }

    public function actionDeleteUser(int $id): void
    {
        $this->editedUser = $this->findUser($id);
        $this->template->editedUser = $this->editedUser;
        if ($this->editedUser === $this->currentUser) {
            $this->flashMessage('Vlastní administrátorský účet nemůžete smazat.', 'error');
            $this->redirect('default');
        }
    }

    public function renderHouseholds(): void
    {
        $this->template->households = $this->admin->getHouseholds($this->currentUser);
    }

    public function actionEditHousehold(int $id): void
    {
        $this->editedHousehold = $this->findHousehold($id);
        $this->template->household = $this->editedHousehold;
    }

    public function renderEditHousehold(): void
    {
        $this->template->members = $this->households->getHouseholdMembers($this->requireHousehold());
    }

    public function actionDeleteHousehold(int $id): void
    {
        $this->editedHousehold = $this->findHousehold($id);
        $this->template->household = $this->editedHousehold;
    }

    protected function createComponentUserForm(): Form
    {
        $form = $this->adminForm();
        $form->addText('name', 'Jméno *')->setRequired('Zadejte jméno.')->addRule($form::MaxLength, null, 255);
        $form->addText('surname', 'Příjmení *')->setRequired('Zadejte příjmení.')->addRule($form::MaxLength, null, 255);
        $form->addEmail('email', 'E-mail *')->setRequired('Zadejte e-mail.')->addRule($form::MaxLength, null, 255);
        $password = $form->addPassword('password', $this->editedUser === null ? 'Heslo *' : 'Nové heslo');
        if ($this->editedUser === null) {
            $password->setRequired('Zadejte heslo.');
        }
        $password->addCondition($form::Filled)->addRule($form::MinLength, 'Heslo musí mít alespoň 8 znaků.', 8);
        $role = $form->addSelect('role', 'Role *', ['user' => 'Registrovaný uživatel', 'admin' => 'Administrátor systému'])->setDefaultValue('user')->setRequired('Vyberte roli.');
        if ($this->editedUser === $this->currentUser) {
            $role->setItems(['admin' => 'Administrátor systému'])->setDisabled()->setOmitted(false);
        }
        $form->addSubmit('send', $this->editedUser === null ? 'Vytvořit uživatele' : 'Uložit uživatele');
        if ($this->editedUser !== null) {
            $form->setDefaults([
                'name' => $this->editedUser->getName(),
                'surname' => $this->editedUser->getSurname(),
                'email' => $this->editedUser->getEmail(),
                'role' => $this->editedUser->isAdmin() ? 'admin' : 'user',
            ]);
        }
        $this->onSave($form, function (\stdClass $data): void {
            if ($this->editedUser === null) {
                $this->admin->createUser($this->currentUser, $data->name, $data->surname, $data->email, $data->password, $data->role === 'admin');
            } else {
                $this->admin->updateUser($this->currentUser, $this->editedUser, $data->name, $data->surname, $data->email, $data->password !== '' ? $data->password : null, $data->role === 'admin');
            }
        }, 'Uživatel byl uložen.', 'default');
        return $form;
    }

    protected function createComponentDeleteUserForm(): Form
    {
        $form = $this->adminForm();
        $form->addText('confirmation', 'Pro potvrzení napište e-mail uživatele *')->setRequired('Zadejte e-mail pro potvrzení.');
        $form->addSubmit('send', 'Smazat uživatele');
        $this->onSave($form, function (\stdClass $data): void {
            if ($this->editedUser === null) {
                $this->error('Uživatel nenalezen.', 404);
            }
            if (trim($data->confirmation) !== $this->editedUser->getEmail()) {
                throw new \DomainException('Zadaný e-mail nesouhlasí.');
            }
            $this->admin->deleteUser($this->currentUser, $this->editedUser);
        }, 'Uživatel byl smazán.', 'default');
        return $form;
    }

    protected function createComponentHouseholdForm(): Form
    {
        $form = $this->adminForm();
        $form->addText('name', 'Název domácnosti *')->setRequired('Zadejte název domácnosti.')->addRule($form::MaxLength, null, 255);
        if ($this->editedHousehold === null) {
            $form->addSelect('moderatorId', 'Správce domácnosti', $this->availableUsers())->setPrompt('Zatím bez správce');
        } else {
            $form->setDefaults(['name' => $this->editedHousehold->getName()]);
        }
        $form->addSubmit('send', $this->editedHousehold === null ? 'Vytvořit domácnost' : 'Uložit domácnost');
        $this->onSave($form, function (\stdClass $data): void {
            if ($this->editedHousehold === null) {
                $household = $this->admin->createHousehold($this->currentUser, $data->name, $data->moderatorId !== null ? $this->findUser((int) $data->moderatorId) : null);
                $this->flashMessage('Domácnost byla vytvořena. Nyní můžete přidat členy.');
                $this->redirect('editHousehold', ['id' => $household->getId()]);
            }
            $this->admin->updateHousehold($this->currentUser, $this->editedHousehold, $data->name);
        }, 'Domácnost byla uložena.');
        return $form;
    }

    protected function createComponentAddMemberForm(): Form
    {
        $form = $this->adminForm();
        $form->addSelect('memberId', 'Uživatel *', $this->availableUsers())->setPrompt('Vyberte uživatele bez domácnosti')->setRequired('Vyberte uživatele.');
        $form->addSubmit('send', 'Přidat člena');
        $this->onSave($form, function (\stdClass $data): void {
            $this->admin->addMember($this->currentUser, $this->requireHousehold(), $this->findUser((int) $data->memberId));
        }, 'Člen byl přidán. Případná žádost o členství byla zrušena.');
        return $form;
    }

    protected function createComponentMemberForm(): Form
    {
        $options = [];
        foreach ($this->households->getHouseholdMembers($this->requireHousehold()) as $member) {
            $options[$member->getId()] = $this->userLabel($member);
        }
        $form = $this->adminForm();
        $form->addSelect('memberId', 'Člen domácnosti *', $options)->setPrompt('Vyberte člena')->setRequired('Vyberte člena domácnosti.');
        $form->addSubmit('moderator', 'Nastavit jako správce');
        $form->addSubmit('remove', 'Odebrat z domácnosti');
        $this->onSave($form, function (\stdClass $data) use ($form): void {
            $member = $this->findUser((int) $data->memberId);
            if ($form['moderator']->isSubmittedBy()) {
                $this->admin->setModerator($this->currentUser, $this->requireHousehold(), $member);
            } elseif ($form['remove']->isSubmittedBy()) {
                $this->admin->removeMember($this->currentUser, $this->requireHousehold(), $member);
            } else {
                throw new \DomainException('Vyberte akci pro člena domácnosti.');
            }
        }, 'Členství bylo upraveno.');
        return $form;
    }

    protected function createComponentDeleteHouseholdForm(): Form
    {
        $form = $this->adminForm();
        $form->addText('confirmation', 'Pro potvrzení napište název domácnosti *')->setRequired('Zadejte název domácnosti pro potvrzení.');
        $form->addSubmit('send', 'Smazat domácnost');
        $this->onSave($form, function (\stdClass $data): void {
            $household = $this->requireHousehold();
            if (trim($data->confirmation) !== $household->getName()) {
                throw new \DomainException('Zadaný název domácnosti nesouhlasí.');
            }
            $this->admin->deleteHousehold($this->currentUser, $household);
        }, 'Domácnost byla smazána.', 'households');
        return $form;
    }

    private function adminForm(): Form
    {
        $form = new Form;
        $form->addProtection('Platnost formuláře vypršela. Obnovte stránku a zkuste to znovu.')
            ->setRequired('Platnost formuláře vypršela. Obnovte stránku a zkuste to znovu.');
        return $form;
    }

    private function onSave(Form $form, callable $save, string $message, string $destination = 'this'): void
    {
        $form->onSuccess[] = function (Form $form, \stdClass $data) use ($save, $message, $destination): void {
            try {
                $save($data);
            } catch (UniqueConstraintViolationException) {
                $form->addError('Tento e-mail už používá jiný účet.');
                return;
            } catch (\DomainException|\InvalidArgumentException $exception) {
                $form->addError($exception instanceof \DomainException ? $exception->getMessage() : 'Zkontrolujte údaje. E-mail musí být jedinečný a heslo musí mít alespoň 8 znaků.');
                return;
            }
            $this->flashMessage($message);
            $this->redirect($destination);
        };
    }

    /** @return array<int, string> */
    private function availableUsers(): array
    {
        $options = [];
        foreach ($this->admin->getUsers($this->currentUser) as $user) {
            if (!$user->isAdmin() && $user->getHousehold() === null) {
                $options[$user->getId()] = $this->userLabel($user);
            }
        }
        return $options;
    }

    private function userLabel(UserEntity $user): string
    {
        return $user->getName() . ' ' . $user->getSurname() . ' (' . $user->getEmail() . ')';
    }

    private function findUser(int $id): UserEntity
    {
        try {
            return $this->users->getUserById($id);
        } catch (\InvalidArgumentException) {
            $this->error('Uživatel nenalezen.', 404);
        }
    }

    private function findHousehold(int $id): HouseholdEntity
    {
        try {
            return $this->households->getHouseholdById($id);
        } catch (\InvalidArgumentException) {
            $this->error('Domácnost nenalezena.', 404);
        }
    }

    private function requireHousehold(): HouseholdEntity
    {
        return $this->editedHousehold ?? $this->error('Domácnost nenalezena.', 404);
    }
}
