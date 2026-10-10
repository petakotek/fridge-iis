<?php

namespace App\Model\Entity;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
class ApplianceEntity extends BaseEntity
{
    #[ORM\Column(type: 'string', length: 255, options: ['default' => 'My Appliance'])]
    private string $name;

    #[ORM\OneToMany(targetEntity: ShelfEntity::class, mappedBy: "appliance")]
    #[ORM\JoinColumn(nullable: true, onDelete: "CASCADE")]
    private Collection $shelves;

    #[ORM\ManyToOne (targetEntity: HouseholdEntity::class, inversedBy: 'appliances')]
    #[ORM\JoinColumn(nullable: true, onDelete: 'SET NULL')]
    private ?HouseholdEntity $household = null;

    public function __construct(string $name) {
        $this->setName($name);
        $this->shelves = new ArrayCollection();
    }

    public function addShelf(ShelfEntity $shelf) : void {
        $this->shelves->add($shelf);
        $shelf->setAppliance($this);
    }

//    Setters
    public function setHousehold(HouseholdEntity $household) : void {
        $this->household = $household;
    }

    public function setName(string $name) : void {
        $name = trim($name);
        if (mb_strlen($name) > 255) {
            throw new \InvalidArgumentException("Appliance name is too long");
        }
        $this->name = $name;
    }

//    Getters
    public function getName(): string {
        return $this->name;
    }

    public function getHousehold(): ?HouseholdEntity {
        return $this->household;
    }
}
