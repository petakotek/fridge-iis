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
}