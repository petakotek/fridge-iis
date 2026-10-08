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

    #[ORM\Column (type: 'datetime')]
    private ?DateTime $expiry;

    #[ORM\Column (type: 'integer')]
    private int $weight;

    #[ORM\Column (type: 'string', length: 13)]
    private string $barcode;

    #[ORM\Column (type: 'decimal', precision: 10, scale: 2)]
    private float $price;

    #[ORM\Column (type: 'integer')]
    private int $calories;

    #[ORM\Column (type: 'integer')]
    private int $protein;

    #[ORM\Column (type: 'integer')]
    private int $fat;

    #[ORM\Column (type: 'integer')]
    private int $carb;

    #[ORM\Column (type: 'integer')]
    private int $fibre;

    #[ORM\Column (type: 'datetime', nullable: true)]
    private ?DateTime $consumedAt = null;

    #[ORM\Column (type: 'boolean', nullable: true)]
    private ?bool $trashed = null;

    #[ORM\Column (type: 'datetime', nullable: true)]
    private ?DateTime $discardedAt = null;

    #[ORM\ManyToOne(targetEntity: UserEntity::class, inversedBy: "foodsConsumed")]
    #[ORM\JoinColumn(nullable: true)]
    private ?UserEntity $consumer = null;

    #[ORM\ManyToMany(targetEntity: CategoryEntity::class, inversedBy: 'foods', cascade: ['persist'])]
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
        $this->fatt = $fat;
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

    /** @return Collection<int, CategoryEntity> */
    public function getCategories(): Collection {
        return $this->categories;
    }

    public function getWeight(): ?int {
        return $this->weight;
    }

    public function setTrashed(): void {
        $this->consumer = null;
        $this->consumedAt = null;

        $this->trashed = true;
        $this->discardedAt = new DateTime();
    }
}
