<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AuthAndAccessTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_login_with_username_and_receives_token(): void
    {
        User::factory()->admin()->create([
            'username' => 'admin',
            'password' => 'rahasia',
        ]);

        $response = $this->postJson('/api/login', [
            'username' => 'admin',
            'password' => 'rahasia',
        ]);

        $response->assertOk()
            ->assertJsonPath('user.role', 'admin')
            ->assertJsonStructure(['token', 'user' => ['id', 'name', 'username', 'role']]);
    }

    public function test_login_fails_with_wrong_password(): void
    {
        User::factory()->create(['username' => 'kasir', 'password' => 'rahasia']);

        $this->postJson('/api/login', ['username' => 'kasir', 'password' => 'salah'])
            ->assertStatus(422)
            ->assertJsonValidationErrors('username');
    }

    public function test_guest_cannot_reach_protected_endpoints(): void
    {
        $this->getJson('/api/products')->assertUnauthorized();
    }

    public function test_kasir_cannot_touch_admin_endpoints(): void
    {
        Sanctum::actingAs(User::factory()->kasir()->create());

        $this->postJson('/api/products', [])->assertForbidden();
        $this->postJson('/api/purchases', [])->assertForbidden();
    }

    public function test_admin_cannot_create_sales(): void
    {
        Sanctum::actingAs(User::factory()->admin()->create());

        $this->postJson('/api/sales', [])->assertForbidden();
    }

    public function test_kasir_can_read_catalogue_but_not_reports(): void
    {
        Sanctum::actingAs(User::factory()->kasir()->create());

        $this->getJson('/api/products')
            ->assertOk()
            ->assertJsonStructure(['data', 'meta']);

        $this->getJson('/api/reports/profit-loss')->assertForbidden();
    }

    public function test_owner_can_read_reports_but_not_master_data(): void
    {
        Sanctum::actingAs(User::factory()->owner()->create());

        $this->getJson('/api/reports/profit-loss')->assertOk();
        $this->getJson('/api/reports/stock-history')->assertOk();
        $this->postJson('/api/products', [])->assertForbidden();
    }

    public function test_admin_can_create_product(): void
    {
        $category = Category::create(['name' => 'Minuman']);
        Sanctum::actingAs(User::factory()->admin()->create());

        $this->postJson('/api/products', [
            'category_id' => $category->id,
            'name' => 'Aqua 600ml',
            'purchase_price' => 2500,
            'selling_price' => 4000,
            'current_stock' => 10,
        ])->assertCreated()
            ->assertJsonPath('data.name', 'Aqua 600ml')
            ->assertJsonPath('data.current_stock', 10);
    }
}
