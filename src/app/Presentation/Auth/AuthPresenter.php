<?php declare(strict_types=1);

namespace App\Presentation\Auth;

use App\Model\Services\UserService;
use Nette\Application\UI\Form;
use Nette\Application\UI\Presenter;
use Nette\Security\SimpleIdentity;

final class AuthPresenter extends Presenter
{
    public function __construct(private UserService $users)
    {
        parent::__construct();
    }

    protected function startup(): void
    {
        parent::startup();
        $this->getSession()->start();
        if ($this->getUser()->isLoggedIn()) {
            $this->redirect('Home:default');
        }
    }

    protected function createComponentLoginForm(): Form
    {
        $form = new Form;
        $form->addEmail('email', 'E-mail')->setRequired();
        $form->addPassword('password', 'Heslo')->setRequired();
        $form->addSubmit('send', 'Přihlásit se');
        $form->onSuccess[] = function (Form $form, $data): void {
            $user = $this->users->verifyUser($data->email, $data->password);
            if ($user === null) {
                $form->addError('Nesprávný e-mail nebo heslo.');
                return;
            }
            $this->getUser()->login(new SimpleIdentity($user->getId(), [$user->isAdmin() ? 'admin' : 'user']));
            $this->redirect('Home:default');
        };
        return $form;
    }

    protected function createComponentRegisterForm(): Form
    {
        $form = new Form;
        $form->addText('name', 'Jméno')->setRequired()->addRule($form::MaxLength, null, 255);
        $form->addText('surname', 'Příjmení')->setRequired()->addRule($form::MaxLength, null, 255);
        $form->addEmail('email', 'E-mail')->setRequired()->addRule($form::MaxLength, null, 255);
        $form->addPassword('password', 'Heslo')->setRequired()->addRule($form::MinLength, 'Heslo musí mít alespoň 8 znaků.', 8);
        $form->addSubmit('send', 'Vytvořit účet');
        $form->onSuccess[] = function (Form $form, $data): void {
            try {
                $user = $this->users->createUser($data->name, $data->surname, $data->email, $data->password);
            } catch (\DomainException|\InvalidArgumentException $exception) {
                $form->addError($exception instanceof \DomainException ? 'Tento e-mail už je zaregistrovaný.' : 'Zkontrolujte vyplněné údaje.');
                return;
            }
            $this->getUser()->login(new SimpleIdentity($user->getId(), ['user']));
            $this->redirect('Home:default');
        };
        return $form;
    }
}
