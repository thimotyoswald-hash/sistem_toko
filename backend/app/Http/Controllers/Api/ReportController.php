<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\StockHistoryResource;
use App\Models\Purchase;
use App\Models\Sale;
use App\Models\StockHistory;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Collection;

class ReportController extends Controller
{
    public function stockHistory(Request $request): AnonymousResourceCollection
    {
        $filters = $request->validate([
            'product_id' => ['nullable', 'integer', 'exists:products,id'],
            'reference_type' => ['nullable', 'in:sale,purchase,adjustment'],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
        ]);

        $histories = StockHistory::query()
            ->with(['product.category', 'reference'])
            ->when($filters['product_id'] ?? null, fn ($query, $productId) => $query->where('product_id', $productId))
            ->when($filters['reference_type'] ?? null, fn ($query, $type) => $query->where('reference_type', $type))
            ->when($filters['from'] ?? null, fn ($query, $from) => $query->whereDate('created_at', '>=', $from))
            ->when($filters['to'] ?? null, fn ($query, $to) => $query->whereDate('created_at', '<=', $to))
            ->orderByDesc('id')
            ->paginate(min(max($request->integer('per_page', 25), 1), 100));

        return StockHistoryResource::collection($histories);
    }

    public function profitLoss(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'month' => ['nullable', 'integer', 'between:1,12'],
            'year' => ['nullable', 'integer', 'between:2000,2100'],
        ]);

        // Query string values arrive as strings; the response must echo integers.
        $month = (int) ($filters['month'] ?? now()->month);
        $year = (int) ($filters['year'] ?? now()->year);

        $start = CarbonImmutable::create($year, $month, 1)->startOfMonth();
        $end = $start->endOfMonth();

        $sales = Sale::query()
            ->whereBetween('created_at', [$start, $end])
            ->get(['total_amount', 'created_at']);

        $purchases = Purchase::query()
            ->whereBetween('created_at', [$start, $end])
            ->get(['total_amount', 'created_at']);

        $salesTotal = round((float) $sales->sum('total_amount'), 2);
        $purchasesTotal = round((float) $purchases->sum('total_amount'), 2);

        return response()->json([
            'month' => $month,
            'year' => $year,
            'sales_total' => $salesTotal,
            'purchases_total' => $purchasesTotal,
            'profit' => round($salesTotal - $purchasesTotal, 2),
            'sales_count' => $sales->count(),
            'purchases_count' => $purchases->count(),
            'daily' => $this->dailyBreakdown($sales, $purchases),
        ]);
    }

    /**
     * Per-day totals so the owner dashboard can draw a chart.
     *
     * @param  Collection<int, Sale>  $sales
     * @param  Collection<int, Purchase>  $purchases
     * @return array<int, array<string, mixed>>
     */
    private function dailyBreakdown($sales, $purchases): array
    {
        $daily = [];

        $row = function (string $date) use (&$daily): array {
            return $daily[$date] ?? ['date' => $date, 'sales' => 0.0, 'purchases' => 0.0, 'profit' => 0.0];
        };

        foreach ($sales as $sale) {
            $date = $sale->created_at->toDateString();
            $entry = $row($date);
            $entry['sales'] = round($entry['sales'] + (float) $sale->total_amount, 2);
            $daily[$date] = $entry;
        }

        foreach ($purchases as $purchase) {
            $date = $purchase->created_at->toDateString();
            $entry = $row($date);
            $entry['purchases'] = round($entry['purchases'] + (float) $purchase->total_amount, 2);
            $daily[$date] = $entry;
        }

        foreach ($daily as $date => $entry) {
            $daily[$date]['profit'] = round($entry['sales'] - $entry['purchases'], 2);
        }

        ksort($daily);

        return array_values($daily);
    }
}
