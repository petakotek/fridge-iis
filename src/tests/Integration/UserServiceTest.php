<?php

/** @testCase */

declare(strict_types=1);

namespace Tests\Services;

use App\Model\Entity\UserEntity;
use App\Model\Services\UserService;
use Tester\Assert;
use Tests\Support\ServiceTestCase;

require __DIR__ . '/../bootstrap.php';

final class UserServiceTest extends ServiceTestCase
{
    public function testCreateUserPersistsProfileAndHashedPassword(): void
    {
        $user = (new UserService($this->em))->createUser('Eva', 'Nova', 'eva@example.test', 'secret');
        $id = $user->getId();
        Assert::notNull($id);
        $this->em->clear();

        $stored = (new UserService($this->em))->getUserById($id);
        Assert::same('Eva', $stored->getName());
        Assert::same('Nova', $stored->getSurname());
        Assert::same('eva@example.test', $stored->getEmail());
        Assert::true($stored->verifyPassword('secret'));
        Assert::false($stored->verifyPassword('wrong'));
        Assert::false($stored->isAdmin());
        Assert::null($stored->getHousehold());
        $hash = $this->em->getConnection()->fetchOne('SELECT password FROM UserEntity WHERE id = ?', [$id]);
        Assert::notSame('secret', $hash);
        Assert::true(password_verify('secret', $hash));
    }

    public function testCreateUserRejectsEmptyRequiredFieldsWithoutSaving(): void
    {
        $service = new UserService($this->em);
        foreach ([['Jan', 'Novak', ''], ['', 'Novak', 'secret'], ['Jan', '', 'secret']] as [$name, $surname, $password]) {
            Assert::exception(
                fn() => $service->createUser($name, $surname, 'invalid@example.test', $password),
                \InvalidArgumentException::class,
            );
        }
        Assert::same(0, $this->em->getRepository(UserEntity::class)->count([]));
    }

    public function testGetUserByIdReturnsExistingUser(): void
    {
        $user = $this->user();
        Assert::same($user, (new UserService($this->em))->getUserById($user->getId()));
    }

    public function testGetUserByIdRejectsMissingUser(): void
    {
        Assert::exception(fn() => (new UserService($this->em))->getUserById(999), \InvalidArgumentException::class, 'User not found');
    }

    public function testVerifyUserReturnsUserForCorrectCredentials(): void
    {
        $user = $this->user();
        Assert::same($user, (new UserService($this->em))->verifyUser($user->getEmail(), 'fixture-password'));
    }

    public function testVerifyUserRejectsWrongPasswordAndUnknownEmail(): void
    {
        $user = $this->user();
        $service = new UserService($this->em);
        Assert::null($service->verifyUser($user->getEmail(), 'wrong'));
        Assert::null($service->verifyUser('unknown@example.test', 'fixture-password'));
    }
}

(new UserServiceTest())->run();
