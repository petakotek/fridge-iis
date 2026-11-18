<?php declare(strict_types=1);

namespace App\Model\Services;

use App\Model\Common\ProductLookupException;
use Nette\Caching\Cache;
use Nette\Caching\Storage;
use Nette\Utils\Json;
use Nette\Utils\JsonException;

/**
 * Looks up food products by barcode in the public Open Food Facts database.
 * Nutrients are returned per 100 g; the caller scales them to the actual weight.
 */
final class ProductLookupService
{
    private const ApiUrl = 'https://world.openfoodfacts.org/api/v2/product/%s.json'
        . '?fields=product_name,product_name_cs,nutriments';
    private const UserAgent = 'IIS-Lednice/1.0';
    private const Timeout = 5;

    private const Nutrients = [
        'calories' => 'energy-kcal_100g',
        'protein' => 'proteins_100g',
        'fat' => 'fat_100g',
        'carb' => 'carbohydrates_100g',
        'fibre' => 'fiber_100g',
    ];

    private Cache $cache;

    public function __construct(Storage $storage)
    {
        $this->cache = new Cache($storage, 'barcode-per100g');
    }

    /**
     * @return array{name: ?string, calories: ?float, protein: ?float, fat: ?float, carb: ?float, fibre: ?float}|null
     *         nutrients per 100 g/ml; null when the product is not in the database
     * @throws \InvalidArgumentException for a malformed barcode
     * @throws ProductLookupException when the database is unavailable
     */
    public function lookup(string $barcode): ?array
    {
        $barcode = trim($barcode);
        if (!preg_match('/^\d{8,13}$/', $barcode)) {
            throw new \InvalidArgumentException('Barcode must have 8–13 digits.');
        }

        $cached = $this->cache->load($barcode);
        if ($cached !== null) {
            return $cached === false ? null : $cached;
        }

        $product = $this->fetch($barcode);
        $this->cache->save($barcode, $product ?? false, [
            Cache::Expire => $product === null ? '1 day' : '7 days',
        ]);
        return $product;
    }

    /** @return array{name: ?string, calories: ?float, protein: ?float, fat: ?float, carb: ?float, fibre: ?float}|null */
    private function fetch(string $barcode): ?array
    {
        $context = stream_context_create(['http' => [
            'timeout' => self::Timeout,
            'ignore_errors' => true, // read the body of 404 responses too
            'header' => 'User-Agent: ' . self::UserAgent . "\r\n",
        ]]);
        $body = @file_get_contents(sprintf(self::ApiUrl, $barcode), false, $context);
        if ($body === false) {
            throw new ProductLookupException('Open Food Facts is unreachable.');
        }

        try {
            $data = Json::decode($body, forceArrays: true);
        } catch (JsonException $e) {
            throw new ProductLookupException('Open Food Facts returned invalid JSON.', 0, $e);
        }

        if (!is_array($data) || ($data['status'] ?? 0) !== 1 || !is_array($data['product'] ?? null)) {
            return null;
        }
        return $this->mapProduct($data['product']);
    }

    /**
     * @param array<string, mixed> $product
     * @return array{name: ?string, calories: ?float, protein: ?float, fat: ?float, carb: ?float, fibre: ?float}
     */
    private function mapProduct(array $product): array
    {
        $name = trim((string) ($product['product_name_cs'] ?? ''));
        if ($name === '') {
            $name = trim((string) ($product['product_name'] ?? ''));
        }

        $result = ['name' => $name !== '' ? mb_substr($name, 0, 255) : null];
        $nutriments = is_array($product['nutriments'] ?? null) ? $product['nutriments'] : [];
        foreach (self::Nutrients as $key => $field) {
            $per100 = $nutriments[$field] ?? null;
            $result[$key] = is_numeric($per100) && $per100 >= 0 ? (float) $per100 : null;
        }
        return $result;
    }
}
