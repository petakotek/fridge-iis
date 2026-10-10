<?php

namespace App\Model\Common;

use App\Model\Entity\CategoryEntity;
use App\Model\Entity\HouseholdEntity;
use App\Model\Entity\UserEntity;

class Verification
{
    public static function assertModerator(HouseholdEntity $household, UserEntity $user): void
    {
        if ($user !== $household->getModerator()) {
            throw new \DomainException('Current user is not moderator for this household.');
        }
    }

    public static function assertHouseholdCategory(HouseholdEntity $household, CategoryEntity $category): void {
        if ($category->getHousehold() !== $household) {
            throw new \DomainException('Category belongs to another household.');
        }
    }
}