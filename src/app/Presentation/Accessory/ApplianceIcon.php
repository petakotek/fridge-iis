<?php declare(strict_types=1);

namespace App\Presentation\Accessory;

use Nette\Utils\Strings;

final class ApplianceIcon
{
    public static function forName(string $name): string
    {
        $name = strtolower(Strings::toAscii($name));
        // Match whole words so custom names such as "Kitchen fridge" work too.
        foreach ([
            'freezer' => 'freezer|mrazak|mraznicka',
            'fridge' => 'fridge|refrigerator|lednice|lednicka|chladnicka',
            'microwave' => 'microwave|mikrovlnka|mikrovlnna',
            'oven' => 'oven|trouba|sporak',
            'pantry' => 'pantry|cupboard|spiz|spizka|skrin|skrinka',
        ] as $icon => $words) {
            if (preg_match('/\\b(?:' . $words . ')\\b/', $name)) {
                return $icon;
            }
        }
        return 'generic';
    }
}
