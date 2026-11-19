<?php

namespace App\Http\Resources;

use App\Models\StockHistory;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin StockHistory
 */
class StockHistoryResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'product' => new ProductResource($this->whenLoaded('product')),
            'reference_type' => $this->reference_type,
            'reference_id' => $this->reference_id,
            'reference' => $this->whenLoaded('reference', fn () => $this->referenceSummary()),
            'quantity_change' => $this->quantity_change,
            'final_stock' => $this->final_stock,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }

    /**
     * @return array<string, mixed>|null
     */
    private function referenceSummary(): ?array
    {
        if ($this->reference === null) {
            return null;
        }

        return match ($this->reference_type) {
            'sale', 'purchase' => [
                'total_amount' => (float) $this->reference->total_amount,
            ],
            'adjustment' => [
                'reason' => $this->reference->type,
                'description' => $this->reference->description,
            ],
            default => null,
        };
    }
}
