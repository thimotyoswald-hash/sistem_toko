<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StorePurchaseRequest;
use App\Http\Resources\PurchaseResource;
use App\Models\Purchase;
use App\Models\PurchaseItem;
use App\Services\StockService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class PurchaseController extends Controller
{
    public function store(StorePurchaseRequest $request, StockService $stockService): JsonResponse
    {
        $validated = $request->validated();

        $purchase = DB::transaction(function () use ($validated, $request, $stockService) {
            $items = collect($validated['items']);
            $products = $stockService->lock($items->pluck('product_id')->all());

            $lines = $items->map(function (array $item) use ($products) {
                $quantity = (int) $item['quantity'];
                $price = round((float) $item['purchase_price'], 2);

                return [
                    'product' => $products->get($item['product_id']),
                    'quantity' => $quantity,
                    'price' => $price,
                    'subtotal' => round($price * $quantity, 2),
                ];
            });

            $purchase = Purchase::create([
                'distributor_id' => $validated['distributor_id'] ?? null,
                'admin_id' => $request->user()->id,
                'total_amount' => round($lines->sum('subtotal'), 2),
            ]);

            $now = now();
            $itemsData = [];
            $stockEntries = [];

            foreach ($lines as $line) {
                $itemsData[] = [
                    'purchase_id' => $purchase->id,
                    'product_id' => $line['product']->id,
                    'quantity' => $line['quantity'],
                    'purchase_price' => $line['price'],
                    'subtotal' => $line['subtotal'],
                    'created_at' => $now,
                    'updated_at' => $now,
                ];

                $stockEntries[] = [
                    'product' => $line['product'],
                    'quantity_change' => $line['quantity'],
                    'reference_type' => 'purchase',
                    'reference_id' => $purchase->id,
                ];
            }

            PurchaseItem::insert($itemsData);
            $stockService->applyMany($stockEntries);

            return $purchase;
        });

        $purchase->load('items.product', 'distributor', 'admin');

        return PurchaseResource::make($purchase)->response()->setStatusCode(201);
    }
}
