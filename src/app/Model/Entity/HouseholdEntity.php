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
    #[ORM\OneToMany(targetEntity: UserEntity::class, mappedBy: "household", cascade: ["persist"])]
    private Collection $users;

    #[ORM\OneToMany(targetEntity: ApplianceEntity::class, mappedBy: "household", cascade: ["remove"], orphanRemoval: true)]
    private Collection $appliances;

    #[ORM\OneToMany(targetEntity: CategoryEntity::class, mappedBy: "household")]
    private Collection $categories;

    #[ORM\OneToOne(targetEntity: UserEntity::class)]
    #[ORM\JoinColumn(nullable: false, onDelete: 'RESTRICT')]
    private ?UserEntity $moderator = null;

    public function __construct(){
        $this->users = new ArrayCollection();
        $this->appliances = new ArrayCollection();
        $this->categories = new ArrayCollection();
    }

    private function addAppliance(ApplianceEntity $appliance): void {
        $this->appliances->add($appliance);
        $appliance->setHousehold($this);
    }
    private function removeAppliance(ApplianceEntity $appliance): void {
        $this->appliances->removeElement($appliance);
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

    public function setModerator(UserEntity $moderator): void {
        $this->addUser($moderator);
        $this->moderator = $moderator;
    }

    public function getModerator(): ?UserEntity {
        return $this->moderator;
    }

    public function addCategory(CategoryEntity $category): void {
        $category->setHousehold($this);
        if (!$this->categories->contains($category)) {
            $this->categories->add($category);
        }
    }

    /** @return Collection<int, CategoryEntity> */
    public function getCategories(): Collection {
        return $this->categories;
    }
}
