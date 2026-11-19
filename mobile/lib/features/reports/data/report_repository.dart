import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';

class ProfitLossReport {
  const ProfitLossReport({
    required this.month,
    required this.year,
    required this.salesTotal,
    required this.purchasesTotal,
    required this.profit,
    required this.salesCount,
    required this.purchasesCount,
    required this.daily,
  });

  final int month;
  final int year;
  final double salesTotal;
  final double purchasesTotal;
  final double profit;
  final int salesCount;
  final int purchasesCount;
  final List<DailyPoint> daily;

  factory ProfitLossReport.fromJson(Map<String, dynamic> json) {
    final daily = (json['daily'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((row) => DailyPoint.fromJson(Map<String, dynamic>.from(row)))
        .toList();
    return ProfitLossReport(
      month: (json['month'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      salesTotal: (json['sales_total'] as num).toDouble(),
      purchasesTotal: (json['purchases_total'] as num).toDouble(),
      profit: (json['profit'] as num).toDouble(),
      salesCount: (json['sales_count'] as num).toInt(),
      purchasesCount: (json['purchases_count'] as num).toInt(),
      daily: daily,
    );
  }
}

class DailyPoint {
  const DailyPoint({
    required this.date,
    required this.sales,
    required this.purchases,
    required this.profit,
  });

  final String date;
  final double sales;
  final double purchases;
  final double profit;

  factory DailyPoint.fromJson(Map<String, dynamic> json) {
    return DailyPoint(
      date: json['date'] as String,
      sales: (json['sales'] as num).toDouble(),
      purchases: (json['purchases'] as num).toDouble(),
      profit: (json['profit'] as num).toDouble(),
    );
  }
}

class StockHistoryEntry {
  const StockHistoryEntry({
    required this.id,
    required this.productId,
    required this.productName,
    required this.referenceType,
    required this.referenceId,
    required this.quantityChange,
    required this.finalStock,
    required this.createdAt,
    this.referenceTotal,
    this.adjustmentReason,
    this.adjustmentDescription,
  });

  final int id;
  final int productId;
  final String productName;
  final String referenceType;
  final int referenceId;
  final int quantityChange;
  final int finalStock;
  final String createdAt;
  final double? referenceTotal;
  final String? adjustmentReason;
  final String? adjustmentDescription;

  factory StockHistoryEntry.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final reference = json['reference'] as Map<String, dynamic>?;
    return StockHistoryEntry(
      id: (json['id'] as num).toInt(),
      productId: (product['id'] as num?)?.toInt() ?? 0,
      productName: (product['name'] as String?) ?? '-',
      referenceType: json['reference_type'] as String,
      referenceId: (json['reference_id'] as num).toInt(),
      quantityChange: (json['quantity_change'] as num).toInt(),
      finalStock: (json['final_stock'] as num).toInt(),
      createdAt: (json['created_at'] as String?) ?? '',
      referenceTotal: reference == null ? null : (reference['total_amount'] as num?)?.toDouble(),
      adjustmentReason: reference == null ? null : reference['reason'] as String?,
      adjustmentDescription: reference == null ? null : reference['description'] as String?,
    );
  }
}

class ReportRepository {
  ReportRepository(this._client);

  final ApiClient _client;

  Future<ProfitLossReport> profitLoss({required int month, required int year}) async {
    final payload = await _client.getJson(
      '/reports/profit-loss',
      query: <String, dynamic>{'month': month, 'year': year},
    );
    return ProfitLossReport.fromJson(payload);
  }

  Future<List<StockHistoryEntry>> stockHistory({
    int? productId,
    String? referenceType,
    int page = 1,
    int perPage = 25,
  }) async {
    final payload = await _client.getJson(
      '/reports/stock-history',
      query: <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (productId != null) 'product_id': productId,
        if (referenceType != null) 'reference_type': referenceType,
      },
    );
    final rows = payload['data'];
    if (rows is! List) return const <StockHistoryEntry>[];
    return rows
        .whereType<Map>()
        .map((row) => StockHistoryEntry.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }
}

final Provider<ReportRepository> reportRepositoryProvider =
    Provider<ReportRepository>((ref) => ReportRepository(ref.watch(apiClientProvider)));
