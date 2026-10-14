<?php

namespace App\Model\Common;

use App\Model\Entity\ApplianceEntity;
use App\Model\Entity\CategoryEntity;
use App\Model\Entity\HouseholdEntity;
use App\Model\Entity\UserEntity;

class Verification
{
    public static function assertModerator(HouseholdEntity $household, UserEntity $user): void
    {
        if ($user->isAdmin()) {
            return;
        }
        if ($user !== $household->getModerator()) {
            throw new \DomainException('Current user is not moderator for this household.');
        }
    }

    public static function assertHouseholdCategory(HouseholdEntity $household, CategoryEntity $category): void {
        if ($category->getHousehold() !== $household) {
            throw new \DomainException('Category belongs to another household.');
        }
    }

    public static function assertHouseholdUser(HouseholdEntity $household, UserEntity $user): void {
        if ($user->getHousehold() !== $household) {
            throw new \DomainException('User is not part of this household.');
        }
    }

    public static function assertHouseholdAppliance(HouseholdEntity $household, ApplianceEntity $appliance): void {
        if  ($appliance->getHousehold() !== $household) {
            throw new \DomainException('Appliance does not belong to household.');
        }
    }
}