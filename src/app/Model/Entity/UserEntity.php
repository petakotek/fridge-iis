<?php

namespace App\Model\Entity;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
class UserEntity extends BaseEntity
{
    #[ORM\Column(type: 'string', length: 255)]
    private string $name;

    #[ORM\Column(type: 'string', length: 255)]
    private string $surname;

    #[ORM\Column(type: 'string', length: 255, unique: true)]
    private string $email;
    #[ORM\Column(type: 'string', length: 255)]
    private string $password;

    #[ORM\Column(type: 'boolean', options: ['default' => false])]
    private bool $isAdmin = false;

    #[ORM\ManyToOne(targetEntity: HouseholdEntity::class , inversedBy: 'users')]
    #[ORM\JoinColumn(nullable: true, onDelete: 'SET NULL')]
    private ?HouseholdEntity $household = null;

    #[ORM\OneToMany(targetEntity: FoodEntity::class, mappedBy: 'consumer')]
    #[ORM\JoinColumn(nullable: true, onDelete: 'CASCADE')]
    private ?Collection $foodsConsumed;

    #[ORM\ManyToOne(targetEntity: HouseholdEntity::class)]
    #[ORM\JoinColumn(name: 'householdRequest', nullable: true, onDelete: 'SET NULL')]
    private ?HouseholdEntity $householdRequest = null;

    public function __construct(string $name, string $surname, string $email) {
        $this->name = $name;
        $this->surname = $surname;
        $this->email = $email;
        $this->foodsConsumed = new ArrayCollection();
    }

    public function verifyPassword(string $password): bool {
        return password_verify($password, $this->password);
    }

    public function isAdmin(): bool {
        return $this->isAdmin;
    }

    public function removeHousehold(HouseholdEntity $household): void {
        if ($this->household !== $household) {
            throw new \DomainException('User is not in this household.');
        }
        $this->household = null;
    }

    public function unsetHouseholdRequest(): void {
        $this->householdRequest = null;
    }

//    Setters

    public function setAdminLevel(bool $boolean = true): void {
        $this->isAdmin = $boolean;
    }

    public function setHousehold(HouseholdEntity $household): void {
        if ($this->household !== null && $this->household !== $household
            && $this->household->getModerator() === $this) {
            throw new \DomainException('Transfer household management before moving its moderator.');
        }
        $this->household = $household;
    }

    public function setPassword(string $password): void {
        $hashed = password_hash($password, PASSWORD_DEFAULT);
        $this->password = $hashed;
    }

    public function setRequest(HouseholdEntity $household): void {
        if ($this->household === null) {
            $this->householdRequest = $household;
        }
    }
//    Getters

    public function getName(): string {
        return $this->name;
    }

    public function getSurname(): string {
        return $this->surname;
    }

    public function getEmail(): string {
        return $this->email;
    }

    public function getFoodsConsumed(): Collection {
        return $this->foodsConsumed;
    }

    public function getHousehold(): ?HouseholdEntity {
        return $this->household;
    }

    public function getHouseholdRequest(): ?HouseholdEntity {
        return $this->householdRequest;
    }
}
