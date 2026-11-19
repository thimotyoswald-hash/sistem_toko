<?php

namespace App\Http\Resources;

use App\Models\Purchase;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Purchase
 */
class PurchaseResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'distributor' => $this->whenLoaded('distributor', fn () => $this->distributor ? [
                'id' => $this->distributor->id,
                'name' => $this->distributor->name,
            ] : null),
            'admin' => $this->whenLoaded('admin', fn () => $this->admin->name),
            'total_amount' => (float) $this->total_amount,
            'items' => PurchaseItemResource::collection($this->whenLoaded('items')),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
