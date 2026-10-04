<?php

namespace App\Model\Entity;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
class HouseholdEntity extends BaseEntity
{
    #[ORM\OneToMany(targetEntity: UserEntity::class, mappedBy: "household")]
    private Collection $users;

    #[ORM\OneToMany(targetEntity: ApplianceEntity::class, mappedBy: "household")]
    private Collection $appliances;

    public function __construct(){
        $this->users = new ArrayCollection();
        $this->appliances = new ArrayCollection();
    }
}