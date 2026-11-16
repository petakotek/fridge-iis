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
        $user = (new UserService($this->em))->createUser('Eva', 'Nova', 'eva@example.test', 'secret123');
        $id = $user->getId();
        Assert::notNull($id);
        $this->em->clear();

        $stored = (new UserService($this->em))->getUserById($id);
        Assert::same('Eva', $stored->getName());
        Assert::same('Nova', $stored->getSurname());
        Assert::same('eva@example.test', $stored->getEmail());
        Assert::true($stored->verifyPassword('secret123'));
        Assert::false($stored->verifyPassword('wrong'));
        Assert::false($stored->isAdmin());
        Assert::null($stored->getHousehold());
        $hash = $this->em->getConnection()->fetchOne('SELECT password FROM UserEntity WHERE id = ?', [$id]);
        Assert::notSame('secret123', $hash);
        Assert::true(password_verify('secret123', $hash));
    }

    public function testCreateUserRejectsEmptyRequiredFieldsWithoutSaving(): void
    {
        $service = new UserService($this->em);
        foreach ([['Jan', 'Novak', ''], ['', 'Novak', 'secret123'], ['Jan', '', 'secret123']] as [$name, $surname, $password]) {
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

    public function testUpdateProfilePersistsDetailsAndOptionalPassword(): void
    {
        $user = $this->user();
        $id = $user->getId();
        (new UserService($this->em))->updateProfile($user, 'Eva', 'Nová', 'new@example.test', 'new-password');
        $this->em->clear();

        $stored = (new UserService($this->em))->getUserById($id);
        Assert::same('Eva', $stored->getName());
        Assert::same('Nová', $stored->getSurname());
        Assert::same('new@example.test', $stored->getEmail());
        Assert::true($stored->verifyPassword('new-password'));
        Assert::false($stored->verifyPassword('fixture-password'));
    }

    public function testCreateUserEnforcesPasswordLengthInService(): void
    {
        $service = new UserService($this->em);
        Assert::exception(fn() => $service->createUser('Eva', 'Nova', 'eva@example.test', '1234567'), \InvalidArgumentException::class);
        Assert::same(0, $this->em->getRepository(UserEntity::class)->count([]));

        $user = $service->createUser('Eva', 'Nova', 'eva@example.test', '12345678');
        Assert::true($user->verifyPassword('12345678'));
    }

    public function testRejectedPasswordChangeDoesNotModifyProfileEvenOnLaterFlush(): void
    {
        $user = $this->user();
        $id = $user->getId();
        $email = $user->getEmail();
        $service = new UserService($this->em);
        Assert::exception(fn() => $service->updateProfile($user, 'Eva', 'Nova', 'new@example.test', 'short'), \InvalidArgumentException::class);
        $this->em->flush();
        $this->em->clear();

        $stored = $service->getUserById($id);
        Assert::same('Jan', $stored->getName());
        Assert::same($email, $stored->getEmail());
        Assert::true($stored->verifyPassword('fixture-password'));
    }

    public function testEmailUniquenessIsSharedByCreationAndProfileEditing(): void
    {
        $existing = $this->user();
        $user = $this->user();
        $service = new UserService($this->em);
        $duplicate = '  ' . $existing->getEmail() . '  ';

        Assert::exception(fn() => $service->createUser('Eva', 'Nova', $duplicate, 'password123'), \DomainException::class);
        Assert::exception(fn() => $service->updateProfile($user, 'Eva', 'Nova', $duplicate), \DomainException::class);
        Assert::same(2, $this->em->getRepository(UserEntity::class)->count([]));
        Assert::same('Jan', $user->getName());

        $service->updateProfile($user, 'Eva', 'Nova', '  ' . $user->getEmail() . '  ');
        Assert::same('Eva', $user->getName());
        Assert::true($user->verifyPassword('fixture-password'));
    }

    public function testEmailFormatIsValidatedByServiceForCreationAndEditing(): void
    {
        $user = $this->user();
        $email = $user->getEmail();
        $service = new UserService($this->em);

        Assert::exception(fn() => $service->createUser('Eva', 'Nova', 'invalid-email', 'password123'), \InvalidArgumentException::class, 'Invalid e-mail address');
        Assert::exception(fn() => $service->updateProfile($user, 'Eva', 'Nova', 'invalid-email'), \InvalidArgumentException::class, 'Invalid e-mail address');
        Assert::same('Jan', $user->getName());
        Assert::same($email, $user->getEmail());
        Assert::same(1, $this->em->getRepository(UserEntity::class)->count([]));
    }
}

(new UserServiceTest())->run();
