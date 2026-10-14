<?php

namespace App\Model\Entity;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;
use Gedmo\Mapping\Annotation as Gedmo;

#[ORM\Entity]
#[Gedmo\Tree(type: 'nested')]
class CategoryEntity extends BaseEntity
{
    #[ORM\Column(length: 50)]
    private string $name;
    #[ORM\ManyToMany(targetEntity: FoodEntity::class, mappedBy: 'categories')]
    private Collection $foods;

    #[Gedmo\TreeLeft]
    #[ORM\Column(type: 'integer')]
    private ?int $lft = null;

    #[Gedmo\TreeRight]
    #[ORM\Column(type: 'integer')]
    private ?int $rgt = null;

    #[Gedmo\TreeLevel]
    #[ORM\Column(type: 'integer')]
    private ?int $level = null;

    #[Gedmo\TreeRoot]
    #[ORM\ManyToOne(targetEntity: self::class)]
    #[ORM\JoinColumn(name: 'tree_root', onDelete: 'CASCADE')]
    private ?self $root = null;

    #[Gedmo\TreeParent]
    #[ORM\ManyToOne(targetEntity: self::class)]
    #[ORM\JoinColumn(name: 'parent_id', onDelete: 'CASCADE')]
    private ?self $parent = null;

    #[ORM\ManyToOne(targetEntity: HouseholdEntity::class, inversedBy: "categories")]
    #[ORM\JoinColumn(nullable: false, onDelete: 'CASCADE')]
    private HouseholdEntity $household;

    public function __construct(HouseholdEntity $household, string $name) {
        $this->setName($name);
        $this->foods = new ArrayCollection();
        $household->addCategory($this);
    }

    public function getName(): string {
        return $this->name;
    }

    public function setName(string $name): void {
        $name = trim($name);
        if ($name === '' || mb_strlen($name) > 50) {
            throw new \InvalidArgumentException('Category name must contain 1 to 50 characters.');
        }
        $this->name = $name;
    }

    public function getParent(): ?self {
        return $this->parent;
    }

    public function setParent(?self $parent): void {
        if ($parent !== null && $parent->getHousehold() !== $this->household) {
            throw new \DomainException('Parent category must belong to the same household.');
        }

        for ($ancestor = $parent; $ancestor !== null; $ancestor = $ancestor->getParent()) {
            if ($ancestor === $this) {
                throw new \DomainException('A category cannot be placed under itself or its descendant.');
            }
        }

        $this->parent = $parent;
    }

    public function setHousehold(HouseholdEntity $household): void {
        if (isset($this->household)) {
            if ($this->household !== $household) {
                throw new \DomainException('A category cannot be moved to another household.');
            }
            return;
        }
        $this->household = $household;
        if (!$household->getCategories()->contains($this)) {
            $household->addCategory($this);
        }
    }

    public function getHousehold(): HouseholdEntity {
        return $this->household;
    }

    public function addFood(FoodEntity $food): void {
        if (!$food->getCategories()->contains($this)) {
            $food->addCategory($this);
        }
        if (!$this->foods->contains($food)) {
            $this->foods->add($food);
        }
    }

    public function removeFood(FoodEntity $food): void {
        $this->foods->removeElement($food);
        if ($food->getCategories()->contains($this)) {
            $food->removeCategory($this);
        }
    }

    /** @return Collection<int, FoodEntity> */
    public function getFoods(): Collection {
        return $this->foods;
    }
}
