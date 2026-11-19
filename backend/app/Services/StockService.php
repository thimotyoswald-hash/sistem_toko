<?php

namespace App\Services;

use App\Exceptions\InsufficientStockException;
use App\Models\Product;
use App\Models\StockHistory;
use Illuminate\Database\Eloquent\Collection;

/**
 * The only place that mutates products.current_stock.
 *
 * Every call must run inside a DB::transaction(), and the product rows must be
 * locked first through lock() so concurrent sales/purchases cannot oversell.
 */
class StockService
{
    /**
     * Lock the given products for the rest of the current transaction.
     *
     * @param  array<int, int>  $productIds
     * @return Collection<int, Product>
     */
    public function lock(array $productIds): Collection
    {
        return Product::query()
            ->whereIn('id', array_values(array_unique($productIds)))
            ->lockForUpdate()
            ->get()
            ->keyBy('id');
    }

    public function apply(Product $product, int $quantityChange, string $referenceType, int $referenceId): StockHistory
    {
        $finalStock = $product->current_stock + $quantityChange;

        if ($finalStock < 0) {
            throw new InsufficientStockException(
                "Stok {$product->name} tidak mencukupi. Sisa {$product->current_stock}, dibutuhkan ".abs($quantityChange).'.'
            );
        }

        $product->forceFill(['current_stock' => $finalStock])->save();

        return StockHistory::create([
            'product_id' => $product->id,
            'reference_type' => $referenceType,
            'reference_id' => $referenceId,
            'quantity_change' => $quantityChange,
            'final_stock' => $finalStock,
        ]);
    }

    /**
     * Apply multiple stock mutations efficiently in a single batch.
     * Validates all final stocks first before mutating, then inserts stock history records in bulk.
     *
     * @param  array<int, array{product: Product, quantity_change: int, reference_type: string, reference_id: int}>  $entries
     * @return void
     */
    public function applyMany(array $entries): void
    {
        // 1. Pre-validate all stock levels to prevent partial failure
        foreach ($entries as $entry) {
            $finalStock = $entry['product']->current_stock + $entry['quantity_change'];
            if ($finalStock < 0) {
                throw new InsufficientStockException(
                    "Stok {$entry['product']->name} tidak mencukupi. Sisa {$entry['product']->current_stock}, dibutuhkan ".abs($entry['quantity_change']).'.'
                );
            }
        }

        $now = now();
        $records = [];

        foreach ($entries as $entry) {
            $product = $entry['product'];
            $qtyChange = $entry['quantity_change'];
            $finalStock = $product->current_stock + $qtyChange;

            $product->forceFill(['current_stock' => $finalStock])->save();

            $records[] = [
                'product_id' => $product->id,
                'reference_type' => $entry['reference_type'],
                'reference_id' => $entry['reference_id'],
                'quantity_change' => $qtyChange,
                'final_stock' => $finalStock,
                'created_at' => $now,
                'updated_at' => $now,
            ];
        }

        if (!empty($records)) {
            StockHistory::insert($records);
        }
    }
}
