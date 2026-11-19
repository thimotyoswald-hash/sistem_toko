import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../domain/cart.dart';
import '../domain/sale.dart';

final Provider<SaleRepository> saleRepositoryProvider = Provider<SaleRepository>(
  (ref) => SaleRepository(ref.watch(apiClientProvider)),
);

final FutureProvider<List<Buyer>> buyerListProvider = FutureProvider<List<Buyer>>((ref) async {
  final payload = await ref.watch(apiClientProvider).getJson('/buyers');
  final rows = payload['data'];
  if (rows is! List) {
    return const <Buyer>[];
  }
  return rows
      .whereType<Map>()
      .map((row) => Buyer.fromJson(Map<String, dynamic>.from(row)))
      .toList();
});

class SaleRepository {
  SaleRepository(this._client);

  final ApiClient _client;

  /// Sends only product ids and quantities: the server owns prices and totals.
  Future<Sale> create({
    required List<({int productId, int quantity})> items,
    int? buyerId,
  }) async {
    final payload = await _client.postJson(
      '/sales',
      body: <String, dynamic>{
        if (buyerId != null) 'buyer_id': buyerId,
        'items': items
            .map((item) => <String, int>{'product_id': item.productId, 'quantity': item.quantity})
            .toList(),
      },
    );

    return Sale.fromJson(ApiClient.unwrap(payload));
  }

  Future<Buyer> createBuyer({required String name, String? phone}) async {
    final payload = await _client.postJson(
      '/buyers',
      body: <String, dynamic>{'name': name, if (phone != null && phone.isNotEmpty) 'phone': phone},
    );
    return Buyer.fromJson(ApiClient.unwrap(payload));
  }
}
