<?php declare(strict_types=1);

namespace App\Presentation\Sign;

use App\Model\Services\HouseholdService;
use App\Model\Services\UserService;
use Nette;
use Nette\Application\Attributes\Persistent;
use Nette\Application\UI\Form;

final class SignPresenter extends Nette\Application\UI\Presenter
{
    #[Persistent]
    public string $backlink = "";
    public function __construct(
        private UserService $userService,
        private HouseholdService $householdService,
    ) {
        parent::__construct();
        // addEmail() has a built-in format rule with an English default message
        Nette\Forms\Validator::$messages[Form::Email] =
            "Zadejte platnou e-mailovou adresu.";
    }

    public function actionIn(): void
    {
        if ($this->getUser()->isLoggedIn()) {
            $this->redirect("Home:");
        }
    }

    public function actionUp(): void
    {
        if ($this->getUser()->isLoggedIn()) {
            $this->redirect("Home:");
        }
    }

    protected function createComponentGuestForm(): Form
    {
        $form = new Form();
        $form->addText("token", "Token domácnosti")->setRequired("Zadejte token.");
        $form->addSubmit("send", "Vstoupit jako host");

        $form->onSuccess[] = function (Form $form, \stdClass $data): void {
            $token = trim($data->token);
            try {
                $household = $this->householdService->getHouseholdByToken($token);
            } catch (\InvalidArgumentException) {
                $form->addError("Domácnost s tímto tokenem nebyla nalezena.");
                return;
            }
            $session = $this->getSession("guest");
            $session->setExpiration("2 hours");
            $session->set("householdId", $household->getId());
            $session->set("token", $token);
            $this->redirect("Guest:default");
        };
        return $form;
    }

    protected function createComponentSignInForm(): Form
    {
        $form = new Form();
        $form->addEmail("email", "E-mail")->setRequired("Zadejte e-mail.");
        $form->addPassword("password", "Heslo")->setRequired("Zadejte heslo.");
        $form->addCheckbox("remember", "Zapamatovat si mě");
        $form->addSubmit("send", "Přihlásit se");

        $form->onSuccess[] = function (Form $form, \stdClass $data): void {
            try {
                $this->getUser()->setExpiration(
                    $data->remember ? "14 days" : "30 minutes",
                );
                $this->getUser()->login($data->email, $data->password);
            } catch (Nette\Security\AuthenticationException $e) {
                $form->addError($e->getMessage());
                return;
            }
            $this->restoreRequest($this->backlink);
            $this->redirect("Home:");
        };
        return $form;
    }
    protected function createComponentSignUpForm(): Form
    {
        $form = new Form();
        $form->addText("name", "Jméno")->setRequired("Zadejte jméno.");
        $form->addText("surname", "Příjmení")->setRequired("Zadejte příjmení.");
        $form->addEmail("email", "E-mail")->setRequired("Zadejte e-mail.");
        $form
            ->addPassword("password", "Heslo")
            ->setRequired("Zadejte heslo.")
            ->addRule($form::MinLength, "Heslo musí mít alespoň %d znaků.", 8);
        $form
            ->addPassword("passwordVerify", "Potvrzení hesla")
            ->setRequired("Zopakujte heslo.")
            ->addRule($form::Equal, "Hesla se neshodují.", $form["password"])
            ->setOmitted();
        $form->addSubmit("send", "Vytvořit účet");

        $form->onSuccess[] = function (Form $form, \stdClass $data): void {
            try {
                $this->userService->createUser(
                    $data->name,
                    $data->surname,
                    $data->email,
                    $data->password,
                );
            } catch (\InvalidArgumentException $e) {
                $form->addError($e->getMessage()); // e.g. "E-mail is already registered"
                return;
            }
            $this->getUser()->login($data->email, $data->password);
            $this->flashMessage("Účet byl vytvořen.");
            $this->redirect("Home:");
        };
        return $form;
    }
}
