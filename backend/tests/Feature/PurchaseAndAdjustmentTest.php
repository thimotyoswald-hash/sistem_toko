<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Product;
use App\Models\StockAdjustment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PurchaseAndAdjustmentTest extends TestCase
{
    use RefreshDatabase;

    private function product(int $stock = 5): Product
    {
        $category = Category::firstOrCreate(['name' => 'Sembako']);

        return Product::create([
            'category_id' => $category->id,
            'name' => 'Gula Pasir 1kg',
            'purchase_price' => 14000,
            'selling_price' => 17000,
            'current_stock' => $stock,
        ]);
    }

    public function test_purchase_increases_stock_and_writes_ledger(): void
    {
        Sanctum::actingAs(User::factory()->admin()->create());
        $product = $this->product(stock: 5);

        $response = $this->postJson('/api/purchases', [
            'items' => [['product_id' => $product->id, 'quantity' => 10, 'purchase_price' => 14000]],
        ]);

        $response->assertCreated()->assertJsonPath('data.total_amount', 140000);

        $this->assertSame(15, $product->fresh()->current_stock);
        $this->assertDatabaseHas('stock_histories', [
            'product_id' => $product->id,
            'reference_type' => 'purchase',
            'reference_id' => $response->json('data.id'),
            'quantity_change' => 10,
            'final_stock' => 15,
        ]);
    }

    public function test_adjustment_decreases_stock_and_writes_ledger(): void
    {
        Sanctum::actingAs(User::factory()->admin()->create());
        $product = $this->product(stock: 10);

        $response = $this->postJson('/api/stock-adjustments', [
            'product_id' => $product->id,
            'type' => 'rusak',
            'quantity' => 4,
            'description' => 'Kemasan penyok',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.type', 'rusak')
            ->assertJsonPath('data.quantity', 4);

        $this->assertSame(6, $product->fresh()->current_stock);
        $this->assertDatabaseHas('stock_histories', [
            'product_id' => $product->id,
            'reference_type' => 'adjustment',
            'reference_id' => $response->json('data.id'),
            'quantity_change' => -4,
            'final_stock' => 6,
        ]);
    }

    public function test_adjustment_cannot_drive_stock_negative(): void
    {
        Sanctum::actingAs(User::factory()->admin()->create());
        $product = $this->product(stock: 3);

        $this->postJson('/api/stock-adjustments', [
            'product_id' => $product->id,
            'type' => 'expired',
            'quantity' => 10,
        ])->assertStatus(422);

        $this->assertSame(3, $product->fresh()->current_stock);
        $this->assertSame(0, StockAdjustment::count());
    }

    public function test_adjustment_rejects_unknown_type(): void
    {
        Sanctum::actingAs(User::factory()->admin()->create());
        $product = $this->product();

        $this->postJson('/api/stock-adjustments', [
            'product_id' => $product->id,
            'type' => 'hilang',
            'quantity' => 1,
        ])->assertStatus(422)->assertJsonValidationErrors('type');
    }
}
