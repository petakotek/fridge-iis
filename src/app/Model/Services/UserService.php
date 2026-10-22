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

        $email = trim($email);
        if (!filter_var($email, FILTER_VALIDATE_EMAIL) || mb_strlen($email) > 255) {
            throw new \InvalidArgumentException('Invalid email address.');
        }
        if ($this->entityManager->getRepository(UserEntity::class)->findOneBy(['email' => $email]) !== null) {
            throw new \DomainException('Email is already in use.');
        }
        $user = new UserEntity($name, $surname, $email);
        $user->setProfile($name, $surname, $email);
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

    public function updateProfile(UserEntity $user, string $name, string $surname, string $email, ?string $newPassword = null): void {
        $email = trim($email);
        $existing = $this->entityManager->getRepository(UserEntity::class)->findOneBy(['email' => $email]);
        if ($existing !== null && $existing !== $user) {
            throw new \DomainException('Email is already in use.');
        }
        $user->setProfile($name, $surname, $email);
        if ($newPassword !== null) {
            if (mb_strlen($newPassword) < 8) {
                throw new \InvalidArgumentException('Password must contain at least 8 characters.');
            }
            $user->setPassword($newPassword);
        }
        $this->entityManager->flush();
    }

}
