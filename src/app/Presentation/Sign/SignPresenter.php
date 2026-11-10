<?php declare(strict_types=1);

namespace App\Presentation\Sign;

use App\Model\Entity\HouseholdEntity;
use App\Model\Services\HouseholdService;
use App\Model\Services\UserService;
use Nette;
use Nette\Application\Attributes\Persistent;
use Nette\Application\UI\Form;

final class SignPresenter extends Nette\Application\UI\Presenter
{
    #[Persistent]
    public string $backlink = "";

    #[Persistent]
    public string $join = "";

    public function __construct(
        private UserService $userService,
        private HouseholdService $householdService,
    ) {
        parent::__construct();
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

    public function renderUp(): void
    {
        $this->template->joinHousehold = $this->getJoinHousehold();
    }

    private function getJoinHousehold(): ?HouseholdEntity
    {
        if ($this->join === "") {
            return null;
        }
        try {
            $household = $this->householdService->getHouseholdByToken(
                $this->join,
            );
        } catch (\InvalidArgumentException) {
            return null;
        }
        return $household->getToken() === $this->join ? $household : null;
    }

    protected function createComponentGuestForm(): Form
    {
        $form = new Form();
        $form
            ->addText("token", "Token domácnosti")
            ->setRequired("Zadejte token.");
        $form->addSubmit("send", "Vstoupit jako host");

        $form->onSuccess[] = function (Form $form, \stdClass $data): void {
            $token = trim($data->token);
            try {
                $household = $this->householdService->getHouseholdByToken(
                    $token,
                );
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
                $user = $this->userService->createUser(
                    $data->name,
                    $data->surname,
                    $data->email,
                    $data->password,
                );
            } catch (\InvalidArgumentException $e) {
                $form->addError($e->getMessage());
                return;
            }
            $this->getUser()->setExpiration("30 minutes");
            $this->getUser()->login($data->email, $data->password);

            $household = $this->getJoinHousehold();
            if ($household !== null) {
                $this->householdService->createHouseholdRequest(
                    $household,
                    $user,
                    $this->join,
                );
                $this->flashMessage(
                    "Účet byl vytvořen a správci domácnosti {$household->getName()} byla odeslána žádost o připojení.",
                );
            } elseif ($this->join !== "") {
                $this->flashMessage(
                    "Účet byl vytvořen, ale token domácnosti už není platný. Požádejte správce o nový.",
                    "error",
                );
            } else {
                $this->flashMessage("Účet byl vytvořen.");
            }
            $this->getSession("guest")->remove();
            $this->redirect("Home:");
        };
        return $form;
    }
}
