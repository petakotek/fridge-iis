<?php

namespace App\Model\Entity;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
class ShelfEntity extends BaseEntity
{
    #[ORM\Column(type: 'string', length: 255, nullable: true, options: ['default' => "My Shelf"])]
    private string $name;
    #[ORM\Column (type: 'integer')]
    private int $shelfCapacity;

    #[ORM\OneToMany (targetEntity: FoodEntity::class, mappedBy: "shelf")]
    private ?Collection $foods;

    #[ORM\ManyToOne (targetEntity: ApplianceEntity::class, inversedBy: 'shelves')]
    #[ORM\JoinColumn(nullable: true, onDelete: 'CASCADE')]
    private ?ApplianceEntity $appliance = null;

    public function __construct(int $capacity) {
        $this->foods = new ArrayCollection();
        $this->setCapacity($capacity);
    }

    public function addFood(FoodEntity $food): void {
        if ($this->shelfCapacity - $food->getWeight() < 0){
            throw new \DomainException('Food weight is too big for this shelf.');
        }
        $capacity = $this->shelfCapacity;

        foreach ($this->foods as $foodData) {
            if ($foodData->isConsumed() || $foodData->isTrashed()){
                continue;
            }
            $capacity -= $foodData->getWeight();
        }
        if ($capacity - $food->getWeight() < 0){
            throw new \DomainException('Food weight is too big for this shelf.');
        }

        $food->setShelf($this);
        if (!$this->foods->contains($food)) {
            $this->foods->add($food);
        }
    }

//    Setters
    public function setCapacity(int $capacity): void {
        if  ($capacity <= 0) {
            throw new \InvalidArgumentException('Capacity must be greater than 0.');
        }
        $this->shelfCapacity = $capacity;
    }

    public function setName(string $name): void {
        $name = trim($name);
        if ($name === '' || mb_strlen($name) > 255) {
            throw new \InvalidArgumentException('Shelf name must contain 1 to 255 characters.');
        }
        $this->name = $name;
    }

    public function setAppliance(ApplianceEntity $appliance): void {
        $this->appliance = $appliance;
    }

//    Getters

    public function getAppliance(): ?ApplianceEntity {
        return $this->appliance;
    }

    public function getName(): string {
        return $this->name;
    }

    public function getShelfCapacity(): int {
        return $this->shelfCapacity;
    }

    public function getFoods(): Collection {
        return $this->foods;
    }

}
