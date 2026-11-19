<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BuyerController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\DistributorController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\PurchaseController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\SaleController;
use App\Http\Controllers\Api\StockAdjustmentController;
use Illuminate\Support\Facades\Route;

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Catalogue is read-only for cashiers so the POS screen can search products.
    Route::middleware('role:kasir,admin')->group(function () {
        Route::get('/products', [ProductController::class, 'index']);
        Route::get('/categories', [CategoryController::class, 'index']);
    });

    Route::middleware('role:kasir')->group(function () {
        Route::post('/sales', [SaleController::class, 'store']);
        Route::get('/buyers', [BuyerController::class, 'index']);
        Route::post('/buyers', [BuyerController::class, 'store']);
    });

    Route::middleware('role:admin')->group(function () {
        Route::post('/purchases', [PurchaseController::class, 'store']);
        Route::post('/products', [ProductController::class, 'store']);
        Route::put('/products/{product}', [ProductController::class, 'update']);
        Route::post('/categories', [CategoryController::class, 'store']);
        Route::get('/distributors', [DistributorController::class, 'index']);
        Route::post('/distributors', [DistributorController::class, 'store']);
        Route::put('/distributors/{distributor}', [DistributorController::class, 'update']);
        Route::post('/stock-adjustments', [StockAdjustmentController::class, 'store']);
    });

    Route::middleware('role:owner')->group(function () {
        Route::get('/reports/stock-history', [ReportController::class, 'stockHistory']);
        Route::get('/reports/profit-loss', [ReportController::class, 'profitLoss']);
    });
});
