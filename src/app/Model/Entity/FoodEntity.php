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
    private string $price;

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

    #[ORM\Column (type: 'boolean')]
    private ?bool $consumed;

    #[ORM\ManyToMany(targetEntity: CategoryEntity::class, mappedBy: 'foods')]
    private Collection $categories;

    #[ORM\ManyToOne (targetEntity: ShelfEntity::class, inversedBy: 'foods')]
    #[ORM\JoinColumn(nullable: false, onDelete: 'RESTRICT')]
    private ShelfEntity $shelf;

    public function __construct(){
        $this->categories = new ArrayCollection();
    }
    public function setExpiry(?DateTime $time): void
    {
        $this->expiry = $time;
    }
}