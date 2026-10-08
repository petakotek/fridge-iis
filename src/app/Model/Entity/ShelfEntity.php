<?php

namespace App\Model\Entity;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
class ShelfEntity extends BaseEntity
{
    #[ORM\Column (type: 'integer')]
    private int $shelfCapacity;

    #[ORM\OneToMany (targetEntity: FoodEntity::class, mappedBy: "shelf")]
    private Collection $foods;

    #[ORM\ManyToOne (targetEntity: ApplianceEntity::class, inversedBy: 'shelves')]
    #[ORM\JoinColumn(nullable: false, onDelete: 'RESTRICT')]
    private ApplianceEntity $appliance;

    public function __construct(int $capacity) {
        $this->foods = new ArrayCollection();
        $this->shelfCapacity = $capacity;
    }

    public function setAppliance(ApplianceEntity $appliance): void {
        $this->appliance = $appliance;
    }

    public function getAppliance(): ApplianceEntity {
        return $this->appliance;
    }

    public function addFood(FoodEntity $food): void {
        if ($this->shelfCapacity - $food->getWeight() < 0){
            throw new \DomainException('Food weight is too big for this shelf.');
        }
        $food->setShelf($this);
        if (!$this->foods->contains($food)) {
            $this->foods->add($food);
        }
    }
}
