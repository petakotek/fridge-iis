<?php

namespace App\Model\Security;

use App\Model\Services\UserService;
use Nette\Security\AuthenticationException;
use Nette\Security\Authenticator;
use Nette\Security\IIdentity;
use Nette\Security\SimpleIdentity;

final class UserAuthenticator implements Authenticator
{
    public function __construct(private UserService $userService) {
    }

    public function authenticate(string $email, string $password): IIdentity {
        $user = $this->userService->verifyUser($email, $password);
        if ($user === null) {
            throw new AuthenticationException('Nesprávný e-mail nebo heslo.');
        }
        return new SimpleIdentity(
            $user->getId(),
            $user->isAdmin() ? ['admin'] : ['user'],
            ['name' => $user->getName(), 'surname' => $user->getSurname(), 'email' => $user->getEmail()],
        );
    }
}
