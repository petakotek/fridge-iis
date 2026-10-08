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

    #[ORM\Column(type: 'string', length: 255)]
    private string $password;

    #[ORM\Column(type: 'boolean', options: ['default' => false])]
    private bool $isAdmin;

    #[ORM\ManyToOne(targetEntity: HouseholdEntity::class , inversedBy: 'users')]
    #[ORM\JoinColumn(nullable: true)]
    private ?HouseholdEntity $household = null;

    #[ORM\OneToMany(targetEntity: FoodEntity::class, mappedBy: 'consumer')]
    private Collection $foodsConsumed;
    #[ORM\Column(type: 'integer')]
    private int $householdRequest;

    public function __construct(){
        $this->foodsConsumed = new ArrayCollection();
    }

    public function setHousehold(HouseholdEntity $household): void {
        if ($this->household !== null && $this->household !== $household
            && $this->household->getModerator() === $this) {
            throw new \DomainException('Transfer household management before moving its moderator.');
        }
        $this->household = $household;
    }

    public function getHousehold(): ?HouseholdEntity {
        return $this->household;
    }
}
