<?php

namespace App\Providers;

use App\Models\Purchase;
use App\Models\Sale;
use App\Models\StockAdjustment;
use Illuminate\Database\Eloquent\Relations\Relation;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Relation::morphMap([
            'sale' => Sale::class,
            'purchase' => Purchase::class,
            'adjustment' => StockAdjustment::class,
        ]);
    }
}
