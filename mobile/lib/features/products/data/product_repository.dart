import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../domain/product.dart';

final Provider<ProductRepository> productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(apiClientProvider)),
);

/// Whole catalogue, refetched after any purchase, sale, or stock adjustment.
class ProductQuery {
  const ProductQuery({this.page = 1, this.search, this.categoryId});

  final int page;
  final String? search;
  final int? categoryId;

  @override
  bool operator ==(Object other) {
    return other is ProductQuery &&
        other.page == page &&
        other.search == search &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode => Object.hash(page, search, categoryId);
}

final productsProvider = FutureProvider.family<List<Product>, ProductQuery>(
  (ref, query) => ref.watch(productRepositoryProvider).list(
        page: query.page,
        search: query.search,
        categoryId: query.categoryId,
      ),
);

final FutureProvider<List<Product>> productListProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).list(),
);

final FutureProvider<List<Category>> categoryListProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(productRepositoryProvider).categories(),
);

class ProductRepository {
  ProductRepository(this._client);

  final ApiClient _client;

  Future<List<Product>> list({
    String? search,
    int? categoryId,
    int page = 1,
    int perPage = 20,
  }) async {
    final payload = await _client.getJson(
      '/products',
      query: <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
        if (categoryId != null) 'category_id': categoryId,
      },
    );
    return Product.listFromPayload(payload);
  }

  Future<List<Category>> categories() async {
    final payload = await _client.getJson('/categories');
    final rows = payload['data'];
    if (rows is! List) {
      return const <Category>[];
    }
    return rows
        .whereType<Map>()
        .map((row) => Category.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Product> create({
    required int categoryId,
    required String name,
    required num purchasePrice,
    required num sellingPrice,
    required int currentStock,
  }) async {
    final payload = await _client.postJson(
      '/products',
      body: <String, dynamic>{
        'category_id': categoryId,
        'name': name,
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'current_stock': currentStock,
      },
    );
    return Product.fromJson(ApiClient.unwrap(payload));
  }

  Future<Product> update(
    int id, {
    required int categoryId,
    required String name,
    required num purchasePrice,
    required num sellingPrice,
    required int currentStock,
  }) async {
    final payload = await _client.putJson(
      '/products/$id',
      body: <String, dynamic>{
        'category_id': categoryId,
        'name': name,
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'current_stock': currentStock,
      },
    );
    return Product.fromJson(ApiClient.unwrap(payload));
  }
}
