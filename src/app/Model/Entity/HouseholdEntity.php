<?php

namespace App\Model\Entity;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
class HouseholdEntity extends BaseEntity
{
    #[ORM\Column (type: 'string', length: 255)]
    private string $name;

    #[ORM\Column (type: 'string', length: 255)]
    private ?string $token;
    #[ORM\OneToMany(targetEntity: UserEntity::class, mappedBy: "household")]
    #[ORM\JoinColumn (nullable: false, onDelete: 'SET NULL')]
    private Collection $users;

    #[ORM\OneToMany(targetEntity: ApplianceEntity::class, mappedBy: "household")]
    #[ORM\JoinColumn (nullable: true, onDelete: 'CASCADE')]
    private Collection $appliances;

    #[ORM\OneToMany(targetEntity: CategoryEntity::class, mappedBy: "household")]
    #[ORM\JoinColumn (nullable: true, onDelete: 'CASCADE')]
    private Collection $categories;

    #[ORM\OneToOne(targetEntity: UserEntity::class)]
    #[ORM\JoinColumn(nullable: true, onDelete: 'SET NULL')]
    private ?UserEntity $moderator = null;

    public function __construct(string $name) {
        $this->setName($name);
        $this->users = new ArrayCollection();
        $this->appliances = new ArrayCollection();
        $this->categories = new ArrayCollection();
    }

    public function addAppliance(ApplianceEntity $appliance): void {
        $appliance->setHousehold($this);
        $this->appliances->add($appliance);
    }

    public function removeAppliance(ApplianceEntity $appliance): void {
        $this->appliances->removeElement($appliance);
    }

    public function removeCategory(CategoryEntity $category): void {
        $this->categories->removeElement($category);
    }

    public function addUser(UserEntity $user): void {
        if ($user->getHousehold() !== null && $user->getHousehold() !== $this) {
            throw new \DomainException('User already belongs to another household.');
        }
        $user->setHousehold($this);
        if (!$this->users->contains($user)) {
            $this->users->add($user);
        }
    }

    public function addCategory(CategoryEntity $category): void {
        $category->setHousehold($this);
        if (!$this->categories->contains($category)) {
            $this->categories->add($category);
        }
    }

    public function generateToken(): void {
        $length = 10;
        $characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
        $charactersLength = strlen($characters);
        $randomString = '';

        for ($i = 0; $i < $length; $i++) {
            $randomString .= $characters[random_int(0, $charactersLength - 1)];
        }
        $this->token = $randomString;
    }

    public function isInHousehold(UserEntity $user): bool {
        return $this->users->contains($user);
    }

    public function removeUser(UserEntity $user): void {
        $this->users->removeElement($user);
    }

//    Setters
    public function setModerator(UserEntity $moderator): void {
        $this->addUser($moderator);
        $this->moderator = $moderator;
    }

    public function setName(string $name): void {
        $name = trim($name);
        if (empty($name)) {
            throw new \InvalidArgumentException('Name cannot be empty.');
        }
        if (mb_strlen($name) > 255){
            throw new \InvalidArgumentException('Household name must contain 1 to 255 characters.');
        }
        $this->name = $name;
    }

//    Getters
    public function getName(): string {
        return $this->name;
    }

    public function getCategories(): Collection {
        return $this->categories;
    }

    public function getModerator(): ?UserEntity {
        return $this->moderator;
    }

    public function getToken(): ?string {
        return $this->token;
    }
}
