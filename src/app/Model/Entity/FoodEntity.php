<?php

namespace App\Model\Entity;

use DateTime;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
class FoodEntity extends BaseEntity
{
    #[ORM\Column (type: 'string', length: 255)]
    private string $name;

    #[ORM\Column (type: 'datetime', nullable: true)]
    private ?DateTime $expiry = null;

    #[ORM\Column (type: 'integer', nullable: true)]
    private ?int $weight = null;

    #[ORM\Column (type: 'string', length: 13, nullable: true)]
    private ?string $barcode;

    #[ORM\Column (type: 'decimal', precision: 10, scale: 2, nullable: true)]
    private ?float $price;

    #[ORM\Column (type: 'integer', nullable: true)]
    private ?int $calories;

    #[ORM\Column (type: 'integer', nullable: true)]
    private ?int $protein;

    #[ORM\Column (type: 'integer', nullable: true)]
    private ?int $fat;

    #[ORM\Column (type: 'integer', nullable: true)]
    private ?int $carb;

    #[ORM\Column (type: 'integer', nullable: true)]
    private ?int $fibre;

    #[ORM\Column (type: 'datetime', nullable: true)]
    private ?DateTime $consumedAt = null;

    #[ORM\Column (type: 'boolean', nullable: true)]
    private ?bool $trashed = null;

    #[ORM\Column (type: 'datetime', nullable: true)]
    private ?DateTime $discardedAt = null;

    #[ORM\ManyToOne(targetEntity: UserEntity::class, inversedBy: "foodsConsumed")]
    #[ORM\JoinColumn(nullable: true, onDelete: 'SET NULL')]
    private ?UserEntity $consumer = null;

    #[ORM\ManyToMany(targetEntity: CategoryEntity::class, inversedBy: 'foods')]
    #[ORM\JoinTable(name: 'categoryentity_foodentity')]
    #[ORM\JoinColumn(name: 'foodentity_id', referencedColumnName: 'id', onDelete: 'CASCADE')]
    #[ORM\InverseJoinColumn(name: 'categoryentity_id', referencedColumnName: 'id', onDelete: 'CASCADE')]
    private Collection $categories;

    #[ORM\ManyToOne (targetEntity: ShelfEntity::class, inversedBy: 'foods')]
    #[ORM\JoinColumn(nullable: false, onDelete: 'RESTRICT')]
    private ShelfEntity $shelf;

    public function __construct(string $name,
                                string $barcode,
                                float $price,
                                int $calories,
                                int $protein,
                                int $fat,
                                int $carb,
                                int $fibre) {
        $this->name = $name;
        $this->barcode = $barcode;
        $this->price = $price;
        $this->calories = $calories;
        $this->protein = $protein;
        $this->fibre = $fibre;
        $this->carb = $carb;
        $this->fat = $fat;
        $this->categories = new ArrayCollection();
    }

    public function setExpiry(?DateTime $time): void
    {
        $this->expiry = $time;
    }

    public function setConsumed(UserEntity $user): void {
        $this->consumedAt = new DateTime();
        $this->consumer = $user;

        $this->trashed = null;
        $this->discardedAt = null;
    }

    public function setShelf(ShelfEntity $shelf): void {
        foreach ($this->categories as $category) {
            if ($category->getHousehold() !== $shelf->getAppliance()->getHousehold()) {
                throw new \DomainException('Food and its categories must belong to the same household.');
            }
        }
        $this->shelf = $shelf;
    }

    public function addCategory(CategoryEntity $category): void {
        if (!isset($this->shelf)) {
            throw new \LogicException('Assign a shelf before assigning food categories.');
        }
        if ($category->getHousehold() !== $this->shelf->getAppliance()->getHousehold()) {
            throw new \DomainException('Food and its categories must belong to the same household.');
        }
        if (!$this->categories->contains($category)) {
            $this->categories->add($category);
        }
        $category->addFood($this);
    }

    public function removeCategory(CategoryEntity $category): void {
        $this->categories->removeElement($category);
        $category->removeFood($this);
    }

    public function setTrashed(): void {
        $this->consumer = null;
        $this->consumedAt = null;

        $this->trashed = true;
        $this->discardedAt = new DateTime();
    }

//    Getter functions

    public function getName(): string {
        return $this->name;
    }

    public function getExpiry(): ?DateTime {
        return $this->expiry;
    }

    public function getBarcode(): ?string {
        return $this->barcode;
    }

    public function getPrice(): ?float {
        return $this->price;
    }

    public function getCalories(): ?float {
        return $this->calories;
    }

    public function getProtein(): ?int {
        return $this->protein;
    }

    public function getFat(): ?int {
        return $this->fat;
    }

    public function getCarb(): ?int {
        return $this->carb;
    }

    public function getFibre(): ?int {
        return $this->fibre;
    }

    public function isConsumed(): bool {
        return $this->consumer !== null;
    }

    public function getConsumedAt(): ?DateTime {
        return $this->consumedAt;
    }

    public function isTrashed(): bool {
        return $this->trashed;
    }

    public function getDiscardedAt(): ?DateTime {
        return $this->discardedAt;
    }

    public function getCategories(): Collection {
        return $this->categories;
    }

    public function getWeight(): ?int {
        return $this->weight;
    }

}
