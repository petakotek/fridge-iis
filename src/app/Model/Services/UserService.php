<?php

namespace App\Model\Services;

use App\Model\Entity\UserEntity;
use Nette\Utils\Validators;

final class UserService extends BaseService
{
    public function createUser(
        string $name,
        string $surname,
        string $email,
        string $password,
    ): UserEntity {
        $this->validatePassword($password);
        $email = trim($email);
        $this->validateProfile($name, $surname, $email);
        $this->assertAvailableEmail($email);
        $user = new UserEntity($name, $surname, $email);
        $user->setProfile($name, $surname, $email);
        $user->setPassword($password);

        $this->entityManager->persist($user);
        $this->entityManager->flush();

        return $user;
    }

    public function getUserById(int $id): UserEntity
    {
        $user = $this->entityManager
            ->getRepository(UserEntity::class)
            ->find($id);
        if (!$user) {
            throw new \InvalidArgumentException("User not found");
        }
        return $user;
    }

    public function verifyUser(string $email, string $password): ?UserEntity
    {
        $user = $this->entityManager
            ->getRepository(UserEntity::class)
            ->findOneBy(["email" => $email]);
        if ($user == null || !$user->verifyPassword($password)) {
            return null;
        }
        return $user;
    }

    public function updateProfile(UserEntity $user, string $name, string $surname, string $email, ?string $newPassword = null): void {
        if ($newPassword !== null) {
            $this->validatePassword($newPassword);
        }
        $email = trim($email);
        $this->validateProfile($name, $surname, $email);
        $this->assertAvailableEmail($email, $user);
        $user->setProfile($name, $surname, $email);
        if ($newPassword !== null) {
            $user->setPassword($newPassword);
        }
        $this->entityManager->flush();
    }

    private function validatePassword(string $password): void
    {
        if ($password === '') {
            throw new \InvalidArgumentException("Password can't be empty");
        }
        if (mb_strlen($password) < 8) {
            throw new \InvalidArgumentException('Heslo musí mít alespoň 8 znaků.');
        }
    }

    private function validateProfile(string $name, string $surname, string $email): void
    {
        if ($name === '' || $surname === '') {
            throw new \InvalidArgumentException("Name and surname can't be empty");
        }
        if (!Validators::isEmail($email)) {
            throw new \InvalidArgumentException('Invalid e-mail address');
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL) || mb_strlen($email) > 255) {
            throw new \InvalidArgumentException('Invalid email address.');
        }
    }

    private function assertAvailableEmail(string $email, ?UserEntity $user = null): void
    {
        $existing = $this->entityManager->getRepository(UserEntity::class)->findOneBy(['email' => $email]);
        if ($existing !== null && $existing !== $user) {
            throw new \DomainException('Tento e-mail už používá jiný účet.');
        }
    }
}
