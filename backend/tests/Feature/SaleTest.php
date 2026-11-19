<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Product;
use App\Models\Sale;
use App\Models\StockHistory;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SaleTest extends TestCase
{
    use RefreshDatabase;

    private function product(int $stock = 10, float $price = 5000, string $name = 'Teh Pucuk'): Product
    {
        $category = Category::firstOrCreate(['name' => 'Minuman']);

        return Product::create([
            'category_id' => $category->id,
            'name' => $name,
            'purchase_price' => 3500,
            'selling_price' => $price,
            'current_stock' => $stock,
        ]);
    }

    public function test_checkout_decreases_stock_and_writes_ledger(): void
    {
        $kasir = User::factory()->kasir()->create();
        $product = $this->product(stock: 10, price: 5000);
        Sanctum::actingAs($kasir);

        $response = $this->postJson('/api/sales', [
            'items' => [['product_id' => $product->id, 'quantity' => 3]],
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.total_amount', 15000)
            ->assertJsonPath('data.items.0.quantity', 3)
            ->assertJsonPath('data.cashier', $kasir->name);

        $this->assertSame(7, $product->fresh()->current_stock);
        $this->assertDatabaseHas('stock_histories', [
            'product_id' => $product->id,
            'reference_type' => 'sale',
            'reference_id' => $response->json('data.id'),
            'quantity_change' => -3,
            'final_stock' => 7,
        ]);
    }

    public function test_total_uses_database_price_not_client_payload(): void
    {
        Sanctum::actingAs(User::factory()->kasir()->create());
        $product = $this->product(stock: 10, price: 5000);

        $this->postJson('/api/sales', [
            'items' => [[
                'product_id' => $product->id,
                'quantity' => 2,
                'selling_price' => 1,
                'subtotal' => 2,
            ]],
        ])->assertCreated()->assertJsonPath('data.total_amount', 10000);
    }

    public function test_checkout_is_rejected_when_stock_is_insufficient(): void
    {
        Sanctum::actingAs(User::factory()->kasir()->create());
        $product = $this->product(stock: 2);

        $this->postJson('/api/sales', [
            'items' => [['product_id' => $product->id, 'quantity' => 5]],
        ])->assertStatus(422)->assertJsonPath('message', fn ($message) => str_contains($message, 'tidak mencukupi'));

        $this->assertSame(2, $product->fresh()->current_stock);
        $this->assertSame(0, Sale::count());
        $this->assertSame(0, StockHistory::count());
    }

    public function test_a_failing_line_rolls_back_the_whole_sale(): void
    {
        Sanctum::actingAs(User::factory()->kasir()->create());
        $available = $this->product(stock: 10, name: 'Aqua');
        $scarce = $this->product(stock: 1, name: 'Beras');

        $this->postJson('/api/sales', [
            'items' => [
                ['product_id' => $available->id, 'quantity' => 2],
                ['product_id' => $scarce->id, 'quantity' => 2],
            ],
        ])->assertStatus(422);

        $this->assertSame(10, $available->fresh()->current_stock);
        $this->assertSame(1, $scarce->fresh()->current_stock);
        $this->assertSame(0, Sale::count());
        $this->assertSame(0, StockHistory::count());
    }

    public function test_duplicate_product_lines_are_rejected(): void
    {
        Sanctum::actingAs(User::factory()->kasir()->create());
        $product = $this->product();

        $this->postJson('/api/sales', [
            'items' => [
                ['product_id' => $product->id, 'quantity' => 1],
                ['product_id' => $product->id, 'quantity' => 1],
            ],
        ])->assertStatus(422)->assertJsonValidationErrors('items.1.product_id');
    }
}
