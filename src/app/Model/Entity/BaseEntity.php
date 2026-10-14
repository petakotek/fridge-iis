<?php

namespace App\Model\Entity;

use Doctrine\ORM\Mapping as ORM;

#[ORM\MappedSuperclass]
abstract class BaseEntity
{
    #[ORM\Id]
    #[ORM\Column(type: 'integer')]
    #[ORM\GeneratedValue(strategy: "AUTO")]
    private ?int $id = null;

    public function getId(): ?int {
        return $this->id;
    }
}