import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';

class PurchaseRepository {
  PurchaseRepository(this._client);

  final ApiClient _client;

  Future<void> create({
    required int distributorId,
    required List<Map<String, dynamic>> items,
  }) async {
    await _client.postJson(
      '/purchases',
      body: <String, dynamic>{
        'distributor_id': distributorId,
        'items': items,
      },
    );
  }
}

final Provider<PurchaseRepository> purchaseRepositoryProvider =
    Provider<PurchaseRepository>((ref) => PurchaseRepository(ref.watch(apiClientProvider)));
