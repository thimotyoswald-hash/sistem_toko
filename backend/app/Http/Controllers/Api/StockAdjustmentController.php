<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreStockAdjustmentRequest;
use App\Http\Resources\StockAdjustmentResource;
use App\Models\StockAdjustment;
use App\Services\StockService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class StockAdjustmentController extends Controller
{
    public function store(StoreStockAdjustmentRequest $request, StockService $stockService): JsonResponse
    {
        $validated = $request->validated();

        $adjustment = DB::transaction(function () use ($validated, $request, $stockService) {
            $product = $stockService->lock([$validated['product_id']])->get($validated['product_id']);

            $adjustment = StockAdjustment::create([
                'admin_id' => $request->user()->id,
                'product_id' => $product->id,
                'type' => $validated['type'],
                'quantity' => $validated['quantity'],
                'description' => $validated['description'] ?? null,
            ]);

            $stockService->apply($product, -$validated['quantity'], 'adjustment', $adjustment->id);

            return $adjustment;
        });

        $adjustment->load('product.category', 'admin');

        return StockAdjustmentResource::make($adjustment)->response()->setStatusCode(201);
    }
}
