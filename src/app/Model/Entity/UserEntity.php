<?php

namespace App\Model\Entity;
use Doctrine\ORM\Mapping as ORM;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
#[ORM\Entity]
class UserEntity extends BaseEntity
{
    #[ORM\Column(type: 'string', length: 255)]
    private string $name;

    #[ORM\Column(type: 'string', length: 255)]
    private string $surname;

    #[ORM\Column(type: 'integer')]
    private int $authLevel;

    #[ORM\ManyToOne(targetEntity: HouseholdEntity::class , inversedBy: 'users')]
    private HouseholdEntity $household;
}