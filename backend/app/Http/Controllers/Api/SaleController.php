<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreSaleRequest;
use App\Http\Resources\SaleResource;
use App\Models\Sale;
use App\Models\SaleItem;
use App\Services\StockService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class SaleController extends Controller
{
    public function store(StoreSaleRequest $request, StockService $stockService): JsonResponse
    {
        $validated = $request->validated();

        $sale = DB::transaction(function () use ($validated, $request, $stockService) {
            $items = collect($validated['items']);
            $products = $stockService->lock($items->pluck('product_id')->all());

            // Prices come from the database, never from the client payload.
            $lines = $items->map(function (array $item) use ($products) {
                $product = $products->get($item['product_id']);
                $quantity = (int) $item['quantity'];
                $price = (float) $product->selling_price;

                return [
                    'product' => $product,
                    'quantity' => $quantity,
                    'price' => $price,
                    'subtotal' => round($price * $quantity, 2),
                ];
            });

            $sale = Sale::create([
                'buyer_id' => $validated['buyer_id'] ?? null,
                'cashier_id' => $request->user()->id,
                'total_amount' => round($lines->sum('subtotal'), 2),
            ]);

            $now = now();
            $itemsData = [];
            $stockEntries = [];

            foreach ($lines as $line) {
                $itemsData[] = [
                    'sale_id' => $sale->id,
                    'product_id' => $line['product']->id,
                    'quantity' => $line['quantity'],
                    'selling_price' => $line['price'],
                    'subtotal' => $line['subtotal'],
                    'created_at' => $now,
                    'updated_at' => $now,
                ];

                $stockEntries[] = [
                    'product' => $line['product'],
                    'quantity_change' => -$line['quantity'],
                    'reference_type' => 'sale',
                    'reference_id' => $sale->id,
                ];
            }

            SaleItem::insert($itemsData);
            $stockService->applyMany($stockEntries);

            return $sale;
        });

        $sale->load('items.product', 'buyer', 'cashier');

        return SaleResource::make($sale)->response()->setStatusCode(201);
    }
}
