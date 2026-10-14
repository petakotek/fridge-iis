<?php

namespace App\Model\Services;

use App\Model\Entity\UserEntity;
final class UserService extends BaseService
{

    public function createUser(string $name, string $surname, string $email, string $password): UserEntity {
        if  ($password == "") {
            throw new \InvalidArgumentException("Password can't be empty");
        }
        if ($name == "" || $surname == "") {
            throw new \InvalidArgumentException("Name and surname can't be empty");
        }

        $user = new UserEntity($name, $surname, $email);
        $user->setPassword($password);

        $this->entityManager->persist($user);
        $this->entityManager->flush();

        return $user;
    }

    public function getUserById(int $id): UserEntity {
        $user = $this->entityManager->getRepository(UserEntity::class)->find($id);
        if (!$user) {
            throw new \InvalidArgumentException("User not found");
        }
        return $user;
    }

    public function verifyUser(string $email, string $password): ?UserEntity {
        $user = $this->entityManager
                        ->getRepository(UserEntity::class)
                        ->findOneBy(['email' => $email]);
        if ($user == null || !$user->verifyPassword($password)) {
            return null;
        }
        return $user;
    }

// Example of User Login
//$this->getUser()->login(
//new \Nette\Security\SimpleIdentity(
//$user->getId(),
//$user->isAdmin() ? ['admin'] : ['user'],
//),
//);
//
//$this->redirect('Home:default');
}