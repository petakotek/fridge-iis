<?php declare(strict_types=1);

namespace App\Presentation\Consumption;

use App\Model\Entity\FoodEntity;
use App\Model\Services\FoodService;
use App\Model\Services\UserService;
use App\Presentation\Accessory\AuthenticatedPresenter;
use DateTimeImmutable;

final class ConsumptionPresenter extends AuthenticatedPresenter
{
    public function __construct(UserService $users, private FoodService $foods)
    {
        parent::__construct($users);
    }

    public function renderDefault(?string $from = null, ?string $to = null): void
    {
        $fromDate = $this->parseDate($from);
        $toDate = $this->parseDate($to);
        if ($fromDate > $toDate) {
            $this->error('Datum od nesmí být po datu do.', 400);
        }
        if ($fromDate->diff($toDate)->days > 366) {
            $this->error('Období může být nejvýše jeden rok.', 400);
        }

        $toExclusive = $toDate->modify('+1 day');
        $foods = $this->foods->getConsumedFoods($this->currentUser, $fromDate, $toExclusive);
        $totals = $this->sumNutrients($foods);
        $today = new DateTimeImmutable('today');
        $singleDay = $fromDate == $toDate;
        $chart = $singleDay
            ? $this->caloriesByHour($foods)
            : $this->caloriesByDay($foods, $fromDate, $toExclusive);

        $this->template->foods = $foods;
        $this->template->totals = $totals;
        $this->template->totalCalories = $totals['calories'];
        $this->template->singleDay = $singleDay;
        $this->template->dayCount = $fromDate->diff($toDate)->days + 1;
        $this->template->periodLabel = $this->periodLabel($fromDate, $toDate, $today);
        $this->template->chart = $chart;
        $this->template->chartMax = max(1, ...array_column($chart, 'calories'));
        $macroTotal = $totals['protein'] + $totals['fat'] + $totals['carb'] + $totals['fibre'];
        $this->template->macroTotal = $macroTotal;
        $this->template->pie = $this->pieStops($totals, $macroTotal);
        $this->template->from = $fromDate;
        $this->template->to = $toDate;
        $this->template->today = $today;
        $this->template->yesterday = $today->modify('-1 day');
        $this->template->weekFrom = $this->template->today->modify('-6 days');
    }

    /**
     * @param FoodEntity[] $foods
     * @return array{count: int, weight: int, calories: int, protein: int, fat: int, carb: int, fibre: int, price: float}
     */
    private function sumNutrients(array $foods): array
    {
        $totals = ['count' => count($foods), 'weight' => 0, 'calories' => 0, 'protein' => 0, 'fat' => 0, 'carb' => 0, 'fibre' => 0, 'price' => 0.0];
        foreach ($foods as $food) {
            $totals['weight'] += $food->getWeight() ?? 0;
            $totals['calories'] += (int) ($food->getCalories() ?? 0);
            $totals['protein'] += $food->getProtein() ?? 0;
            $totals['fat'] += $food->getFat() ?? 0;
            $totals['carb'] += $food->getCarb() ?? 0;
            $totals['fibre'] += $food->getFibre() ?? 0;
            $totals['price'] += (float) ($food->getPrice() ?? 0);
        }
        return $totals;
    }

    /**
     * Cumulative pie slice boundaries in tenths of a percent (0–1000); fibre fills the rest.
     * @param array{protein: int, fat: int, carb: int, fibre: int} $totals
     * @return array{s1: int, s2: int, s3: int}
     */
    private function pieStops(array $totals, int $macroTotal): array
    {
        if ($macroTotal <= 0) {
            return ['s1' => 0, 's2' => 0, 's3' => 0];
        }
        $stop = fn(int $grams): int => (int) round($grams / $macroTotal * 1000);
        return [
            's1' => $stop($totals['protein']),
            's2' => $stop($totals['protein'] + $totals['fat']),
            's3' => $stop($totals['protein'] + $totals['fat'] + $totals['carb']),
        ];
    }

    private function periodLabel(DateTimeImmutable $from, DateTimeImmutable $to, DateTimeImmutable $today): string
    {
        if ($from == $to) {
            return match (true) {
                $from == $today => 'dnes',
                $from == $today->modify('-1 day') => 'včera',
                default => $from->format('j. n. Y'),
            };
        }
        return $from->format('j. n. Y') . ' – ' . $to->format('j. n. Y');
    }

    /**
     * Chart buckets: calories per day for every day of the period (days without consumption are 0).
     * @param FoodEntity[] $foods
     * @return list<array{label: string, title: string, calories: int, count: int}>
     */
    private function caloriesByDay(array $foods, DateTimeImmutable $from, DateTimeImmutable $toExclusive): array
    {
        $buckets = [];
        for ($day = $from; $day < $toExclusive; $day = $day->modify('+1 day')) {
            $buckets[$day->format('Y-m-d')] = [
                'label' => $day->format('j. n.'),
                'title' => $day->format('j. n. Y'),
                'calories' => 0,
                'count' => 0,
            ];
        }
        return $this->fillBuckets($buckets, $foods, 'Y-m-d');
    }

    /**
     * Chart buckets for a single day: calories per hour (0–23).
     * @param FoodEntity[] $foods
     * @return list<array{label: string, title: string, calories: int, count: int}>
     */
    private function caloriesByHour(array $foods): array
    {
        $buckets = [];
        for ($hour = 0; $hour < 24; $hour++) {
            $buckets[(string) $hour] = [
                'label' => $hour . ' h',
                'title' => sprintf('%d:00–%d:59', $hour, $hour),
                'calories' => 0,
                'count' => 0,
            ];
        }
        return $this->fillBuckets($buckets, $foods, 'G');
    }

    /**
     * @param array<string, array{label: string, title: string, calories: int, count: int}> $buckets
     * @param FoodEntity[] $foods
     * @return list<array{label: string, title: string, calories: int, count: int}>
     */
    private function fillBuckets(array $buckets, array $foods, string $keyFormat): array
    {
        foreach ($foods as $food) {
            $key = $food->getConsumedAt()?->format($keyFormat);
            if ($key !== null && isset($buckets[$key])) {
                $buckets[$key]['calories'] += (int) ($food->getCalories() ?? 0);
                $buckets[$key]['count']++;
            }
        }
        return array_values($buckets);
    }

    private function parseDate(?string $date): DateTimeImmutable
    {
        if ($date === null) {
            return new DateTimeImmutable('today');
        }

        $parsed = DateTimeImmutable::createFromFormat('!Y-m-d', $date);
        if ($parsed === false || $parsed->format('Y-m-d') !== $date) {
            $this->error('Neplatné datum.', 400);
        }

        return $parsed;
    }
}
