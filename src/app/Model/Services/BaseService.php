<?php

namespace App\Model\Services;

use Doctrine\ORM\EntityManagerInterface;

abstract class BaseService
{
    public function __construct(public EntityManagerInterface $entityManager) {

    }
}