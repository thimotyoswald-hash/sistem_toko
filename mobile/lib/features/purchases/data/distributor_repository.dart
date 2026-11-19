import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';

class Distributor {
  const Distributor({required this.id, required this.name, this.phone, this.address});

  final int id;
  final String name;
  final String? phone;
  final String? address;

  factory Distributor.fromJson(Map<String, dynamic> json) {
    return Distributor(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
    );
  }
}

class DistributorRepository {
  DistributorRepository(this._client);

  final ApiClient _client;

  Future<List<Distributor>> list() async {
    final payload = await _client.getJson('/distributors', query: <String, dynamic>{'per_page': 100});
    final rows = payload['data'];
    if (rows is! List) return const <Distributor>[];
    return rows
        .whereType<Map>()
        .map((row) => Distributor.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Distributor> create({required String name, String? phone, String? address}) async {
    final payload = await _client.postJson(
      '/distributors',
      body: <String, dynamic>{
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
      },
    );
    return Distributor.fromJson(ApiClient.unwrap(payload));
  }
}

final Provider<DistributorRepository> distributorRepositoryProvider =
    Provider<DistributorRepository>((ref) => DistributorRepository(ref.watch(apiClientProvider)));

final FutureProvider<List<Distributor>> distributorListProvider =
    FutureProvider<List<Distributor>>((ref) => ref.watch(distributorRepositoryProvider).list());
