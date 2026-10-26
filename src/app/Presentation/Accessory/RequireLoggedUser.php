<?php declare(strict_types=1);

namespace App\Presentation\Accessory;

use Nette\Security\User;

trait RequireLoggedUser
{
    public function injectRequireLoggedUser(): void
    {
        $this->onStartup[] = function (): void {
            $user = $this->getUser();
            if ($user->isLoggedIn()) {
                return;
            }
            if ($user->getLogoutReason() === User::LogoutInactivity) {
                $this->flashMessage("Byli jste odhlášeni z důvodu nečinnosti.");
            }
            $this->redirect("Sign:in", ["backlink" => $this->storeRequest()]);
        };
    }
}
