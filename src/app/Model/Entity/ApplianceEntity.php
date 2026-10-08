<?php

namespace App\Model\Entity;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
class ApplianceEntity extends BaseEntity
{
    #[ORM\Column(type: 'string', length: 255)]
    private string $name;

    #[ORM\OneToMany(targetEntity: ShelfEntity::class, mappedBy: "appliance")]
    private Collection $shelves;

    #[ORM\ManyToOne (targetEntity: HouseholdEntity::class, inversedBy: 'appliances')]
    #[ORM\JoinColumn(nullable: false, onDelete: 'RESTRICT')]
    private HouseholdEntity $household;

    public function __construct(string $name) {
        $this->name = $name;
        $this->shelves = new ArrayCollection();
    }

    public function getName(): string {
        return $this->name;
    }

    public function setHousehold(HouseholdEntity $household) : void {
        $this->household = $household;
    }

    public function getHousehold(): HouseholdEntity {
        return $this->household;
    }

    public function addShelf(ShelfEntity $shelf) : void {
        $this->shelves->add($shelf);
        $shelf->setAppliance($this);
    }
}
