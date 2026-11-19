<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Product;
use App\Models\Purchase;
use App\Models\Sale;
use App\Models\StockHistory;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ReportTest extends TestCase
{
    use RefreshDatabase;

    public function test_profit_loss_is_filtered_by_month_and_year(): void
    {
        $owner = User::factory()->owner()->create();
        Sanctum::actingAs($owner);

        $cashier = User::factory()->kasir()->create();
        $admin = User::factory()->admin()->create();

        $augustSale = Sale::create(['cashier_id' => $cashier->id, 'total_amount' => 50000]);
        $augustSale->forceFill(['created_at' => '2026-08-10 09:00:00'])->save();

        $septemberSale = Sale::create(['cashier_id' => $cashier->id, 'total_amount' => 100000]);
        $septemberSale->forceFill(['created_at' => '2026-09-02 09:00:00'])->save();

        $augustPurchase = Purchase::create(['admin_id' => $admin->id, 'total_amount' => 30000]);
        $augustPurchase->forceFill(['created_at' => '2026-08-20 09:00:00'])->save();

        $response = $this->getJson('/api/reports/profit-loss?month=8&year=2026');

        $response->assertOk()
            ->assertJsonPath('month', 8)
            ->assertJsonPath('year', 2026)
            ->assertJsonPath('sales_total', 50000)
            ->assertJsonPath('purchases_total', 30000)
            ->assertJsonPath('profit', 20000)
            ->assertJsonPath('sales_count', 1)
            ->assertJsonPath('purchases_count', 1)
            ->assertJsonPath('daily.0.date', '2026-08-10')
            ->assertJsonPath('daily.0.profit', 50000);
    }

    public function test_profit_loss_rejects_invalid_month(): void
    {
        Sanctum::actingAs(User::factory()->owner()->create());

        $this->getJson('/api/reports/profit-loss?month=13&year=2026')
            ->assertStatus(422)
            ->assertJsonValidationErrors('month');
    }

    public function test_stock_history_returns_ledger_entries_with_product(): void
    {
        $owner = User::factory()->owner()->create();
        $category = Category::create(['name' => 'Makanan']);
        $product = Product::create([
            'category_id' => $category->id,
            'name' => 'Indomie Goreng',
            'purchase_price' => 2800,
            'selling_price' => 3500,
            'current_stock' => 8,
        ]);

        Sanctum::actingAs(User::factory()->kasir()->create());
        $sale = $this->postJson('/api/sales', [
            'items' => [['product_id' => $product->id, 'quantity' => 2]],
        ])->json('data');

        Sanctum::actingAs($owner);
        $response = $this->getJson('/api/reports/stock-history');

        $response->assertOk()
            ->assertJsonPath('data.0.product.name', 'Indomie Goreng')
            ->assertJsonPath('data.0.reference_type', 'sale')
            ->assertJsonPath('data.0.quantity_change', -2)
            ->assertJsonPath('data.0.final_stock', 6)
            ->assertJsonPath('data.0.reference_id', $sale['id'])
            ->assertJsonPath('data.0.reference.total_amount', 7000);
    }

    public function test_stock_history_can_filter_by_reference_type(): void
    {
        Sanctum::actingAs(User::factory()->owner()->create());

        $category = Category::create(['name' => 'Minuman']);
        $product = Product::create([
            'category_id' => $category->id,
            'name' => 'Aqua',
            'purchase_price' => 2500,
            'selling_price' => 4000,
            'current_stock' => 10,
        ]);

        StockHistory::create([
            'product_id' => $product->id,
            'reference_type' => 'adjustment',
            'reference_id' => 99,
            'quantity_change' => -1,
            'final_stock' => 9,
        ]);

        $this->getJson('/api/reports/stock-history?reference_type=adjustment')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.reference_type', 'adjustment');

        $this->getJson('/api/reports/stock-history?reference_type=sale')
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }
}
