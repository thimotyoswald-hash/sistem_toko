<?php

namespace Database\Seeders;

use App\Enums\Role;
use App\Models\Buyer;
use App\Models\Category;
use App\Models\Distributor;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $users = [
            ['name' => 'Kasir Satu', 'username' => 'kasir', 'role' => Role::Kasir],
            ['name' => 'Admin Toko', 'username' => 'admin', 'role' => Role::Admin],
            ['name' => 'Pemilik Toko', 'username' => 'owner', 'role' => Role::Owner],
        ];

        foreach ($users as $user) {
            User::updateOrCreate(
                ['username' => $user['username']],
                [...$user, 'password' => Hash::make('password')],
            );
        }

        $categories = collect(['Makanan', 'Minuman', 'Sembako', 'Kebersihan'])
            ->mapWithKeys(fn (string $name) => [$name => Category::firstOrCreate(['name' => $name])]);

        $products = [
            ['Makanan', 'Indomie Goreng', 2800, 3500, 120],
            ['Makanan', 'Roti Tawar Sari Roti', 12000, 15000, 40],
            ['Minuman', 'Aqua 600ml', 2500, 4000, 200],
            ['Minuman', 'Teh Pucuk 350ml', 3500, 5000, 96],
            ['Sembako', 'Beras Pandan Wangi 5kg', 62000, 72000, 25],
            ['Sembako', 'Minyak Goreng Bimoli 1L', 16000, 19000, 60],
            ['Sembako', 'Gula Pasir 1kg', 14000, 17000, 80],
            ['Kebersihan', 'Sabun Lifebuoy 75g', 3800, 5000, 150],
        ];

        foreach ($products as [$category, $name, $purchasePrice, $sellingPrice, $stock]) {
            Product::updateOrCreate(
                ['name' => $name],
                [
                    'category_id' => $categories[$category]->id,
                    'purchase_price' => $purchasePrice,
                    'selling_price' => $sellingPrice,
                    'current_stock' => $stock,
                ],
            );
        }

        Buyer::firstOrCreate(['name' => 'Umum']);

        Distributor::firstOrCreate(
            ['name' => 'PT Sumber Rejeki'],
            ['phone' => '021-5550100', 'address' => 'Jl. Industri No. 12, Jakarta'],
        );
    }
}
