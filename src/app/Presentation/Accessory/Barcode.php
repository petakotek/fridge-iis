<?php declare(strict_types=1);

namespace App\Presentation\Accessory;

final class Barcode
{
    private const LEFT = [
        '0001101', '0011001', '0010011', '0111101', '0100011',
        '0110001', '0101111', '0111011', '0110111', '0001011',
    ];

    private const PARITY = [
        'LLLLLL', 'LLGLGG', 'LLGGLG', 'LLGGGL', 'LGLLGG',
        'LGGLLG', 'LGGGLL', 'LGLGLG', 'LGLGGL', 'LGGLGL',
    ];

    /**
     * Encode complete EAN-13 values, or EAN-8/UPC-A with an optional check digit.
     *
     * @return array{value: string, width: int, bars: list<array{x: int, width: int, guard: bool}>}|null
     */
    public static function encode(?string $value): ?array
    {
        if ($value === null || !preg_match('/\A(?:[0-9]{7}|[0-9]{8}|[0-9]{11}|[0-9]{12}|[0-9]{13})\z/', $value)) {
            return null;
        }
        if (strlen($value) === 7 || strlen($value) === 11) {
            $value .= self::checkDigit($value);
        }
        if (self::checkDigit(substr($value, 0, -1)) !== (int) $value[strlen($value) - 1]) {
            return null;
        }

        // UPC-A uses the same bars as EAN-13 with a leading zero.
        $digits = strlen($value) === 12 ? '0' . $value : $value;
        $short = strlen($digits) === 8;
        $half = $short ? 4 : 6;
        $left = $short ? substr($digits, 0, 4) : substr($digits, 1, 6);
        $right = substr($digits, -$half);
        $parity = $short ? 'LLLL' : self::PARITY[(int) $digits[0]];
        $bits = '101';
        for ($index = 0; $index < $half; ++$index) {
            $pattern = self::LEFT[(int) $left[$index]];
            $bits .= $parity[$index] === 'L' ? $pattern : strrev(strtr($pattern, '01', '10'));
        }
        $bits .= '01010';
        for ($index = 0; $index < $half; ++$index) {
            $bits .= strtr(self::LEFT[(int) $right[$index]], '01', '10');
        }
        $bits .= '101';

        // Leave an eleven-module quiet zone on each side for barcode readers.
        $bars = [];
        $length = strlen($bits);
        $middle = 3 + $half * 7;
        for ($index = 0; $index < $length; ++$index) {
            if ($bits[$index] !== '1') {
                continue;
            }
            $start = $index;
            while ($index + 1 < $length && $bits[$index + 1] === '1') {
                ++$index;
            }
            $bars[] = [
                'x' => 11 + $start,
                'width' => $index - $start + 1,
                'guard' => $start < 3 || ($start >= $middle && $start < $middle + 5) || $start >= $length - 3,
            ];
        }
        return ['value' => $value, 'width' => $length + 22, 'bars' => $bars];
    }

    private static function checkDigit(string $body): int
    {
        $sum = 0;
        $weight = 3;
        for ($index = strlen($body) - 1; $index >= 0; --$index) {
            $sum += (int) $body[$index] * $weight;
            $weight = 4 - $weight;
        }
        return (10 - $sum % 10) % 10;
    }
}
