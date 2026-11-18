<?php declare(strict_types=1);

namespace App\Model\Common;

final class FoodNutrition
{
    /** Convert input to the whole-package integer values used by existing food records. */
    public static function toPackage(float $value, string $basis, int $weight, ?float $volume = null): int
    {
        $amount = match ($basis) {
            '100g' => $weight,
            '100ml' => $volume,
            'package' => 100,
            default => throw new \InvalidArgumentException('Unknown nutrition basis.'),
        };
        if (!is_finite($value) || $value < 0 || $value > 2147483647
            || $amount === null || !is_finite((float) $amount) || $amount <= 0) {
            throw new \InvalidArgumentException('Invalid nutrient value or package amount.');
        }

        $total = round($value * $amount / 100);
        if (!is_finite($total) || $total > 2147483647) {
            throw new \InvalidArgumentException('Package nutrient value exceeds the supported range.');
        }
        return (int) $total;
    }
}
