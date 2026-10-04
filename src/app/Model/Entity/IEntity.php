<?php

namespace App\Model\Entity;

use Doctrine\ORM\Mapping as ORM;
abstract class IEntity
{
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    #[ORM\GeneratedValuee(strategy: "CUSTOM")]
    #[ORM\CustomIdGenerator('doctrine.uuid_generator')]
    private $id;
}