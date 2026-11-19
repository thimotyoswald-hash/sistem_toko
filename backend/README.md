# 🛒 Bagimu Negriku Market (BN Mart) - Backend API

REST API untuk sistem informasi keuangan dan POS ritel **Bagimu Negriku Market (BN Mart)**: penjualan (kasir), pembelian & manajemen stok (admin), serta laporan keuangan (owner).

## Setup

```sh
composer install
cp .env.example .env
php artisan key:generate
touch database/database.sqlite
php artisan migrate --seed
php artisan serve
```

Base URL: `http://127.0.0.1:8000/api`

## Akun Bawaan Sistem (Initial Accounts)

| Username | Password | Role  |
| -------- | -------- | ----- |
| kasir    | password | kasir |
| admin    | password | admin |
| owner    | password | owner |

Semua endpoint (kecuali login) memakai header `Authorization: Bearer <token>`.

## Endpoint

| Method | Path                        | Role         | Keterangan                                              |
| ------ | --------------------------- | ------------ | ------------------------------------------------------- |
| POST   | `/login`                    | publik       | Login `username` + `password`, mengembalikan token      |
| GET    | `/me`                       | semua        | Profil user yang login                                  |
| POST   | `/logout`                   | semua        | Hapus token aktif                                       |
| GET    | `/products`                 | kasir, admin | Daftar produk (pagination, `q`, `category_id`)          |
| GET    | `/categories`               | kasir, admin | Daftar kategori                                         |
| POST   | `/sales`                    | kasir        | Checkout: kurangi stok + catat ledger                   |
| GET    | `/buyers`                   | kasir        | Cari pembeli (`q`)                                      |
| POST   | `/buyers`                   | kasir        | Tambah pembeli                                          |
| POST   | `/purchases`                | admin        | Barang masuk: tambah stok + catat ledger                |
| POST   | `/products`                 | admin        | Tambah produk                                           |
| PUT    | `/products/{product}`       | admin        | Ubah produk                                             |
| POST   | `/categories`               | admin        | Tambah kategori                                         |
| GET    | `/distributors`             | admin        | Daftar distributor                                      |
| POST   | `/distributors`             | admin        | Tambah distributor                                      |
| PUT    | `/distributors/{distributor}` | admin      | Ubah distributor                                        |
| POST   | `/stock-adjustments`        | admin        | Barang keluar non-transaksi (rusak/expired/lainnya)     |
| GET    | `/reports/stock-history`    | owner        | Ledger stok, filter `product_id`, `reference_type`, `from`, `to` |
| GET    | `/reports/profit-loss`      | owner        | Laba/rugi per bulan, filter `month`, `year`             |

`GET /products` dibuka untuk kasir karena halaman POS membutuhkan katalog; endpoint tulis tetap admin-only.

## Aturan integritas stok

- Harga dan total **selalu dihitung di server** dari data produk, bukan dari payload klien.
- Setiap mutasi stok berjalan di dalam `DB::transaction()`.
- Produk yang terlibat di-`lockForUpdate()` lebih dulu (`App\Services\StockService::lock`), sehingga dua transaksi bersamaan tidak bisa menjual stok yang sama.
- `stock_histories` adalah satu-satunya ledger pergerakan stok: setiap baris mencatat `quantity_change` (+/-) dan `final_stock`.
- Stok tidak bisa minus: penjualan atau adjustment yang melebihi stok dibatalkan seluruhnya dan mengembalikan `422`.

## Contoh

Checkout:

```http
POST /api/sales
{
  "buyer_id": 1,
  "items": [{ "product_id": 3, "quantity": 2 }]
}
```

Laporan laba/rugi:

```http
GET /api/reports/profit-loss?month=8&year=2026
```

```json
{
  "month": 8,
  "year": 2026,
  "sales_total": 50000,
  "purchases_total": 30000,
  "profit": 20000,
  "sales_count": 1,
  "purchases_count": 1,
  "daily": [
    { "date": "2026-08-10", "sales": 50000, "purchases": 0, "profit": 50000 }
  ]
}
```

## Test

```sh
php artisan test
```
