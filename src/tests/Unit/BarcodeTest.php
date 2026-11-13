<?php declare(strict_types=1);

use App\Presentation\Accessory\Barcode;
use Tester\Assert;
use Tester\TestCase;

require __DIR__ . '/../bootstrap.php';

final class BarcodeTest extends TestCase
{
    public function testKnownEan13Encoding(): void
    {
        $encoded = Barcode::encode('4006381333931');
        Assert::notNull($encoded);
        Assert::same('4006381333931', $encoded['value']);
        Assert::same(117, $encoded['width']);
        $bits = str_repeat('0', 95);
        foreach ($encoded['bars'] as $bar) {
            $bits = substr_replace($bits, str_repeat('1', $bar['width']), $bar['x'] - 11, $bar['width']);
        }
        Assert::same(
            '101' . '0001101' . '0100111' . '0101111' . '0111101' . '0001001' . '0110011'
            . '01010' . '1000010' . '1000010' . '1000010' . '1110100' . '1000010' . '1100110' . '101',
            $bits,
        );
    }

    public function testUpcPreservesLeadingZeroAndMatchesEanBars(): void
    {
        $upc = Barcode::encode('036000291452');
        $ean = Barcode::encode('0036000291452');
        Assert::same('036000291452', $upc['value']);
        Assert::same($ean['bars'], $upc['bars']);
        Assert::same($ean['width'], $upc['width']);
    }

    public function testUpcWithoutCheckDigitIsCompleted(): void
    {
        $encoded = Barcode::encode('72527273070');
        Assert::same('725272730706', $encoded['value']);
        Assert::same(Barcode::encode('725272730706'), $encoded);
        Assert::same(Barcode::encode('036000291452'), Barcode::encode('03600029145'));
        Assert::same('000000000000', Barcode::encode('00000000000')['value']);
        Assert::null(Barcode::encode('725272730700'));
        Assert::null(Barcode::encode('7252727307X'));
    }

    public function testEan8WithoutCheckDigitIsCompleted(): void
    {
        $encoded = Barcode::encode('9031101');
        Assert::same('90311017', $encoded['value']);
        Assert::same(89, $encoded['width']);
        Assert::same(Barcode::encode('90311017'), $encoded);
        Assert::same(Barcode::encode('96385074'), Barcode::encode('9638507'));
        Assert::same('00000000', Barcode::encode('0000000')['value']);
        Assert::null(Barcode::encode('90311018'));
        Assert::null(Barcode::encode('903110X'));
    }

    public function testEan8AndQuietZones(): void
    {
        $encoded = Barcode::encode('96385074');
        Assert::same(89, $encoded['width']);
        Assert::same(11, $encoded['bars'][0]['x']);
        $last = $encoded['bars'][array_key_last($encoded['bars'])];
        Assert::same($encoded['width'] - 11, $last['x'] + $last['width']);
    }

    public function testMissingUnsupportedAndInvalidChecksumsAreRejected(): void
    {
        foreach ([null, '', ' ', 'ABC123', '<script>', '123456', '12345678901234', '4006381333932', '96385075', '036000291453', "4006381333931\n"] as $value) {
            Assert::null(Barcode::encode($value));
        }
    }
}

(new BarcodeTest())->run();
