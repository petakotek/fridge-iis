<?php

namespace App\Model\Entity;

use Doctrine\ORM\Mapping as ORM;
use Gedmo\Mapping\Annotation as Gedmo;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping\ManyToMany;

#[ORM\Entity]
#[Gedmo\Tree(type: 'nested')]
class CategoryEntity extends BaseEntity
{
    #[ORM\Column(length: 50)]
    private string $name;
    #[ManyToMany(targetEntity: FoodEntity::class, inversedBy: "categories")]
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

    public function __construct(){
        $this->foods = new ArrayCollection();
    }
}